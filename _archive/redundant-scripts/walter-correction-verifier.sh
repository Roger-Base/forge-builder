#!/bin/bash
# walter-correction-verifier.sh
# Stage 4 of the detect→correct loop: VERIFY
# Runs after a correction task is marked Complete.
# Reads walter-fix-outcomes.jsonl (newest entry), extracts the original LRN,
# re-runs mismatch-detector, and writes verified/still-mismatched back to the plan.
# If still-mismatched: re-injects a follow-up task and increments escalation counter.

set -e

WORKSPACE="/Users/roger/.openclaw/workspace"
STATE_DIR="$WORKSPACE/state"
OUTCOMES_FILE="$STATE_DIR/walter-fix-outcomes.jsonl"
MISMATCH_LOG="$STATE_DIR/walter-mismatch-log.jsonl"
CORRECTION_PLANS="$STATE_DIR/walter-correction-plans.json"
OVERRIDE_FILE="$STATE_DIR/walter-correction-override.json"
QUEUE_FILE="$WORKSPACE/walter/tasks/QUEUE.md"
METRICS_FILE="$STATE_DIR/walter-daily-metrics.json"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Step 1: Read newest fix outcome ──────────────────────────────────────────
if [[ ! -f "$OUTCOMES_FILE" ]] || [[ ! -s "$OUTCOMES_FILE" ]]; then
    echo "[verifier] No fix outcomes found. Nothing to verify."
    exit 0
fi

newest=$(tail -1 "$OUTCOMES_FILE" | grep -v '^$' | head -1 || echo "")
if [[ -z "$newest" ]]; then
    echo "[verifier] No valid fix outcomes found. Nothing to verify."
    exit 0
fi
LRN=$(echo "$newest" | jq -r '.lrn // empty' 2>/dev/null || echo "")
ORIGINAL_TYPE=$(echo "$newest" | jq -r '.mismatchType // ""' 2>/dev/null || echo "")
TASK_TITLE=$(echo "$newest" | jq -r '.taskTitle // ""' 2>/dev/null || echo "")
COMPLETED_AT=$(echo "$newest" | jq -r '.completedAt // ""' 2>/dev/null || echo "")

if [[ -z "$LRN" ]]; then
    echo "[verifier] Newest outcome has no LRN. Skipping."
    exit 0
fi

echo "[verifier] Verifying correction for LRN=$LRN (type=$ORIGINAL_TYPE, task=$TASK_TITLE)"

# ─── Step 2: Run the mismatch detector to check current state ──────────────────
# Call the existing mismatch-detector (read-only check mode: exit 0=clean, 1=mismatch, 2=critical)
MISMATCH_CHECK_SCRIPT="$WORKSPACE/scripts/walter-mismatch-detector.sh"
if [[ ! -f "$MISMATCH_CHECK_SCRIPT" ]]; then
    echo "[verifier] mismatch-detector.sh not found at $MISMATCH_CHECK_SCRIPT. Using inline checks."
    MISMATCH_RESULT="inline_check"
    INLINE_CLEAN="true"

    # Inline P1-L stale task check (from mismatch-detector logic)
    if [[ -f "$QUEUE_FILE" ]]; then
        now_sec=$(date +%s)
        stale_limit=14400  # 4 hours
        while IFS= read -r line; do
            linenum=$(echo "$line" | cut -d: -f1)
            content=$(echo "$line" | cut -d: -f2-)
            if [[ "$content" =~ ^-\ \[\ \]\ \*\* ]]; then
                task_name="${content#*\[ \] **}"
                task_name="${task_name%%\*\*}"
                # look for Ready timestamp within next 10 lines
                ready_ts=""
                for ((off=1; off<=10; off++)); do
                    nl=$((linenum + off))
                    f=$(sed -n "${nl}p" "$QUEUE_FILE" 2>/dev/null || true)
                    if [[ "$f" =~ Ready:\ (20[0-9][0-9]-) ]]; then
                        ready_ts="${BASH_REMATCH[1]}"; break
                    fi
                done
                if [[ -n "$ready_ts" ]]; then
                    ready_sec=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${ready_ts}" +%s 2>/dev/null || echo "0")
                    age=$((now_sec - ready_sec))
                    if [[ "$age" -gt "$stale_limit" ]]; then
                        INLINE_CLEAN="false"
                        echo "[verifier] Inline check found stale task (${age}s old): $task_name"
                    fi
                fi
            fi
        done < <(grep -n "^" "$QUEUE_FILE" 2>/dev/null || true)
    fi

    if [[ "$INLINE_CLEAN" == "true" ]]; then
        MISMATCH_RESULT="clean"
        echo "[verifier] Inline check: no mismatches detected."
    else
        MISMATCH_RESULT="mismatch"
        echo "[verifier] Inline check: mismatch still present."
    fi
else
    set +e
    bash "$MISMATCH_CHECK_SCRIPT" > /dev/null 2>&1
    MISMATCH_EXIT=$?
    set -e

    case $MISMATCH_EXIT in
        0)  MISMATCH_RESULT="clean" ;;
        1)  MISMATCH_RESULT="mismatch" ;;
        2)  MISMATCH_RESULT="critical" ;;
        *)  MISMATCH_RESULT="unknown" ;;
    esac
    echo "[verifier] mismatch-detector exit=$MISMATCH_EXIT → result=$MISMATCH_RESULT"
fi

# ─── Step 3: Determine verification outcome ────────────────────────────────────
VERDICT="verified"   # default: mismatch resolved
REASON="Mismatch detector returned clean (exit 0). Original problem resolved."

if [[ "$MISMATCH_RESULT" == "mismatch" ]] || [[ "$MISMATCH_RESULT" == "critical" ]]; then
    VERDICT="still_mismatched"
    REASON="Mismatch detector still reporting $MISMICT_RESULT after correction. Original problem persists."

    # Re-inject follow-up task
    echo "[verifier] Re-injecting follow-up task for $LRN"
    FOLLOWUP_TITLE="Follow-up: $TASK_TITLE (escalated)"
    FOLLOWUP_LRN="LRN-$(date -u +%Y%m%d-%H%M%S)-FOLLOWUP"

    if [[ -f "$CORRECTION_PLANS" ]]; then
        # Append follow-up task to correction plans
        jq --arg title "$FOLLOWUP_TITLE" \
           --arg lrn "$FOLLOWUP_LRN" \
           --arg original "$LRN" \
           --arg timestamp "$TIMESTAMP" \
           '.corrections += [{
               "lrn": $lrn,
               "originalLrn": $original,
               "title": $title,
               "priority": "P1",
               "effort": "M",
               "status": "Ready",
               "readyAt": $timestamp,
               "type": "follow-up",
               "escalation": true
           }]' "$CORRECTION_PLANS" > "${CORRECTION_PLANS}.tmp" && mv "${CORRECTION_PLANS}.tmp" "$CORRECTION_PLANS"
    fi

    # Increment escalation counter in outcomes file (append to same line or add field)
    # For jsonl simplicity: add escalation note to a new entry in outcomes
    ESCALATION_LRN="LRN-$(date -u +%Y%m%d-%H%M%S)-ESC"
    cat >> "$OUTCOMES_FILE" << EOF
{"timestamp":"$TIMESTAMP","lrn":"$ESCALATION_LRN","originalLrn":"$LRN","type":"escalation","taskTitle":"$FOLLOWUP_TITLE","status":"escalated","reason":"$REASON"}
EOF

    # Clear the override (don't keep spinning on a broken fix)
    echo '{"active": false}' > "$OVERRIDE_FILE"

    echo "[verifier] ESCALATION: Problem persists after correction. Follow-up injected."
fi

# ─── Step 4: Write verification record ─────────────────────────────────────────
VERIFY_FILE="$STATE_DIR/walter-verification-log.jsonl"
cat >> "$VERIFY_FILE" << EOF
{"timestamp":"$TIMESTAMP","lrn":"$LRN","originalType":"$ORIGINAL_TYPE","taskTitle":"$TASK_TITLE","verdict":"$VERDICT","reason":"$REASON","mismatchResult":"$MISMATCH_RESULT"}
EOF

# ─── Step 5: Update metrics ────────────────────────────────────────────────────
if [[ -f "$METRICS_FILE" ]]; then
    jq --arg ts "$TIMESTAMP" \
       --arg verdict "$VERDICT" \
       --arg lrn "$LRN" \
       '.verificationCount = (.verificationCount // 0) + 1 |
        .lastVerification = {"timestamp": $ts, "lrn": $lrn, "verdict": $verdict}' \
       "$METRICS_FILE" > "${METRICS_FILE}.tmp" && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
fi

# ─── Step 6: Compute correction effectiveness (outcome quality, not activity) ─
EFFECTIVENESS_SCRIPT="$WORKSPACE/scripts/walter-correction-effectiveness.sh"
if [[ -f "$EFFECTIVENESS_SCRIPT" ]]; then
    bash "$EFFECTIVENESS_SCRIPT" > /dev/null 2>&1 || true
    echo "[verifier] Effectiveness metrics updated."
fi

echo "[verifier] VERDICT=$VERDICT for $LRN — $REASON"
echo "[verifier] Verification complete."

exit 0
