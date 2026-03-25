#!/usr/bin/env zsh
# walter-cron-rca.sh
# Root Cause Analysis for Walter cron job failures.
# Uses zsh for associative array support.
# Stores findings in state/walter-rca-findings.json for Walter to learn from.

set -euo pipefail

SCRIPT_DIR="${0:a:h}"
WORKSPACE_DIR="${SCRIPT_DIR:h}"
STATE_DIR="$WORKSPACE_DIR/state"
ALERTS_FILE="$STATE_DIR/walter-cron-alerts.json"
FINDINGS_FILE="$STATE_DIR/walter-rca-findings.json"
RCAS_DIR="$STATE_DIR/walter-rca"
LOG_FILE="$STATE_DIR/walter-rca.log"

mkdir -p "$RCAS_DIR"

# ─── Job metadata (zsh associative array) ────────────────────────────────────

typeset -A JOB_NAMES
JOB_NAMES=(
  ["5914bcd4-d46b-4af0-a175-aeb2e0dde267"]="Walter Heartbeat Executor"
  ["840886f0-9ae4-42e1-bcf7-77068b0448a0"]="Walter Verifier Trigger"
  ["13300629-99d6-44da-b75b-9b443ecd152b"]="Walter Autonomous Research"
)

typeset -A JOB_SCRIPTS
JOB_SCRIPTS=(
  ["5914bcd4-d46b-4af0-a175-aeb2e0dde267"]="walter-heartbeat-executor.sh"
  ["840886f0-9ae4-42e1-bcf7-77068b0448a0"]="walter-verifier-trigger.sh"
  ["13300629-99d6-44da-b75b-9b443ecd152b"]="walter-autonomous-research.sh"
)

# ─── Logging ──────────────────────────────────────────────────────────────────

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [rca] $*"
}

log_to_file() {
  log "$*" | tee -a "$LOG_FILE"
}

# ─── Fetch failure details ────────────────────────────────────────────────────

get_last_runs() {
  local job_id="$1"
  local limit="${2:-5}"
  openclaw cron runs --id "$job_id" --limit "$limit" 2>/dev/null \
    | awk '/^{/{f=1} f' \
    || echo '{"entries":[]}'
}

get_error_summary() {
  local job_id="$1"
  local json
  json=$(get_last_runs "$job_id" 1)
  local error_msg summary_msg
  error_msg=$(echo "$json" | jq -r '.entries[0].error // "none"' 2>/dev/null | cut -c1-1000)
  summary_msg=$(echo "$json" | jq -r '.entries[0].summary // "none"' 2>/dev/null | cut -c1-500)
  echo "$error_msg| $summary_msg"
}

get_last_5_errors() {
  local job_id="$1"
  local json
  json=$(get_last_runs "$job_id" 5)
  local count
  count=$(echo "$json" | jq '.entries | length' 2>/dev/null || echo "0")

  local errors=""
  local i
  for (( i=0; i<count; i++ )); do
    local status summary error
    status=$(echo "$json" | jq -r ".entries[$i].status // \"ok\"" 2>/dev/null)
    summary=$(echo "$json" | jq -r ".entries[$i].summary // \"none\"" 2>/dev/null | cut -c1-500)
    error=$(echo "$json" | jq -r ".entries[$i].error // \"none\"" 2>/dev/null | cut -c1-500)
    if [[ "$status" == "error" ]]; then
      errors+="RUN_$i: status=error | summary=$summary | error=$error\n"
    fi
  done
  echo -e "${errors:-no errors found}"
}

# ─── Classify failure type ────────────────────────────────────────────────────

classify_failure() {
  local combined="${1:-}"
  local LOWER=${(L)combined}

  if [[ $LOWER =~ "(no such file|not found|cannot find|file does not exist|enoent)" ]]; then
    echo "MISSING_FILE"
  elif [[ $LOWER =~ "(permission denied|not executable|access denied|eacces|chmod)" ]]; then
    echo "PERMISSION"
  elif [[ $LOWER =~ "(jq:|parse error|invalid json|unexpected token|null is not a function|cannot iterate)" ]]; then
    echo "JSON_PARSE"
  elif [[ $LOWER =~ "(openclaw:|command not found|cli error|non-zero exit|cron.*not found|unknown command)" ]]; then
    echo "CLI_ERROR"
  elif [[ $LOWER =~ "(error at line|exited with|failed with|script error|exit code [1-9])" ]]; then
    echo "SCRIPT_ERROR"
  elif [[ $LOWER =~ "(timeout|connection refused|network|curl|fetch|fail.*http|tls|ssl)" ]]; then
    echo "NETWORK"
  elif [[ $LOWER =~ "(delivering to|delivery|telegram|chatid|chat id|target.*telegram)" ]]; then
    echo "DELIVERY_ERROR"
  elif [[ $LOWER =~ "(roger is|not idle|active|running|busy)" ]]; then
    echo "CONDITION_NOT_MET"
  elif [[ $LOWER =~ "(no tasks|queue empty|invalid task)" ]]; then
    echo "QUEUE_EMPTY"
  elif [[ $LOWER =~ "(memory|disk space|killed|oom|resource)" ]]; then
    echo "RESOURCE"
  else
    echo "UNKNOWN"
  fi
}

# ─── Generate fix recommendation ─────────────────────────────────────────────

get_fix() {
  local failure_type="$1"
  local job_id="$2"
  local job_name="${JOB_NAMES[$job_id]:-unknown}"
  local script="${JOB_SCRIPTS[$job_id]:-unknown}"

  case "$failure_type" in
    MISSING_FILE)
      echo "Create the missing file/script, or verify path in walter-cron-health-monitor.sh CRON_IDS array matches actual openclaw cron ID."
      ;;
    PERMISSION)
      echo "Run: chmod +x $WORKSPACE_DIR/scripts/$script — or check that the cron service account has execute permissions."
      ;;
    JSON_PARSE)
      echo "Debug the jq call: check openclaw output format, add stderr capture, verify jq expression matches actual JSON structure."
      ;;
    CLI_ERROR)
      echo "Check openclaw CLI availability and syntax. Run: openclaw cron list — verify cron job IDs haven't changed."
      ;;
    SCRIPT_ERROR)
      echo "Run the script manually to get full error trace: zsh -x $WORKSPACE_DIR/scripts/$script run 2>&1 | tail -50"
      ;;
    NETWORK)
      echo "Check network connectivity from host. Verify the target service/URL is reachable from the machine running the cron."
      ;;
    DELIVERY_ERROR)
      echo "The cron job completes work but fails on result delivery. Fix: configure the cron job delivery target (chatId/channel) in openclaw cron config, or set delivery.mode='none' if no announcement is needed."
      ;;
    CONDITION_NOT_MET)
      echo "Job ran when condition wasn't right (e.g. Roger not idle). This is expected behavior, not a bug. Consider removing 'set -e' if premature exit is undesirable."
      ;;
    QUEUE_EMPTY)
      echo "No tasks in queue. The script should exit 0 gracefully when queue is empty. Check that check_prerequisites handles this correctly."
      ;;
    RESOURCE)
      echo "Host resource exhaustion. Check disk space (df -h), memory (free -m), and cron service memory limits."
      ;;
    *)
      echo "Unable to classify automatically. Manual investigation required: check $STATE_DIR/walter-rca/job-${job_id}/latest-error.log"
      ;;
  esac
}

# ─── RCA severity ─────────────────────────────────────────────────────────────

get_severity() {
  local failure_type="$1"
  case "$failure_type" in
    MISSING_FILE|PERMISSION)  echo "CRITICAL" ;;
    SCRIPT_ERROR|CLI_ERROR)    echo "HIGH" ;;
    JSON_PARSE)                echo "HIGH" ;;
    DELIVERY_ERROR)           echo "HIGH" ;;
    NETWORK|RESOURCE)          echo "MEDIUM" ;;
    CONDITION_NOT_MET|QUEUE_EMPTY) echo "LOW" ;;
    *)                         echo "UNKNOWN" ;;
  esac
}

# ─── Auto-fix ─────────────────────────────────────────────────────────────────

try_auto_fix() {
  local failure_type="$1"
  local job_id="$2"
  local script="${JOB_SCRIPTS[$job_id]:-}"

  if [[ -z "$script" ]]; then return; fi
  local script_path="$WORKSPACE_DIR/scripts/$script"

  case "$failure_type" in
    PERMISSION)
      if [[ -f "$script_path" ]]; then
        log "ATTEMPTING: chmod +x $script_path"
        chmod +x "$script_path" 2>/dev/null && log "SUCCESS: Fixed permissions on $script" || log "FAILED: Could not fix permissions"
      fi
      ;;
    *)
      ;;
  esac
}

# ─── Prior lessons lookup ────────────────────────────────────────────────────

get_prior_lessons() {
  local failure_type="$1"
  local LESSONS_RETRIEVE="$SCRIPT_DIR/walter-lessons-retrieve.sh"
  local LESSONS_FILE="$STATE_DIR/walter-lessons-learned.json"

  if [[ ! -f "$LESSONS_FILE" ]]; then
    return 0
  fi

  local count
  count=$(jq ".lessons | map(select(.failure_type == \"$failure_type\")) | length" "$LESSONS_FILE" 2>/dev/null || echo "0")

  if [[ "$count" -eq 0 ]]; then
    return 0
  fi

  echo ""
  echo "=== PRIOR LESSONS ($count found for $failure_type) ==="
  jq -r ".lessons[] | select(.failure_type == \"$failure_type\") | \"[\(.lesson_id)] \(.failure_context)\n  Strength: \(.lesson_strength) | Occurrences: \(.occurrence_count)\n  Last occurred: \(.last_occurred)\n  Fix applied: \(.fix_applied)\n  Fix status: \(.fix_status)\n  Outcome: \(.outcome_summary)\n  Lesson: \(.lesson_text)\n  Prevention: \(.prevented_recurrence_actions)\n\"" "$LESSONS_FILE" 2>/dev/null
  echo "=== END PRIOR LESSONS ==="
  echo ""

  return 0
}

inject_prior_lessons_into_finding() {
  local failure_type="$1"
  local LESSONS_FILE="$STATE_DIR/walter-lessons-learned.json"

  if [[ ! -f "$LESSONS_FILE" ]]; then
    echo "{}"
    return
  fi

  local lessons_json
  lessons_json=$(jq -c "[.lessons[] | select(.failure_type == \"$failure_type\")] | if length > 0 then . else null end" "$LESSONS_FILE" 2>/dev/null || echo "null")
  echo "$lessons_json"
}

# ─── Main RCA routine ────────────────────────────────────────────────────────

run_rca() {
  local job_id="$1"
  local job_name="${JOB_NAMES[$job_id]:-$job_id}"
  local script="${JOB_SCRIPTS[$job_id]:-unknown}"

  log_to_file "=== Starting RCA: $job_name (id=$job_id) ==="

  # Skip jobs with no errors in last run
  local last_status
  last_status=$(get_last_runs "$job_id" 1 | jq -r '.entries[0].status // "ok"' 2>/dev/null)
  if [[ "$last_status" == "ok" ]]; then
    log_to_file "Last run status=ok — skipping RCA for $job_name"
    # Clear any stale open findings
    if [[ -f "$FINDINGS_FILE" && -s "$FINDINGS_FILE" ]]; then
      local cleared
      cleared=$(cat "$FINDINGS_FILE" | jq --arg id "$job_id" 'del(.[$id])' 2>/dev/null || echo "{}")
      echo "$cleared" > "$FINDINGS_FILE"
    fi
    return 0
  fi

  # Get error + summary text
  local error_text summary_text
  error_text=$(get_last_runs "$job_id" 1 | jq -r '.entries[0].error // "none"' 2>/dev/null | cut -c1-1000)
  summary_text=$(get_last_runs "$job_id" 1 | jq -r '.entries[0].summary // "none"' 2>/dev/null | cut -c1-500)
  local combined_text="${error_text} ${summary_text}"

  # Get 5-run error log
  local last_5_errors
  last_5_errors=$(get_last_5_errors "$job_id")

  # Classify
  local failure_type
  failure_type=$(classify_failure "$combined_text")

  # ── PROACTIVE LESSON LOOKUP (before fix recommendation) ──
  local prior_lessons_output
  prior_lessons_output=$(get_prior_lessons "$failure_type" 2>/dev/null || echo "")
  local prior_lessons_json
  prior_lessons_json=$(inject_prior_lessons_into_finding "$failure_type" 2>/dev/null || echo "null")
  local has_prior_lessons="false"
  [[ "$prior_lessons_json" != "null" && -n "$prior_lessons_json" && "$prior_lessons_json" != "[]" ]] && has_prior_lessons="true"

  local severity
  severity=$(get_severity "$failure_type")
  local fix_recommendation
  fix_recommendation=$(get_fix "$failure_type" "$job_id")

  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Write per-job RCA log
  local job_rca_dir="$RCAS_DIR/job-${job_id}"
  mkdir -p "$job_rca_dir"
  {
    echo "=== RCA for $job_name ==="
    echo "Job ID: $job_id"
    echo "Timestamp: $ts"
    echo ""
    echo "--- Last 5 error runs ---"
    echo "$last_5_errors"
    echo ""
    echo "Classification: $failure_type"
    echo "Severity: $severity"
    echo ""
    if [[ "$has_prior_lessons" == "true" ]]; then
      echo "⚡ PRIOR LESSONS DETECTED — see below before proceeding"
      echo ""
      echo "$prior_lessons_output"
    fi
    echo "Recommended fix:"
    echo "$fix_recommendation"
  } > "$job_rca_dir/latest-error.log"

  # Get consecutive failures from alerts file
  local consecutive=0
  if [[ -f "$ALERTS_FILE" && -s "$ALERTS_FILE" ]]; then
    consecutive=$(cat "$ALERTS_FILE" | jq -r ".$job_id.consecutiveFailures // 0" 2>/dev/null || echo "0")
  fi

  # Escape for JSON
  local error_escaped summary_escaped fix_escaped
  error_escaped=$(echo "$error_text" | jq -Rs '.' | jq -c . | tr -d '\n')
  summary_escaped=$(echo "$summary_text" | jq -Rs '.' | jq -c . | tr -d '\n')
  fix_escaped=$(echo "$fix_recommendation" | jq -Rs '.' | jq -c . | tr -d '\n')

  local auto_fixable="false"
  [[ "$failure_type" == "PERMISSION" ]] && auto_fixable="true"

  # Build finding JSON — includes prior_lessons if available
  local finding_json
  if [[ "$has_prior_lessons" == "true" ]]; then
    finding_json=$(jq -n \
      --arg id "$job_id" \
      --arg name "$job_name" \
      --arg script "$script" \
      --arg ts "$ts" \
      --argjson cf "$consecutive" \
      --arg err "$error_escaped" \
      --arg summ "$summary_escaped" \
      --arg ftype "$failure_type" \
      --arg sev "$severity" \
      --arg fix "$fix_escaped" \
      --argjson af "$auto_fixable" \
      --arg logpath "$job_rca_dir/latest-error.log" \
      --argjson prior "$prior_lessons_json" \
      '{
        ($id): {
          jobId: $id,
          jobName: $name,
          script: $script,
          timestamp: $ts,
          consecutiveFailures: $cf,
          lastError: $err,
          lastSummary: $summ,
          failureType: $ftype,
          severity: $sev,
          fixRecommendation: $fix,
          autoFixable: $af,
          rcaLog: $logpath,
          priorLessonsFound: true,
          priorLessons: $prior,
          status: "open"
        }
      }'
    )
  else
    finding_json=$(jq -n \
      --arg id "$job_id" \
      --arg name "$job_name" \
      --arg script "$script" \
      --arg ts "$ts" \
      --argjson cf "$consecutive" \
      --arg err "$error_escaped" \
      --arg summ "$summary_escaped" \
      --arg ftype "$failure_type" \
      --arg sev "$severity" \
      --arg fix "$fix_escaped" \
      --argjson af "$auto_fixable" \
      --arg logpath "$job_rca_dir/latest-error.log" \
      '{
        ($id): {
          jobId: $id,
          jobName: $name,
          script: $script,
          timestamp: $ts,
          consecutiveFailures: $cf,
          lastError: $err,
          lastSummary: $summ,
          failureType: $ftype,
          severity: $sev,
          fixRecommendation: $fix,
          autoFixable: $af,
          rcaLog: $logpath,
          priorLessonsFound: false,
          priorLessons: null,
          status: "open"
        }
      }'
    )
  fi

  # Merge into findings file
  local new_findings
  if [[ -f "$FINDINGS_FILE" && -s "$FINDINGS_FILE" ]]; then
    new_findings=$(cat "$FINDINGS_FILE" | jq --arg id "$job_id" 'del(.[$id])' 2>/dev/null || echo "{}")
  else
    new_findings="{}"
  fi
  new_findings=$(echo "$new_findings" | jq -s '.[0] * .[1]' =(print -r -- "$new_findings") =(print -r -- "$finding_json") 2>/dev/null || echo "{}")
  echo "$new_findings" > "$FINDINGS_FILE"

  log_to_file "CLASSIFICATION: $failure_type | SEVERITY: $severity | CONSECUTIVE: $consecutive"
  log_to_file "FIX: $fix_recommendation"
  log_to_file "=== RCA complete: $job_name ==="

  # Try auto-fix
  try_auto_fix "$failure_type" "$job_id"

  echo ""
  echo "=== RCA: $job_name ==="
  echo "  Failure type: $failure_type"
  echo "  Severity: $severity"
  echo "  Consecutive failures: $consecutive"
  if [[ "$has_prior_lessons" == "true" ]]; then
    local lesson_count
    lesson_count=$(echo "$prior_lessons_json" | jq 'length' 2>/dev/null || echo "N")
    echo "  ⚡ Prior lessons found: $lesson_count (see RCA log above)"
  fi
  echo "  Fix: $fix_recommendation"
  echo "  RCA log: $job_rca_dir/latest-error.log"
  echo ""
}

# ─── Entry point ──────────────────────────────────────────────────────────────

case "${1:-}" in
  run)
    if [[ ! -f "$ALERTS_FILE" || ! -s "$ALERTS_FILE" ]]; then
      log "No alerts file — nothing to RCA"
      exit 0
    fi

    local alerting_jobs
    alerting_jobs=$(cat "$ALERTS_FILE" | jq -r 'to_entries[] | select(.value.alertLevel == "WARNING" or .value.alertLevel == "CRITICAL") | .key' 2>/dev/null || echo "")

    if [[ -z "$alerting_jobs" ]]; then
      log "No alerting jobs — nothing to RCA"
      exit 0
    fi

    for job_id in ${=alerting_jobs}; do
      run_rca "$job_id"
    done
    ;;
  single)
    local job_id="${2:-}"
    if [[ -z "$job_id" ]]; then
      echo "Usage: $0 single <job_id>"
      exit 1
    fi
    run_rca "$job_id"
    ;;
  list)
    if [[ -f "$FINDINGS_FILE" && -s "$FINDINGS_FILE" ]]; then
      echo "=== Open RCA Findings ==="
      cat "$FINDINGS_FILE" | jq -r 'to_entries[] | "\(.value.severity // "?"): \(.value.jobName // .key) — \(.value.failureType // "?") — \(.value.status // "?")"' 2>/dev/null
    else
      echo "No RCA findings yet"
    fi
    ;;
  auto-fix)
    if [[ -f "$FINDINGS_FILE" && -s "$FINDINGS_FILE" ]]; then
      cat "$FINDINGS_FILE" | jq -r 'to_entries[] | select(.value.autoFixable == true) | .key' 2>/dev/null | while read job_id; do
        local script="${JOB_SCRIPTS[$job_id]:-}"
        if [[ -n "$script" && -f "$WORKSPACE_DIR/scripts/$script" ]]; then
          log "Auto-fixing permissions: $script"
          chmod +x "$WORKSPACE_DIR/scripts/$script" 2>/dev/null && log "FIXED: $script" || log "FAILED: $script"
        fi
      done
    fi
    ;;
  help|--help|-h)
    echo "walter-cron-rca.sh — Root Cause Analysis for Walter cron failures"
    echo ""
    echo "Usage:"
    echo "  $0 run         — RCA for all WARNING/CRITICAL alerting jobs"
    echo "  $0 single <id> — RCA for a specific job ID"
    echo "  $0 list        — List open RCA findings"
    echo "  $0 auto-fix    — Attempt auto-fix for fixable failures"
    echo ""
    echo "Findings stored: $FINDINGS_FILE"
    ;;
  *)
    echo "Usage: $0 {run|single|list|auto-fix}"
    exit 1
    ;;
esac
