#!/bin/bash
# walter-cron-health-monitor.sh
# Health gate for all Walter cron jobs.
# Alerts on >=3 consecutive failures, auto-disables at >=10.
# Writes state to state/walter-cron-alerts.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use workspace root, not script directory for state
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$WORKSPACE_DIR/state"
ALERTS_FILE="$STATE_DIR/walter-cron-alerts.json"

mkdir -p "$STATE_DIR"

# ─── Actual Walter cron job IDs (from openclaw cron list) ───────────────────
# These are the real job IDs, not the short-form IDs in self-evaluation
WALTER_CRON_IDS=(
  "5914bcd4-d46b-4af0-a175-aeb2e0dde267"  # Walter Heartbeat Executor
  "840886f0-9ae4-42e1-bcf7-77068b0448a0"  # Walter Verifier Trigger
  "13300629-99d6-44da-b75b-9b443ecd152b"  # Walter Autonomous Research (BROKEN)
)

JOB_NAME_HEARTBEAT="Walter Heartbeat Executor"
JOB_NAME_VERIFIER="Walter Verifier Trigger"
JOB_NAME_RESEARCH="Walter Autonomous Research"

# Thresholds
ALERT_THRESHOLD=3
DISABLE_THRESHOLD=10

# ─── Functions ────────────────────────────────────────────────────────────────

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [health-monitor] $*" 2>&1 | tee -a "$STATE_DIR/walter-health-monitor.log"
}

get_job_name() {
  local job_id="$1"
  case "$job_id" in
    "5914bcd4-d46b-4af0-a175-aeb2e0dde267") echo "$JOB_NAME_HEARTBEAT" ;;
    "840886f0-9ae4-42e1-bcf7-77068b0448a0") echo "$JOB_NAME_VERIFIER" ;;
    "13300629-99d6-44da-b75b-9b443ecd152b") echo "$JOB_NAME_RESEARCH" ;;
    *) echo "$job_id" ;;
  esac
}

read_alerts() {
  if [[ -f "$ALERTS_FILE" && -s "$ALERTS_FILE" ]]; then
    cat "$ALERTS_FILE"
  else
    echo "{}"
  fi
}

write_alerts() {
  local content="$1"
  echo "$content" > "$ALERTS_FILE"
}

# Extract clean JSON from openclaw cron output (strips gigabrain plugin lines)
get_cron_json() {
  local job_id="$1"
  local limit="${2:-50}"
  openclaw cron runs --id "$job_id" --limit "$limit" 2>/dev/null | sed -n '/^{/,$p' || echo '{"entries":[]}'
}

get_consecutive_failures() {
  local job_id="$1"
  local json
  json=$(get_cron_json "$job_id" 50)

  # Count consecutive failures from most recent run backward
  # status: "ok" = success, "error" = failure
  local consecutive=0
  local count
  count=$(echo "$json" | jq '.entries | length' 2>/dev/null || echo "0")

  if [[ "$count" -eq 0 ]]; then
    echo "0"
    return
  fi

  # Iterate entries in order (most recent first)
  for i in $(seq 0 $((count - 1))); do
    local status
    status=$(echo "$json" | jq -r ".entries[$i].status // \"ok\"" 2>/dev/null || echo "ok")
    if [[ "$status" == "error" ]]; then
      consecutive=$((consecutive + 1))
    else
      break
    fi
  done

  # Strip trailing whitespace/newlines — critical for bash 3.2 arithmetic
  consecutive=$(echo "$consecutive" | tr -d '\n' | xargs)
  echo "$consecutive"
}

get_last_error() {
  local job_id="$1"
  local json
  json=$(get_cron_json "$job_id" 50)

  local count
  count=$(echo "$json" | jq '.entries | length' 2>/dev/null || echo "0")
  if [[ "$count" -eq 0 ]]; then
    echo "no run history"
    return
  fi

  local error_msg
  error_msg=$(echo "$json" | jq -r '.entries[0].error // "none"' 2>/dev/null | tr -d '\n' | cut -c1-300)
  if [[ -z "$error_msg" || "$error_msg" == "null" ]]; then
    error_msg="none"
  fi
  echo "$error_msg"
}

get_last_summary() {
  local job_id="$1"
  local json
  json=$(get_cron_json "$job_id" 1)

  local summary
  summary=$(echo "$json" | jq -r '.entries[0].summary // "none"' 2>/dev/null | head -5 | tr '\n' ' ' | cut -c1-200)
  if [[ -z "$summary" || "$summary" == "null" ]]; then
    summary="none"
  fi
  echo "$summary"
}

is_job_enabled() {
  local job_id="$1"
  local status_line
  status_line=$(openclaw cron list 2>/dev/null | grep "$job_id" || echo "")
  if echo "$status_line" | grep -qw "disabled"; then
    echo "false"
  else
    echo "true"
  fi
}

check_job_health() {
  local job_id="$1"
  local job_name
  job_name=$(get_job_name "$job_id")
  local consecutive
  consecutive=$(get_consecutive_failures "$job_id")
  consecutive=$(echo "$consecutive" | tr -d '\n' | xargs)  # sanitize multiline
  consecutive=${consecutive:-0}  # fallback to 0 if empty
  local last_error
  last_error=$(get_last_error "$job_id")
  local last_summary
  last_summary=$(get_last_summary "$job_id")
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  log "Checking $job_name (id=$job_id): consecutive_failures=$consecutive"

  local is_enabled
  is_enabled=$(is_job_enabled "$job_id")

  local alert_level=""
  local recommended_action="MONITOR"

  if (( consecutive >= DISABLE_THRESHOLD )); then
    alert_level="CRITICAL"
    recommended_action="DISABLE"
  elif (( consecutive >= ALERT_THRESHOLD )); then
    alert_level="WARNING"
    recommended_action="FIX"
  fi

  # Check if previously alerting
  local previous_alerts
  previous_alerts=$(read_alerts)
  local was_alerting
  was_alerting=$(echo "$previous_alerts" | grep -c "\"$job_id\"" || echo "0")
  was_alerting=$(echo "$was_alerting" | tr -d '\n' | xargs)  # sanitize newline from grep -c
  was_alerting=${was_alerting:-0}

  # Build alert entry as JSON
  local alert_entry
  alert_entry=$(jq -n \
    --arg id "$job_id" \
    --arg name "$job_name" \
    --arg level "${alert_level:-OK}" \
    --argjson cf "$consecutive" \
    --arg err "$last_error" \
    --arg action "$recommended_action" \
    --argjson enabled "$is_enabled" \
    --arg ts "$ts" \
    '{
      ($id): {
        jobName: $name,
        alertLevel: $level,
        consecutiveFailures: $cf,
        lastError: $err,
        recommendedAction: $action,
        enabled: $enabled,
        lastChecked: $ts,
        autoDisabled: false
      }
    }'
  )

  # Merge into alerts file
  local new_alerts
  if [[ -f "$ALERTS_FILE" && -s "$ALERTS_FILE" ]]; then
    new_alerts=$(cat "$ALERTS_FILE" | jq --arg id "$job_id" 'del(.[$id])' 2>/dev/null || echo "{}")
  else
    new_alerts="{}"
  fi
  new_alerts=$(echo "$new_alerts" | jq -s '.[0] * .[1]' <(echo "$new_alerts") <(echo "$alert_entry") 2>/dev/null || echo "{}")
  write_alerts "$new_alerts"

  # Handle recovery
  if (( was_alerting > 0 )) && (( consecutive == 0 )) && [[ "$is_enabled" == "true" ]]; then
    log "RECOVERED: $job_name (id=$job_id) — 0 consecutive failures"
    new_alerts=$(cat "$ALERTS_FILE" | jq --arg id "$job_id" 'del(.[$id])' 2>/dev/null || echo "{}")
    write_alerts "$new_alerts"
    echo "[$ts] RECOVERY: $job_name cleared from alerts" >> "$STATE_DIR/walter-cron-recovery-log.jsonl"
    return
  fi

  # Auto-disable at threshold
  if (( consecutive >= DISABLE_THRESHOLD )) && [[ "$is_enabled" == "true" ]]; then
    log "CRITICAL: $job_name (id=$job_id) — $consecutive consecutive failures — AUTO-DISABLING"
    openclaw cron disable "$job_id" 2>/dev/null || true
    new_alerts=$(cat "$ALERTS_FILE" | jq --arg id "$job_id" --arg ts "$ts" \
      '.[$id].autoDisabled = true | .[$id].lastChecked = $ts' 2>/dev/null || echo "{}")
    write_alerts "$new_alerts"
    echo "[$ts] AUTO-DISABLED: $job_name (id=$job_id) after $consecutive consecutive failures — last_error: $last_error" >> "$STATE_DIR/walter-cron-auto-disable-log.jsonl"
  elif [[ -n "$alert_level" ]]; then
    log "ALERT: $job_name (id=$job_id) — $consecutive consecutive failures — action: $recommended_action — last_error: $last_error"
  else
    log "OK: $job_name (id=$job_id) — healthy"
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

log "=== Starting Walter Cron Health Monitor ==="

for cron_id in "${WALTER_CRON_IDS[@]}"; do
  check_job_health "$cron_id"
done

log "=== Health monitor complete ==="

# Auto-trigger RCA for any alerting jobs
RCA_SCRIPT="$SCRIPT_DIR/walter-cron-rca.sh"
if [[ -x "$RCA_SCRIPT" ]]; then
  log "=== Triggering RCA for alerting jobs ==="
  zsh "$RCA_SCRIPT" run 2>&1 | while read line; do
    log "RCA: $line"
  done
  log "=== RCA complete ==="
else
  log "RCA script not found or not executable: $RCA_SCRIPT"
fi

# Emit summary
echo ""
echo "=== Walter Cron Health Summary ==="
if [[ -f "$ALERTS_FILE" && -s "$ALERTS_FILE" ]]; then
  # Only show non-OK entries
  cat "$ALERTS_FILE" | jq -r 'to_entries[] | select(.value.alertLevel != "OK") | "\(.value.alertLevel): \(.value.jobName) — \(.value.consecutiveFailures) failures — \(.value.recommendedAction)"' 2>/dev/null && echo "" && cat "$ALERTS_FILE" | jq -r 'to_entries[] | select(.value.alertLevel == "OK") | "OK: \(.value.jobName)"' 2>/dev/null
else
  echo "All Walter cron jobs: HEALTHY"
fi
