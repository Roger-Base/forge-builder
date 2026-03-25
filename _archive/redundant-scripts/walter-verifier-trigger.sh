#!/bin/bash
# walter-verifier-trigger.sh
# Chains walter-correction-verifier.sh with idempotent tracking.
# Called by: (a) walter-heartbeat-executor.sh mark_complete path, (b) cron job every 5 min
# Tracks verified LRNs in walter-verified-lrns.json to prevent duplicate verification runs.
#
# HOW IT WORKS:
# 1. Read all entries from walter-fix-outcomes.jsonl
# 2. For each LRN not yet in verified set → call verifier and mark verified
# 3. Verifier writes to walter-verification-log.jsonl
# 4. Idempotent: safe to call multiple times, same outcome is never verified twice

WORKSPACE="/Users/roger/.openclaw/workspace"
STATE_DIR="$WORKSPACE/state"
OUTCOMES_FILE="$STATE_DIR/walter-fix-outcomes.jsonl"
VERIFIED_SET_FILE="$STATE_DIR/walter-verified-lrns.json"
VERIFIER_SCRIPT="$WORKSPACE/scripts/walter-correction-verifier.sh"
LOG_FILE="$STATE_DIR/walter-verifier-trigger.log"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Init verified set if missing
init_verified_set() {
    if [[ ! -f "$VERIFIED_SET_FILE" ]]; then
        echo '{"verified": []}' > "$VERIFIED_SET_FILE"
    fi
}

# Check if an LRN has already been verified
is_verified() {
    local lrn="$1"
    local verified=$(jq -r '.verified[]' "$VERIFIED_SET_FILE" 2>/dev/null | grep -F "$lrn" || echo "")
    [[ -n "$verified" ]]
}

# Mark an LRN as verified
mark_verified() {
    local lrn="$1"
    if [[ -z "$lrn" ]] || [[ "$lrn" == "null" ]]; then return; fi
    # Only add if not already present
    if ! is_verified "$lrn"; then
        jq --arg lrn "$lrn" --arg ts "$TIMESTAMP" \
           '.verified += [{"lrn": $lrn, "verifiedAt": $ts}]' \
           "$VERIFIED_SET_FILE" > "${VERIFIED_SET_FILE}.tmp" \
           && mv "${VERIFIED_SET_FILE}.tmp" "$VERIFIED_SET_FILE"
        echo "[trigger] Marked LRN=$lrn as verified."
    fi
}

# Read all unverified outcomes and verify each
process_unverified() {
    if [[ ! -f "$OUTCOMES_FILE" ]] || [[ ! -s "$OUTCOMES_FILE" ]]; then
        echo "[trigger] No fix outcomes to process."
        return 0
    fi

    init_verified_set

    local verified_count=0
    local skipped_count=0

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        lrn=$(echo "$line" | jq -r '.lrn // empty' 2>/dev/null || echo "")
        [[ -z "$lrn" ]] && continue

        if is_verified "$lrn"; then
            echo "[trigger] LRN=$lrn already verified, skipping."
            ((skipped_count++))
            continue
        fi

        echo "[trigger] Processing unverified outcome: LRN=$lrn"
        bash "$VERIFIER_SCRIPT"
        mark_verified "$lrn"
        ((verified_count++))
    done < <(grep -v '^$' "$OUTCOMES_FILE" 2>/dev/null || true)

    echo "[trigger] Done. verified=$verified_count, skipped=$skipped_count"
}

# ─── LOG ─────────────────────────────────────────────────────────────────────
log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" >> "$LOG_FILE"
}

log "=== Verifier trigger run ==="
process_unverified
log "=== End run ==="
exit 0
