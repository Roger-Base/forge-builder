#!/bin/bash
# walter-correction-router.sh
# Closes the feedback loop from mismatch-detector output.
# Step 2 in heartbeat cycle: after mismatch-detector, before task selection.
#
# Reads: walter-mismatch-log.jsonl (last entry)
# Reads: MISMATCH_EXIT env var or infers from last log entry
# Writes: QUEUE.md (correction tasks), walter-daily-metrics.json (counters)
# Output: walter-correction-override.json (signal for heartbeat-executor.sh)

set -euo pipefail

METRICS_FILE="${WALTER_METRICS:-/Users/roger/.openclaw/workspace/state/walter-daily-metrics.json}"
QUEUE_FILE="/Users/roger/.openclaw/workspace/walter/tasks/QUEUE.md"
OVERRIDE_FILE="/Users/roger/.openclaw/workspace/state/walter-correction-override.json"
LOG_FILE="/Users/roger/.openclaw/workspace/scripts/walter-mismatch-log.jsonl"
LEARNINGS_FILE="/Users/roger/.openclaw/workspace/.learnings/LEARNINGS.md"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Helpers ─────────────────────────────────────────────────────────────────

update_metrics() {
  local cycle_type="$1"
  local today
  today=$(date -u +%Y-%m-%d)

  mkdir -p "$(dirname "$METRICS_FILE")"

  local clean mismatch critical corrections date_in_file
  if [[ -f "$METRICS_FILE" ]]; then
    clean=$(jq -r '.cleanCycles // 0' "$METRICS_FILE" 2>/dev/null || echo 0)
    mismatch=$(jq -r '.mismatchCycles // 0' "$METRICS_FILE" 2>/dev/null || echo 0)
    critical=$(jq -r '.criticalCycles // 0' "$METRICS_FILE" 2>/dev/null || echo 0)
    corrections=$(jq -r '.correctionsInjected // []' "$METRICS_FILE" 2>/dev/null || echo '[]')
    date_in_file=$(jq -r '.date // ""' "$METRICS_FILE" 2>/dev/null || echo "")
  else
    clean=0; mismatch=0; critical=0; corrections='[]'; date_in_file=""
  fi

  if [[ "$date_in_file" != "$today" ]]; then
    clean=0; mismatch=0; critical=0; corrections='[]'
  fi

  case "$cycle_type" in
    clean)    clean=$((clean + 1)) ;;
    mismatch) mismatch=$((mismatch + 1)) ;;
    critical)
      critical=$((critical + 1))
      corrections=$(echo "$corrections" | jq ". + [{\"timestamp\":\"$TIMESTAMP\",\"type\":\"$MISMATCH_TYPE\",\"lrn\":\"${LRN_ID:-}\"}]")
      ;;
  esac

  printf '{"date":"%s","cleanCycles":%s,"mismatchCycles":%s,"criticalCycles":%s,"correctionsInjected":%s,"lastUpdated":"%s"}' \
    "$today" "$clean" "$mismatch" "$critical" "$corrections" "$TIMESTAMP" > "$METRICS_FILE"

  echo "[correction-router] Metrics updated. clean=$clean mismatch=$mismatch critical=$critical"
}

write_override() {
  local priority="$1" task="$2" reason="$3" lrn="$4"
  cat > "$OVERRIDE_FILE" << EOF
{
  "active": true,
  "priority": "$priority",
  "preferTask": "$task",
  "reason": "$reason",
  "lrn": "$lrn",
  "timestamp": "$TIMESTAMP",
  "ttlCycles": 3
}
EOF
  echo "[correction-router] Override written: $OVERRIDE_FILE"
}

inject_correction_task() {
  local title="$1" priority="$2" effort="$3" desc="$4"
  local id timestamp insert_line
  id="$(date +%s)-corr"
  timestamp="$TIMESTAMP"

  if [[ ! -f "$QUEUE_FILE" ]]; then
    echo "[correction-router] QUEUE.md not found. Skipping injection."
    return 0
  fi

  insert_line=$(grep -n "^## Ready" "$QUEUE_FILE" 2>/dev/null | head -1 | cut -d: -f1 || true)
  insert_line=${insert_line:-0}
  if [[ "$insert_line" -eq 0 ]]; then
    echo "[correction-router] No '## Ready' section in QUEUE.md. Skipping injection."
    return 0
  fi

  # Escape | and \ for markdown safety
  local escaped_title escaped_desc
  escaped_title=$(echo "$title" | sed 's/[|\\]/ /g')
  escaped_desc=$(echo "$desc" | sed 's/[|\\]/ /g')

  # Build multi-line task entry and insert after insert_line using awk
  awk -v line="$insert_line" -v title="$escaped_title" \
      -v tid="$id" -v pri="$priority" -v eff="$effort" \
      -v ts="$timestamp" -v desc="$escaped_desc" '
    NR == line {
      print $0
      print ""
      print "### [" title "]"
      print "- **id**: " tid
      print "- **priority**: " pri
      print "- **project**: walter-internal"
      print "- **effort**: " eff
      print "- **status**: Ready"
      print "- **Ready**: " ts
      printf "- **Description**: %s\n", desc
      next
    }
    { print }
    ' "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"

  echo "[correction-router] Injected correction task at priority $priority: $escaped_title"
}

# ─── Ensure state files exist ─────────────────────────────────────────────────
mkdir -p "$(dirname "$METRICS_FILE")" "$(dirname "$OVERRIDE_FILE")" "$(dirname "$QUEUE_FILE")" "$(dirname "$LEARNINGS_FILE")"
touch "$METRICS_FILE" "$LEARNINGS_FILE" 2>/dev/null || true

# ─── Determine detector exit code ────────────────────────────────────────────
if [[ -n "${MISMATCH_EXIT:-}" ]]; then
  DETECTOR_EXIT="$MISMATCH_EXIT"
  LAST_LOG_ENTRY="${LAST_LOG_ENTRY:-$(tail -1 "$LOG_FILE" 2>/dev/null || echo '{}')}"
else
  LAST_LOG_ENTRY=$(tail -1 "$LOG_FILE" 2>/dev/null || echo '{}')
  if [[ -s "$LOG_FILE" ]] && [[ "$LAST_LOG_ENTRY" != "{}" ]]; then
    SEV=$(echo "$LAST_LOG_ENTRY" | jq -r '.severity // "clean"')
    case "$SEV" in
      CRITICAL) DETECTOR_EXIT=2 ;;
      MISMATCH)  DETECTOR_EXIT=1 ;;
      *)         DETECTOR_EXIT=0 ;;
    esac
  else
    DETECTOR_EXIT=0
  fi
fi

echo "[correction-router] Timestamp: $TIMESTAMP"
echo "[correction-router] Detector exit code: $DETECTOR_EXIT"
[[ "$LAST_LOG_ENTRY" != "{}" ]] && echo "[correction-router] Last log: $LAST_LOG_ENTRY"

# ─── Parse log entry fields ───────────────────────────────────────────────────
MISMATCH_TYPE=$(echo "$LAST_LOG_ENTRY" | jq -r '.check // "none"')
STUCK_TASK=$(echo "$LAST_LOG_ENTRY" | jq -r '.task // ""')
TASK_AGE_MIN=$(echo "$LAST_LOG_ENTRY" | jq -r '.ageMinutes // 0')
CONSECUTIVE=$(echo "$LAST_LOG_ENTRY" | jq -r '.consecutiveSelections // 0')
SEVERITY=$(echo "$LAST_LOG_ENTRY" | jq -r '.severity // "clean"')
FINDING=$(echo "$LAST_LOG_ENTRY" | jq -r '.message // .finding // "Mismatch detected"')
DETAILS=$(echo "$LAST_LOG_ENTRY" | jq -r '.details // .description // ""')

# ─── Route ────────────────────────────────────────────────────────────────────
case "$DETECTOR_EXIT" in
  2) # CRITICAL
    echo "[correction-router] CRITICAL mismatch. Routing to correction."

    LRN_COUNT=$(grep -c "^## LRN-" "$LEARNINGS_FILE" 2>/dev/null || true)
    LRN_COUNT=${LRN_COUNT:-0}
    LRN_ID="LRN-$(date +%Y%m%d)-$(printf "%03d" "$((LRN_COUNT + 1))")"

    {
      echo ""
      echo "## $LRN_ID"
      echo ""
      echo "- **Timestamp**: $TIMESTAMP"
      echo "- **Severity**: CRITICAL"
      echo "- **Check Failed**: $MISMATCH_TYPE"
      echo "- **Finding**: $FINDING"
      echo "- **Details**: $DETAILS"
      echo "- **Stuck Task**: $STUCK_TASK"
      echo "- **Task Age**: ${TASK_AGE_MIN} minutes"
      echo "- **Consecutive Selections**: $CONSECUTIVE"
      echo "- **Auto-Promoted By**: walter-correction-router.sh"
      echo ""
    } >> "$LEARNINGS_FILE"

    inject_correction_task \
      "CORRECTION: Fix $MISMATCH_TYPE — ${STUCK_TASK:-unknown}" \
      "P0" "M" \
      "Auto-generated corrective task. Mismatch-detector flagged CRITICAL: **$FINDING**. Task '${STUCK_TASK}' aged ${TASK_AGE_MIN} minutes without selection."

    update_metrics "critical"
    write_override "P0" "$STUCK_TASK" "critical_mismatch" "$LRN_ID"

    echo "[correction-router] CRITICAL handled. LRN: $LRN_ID"
    ;;

  1) # MISMATCH
    echo "[correction-router] Mismatch detected. Routing to correction."

    INJECT_PRIORITY="P1-M"
    INJECT_EFFORT="S"
    case "$MISMATCH_TYPE" in
      p1_large_avoidance) INJECT_PRIORITY="P1-L"; INJECT_EFFORT="M" ;;
      same_priority_lock) INJECT_PRIORITY="P1-M"; INJECT_EFFORT="S" ;;
      role_mismatch)      INJECT_PRIORITY="P1-S"; INJECT_EFFORT="S" ;;
      stale_ready)        INJECT_PRIORITY="P1-S"; INJECT_EFFORT="S" ;;
      *)                  INJECT_PRIORITY="P1-M"; INJECT_EFFORT="S" ;;
    esac

    inject_correction_task \
      "CORRECTION: Address $MISMATCH_TYPE — ${STUCK_TASK:-queue quality}" \
      "$INJECT_PRIORITY" "$INJECT_EFFORT" \
      "Mismatch detector flagged **$MISMATCH_TYPE**. $CONSECUTIVE consecutive cycles of same-priority selection, or task stuck for ${TASK_AGE_MIN}+ minutes."

    update_metrics "mismatch"
    write_override "$INJECT_PRIORITY" "$STUCK_TASK" "mismatch_$MISMATCH_TYPE" ""

    echo "[correction-router] Mismatch handled. Priority: $INJECT_PRIORITY"
    ;;

  0|*) # CLEAN
    echo "[correction-router] Clean cycle."
    update_metrics "clean"
    rm -f "$OVERRIDE_FILE"
    ;;
esac

echo "[correction-router] Done."
exit 0
