#!/usr/bin/env bash
# walter-self-improvement-trigger.sh
# Signal-driven self-improvement trigger for Walter.
# Reads outputs from Walter's monitoring scripts and fires a self-improvement
# pulse when degradation is detected, closing the gap between detection and
# self-correction.
#
# Usage: bash walter-self-improvement-trigger.sh
# Exit codes:
#   0 = check complete (pulse fired or no pulse needed)
#   1 = error during check

set -euo pipefail

WORKSPACE="${WALTER_WORKSPACE:-/Users/roger/.openclaw/workspace}"
WALTER_AGENT_WORKSPACE="${WALTER_AGENT_WORKSPACE:-/Users/roger/.openclaw/workspace-walter}"
STATE_DIR="${WORKSPACE}/state"
SCRIPTS_DIR="${WORKSPACE}/scripts"
SIGNAL_FILE="${STATE_DIR}/walter-improvement-signals.json"
LAST_TRIGGER_FILE="${STATE_DIR}/walter-last-improvement-trigger.json"
LOG_FILE="${STATE_DIR}/walter-improvement-trigger-log.json"
DOCTRINE_SYNC_SCRIPT="${SCRIPTS_DIR}/doctrine-capsule-sync.mjs"

# Minimum interval between pulses (seconds) — prevents spam
MIN_PULSE_INTERVAL_SECS="${MIN_PULSE_INTERVAL_SECS:-1800}"

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

log_event() {
  local level="$1"; shift
  local msg="$1"; shift
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  python3 -c "
import json, sys
entry = {'timestamp': '${ts}', 'level': '${level}', 'message': \"\"\"${msg}\"\"\"}
try:
    with open('${LOG_FILE}') as f:
        log = json.load(f)
except:
    log = []
log.append(entry)
log = log[-200:]
with open('${LOG_FILE}', 'w') as f:
    json.dump(log, f, indent=2)
" 2>/dev/null || true
}

check_min_interval() {
  if [[ ! -f "${LAST_TRIGGER_FILE}" ]]; then return 0; fi
  local last_sec
  last_sec=$(python3 -c "
import json, datetime, sys
try:
    d = json.load(open('${LAST_TRIGGER_FILE}'))
    ts = d.get('triggered_at', '2000-01-01T00:00:00Z')
    last = datetime.datetime.fromisoformat(ts.replace('Z','+00:00'))
    now  = datetime.datetime.now(datetime.timezone.utc)
    print(int((now - last).total_seconds()))
except:
    print(999999)
" 2>/dev/null || echo "999999")
  if [[ "${last_sec}" -lt "${MIN_PULSE_INTERVAL_SECS}" ]]; then
    log_event "info" "Pulse suppressed: last trigger ${last_sec}s ago (< ${MIN_PULSE_INTERVAL_SECS}s minimum)"
    return 1
  fi
  return 0
}

mark_triggered() {
  local reason="$1"; local sc="${2:-0}"
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  python3 -c "
import json
with open('${LAST_TRIGGER_FILE}', 'w') as f:
    json.dump({'triggered_at': '${ts}', 'reason': \"\"\"${reason}\"\"\", 'signal_count': ${sc}}, f, indent=2)
" 2>/dev/null || true
}

sync_doctrine_capsule() {
  if [[ ! -f "${DOCTRINE_SYNC_SCRIPT}" ]]; then
    return 0
  fi
  if ! command -v node >/dev/null 2>&1; then
    log_event "warn" "Doctrine sync skipped: node not available"
    return 0
  fi
  if ! node "${DOCTRINE_SYNC_SCRIPT}" --agent Walter --workspace "${WALTER_AGENT_WORKSPACE}" >/dev/null 2>&1; then
    log_event "warn" "Doctrine sync failed for Walter workspace ${WALTER_AGENT_WORKSPACE}"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SIGNAL SOURCE CHECKS  (each returns "PASS" | "WARN: <msg>" | "CRITICAL: <msg>")
# ══════════════════════════════════════════════════════════════════════════════

# ── Priority integration ───────────────────────────────────────────────────────

# Call the signal priority scorer to determine top-ranked signal
get_top_priority_signal() {
  local scorer="${SCRIPTS_DIR}/walter-signal-priority-scorer.sh"
  if [[ ! -f "${scorer}" ]]; then
    echo ""
    return
  fi
  local output
  output=$(bash "${scorer}" 2>&1 || true)
  local top_line
  top_line=$(echo "$output" | grep "^TOP|" | head -1 || true)
  if [[ -n "$top_line" ]]; then
    # Format: TOP|type|score|severity|signal
    echo "$top_line"
  else
    echo ""
  fi
}

# Returns PASS or WARN/CRITICAL based on health monitor exit code + keywords
check_source_health_monitor() {
  local script="${SCRIPTS_DIR}/walter-cron-health-monitor.sh"
  if [[ ! -f "${script}" ]]; then echo "PASS"; return; fi
  local output rc
  output=$(bash "${script}" 2>&1); rc=$?
  if [[ ${rc} -ne 0 ]]; then
    echo "CRITICAL: health monitor exited ${rc}"
    return
  fi
  if echo "${output}" | grep -qiE "critical|degraded|autodisable|error threshold|failing"; then
    echo "WARN: health monitor reports degraded or critical state"
  else
    echo "PASS"
  fi
}

check_source_escalations() {
  local file="${STATE_DIR}/walter-escalations.json"
  if [[ ! -f "${file}" ]]; then echo "PASS"; return; fi
  local critical overdue
  critical=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    print(sum(1 for v in data.values() if v.get('escalation_status') == 'critical'))
except: print(0)
" 2>/dev/null || echo 0)
  overdue=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    print(sum(1 for v in data.values() if v.get('escalation_status') == 'overdue'))
except: print(0)
" 2>/dev/null || echo 0)
  if [[ "${critical}" -gt 0 ]]; then
    echo "CRITICAL: ${critical} critical escalation(s)"
  elif [[ "${overdue}" -gt 0 ]]; then
    echo "WARN: ${overdue} overdue escalation(s)"
  else
    echo "PASS"
  fi
}

check_source_rca_findings() {
  local file="${STATE_DIR}/walter-rca-findings.json"
  if [[ ! -f "${file}" ]]; then echo "PASS"; return; fi
  local open_count critical_count
  open_count=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    print(len([v for v in data.values() if v.get('status') == 'open']))
except: print(0)
" 2>/dev/null || echo 0)
  critical_count=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    print(len([v for v in data.values() if v.get('status') == 'open' and v.get('severity') in ('CRITICAL','HIGH')]))
except: print(0)
" 2>/dev/null || echo 0)
  if [[ "${critical_count}" -gt 0 ]]; then
    echo "CRITICAL: ${critical_count} open critical/high RCA finding(s)"
  elif [[ "${open_count}" -gt 2 ]]; then
    echo "WARN: ${open_count} open RCA findings (elevated volume)"
  else
    echo "PASS"
  fi
}

check_source_critique_pending() {
  local file="${STATE_DIR}/walter-critique-accuracy.json"
  if [[ ! -f "${file}" ]]; then echo "PASS"; return; fi
  local overdue_count
  overdue_count=$(python3 -c "
import json, datetime, sys
try:
    import dateutil.parser as dp
    parser = lambda s: dp.isoparse(s)
except Exception:
    parser = lambda s: datetime.datetime.fromisoformat(s.replace('Z','+00:00'))
data = json.load(open('${file}'))
now = datetime.datetime.now(datetime.timezone.utc)
overdue = 0
for e in data.get('critiques', []):
    if e.get('status') == 'pending':
        va = e.get('verify_after', '')
        if va:
            try:
                if parser(va) < now:
                    overdue += 1
            except: pass
print(overdue)
" 2>/dev/null || echo 0)
  if [[ "${overdue_count}" -gt 0 ]]; then
    echo "WARN: ${overdue_count} overdue critique verification(s)"
  else
    echo "PASS"
  fi
}

# ── State consistency: run walter-state-sanity-checker.sh ──────────────────────
# Catches: orphaned suppressions (LRN-WALTER-001 pattern), stale trackers,
# RCA status/tracker drift, SLA breaches. First run caught: consecutive_count=3
# on lesson-unverified was CLOSED in RCA — tracker never updated post-work.
# Adding this as an automatic signal source closes the detection gap.
check_source_state_sanity() {
  local script="${STATE_DIR}/walter-state-sanity-checker.sh"
  if [[ ! -f "${script}" ]]; then echo "PASS"; return; fi
  local output rc
  output=$(bash "${script}" 2>&1); rc=$?
  case ${rc} in
    0)  echo "PASS" ;;
    1)  # Degraded: extract WARN-level lines
        local warn_line
        warn_line=$(echo "${output}" | grep "WARN\|WARNING\|⚠" | head -1 || true)
        if [[ -n "${warn_line}" ]]; then
          echo "WARN: state sanity degraded — ${warn_line}"
        else
          echo "WARN: state sanity reports degraded consistency"
        fi
        ;;
    2|*) # Critical: extract CRIT-level lines (the actual finding)
        local crit_lines
        crit_lines=$(echo "${output}" | grep "CRIT\|❌\|ERROR\|critical" | head -3 || true)
        if [[ -n "${crit_lines}" ]]; then
          echo "CRITICAL: state sanity — ${crit_lines}"
        else
          echo "CRITICAL: state sanity check returned code ${rc}"
        fi
        ;;
  esac
}

check_source_lessons_unverified() {
  local file="${STATE_DIR}/walter-lessons-learned.json"
  if [[ ! -f "${file}" ]]; then echo "PASS"; return; fi
  local unverified
  unverified=$(python3 -c "
import json
try:
    data = json.load(open('${file}'))
    print(sum(1 for e in data.get('lessons', []) if e.get('fix_status') not in ('verified','applied')))
except: print(0)
" 2>/dev/null || echo 0)
  if [[ "${unverified}" -gt 3 ]]; then
    echo "WARN: ${unverified} lessons with unverified fix_status (possible stale claims)"
  else
    echo "PASS"
  fi
}

# ── Horizon scan: read walter-improvement-priorities.json ─────────────────────
# Uses the horizon scanner's top_priority + horizon_score to inject forward-looking
# urgency into the improvement pulse. If horizon_score >= 7, bumps signal to CRITICAL
# regardless of current signal state.
#
# AUTO-DISABLE (LRN-WALTER-001 prevention): suppression is valid ONLY after verifying
# the underlying work was actually attempted — not as a substitute for doing it.
# If the work was not attempted and cannot be auto-resolved, mark SUPPRESS_WITH_BLOCKER
# and surface to Roger instead of silently suppressing.

# LRN-WALTER-001 prevention gate: before allowing horizon suppression,
# verify the underlying work was actually attempted.
# Returns: WORK_DONE | WORK_BLOCKED | WORK_NOT_ATTEMPTED | NO_TRACKING
verify_horizon_work_attempted() {
  local top_id="$1"
  local horizon_score="$2"

  # Map common horizon IDs to their tracking locations
  # Pattern: horizon top_id -> (rca_findings key OR lesson_id)
  local rca_file="${STATE_DIR}/walter-rca-findings.json"
  local lessons_file="${STATE_DIR}/walter-lessons-learned.json"

  # Try to find an RCA or lesson matching this top_id
  local rca_status lesson_status found

  # 1. Check RCA findings
  if [[ -f "${rca_file}" ]]; then
    rca_status=$(python3 -c "
import json, sys
try:
    data = json.load(open('${rca_file}'))
    key = '${top_id}'
    # Exact match
    if key in data:
        print(data[key].get('status', 'unknown'))
        sys.exit(0)
    # Partial match (finding_id contains top_id)
    for k, v in data.items():
        if '${top_id}' in k or k in '${top_id}':
            print(v.get('status', 'unknown'))
            sys.exit(0)
    print('NO_TRACKING')
except Exception as e:
    print('NO_TRACKING')
" 2>/dev/null || echo "NO_TRACKING")
  else
    rca_status="NO_TRACKING"
  fi

  # 2. Check lessons learned (for lesson-related horizon items)
  if [[ -f "${lessons_file}" ]] && [[ "${rca_status}" == "NO_TRACKING" ]]; then
    lesson_status=$(python3 -c "
import json, sys
try:
    data = json.load(open('${lessons_file}'))
    for lesson in data.get('lessons', []):
        lid = lesson.get('lesson_id', '')
        if '${top_id}' in lid or lid in '${top_id}':
            print(lesson.get('fix_status', 'unknown'))
            sys.exit(0)
    print('NO_TRACKING')
except:
    print('NO_TRACKING')
" 2>/dev/null || echo "NO_TRACKING")
    if [[ "${lesson_status}" != "NO_TRACKING" ]]; then
      rca_status="${lesson_status}"
    fi
  fi

  # Evaluate the verification result
  case "${rca_status}" in
    CLOSED_VERIFIED|verified|applied|fixed|closed_wont_fix)
      echo "WORK_DONE"
      ;;
    open|pending|in_progress)
      # Open but not blocked — work was attempted, keep signal alive
      echo "WORK_BLOCKED"
      ;;
    NO_TRACKING)
      # Not tracked in RCA/lessons — check if tracker already documented this
      # as WORK_DONE or UNVERIFIABLE_AUTO (manual resolution)
      if [[ -f "${tracker_file}" ]]; then
        local tracker_reason
        tracker_reason=$(python3 -c "
import json
try:
    d = json.load(open('${tracker_file}'))
    print(d.get('suppress_reason', 'NO_TRACKING'))
except:
    print('NO_TRACKING')
" 2>/dev/null || echo "NO_TRACKING")
        if [[ "${tracker_reason}" == "WORK_DONE" ]]; then
          echo "WORK_DONE"
        elif [[ "${tracker_reason}" == "UNVERIFIABLE_AUTO" ]]; then
          echo "UNVERIFIABLE_AUTO"
        else
          echo "NO_TRACKING"
        fi
      else
        echo "NO_TRACKING"
      fi
      ;;
    UNVERIFIABLE_AUTO|prevention_acknowledged)
      # Known unverifiable — document the blocker and suppress with flag
      echo "UNVERIFIABLE_AUTO"
      ;;
    *)
      echo "NO_TRACKING"
      ;;
  esac
}

check_horizon_top_priority() {
  local priorities_file="${STATE_DIR}/walter-improvement-priorities.json"
  local tracker_file="${STATE_DIR}/walter-horizon-tracker.json"
  local CONSECUTIVE_SUPPRESS=3

  if [[ ! -f "${priorities_file}" ]]; then
    echo "PASS"
    return
  fi

  # Check if priorities file is stale (>24h old)
  local file_age_hrs
  file_age_hrs=$(python3 -c "
import json, datetime, os
try:
    mtime = os.path.getmtime('${priorities_file}')
    age = (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromtimestamp(mtime, tz=datetime.timezone.utc)).total_seconds() / 3600
    print(round(age, 1))
except:
    print(999)
" 2>/dev/null || echo "999")

  local is_stale
  is_stale=$(python3 -c "
try:
    print(1 if float('${file_age_hrs}') > 24 else 0)
except:
    print(0)
" 2>/dev/null || echo "0")
  if [[ "${is_stale}" -eq 1 ]]; then
    echo "PASS"
    return
  fi

  # Extract current top_priority and horizon_score
  local top_id horizon horizon_score rally
  top_id=$(python3 -c "
import json
try:
    d = json.load(open('${priorities_file}'))
    print(d.get('top_priority', ''))
except:
    print('')
" 2>/dev/null || echo "")
  horizon=$(python3 -c "
import json
try:
    d = json.load(open('${priorities_file}'))
    print(d.get('overall_horizon_score', 0))
except:
    print(0)
" 2>/dev/null || echo "0")
  horizon_score=$(python3 -c "
import json
try:
    d = json.load(open('${priorities_file}'))
    top = d.get('top_priority', '')
    for s in d.get('signals', []):
        if s.get('id') == top:
            print(s.get('horizon_score', 0))
            break
    else:
        print(0)
except:
    print(0)
" 2>/dev/null || echo "0")
  rally=$(python3 -c "
import json
try:
    d = json.load(open('${priorities_file}'))
    print(d.get('rally_point', ''))
except:
    print('')
" 2>/dev/null || echo "")

  if [[ -z "${top_id}" ]]; then
    echo "PASS"
    return
  fi

  # ── Auto-disable logic: read tracker ─────────────────────────────────────
  local prev_top prev_score consecutive last_check
  if [[ -f "${tracker_file}" ]]; then
    prev_top=$(python3 -c "
import json
try:
    d=json.load(open('${tracker_file}'))
    print(d.get('top_priority',''))
except:
    print('')
" 2>/dev/null || echo "")
    prev_score=$(python3 -c "
import json
try:
    d=json.load(open('${tracker_file}'))
    print(d.get('horizon_score',0))
except:
    print(0)
" 2>/dev/null || echo "0")
    consecutive=$(python3 -c "
import json
try:
    d=json.load(open('${tracker_file}'))
    print(d.get('consecutive_count',0))
except:
    print(0)
" 2>/dev/null || echo "0")
    last_check=$(python3 -c "
import json
try:
    d=json.load(open('${tracker_file}'))
    print(d.get('last_check',''))
except:
    print('')
" 2>/dev/null || echo "")
  else
    prev_top=""; prev_score="0"; consecutive="0"; last_check=""
  fi

  # Determine new consecutive count
  local new_consecutive
  if [[ "${top_id}" == "${prev_top}" ]] && [[ "${horizon_score}" == "${prev_score}" ]]; then
    new_consecutive=$((consecutive + 1))
  else
    new_consecutive=1  # reset on change
  fi

  NOW_UTC=$(python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))")
  python3 -c "
import json, os
tracker = {
    'top_priority': '${top_id}',
    'horizon_score': ${horizon_score},
    'consecutive_count': ${new_consecutive},
    'last_check': '${NOW_UTC}',
    'rally_point': '''${rally}'''
}
with open('${tracker_file}', 'w') as f:
    json.dump(tracker, f, indent=2)
" 2>/dev/null

  # Suppress if same issue repeating without progress
  # LRN-WALTER-001 prevention: verify work was actually attempted before suppressing
  if [[ ${new_consecutive} -ge ${CONSECUTIVE_SUPPRESS} ]]; then
    local work_status
    work_status=$(verify_horizon_work_attempted "${top_id}" "${horizon_score}")
    case "${work_status}" in
      WORK_DONE)
        python3 -c "
import json, os
try:
    tracker_file = '${tracker_file}'
    d = json.load(open(tracker_file)) if os.path.exists(tracker_file) else {}
    d['suppress_reason'] = 'WORK_DONE'
    d['suppress_note'] = 'Work verified complete. Auto-suppressed to prevent horizon-scanner lock-in.'
    with open(tracker_file, 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
        echo "SUPPRESS: horizon [${top_id}] score=${horizon_score}/10 — work verified done, suppressing after ${new_consecutive} cycles"
        return
        ;;
      UNVERIFIABLE_AUTO)
        python3 -c "
import json, os
try:
    tracker_file = '${tracker_file}'
    d = json.load(open(tracker_file)) if os.path.exists(tracker_file) else {}
    d['suppress_reason'] = 'UNVERIFIABLE_AUTO'
    d['suppress_note'] = 'Signal was correct; resolution requires live event or human action. Suppressed to avoid repeated firing, gap remains unverified.'
    with open(tracker_file, 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
        echo "SUPPRESS_WITH_BLOCKER: horizon [${top_id}] score=${horizon_score}/10 — signal was valid, work unverifiable auto. Gap remains open; human check required."
        return
        ;;
      WORK_BLOCKED|NO_TRACKING|*)
        # Work not done, blocked, or untracked — do NOT suppress silently
        # Surface to Roger as degraded-state CRITICAL, but record suppress_reason
        # so NEXT cycle will suppress (DEGRADED fires at most once per horizon item)
        python3 -c "
import json, os
try:
    tracker_file = '${tracker_file}'
    d = json.load(open(tracker_file)) if os.path.exists(tracker_file) else {}
    d['suppress_reason'] = '${work_status}'
    d['suppress_note'] = 'DEGRADED surfaced once. Auto-suppressing subsequent cycles until Roger resolves gap.'
    with open(tracker_file, 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
        echo "DEGRADED: horizon [${top_id}] score=${horizon_score}/10 — ${new_consecutive} cycles, work ${work_status}. Needs attention."
        ;;
    esac
  fi

  # Normal threshold check
  if [[ "${horizon_score}" -ge 7 ]] && [[ -n "${top_id}" ]]; then
    echo "CRITICAL: horizon [${top_id}] score=${horizon_score}/10 — ${rally}"
  elif [[ "${horizon}" -ge 5 ]] && [[ -n "${top_id}" ]]; then
    echo "WARN: horizon [${top_id}] score=${horizon}/10 — ${rally}"
  else
    echo "PASS"
  fi
}

# ── Agent Commons: consult before reasoning ───────────────────────────────────
# Pre-reasoning consult hook for Agent Commons. Calls the commons consult script
# to check for existing reasoning chains on the current top_priority gap before
# Walter starts analysis from scratch. This is the 8th signal source that
# integrates collective intelligence into Walter's improvement loop.
check_source_commons_consult() {
  local script="${STATE_DIR}/walter-commons-consult.sh"
  if [[ ! -f "${script}" ]]; then
    # Script not yet installed — skip gracefully
    echo "PASS"
    return
  fi

  # Run the consult script (non-blocking, just check for findings)
  local output rc
  output=$(bash "${script}" 2>&1 || true)

  # Parse findings file if it exists
  local findings_file="${STATE_DIR}/walter-commons-findings.json"
  if [[ ! -f "${findings_file}" ]]; then
    echo "PASS"
    return
  fi

  # Check if we found relevant chains
  local proven_count relevant_count
  proven_count=$(python3 -c "
import json
try:
    with open('${findings_file}') as f:
        d = json.load(f)
    print(d.get('proven_count', 0))
except: print(0)
" 2>/dev/null || echo 0)

  relevant_count=$(python3 -c "
import json
try:
    with open('${findings_file}') as f:
        d = json.load(f)
    print(d.get('relevant_count', 0))
except: print(0)
" 2>/dev/null || echo 0)

  local total=$((proven_count + relevant_count))
  if [[ ${total} -ge 3 ]]; then
    echo "WARN: commons has ${total} reasoning chains on this topic — consider extending instead of starting from scratch"
  elif [[ ${total} -ge 1 ]]; then
    echo "PASS: ${total} chain(s) found in commons (can extend)"
  else
    echo "PASS: no existing chains — fresh reasoning welcome"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
  log_event "info" "Running self-improvement signal check"

  signals_detected=0
  signal_summary=()
  pulse_reason=""
  top_signal=""
  pulse_recommended=false

  # Each entry: "source_name:check_function"
  # 8 signal sources total:
  # 1. health_monitor - cron health status
  # 2. state_sanity - cross-file consistency check
  # 3. escalations - Roger-actionable items
  # 4. rca_findings - root cause analysis findings
  # 5. critique_pending - unverified critiques
  # 6. lessons_unverified - lessons without verified fix
  # 7. horizon_scan - forward-looking gap prediction
  # 8. commons_consult - collective intelligence check
  for entry in \
    "health_monitor:check_source_health_monitor" \
    "state_sanity:check_source_state_sanity" \
    "escalations:check_source_escalations" \
    "rca_findings:check_source_rca_findings" \
    "critique_pending:check_source_critique_pending" \
    "lessons_unverified:check_source_lessons_unverified" \
    "horizon_scan:check_horizon_top_priority" \
    "commons_consult:check_source_commons_consult"
  do
    local src="${entry%%:*}"
    local check_fn="${entry#*:}"
    local result status detail
    result=$( "${check_fn}" )
    status="${result%%:*}"
    detail="${result#*: }"

    case "${status}" in
      PASS)                           log_event "debug" "${src}: PASS" ;;
      SUPPRESS|SUPPRESS_WITH_BLOCKER)  log_event "debug" "${src}: ${status}" ;;
      DEGRADED)
        # LRN-WALTER-001: horizon suppressed but work not done — surface as CRITICAL
        # to ensure Roger is notified instead of silent lock-in
        signals_detected=$((signals_detected + 1))
        signal_summary+=("${src}: CRITICAL — ${detail}")
        pulse_recommended=true
        [[ -z "${pulse_reason}" ]] && pulse_reason="[${src}] DEGRADED: ${detail}"
        log_event "error" "${src}: DEGRADED — ${detail}"

        # Extract work_status from detail (format: "... work ${work_status}. Needs attention.")
        # Set suppress_reason in tracker so next cycle will suppress (not re-fire CRITICAL).
        # DEGRADED fires once to surface the gap, then auto-suppresses on subsequent cycles.
        local degraded_work_status
        degraded_work_status=$(echo "${detail}" | python3 -c "import sys; d=sys.stdin.read(); print(d.split('work ')[-1].split('.')[0] if 'work ' in d else 'NO_TRACKING')" 2>/dev/null || echo "NO_TRACKING")
        python3 -c "
import json, os
try:
    tracker_file = '${tracker_file}'
    d = json.load(open(tracker_file)) if os.path.exists(tracker_file) else {}
    d['suppress_reason'] = '${degraded_work_status}'
    d['suppress_note'] = 'Auto-suppressed after DEGRADED surfaced once. Gap requires Roger action.'
    d['suppressed_at'] = '${NOW_UTC}'
    with open(tracker_file, 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
        ;;
      WARN)
        signals_detected=$((signals_detected + 1))
        signal_summary+=("${src}: WARN — ${detail}")
        pulse_recommended=true
        [[ -z "${pulse_reason}" ]] && pulse_reason="[${src}] ${detail}"
        log_event "warn" "${src}: ${detail}"
        ;;
      CRITICAL|ERROR)
        signals_detected=$((signals_detected + 1))
        signal_summary+=("${src}: ${status} — ${detail}")
        pulse_recommended=true
        [[ -z "${pulse_reason}" ]] && pulse_reason="[${src}] ${detail}"
        log_event "error" "${src}: ${detail}"
        ;;
    esac
  done

  # Persist signal snapshot
  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local summary_json="[]"
  if [[ ${#signal_summary[@]} -gt 0 ]]; then
    summary_json=$(printf '%s\n' "${signal_summary[@]}" | python3 -c "import json,sys; lines=[l.rstrip() for l in sys.stdin if l.strip()]; print(json.dumps(lines))" 2>/dev/null || echo "[]")
  fi
  python3 -c "
import json, sys
data = {
    'timestamp': '${ts}',
    'signals_checked': ['health_monitor','state_sanity','escalations','rca_findings','critique_pending','lessons_unverified','horizon_scan','commons_consult'],
    'signals_detected': ${signals_detected},
    'pulse_recommended': ${pulse_recommended},
    'pulse_reason': \"\"\"${pulse_reason}\"\"\",
    'summary': ${summary_json}
}
with open('${SIGNAL_FILE}', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true

  # ── Signal cross-validation: detect contradictory diagnoses before priority scoring ──
  # walton-weakness-003 fix: cross-signal conflict detector.
  # Runs after all 8 signals collected, before priority scorer.
  # If contradiction found: upgrade to CRITICAL regardless of individual signal scores.
  local cross_validator="${STATE_DIR}/walter-signal-cross-validator.sh"
  local conflict_result="SKIPPED"
  if [[ -f "${cross_validator}" ]]; then
    log_event "info" "Running signal cross-validation..."
    if bash "${cross_validator}" >/dev/null 2>&1; then
      conflict_result="CLEAN"
      log_event "info" "Cross-validation: no conflicts detected"
    else
      # Conflicts found — read the conflicts file and upgrade pulse
      conflict_result="CONFLICT"
      local conflict_count
      conflict_count=$(python3 -c "
import json
try:
    d=json.load(open('${STATE_DIR}/walter-signal-conflicts.json'))
    print(d.get('conflict_count', 0))
except: print(0)
" 2>/dev/null || echo "?")
      log_event "error" "Cross-validation: ${conflict_count} conflict(s) detected — upgrading pulse to CRITICAL"
      # Extract conflict details for pulse reason
      local conflict_detail
      conflict_detail=$(python3 -c "
import json
try:
    d=json.load(open('${STATE_DIR}/walter-signal-conflicts.json'))
    cs = d.get('conflicts', [])
    if cs:
        c = cs[0]
        print(f\"{c.get('entity_key','?')}: {c.get('detail','')[:120]}\")
    else:
        print('signal-conflict-detected')
except:
    print('signal-conflict-detected')
" 2>/dev/null || echo "signal-conflict-detected")
      pulse_recommended=true
      signals_detected=$((signals_detected + 1))
      signal_summary+=("cross_validator: CRITICAL — ${conflict_detail} (${conflict_count} total)")
      [[ -z "${pulse_reason}" ]] && pulse_reason="cross-signal conflict: ${conflict_detail}"
      python3 -c "
import json
try:
    d=json.load(open('${SIGNAL_FILE}'))
    d['cross_validation'] = {'result': 'CONFLICT', 'conflict_count': ${conflict_count}, 'detail': '${conflict_detail}'}
    with open('${SIGNAL_FILE}', 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
    fi
  else
    log_event "warn" "cross-validator script not found at ${cross_validator}"
  fi

  # ── Self-calibration baseline: track critique accuracy, signal precision, FPR ──────────
  # walton-weakness-004 fix: Walter has signal infrastructure and routing everywhere,
  # but nowhere measures whether his own judgments are accurate. He can't self-correct
  # his own critique accuracy or signal precision without baseline metrics.
  # Runs on every trigger cycle: sync state → record current verdicts → compute metrics.
  local calibration_script="${STATE_DIR}/walter-calibration-tracker.sh"
  if [[ -f "${calibration_script}" ]]; then
    if bash "${calibration_script}" sync >/dev/null 2>&1; then
      log_event "info" "Calibration sync+compute: OK"
    else
      log_event "warn" "Calibration tracker returned non-zero"
    fi
  else
    log_event "warn" "Calibration tracker not found at ${calibration_script}"
  fi

  # ── Signal outcome recorder: close the calibration loop ─────────────────────────
  # Walter's signal infrastructure and calibration tracker existed but had no
  # automatic path from signal → action → outcome. The recorder stamps pending
  # outcome records when the trigger fires (signal → action) and auto-closes them
  # when RCA/escalations resolve (outcome verified). Feeds closed records back into
  # the calibration tracker to measure signal precision over time.
  local outcome_recorder="${STATE_DIR}/walter-signal-outcome-recorder.sh"
  if [[ -f "${outcome_recorder}" ]]; then
    # Auto-close any resolved RCA/escalations first (cleanup pass)
    if bash "${outcome_recorder}" auto_close >/dev/null 2>&1; then
      log_event "info" "Outcome recorder auto-close: OK"
    fi
    # Feed closed records into calibration tracker
    if bash "${outcome_recorder}" calibrate >/dev/null 2>&1; then
      log_event "info" "Outcome recorder calibrate feed: OK"
    fi
    # Record pending outcome for this trigger cycle
    if [[ "${pulse_recommended}" == "true" ]]; then
      if bash "${outcome_recorder}" record_signal >/dev/null 2>&1; then
        log_event "info" "Outcome recorder: pending signal outcome stamped"
      fi
    fi
  else
    log_event "warn" "Signal outcome recorder not found at ${outcome_recorder}"
  fi

  # Get top priority signal from structured scorer
  top_signal=$(get_top_priority_signal)
  if [[ -n "$top_signal" ]]; then
    local top_type top_score top_severity top_desc
    top_type=$(echo "$top_signal" | cut -d'|' -f2)
    top_score=$(echo "$top_signal" | cut -d'|' -f3)
    top_severity=$(echo "$top_signal" | cut -d'|' -f4)
    top_desc=$(echo "$top_signal" | cut -d'|' -f5-)
    log_event "info" "Priority scorer: top=${top_type} score=${top_score} severity=${top_severity} — ${top_desc}"
    # Enrich pulse reason with top priority if not already set
    if [[ -z "${pulse_reason}" ]]; then
      pulse_reason="TOP_PRIORITY [${top_type}] score=${top_score}: ${top_desc}"
    fi
    # Update signal summary with priority rank
    python3 -c "
import json
try:
    d = json.load(open('${SIGNAL_FILE}'))
    d['top_priority'] = {'type': '${top_type}', 'score': ${top_score}, 'severity': '${top_severity}', 'description': '${top_desc}'}
    with open('${SIGNAL_FILE}', 'w') as f:
        json.dump(d, f, indent=2)
except: pass
" 2>/dev/null || true
  fi

  if ! "${pulse_recommended}"; then
    sync_doctrine_capsule
    log_event "info" "No pulse needed — all signals healthy"
    echo "OK: all signals healthy"
    exit 0
  fi

  if ! check_min_interval; then
    sync_doctrine_capsule
    echo "OK: pulse suppressed (minimum interval not met)"
    exit 0
  fi

  mark_triggered "${pulse_reason}" "${signals_detected}"
  log_event "info" "Improvement pulse FIRED — reason: ${pulse_reason}"
  sync_doctrine_capsule

  echo "PULSE_FIRED: ${pulse_reason}"
  echo "Signals detected: ${signals_detected}"
  for s in "${signal_summary[@]+"${signal_summary[@]}"}"; do
    echo "  - ${s}"
  done
  exit 0
}

main "$@"
