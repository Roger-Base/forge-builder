#!/bin/bash
# walter-capability-gap-analyzer.sh
# Audits Walter's current capabilities, maps them against needed work modes,
# and generates a ranked gap list with the top priority gap + recommended action.
# Built: 2026-03-19 (Walter self-improvement cycle)
# Reason: capability-dashboard.sh lists scripts but cannot answer
#          "what capability do I most urgently need and why?"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="$WORKSPACE_DIR/state"
GAP_DB="$STATE_DIR/walter-capability-gaps.json"
LOG="$STATE_DIR/walter-gap-analysis-log.jsonl"

# ── timestamp helper ────────────────────────────────────────────────────────
now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# ── 1. Detect current capabilities ────────────────────────────────────────────
# Returns a JSON array of {name, category, status, evidence}
detect_capabilities() {
  local caps=()
  local script_dir="$SCRIPT_DIR"

  # Helper: script exists and is executable (checks scripts/ AND state/)
  has_script() {
    if [[ -x "$script_dir/$1" ]] || [[ -x "$STATE_DIR/$1" ]]; then
      echo "present"
    else
      echo "missing"
    fi
  }

  # Core loop scripts
  for script in \
    walter-mismatch-detector.sh \
    walter-correction-router.sh \
    walter-correction-verifier.sh \
    walter-heartbeat-executor.sh \
    walter-self-improvement-trigger.sh \
    walter-signal-priority-scorer.sh
  do
    caps+=("$(jq -n \
      --arg n "$script" \
      --arg cat "core-loop" \
      --arg st "$(has_script "$script")" \
      '{name:$n,category:$cat,status:$st}' \
    )")
  done

  # Monitoring / health
  for script in \
    walter-cron-health-monitor.sh \
    walter-cron-rca.sh \
    walter-rca-followup.sh \
    walter-escalation-tracker.sh \
    walter-health-monitor.sh
  do
    caps+=("$(jq -n \
      --arg n "$script" \
      --arg cat "monitoring" \
      --arg st "$(has_script "$script")" \
      '{name:$n,category:$cat,status:$st}' \
    )")
  done

  # Learning / critique
  for script in \
    walter-critique-logger.sh \
    walter-critique-verifier.sh \
    walter-lessons-retrieve.sh \
    walter-lessons-from-rca.sh \
    walter-lessons-check.py \
    walter-learn-promote.sh \
    walter-fix-learner.sh
  do
    caps+=("$(jq -n \
      --arg n "$script" \
      --arg cat "learning" \
      --arg st "$(has_script "$script")" \
      '{name:$n,category:$cat,status:$st}' \
    )")
  done

  # Knowledge bases
  for kb in \
    walter-lessons-learned.json \
    walter-critique-accuracy.json \
    walter-rca-findings.json \
    walter-escalations.json \
    walter-verified-lrns.json \
    walter-self-evaluation.json
  do
    local kb_path="$STATE_DIR/$kb"
    local kb_st="missing"
    [[ -f "$kb_path" ]] && kb_st="present"
    caps+=("$(jq -n \
      --arg n "$kb" \
      --arg cat "knowledge-base" \
      --arg st "$kb_st" \
      '{name:$n,category:$cat,status:$st}' \
    )")
  done

  # Stage 5 growth capabilities
  for script in \
    walter-self-audit.sh \
    walter-auto-calibrate.sh \
    walter-capability-dashboard.sh \
    walter-goals-tracker.sh \
    walter-quick-status.sh \
    walter-diagnostic.sh
  do
    caps+=("$(jq -n \
      --arg n "$script" \
      --arg cat "stage5-growth" \
      --arg st "$(has_script "$script")" \
      '{name:$n,category:$cat,status:$st}' \
    )")
  done

  # Integration checks — is the self-improvement trigger wired into cron?
  local trigger_cron="not_verified"
  if "$0" check-cron 2>/dev/null | grep -q "walter-self-improvement-trigger.*scheduled"; then
    trigger_cron="wired"
  elif grep -q "walter-self-improvement-trigger" "$STATE_DIR"/*.json 2>/dev/null; then
    trigger_cron="referenced"
  else
    trigger_cron="unconnected"
  fi
  caps+=("$(jq -n \
    --arg n "self-improvement-trigger-cron-integration" \
    --arg cat "integration" \
    --arg st "$trigger_cron" \
    '{name:$n,category:$cat,status:$st}' \
  )")

  # Output as JSON array
  printf '%s\n' "${caps[@]}" | jq -s '.'
}

# ── 2. Define needed work-mode capabilities ─────────────────────────────────
# Each entry: what Walter needs to do + the capability required
needed_capabilities() {
  jq -n '
  [
    {
      mode: "signal-driven-self-improvement",
      description: "Detect degradation signals and fire improvement pulse between cron cycles",
      required: ["walter-self-improvement-trigger.sh","walter-signal-priority-scorer.sh"],
      category: "core-loop"
    },
    {
      mode: "critique-verification",
      description: "Verify critiques and predictions against outcomes automatically",
      required: ["walter-critique-verifier.sh","walter-critique-logger.sh"],
      category: "learning"
    },
    {
      mode: "lesson-capture-from-rca",
      description: "Capture verified lessons from RCA findings automatically",
      required: ["walter-lessons-from-rca.sh","walter-lessons-learned.json"],
      category: "learning"
    },
    {
      mode: "escalation-tracking",
      description: "Track Roger-actionable findings with SLA and auto-escalation",
      required: ["walter-escalation-tracker.sh","walter-escalations.json"],
      category: "monitoring"
    },
    {
      mode: "rca-followup",
      description: "Verify RCA fixes were applied and close findings",
      required: ["walter-rca-followup.sh","walter-rca-findings.json"],
      category: "monitoring"
    },
    {
      mode: "capability-self-awareness",
      description: "Know what capabilities exist and which are missing at any moment",
      required: ["walter-capability-gap-analyzer.sh"],
      category: "stage5-growth"
    },
    {
      mode: "heartbeat-driven-task-selection",
      description: "Auto-select next task from queue based on priority and effort",
      required: ["walter-heartbeat-executor.sh"],
      category: "core-loop"
    },
    {
      mode: "correction-routing",
      description: "Route mismatches to correct fix script automatically",
      required: ["walter-correction-router.sh","walter-mismatch-detector.sh"],
      category: "core-loop"
    }
  ]'
}

# ── 3. Compute gaps ──────────────────────────────────────────────────────────
# For each needed capability, check if ALL required components are present
compute_gaps() {
  local caps_json="$1"
  local needed_json="$2"

  # Get list of present capability names
  local present
  present=$(echo "$caps_json" | jq -r \
    '.[] | select(.status=="present" or .status=="wired" or .status=="referenced") | .name')

  # Output a temporary JSON file with results
  local tmp
  tmp=$(mktemp)
  echo "$needed_json" | jq -c '.[]' | while IFS= read -r mode_obj; do
    local mode desc category
    mode=$(echo "$mode_obj" | jq -r '.mode')
    desc=$(echo "$mode_obj" | jq -r '.description')
    category=$(echo "$mode_obj" | jq -r '.category')

    # Check each required component
    local status="operational"
    local -a missing_arr=()
    echo "$mode_obj" | jq -r '.required | .[]' | while IFS= read -r req; do
      if ! echo "$present" | grep -qxF "$req"; then
        status="gap"
        missing_arr+=("$req")
      fi
    done > /dev/null

    local missing_json
    if [[ ${#missing_arr[@]} -eq 0 ]]; then
      missing_json='[]'
    else
      missing_json=$(printf '%s\n' "${missing_arr[@]}" | jq -R . | jq -s .)
    fi

    jq -n \
      --arg mode "$mode" \
      --arg desc "$desc" \
      --arg cat "$category" \
      --arg st "$status" \
      --argjson missing "$missing_json" \
      '{
        mode: $mode,
        description: $desc,
        category: $cat,
        status: $st,
        missing_components: $missing
      }'
  done > "$tmp"

  jq -s '.' "$tmp"
  rm -f "$tmp"
}

# ── 4. Rank gaps by severity ─────────────────────────────────────────────────
rank_gaps() {
  local gaps_json="$1"
  local ranked=()

  # Weight by category: core-loop > monitoring > learning > stage5-growth
  local cat_weight
  cat_weight=$(jq -n '
    {"core-loop":4,"monitoring":3,"learning":2,"stage5-growth":1}
  ')

  while IFS= read -r gap; do
    local mode status cat missing_count priority_score
    mode=$(echo "$gap" | jq -r '.mode')
    status=$(echo "$gap" | jq -r '.status')
    cat=$(echo "$gap" | jq -r '.category')
    missing_count=$(echo "$gap" | jq -r '.missing_components | length')

    local weight
    weight=$(echo "$cat_weight" | jq -r --arg c "$cat" '.[$c] // 1')

    if [[ "$status" == "gap" ]]; then
      priority_score=$((weight * missing_count))
    else
      priority_score=0
    fi

    ranked+=("$(echo "$gap" | jq \
      --argjson ps "$priority_score" \
      --argjson w "$weight" \
      '(. + {priority_score:$ps, category_weight:$w})' \
    )")
  done < <(echo "$gaps_json" | jq -c '.[]')

  printf '%s\n' "${ranked[@]}" | jq -s 'sort_by(.priority_score) | reverse'
}

# ── 5. Get top gap ───────────────────────────────────────────────────────────
top_gap() {
  local ranked="$1"
  local top
  top=$(echo "$ranked" | jq -c '.[] | select(.priority_score > 0) | .' 2>/dev/null | head -1)
  if [[ -n "$top" ]]; then
    echo "$top"
  else
    echo "{}"
  fi
}

# ── 6. Format output ─────────────────────────────────────────────────────────
format_output() {
  local caps="$1"
  local gaps="$2"
  local ranked="$3"
  local top="$4"
  local ts
  ts=$(now)

  local total_caps missing_caps total_modes operational_modes gapped_modes
  total_caps=$(echo "$caps" | jq 'length')
  missing_caps=$(echo "$caps" | jq '[.[] | select(.status=="missing")] | length')
  total_modes=$(echo "$gaps" | jq 'length')
  operational_modes=$(echo "$gaps" | jq '[.[] | select(.status=="operational")] | length')
  gapped_modes=$(echo "$gaps" | jq '[.[] | select(.status=="gap")] | length')

  echo "═══════════════════════════════════════════════════════════════"
  echo "  WALTER CAPABILITY GAP ANALYSIS"
  echo "  Generated: $ts"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""
  echo "── CAPABILITY OVERVIEW ───────────────────────────────────────"
  echo "  Total tracked capabilities: $total_caps"
  echo "  Present: $(( total_caps - missing_caps )) | Missing: $missing_caps"
  echo ""
  echo "── WORK MODE STATUS ──────────────────────────────────────────"
  printf "  %-45s %-12s %s\n" "MODE" "STATUS" "PRIORITY"
  echo "  $(printf '%.0s-' {1..45})  $(printf '%-12s' '--------')  -------"
  while IFS= read -r entry; do
    local mode status score
    mode=$(echo "$entry" | jq -r '.mode')
    status=$(echo "$entry" | jq -r '.status')
    score=$(echo "$entry" | jq -r '.priority_score')
    [[ "$status" == "gap" ]] && status="⚠️  GAP" || status="✓ operational"
    printf "  %-45s %-12s %s\n" "$mode" "$status" "$score"
  done < <(echo "$ranked" | jq -c '.[]')
  echo ""

  local top_mode top_desc top_score top_missing_json
  top_mode=$(echo "$top" | jq -r '.mode // "none"')
  top_score=$(echo "$top" | jq -r '.priority_score // 0')
  top_desc=$(echo "$top" | jq -r '.description // ""')
  top_missing_json=$(echo "$top" | jq -r '.missing_components // [] | .[]' 2>/dev/null | tr '\n' ',' | sed 's/,$//')

  echo "── TOP PRIORITY GAP ──────────────────────────────────────────"
  if [[ "$top_mode" != "none" && "$top_score" != "0" ]]; then
    echo "  Mode:        $top_mode"
    echo "  Score:       $top_score"
    echo "  Description: ${top_desc:-—}"
    [[ -n "$top_missing_json" ]] && echo "  Missing:     ${top_missing_json}"
    echo ""
    echo "  → Recommended action:"
    recommend_action "$top_mode" "$top_missing_json"
  else
    echo "  No critical gaps detected. All tracked work modes operational."
  fi
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
}

recommend_action() {
  local mode="$1"
  local missing="$2"

  case "$mode" in
    "signal-driven-self-improvement")
      echo "  Wire walter-self-improvement-trigger.sh into heartbeat executor chain."
      echo "  Current trigger fires independently — connect it so heartbeat calls"
      echo "  it before the scheduled 6-hour self-improvement cron."
      ;;
    "capability-self-awareness")
      echo "  This script (walter-capability-gap-analyzer.sh) IS the fix."
      echo "  Run it on each self-improvement cycle to maintain awareness."
      ;;
    "heartbeat-driven-task-selection")
      echo "  Verify walter-heartbeat-executor.sh is called by heartbeat cron."
      echo "  Check cron job status for heartbeat executor wiring."
      ;;
    "correction-routing")
      echo "  Both walter-correction-router.sh and walter-mismatch-detector.sh"
      echo "  must be present and executable. Check script permissions."
      ;;
    "critique-verification")
      echo "  Run walter-critique-verifier.sh — if missing, build it."
      echo "  If present but not in cron, add to 4-hour cron cycle."
      ;;
    "lesson-capture-from-rca")
      echo "  Ensure walter-lessons-from-rca.sh is triggered from RCA followup."
      echo "  Check walter-rca-followup.sh integration."
      ;;
    "escalation-tracking")
      echo "  Run walter-escalation-tracker.sh. If findings are open,"
      echo "  surface them to Roger via Telegram or state handoff."
      ;;
    "rca-followup")
      echo "  Check cron job bb59931a status (Walter RCA Followup, every 2h)."
      echo "  If disabled, re-enable. If missing, add walter-rca-followup.sh to cron."
      ;;
    *)
      echo "  Manual review required — no automatic recommendation for: $mode"
      ;;
  esac
}

# ── 7. Write persistent gap DB ───────────────────────────────────────────────
write_gap_db() {
  local ranked="$1"
  local top="$2"
  local ts
  ts=$(now)
  local db_entry
  db_entry=$(jq -n \
    --arg ts "$ts" \
    --argjson top "$(echo "$top" | jq '.')" \
    --argjson ranked "$(echo "$ranked" | jq '.')" \
    '{
      last_analyzed: $ts,
      top_gap: $top,
      all_modes_ranked: $ranked
    }' \
  )
  echo "$db_entry" | jq '.' > "$GAP_DB"
}

# ── 8. Log entry ─────────────────────────────────────────────────────────────
log_run() {
  local top_mode="$1"
  local top_score="$2"
  local gapped_modes="$3"
  local ts
  ts=$(now)
  local entry
  entry=$(jq -n \
    --arg ts "$ts" \
    --arg top_mode "$top_mode" \
    --argjson top_score "$top_score" \
    --argjson gapped "$gapped_modes" \
    '{timestamp:$ts,top_gap_mode:$top_mode,top_priority_score:$top_score,gapped_mode_count:$gapped}'
  )
  echo "$entry" >> "$LOG"
}

# ── 9. Cron integration check ─────────────────────────────────────────────────
check_cron() {
  local out
  out=$(openclaw cron list 2>/dev/null | grep -i "walter-self-improvement-trigger\|walter-heartbeat\|walter-rca-followup\|walter-critique-verifier" || true)
  echo "$out"
}

# ── MAIN ─────────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-analyze}"

  if [[ "$cmd" == "check-cron" ]]; then
    check_cron
    return
  fi

  echo "Analyzing Walter capabilities..." >&2

  local caps needed gaps ranked top
  caps=$(detect_capabilities)
  needed=$(needed_capabilities)
  gaps=$(compute_gaps "$caps" "$needed")
  ranked=$(rank_gaps "$gaps")
  top=$(top_gap "$ranked")

  local gapped_modes
  gapped_modes=$(echo "$gaps" | jq '[.[] | select(.status=="gap")] | length')

  local top_mode top_score top_desc vault_context
  top_mode=$(echo "$top" | jq -r '.mode // "none"')
  top_score=$(echo "$top" | jq -r '.priority_score // 0')
  top_desc=$(echo "$top" | jq -r '.description // ""')

  # ClawVault semantic search: query vault for patterns related to the top gap
  vault_context=""
  if [[ "$top_score" -gt 0 ]]; then
    vault_context=$(qmd query --json --limit 5 \
      "capability gap walter ${top_mode} ${top_desc}" 2>/dev/null | \
      jq -r '.[] | "[\(.score * 100 | floor)] \(.title)"' 2>/dev/null || echo "")
    if [[ -n "$vault_context" ]]; then
      echo "" >&2
      echo "── VAULT CONTEXT (ClawVault/qmd query) ─────────────────────────────" >&2
      echo "$vault_context" | head -10 >&2
      echo "───────────────────────────────────────────────────────────────────" >&2
      echo "" >&2
    fi
  fi

  format_output "$caps" "$gaps" "$ranked" "$top"
  write_gap_db "$ranked" "$top"
  log_run "$top_mode" "$top_score" "$gapped_modes"

  echo "" >&2
  echo "Gap DB written to: $GAP_DB" >&2
  echo "Log written to: $LOG" >&2
}

main "$@"
