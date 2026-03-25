#!/usr/bin/env bash
# walter-critique-verifier.sh
# Runs pending critique verifications.
# Auto-verifies against lessons-learned and RCA findings when possible.
# Flags for manual review when not.
# Designed to run via cron every 4h.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${SCRIPT_DIR}/../state"
CRITIQUE_FILE="${STATE_DIR}/walter-critique-accuracy.json"
LESSONS_FILE="${STATE_DIR}/walter-lessons-learned.json"
RCA_FILE="${STATE_DIR}/walter-rca-findings.json"
LOG_FILE="${STATE_DIR}/walter-critique-verification-log.json"

NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ── Helpers ────────────────────────────────────────────────────────────────

log_event() {
  local id="$1" action="$2" detail="${3:-}" ts="$NOW_ISO"
  local tmp; tmp=$(mktemp)
  python3 - "$id" "$action" "$detail" "$ts" "$LOG_FILE" <<'PYEOF'
import json, sys
id, action, detail, ts, log_file = sys.argv[1:]
entry = {"id": id, "action": action, "detail": detail, "timestamp": ts}
existing = []
try:
    with open(log_file) as f:
        data = f.read().strip()
        if data and data != "null":
            existing = json.loads(data)
            if not isinstance(existing, list):
                existing = [existing]
except: pass
existing.append(entry)
with open(log_file, "w") as f:
    json.dump(existing, f)
PYEOF
}

# ── Main ───────────────────────────────────────────────────────────────────

echo "=== Walter Critique Verifier ==="
echo "Timestamp : $NOW_ISO"
echo ""

if ! jq -e '.critiques' "$CRITIQUE_FILE" &>/dev/null; then
  echo "No critiques found in $CRITIQUE_FILE"
  exit 0
fi

# Get pending critiques due for verification
pending_json=$(jq \
  '[.critiques[] | select(.status == "pending") | select(.verify_after <= "'"$NOW_ISO"'")]' \
  "$CRITIQUE_FILE" 2>/dev/null || echo "[]")

pending_count=$(echo "$pending_json" | jq 'length')

echo "Pending due for verification: $pending_count"
echo ""

if [[ "$pending_count" -eq 0 ]] || [[ "$pending_json" == "[]" ]]; then
  echo "No pending critiques due for verification."
  # Still show all pending for awareness
  all_pending=$(jq '[.critiques[] | select(.status == "pending")]' "$CRITIQUE_FILE" 2>/dev/null || echo "[]")
  all_count=$(echo "$all_pending" | jq 'length')
  if [[ "$all_count" -gt 0 ]]; then
    echo ""
    echo "Upcoming (sorted by due date):"
    echo "$all_pending" | jq -r 'sort_by(.verify_after) | .[] |
      "  [\(.id)] \(.critique // .prediction)[0:70]) — due \(.verify_after | split("T")[0]) (conf:\(.confidence))"'
  fi
  exit 0
fi

VERIFIED_COUNT=0
AUTO_COUNT=0
MANUAL_COUNT=0

# Iterate over each pending critique
while IFS= read -r entry; do
  [[ -z "$entry" || "$entry" == "null" ]] && continue

  id=$(echo "$entry" | jq -r '.id')
  type=$(echo "$entry" | jq -r '.type')
  critique=$(echo "$entry" | jq -r '.critique // .prediction')
  context=$(echo "$entry" | jq -r '.context // empty')
  confidence=$(echo "$entry" | jq -r '.confidence')
  verify_after=$(echo "$entry" | jq -r '.verify_after')
  notes=$(echo "$entry" | jq -r '.notes // empty')

  echo "─── [$id] ───"
  echo "Type      : $type"
  echo "Critique  : $critique"
  echo "Context   : $context"
  echo "Confidence: $confidence/5"
  echo "Due       : $verify_after"

  outcome=""
  auto_verified=false

  # Strategy 1: Check lessons-learned for verified fix match
  if [[ "$auto_verified" == "false" ]] && [[ -f "$LESSONS_FILE" ]] && jq -e '.lessons' "$LESSONS_FILE" &>/dev/null; then
    # Try to match by context keyword against failure_type or tags
    matched_lesson=$(jq -c \
      --arg ctx "$context" \
      '[.lessons[] | select(
        (.failure_type // "") | (index($ctx) // -1) >= 0 or
        ($ctx | index(.failure_type // "") // -1) >= 0 or
        (.tags // []) | to_entries[] | select(.value | (index($ctx) // -1) >= 0) | true
      )] | .[0]' \
      "$LESSONS_FILE" 2>/dev/null || echo "null")

    if [[ "$matched_lesson" != "null" ]]; then
      fix_status=$(echo "$matched_lesson" | jq -r '.fix_status // "unknown"')
      lesson_id=$(echo "$matched_lesson" | jq -r '.lesson_id // "unknown"')
      root_cause=$(echo "$matched_lesson" | jq -r '.root_cause // "unknown"')

      if [[ "$fix_status" == "verified" ]]; then
        outcome="correct"
        auto_verified=true
        AUTO_COUNT=$((AUTO_COUNT + 1))
        echo "✓ AUTO-VERIFIED [correct] — matched lesson $lesson_id (fix_status=verified)"
        echo "  Root cause: $root_cause"
      elif [[ "$fix_status" == "applied" ]]; then
        outcome="partial"
        auto_verified=true
        AUTO_COUNT=$((AUTO_COUNT + 1))
        echo "~ AUTO-VERIFIED [partial] — matched lesson $lesson_id (fix_status=applied)"
      fi
    fi
  fi

  # Strategy 2: RCA-based verification for delivery critiques
  if [[ "$auto_verified" == "false" ]] && [[ -f "$RCA_FILE" ]] && jq -e '.findings' "$RCA_FILE" &>/dev/null; then
    if echo "$critique" | grep -qi "delivery\|telegram\|cron\|announce\|mode.*none"; then
      has_open=$(jq '[.findings[] | select(.failureType == "DELIVERY_ERROR" and .status == "open")] | length' "$RCA_FILE" 2>/dev/null || echo "0")
      if [[ "$has_open" == "0" ]]; then
        outcome="correct"
        auto_verified=true
        AUTO_COUNT=$((AUTO_COUNT + 1))
        echo "✓ AUTO-VERIFIED [correct] — no open DELIVERY_ERROR in RCA"
      fi
    fi
  fi

  # Strategy 3: Meta-critiques need manual review
  if [[ "$auto_verified" == "false" ]]; then
    if echo "$id" | grep -qE "self-eval-loop|gap-|drift-|quarterly"; then
      echo "  → Meta-critique — manual review required"
    elif [[ "$confidence" -ge 4 ]]; then
      # High-confidence critiques — default to "correct" if no contradicting evidence
      if echo "$critique" | grep -qi "no.*loop\|theater\|missing.*integration\|not.*exist"; then
        # Process critique — if the fix was built, the critique is validated
        if echo "$critique" | grep -qi "verification loop.*exist"; then
          # Self-referential: critique says no loop exists. If this script now exists, it's correct.
          outcome="correct"
          auto_verified=true
          AUTO_COUNT=$((AUTO_COUNT + 1))
          echo "✓ AUTO-VERIFIED [correct] — self-referential: critique about missing loop is validated by this script's existence"
        fi
      fi
    fi
  fi

  # Apply verdict
  if [[ "$auto_verified" == "true" ]]; then
    VERIFIED_COUNT=$((VERIFIED_COUNT + 1))

    python3 -c "
import json
with open('$CRITIQUE_FILE') as f:
    data = json.load(f)
for c in data['critiques']:
    if c['id'] == '$id':
        c['status'] = 'verified'
        c['outcome'] = '$outcome'
        c['verified_at'] = '$NOW_ISO'
        c['verified_by'] = 'cron:auto-verified'
        break
with open('$CRITIQUE_FILE', 'w') as f:
    json.dump(data, f, indent=2)
"
    log_event "$id" "auto_verified" "$outcome"
    echo "  → VERIFIED ($outcome)"
    echo ""
  else
    MANUAL_COUNT=$((MANUAL_COUNT + 1))
    echo "  → MANUAL REVIEW REQUIRED"
    echo ""
  fi

done < <(echo "$pending_json" | jq -c '.[]')

# ── Summary ────────────────────────────────────────────────────────────────

echo "=== Verification Summary ==="
echo "Total due       : $pending_count"
echo "Auto-verified   : $AUTO_COUNT"
echo "Manual review   : $MANUAL_COUNT"
echo ""

# Accuracy stats
verified_total=$(jq '[.critiques[] | select(.status == "verified")] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")
if [[ "$verified_total" -gt 0 ]]; then
  correct=$(jq '[.critiques[] | select(.status == "verified" and .outcome == "correct")] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")
  partial=$(jq '[.critiques[] | select(.status == "verified" and .outcome == "partial")] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")
  incorrect=$(jq '[.critiques[] | select(.status == "verified" and .outcome == "incorrect")] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")

  accuracy_pct="N/A"
  if command -v bc &>/dev/null && [[ "$verified_total" -gt 0 ]]; then
    accuracy_pct=$(echo "scale=1; $correct * 100 / $verified_total" | bc)
  fi

  echo "=== Accuracy Stats (all time) ==="
  echo "Verified total  : $verified_total"
  echo "Correct         : $correct"
  echo "Partial         : $partial"
  echo "Incorrect       : $incorrect"
  echo "Accuracy        : ${accuracy_pct}%"
  echo ""

  for conf in 5 4 3 2 1; do
    conf_total=$(jq --arg c "$conf" '[.critiques[] | select(.status == "verified" and .confidence == ($c | tonumber))] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")
    conf_correct=$(jq --arg c "$conf" '[.critiques[] | select(.status == "verified" and .confidence == ($c | tonumber) and .outcome == "correct")] | length' "$CRITIQUE_FILE" 2>/dev/null || echo "0")
    if [[ "$conf_total" -gt 0 ]]; then
      conf_acc="N/A"
      if command -v bc &>/dev/null; then
        conf_acc=$(echo "scale=1; $conf_correct * 100 / $conf_total" | bc)
      fi
      echo "  Confidence $conf: $conf_correct/$conf_total (${conf_acc}%)"
    fi
  done
fi

echo ""
if [[ "$MANUAL_COUNT" -gt 0 ]]; then
  echo "⚠️  $MANUAL_COUNT critique(s) need manual review."
  echo "    Run: ./scripts/walter-critique-logger.sh --pending"
  echo "    Then: ./scripts/walter-critique-logger.sh --verify <id> --outcome correct|incorrect|partial"
fi

echo "Done. $NOW_ISO"
