#!/usr/bin/env bash
# Lightweight run fitness evaluator for Roger.

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
QUEUE="$WORKSPACE/state/base-opportunity-queue.json"
LEDGER="$WORKSPACE/state/subagent-ledger.json"
REPORT="$WORKSPACE/state/runtime/run-evaluator-$(date -u +%Y%m%d-%H%M%S).md"
LANE="unspecified"
INPUT_REPORT=""
ARTIFACT=""
PROOF=""
STAGE_BEFORE=""
STAGE_AFTER=""
UPDATE_STATE=false
JSON_OUT=false

usage() {
  cat <<USAGE
Usage:
  $0 [--lane <name>] [--report <path>] [--artifact <path>] [--proof <path-or-url>] [--stage-before <stage>] [--stage-after <stage>] [--update-state] [--json]
  $0 --agent-help
USAGE
}

agent_help() {
  cat <<HELP
run-evaluator scores whether a run improved Roger's mission state.

Signals rewarded:
- active wedge matches primary
- root next_action is executable and non-passive
- stage guard passes
- artifact path exists
- proof path/url exists
- no generic swarm drift
- no support-layer root drift

Signals penalized:
- passive or observation-only next_action
- generic swarm next_action
- support-layer root action without wedge attachment
- anti-loop counter overflow
HELP
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lane) shift; LANE="${1:-}" ;;
    --report) shift; INPUT_REPORT="${1:-}" ;;
    --artifact) shift; ARTIFACT="${1:-}" ;;
    --proof) shift; PROOF="${1:-}" ;;
    --stage-before) shift; STAGE_BEFORE="${1:-}" ;;
    --stage-after) shift; STAGE_AFTER="${1:-}" ;;
    --update-state) UPDATE_STATE=true ;;
    --json) JSON_OUT=true ;;
    --agent-help) agent_help; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
  shift || true
done

mkdir -p "$WORKSPACE/state/runtime"
score=0
status="hold"
penalties=()
rewards=()

primary_id="$(jq -r '.portfolio.primary_id // empty' "$STATE")"
active_id="$(jq -r '.active_wedge.id // empty' "$STATE")"
next_cmd="$(jq -r '.next_action.command // empty' "$STATE")"
bench_count="$(jq -r '.stage_transition_guard.consecutive_benchmark_briefs // 0' "$STATE")"
research_count="$(jq -r '.stage_transition_guard.consecutive_research_refreshes // 0' "$STATE")"

if [[ "$active_id" == "$primary_id" && -n "$active_id" ]]; then
  score=$((score + 20))
  rewards+=("active_wedge_matches_primary")
else
  penalties+=("active_wedge_drift")
  score=$((score - 15))
fi

if bash "$WORKSPACE/scripts/stage-transition-guard.sh" >/dev/null 2>&1; then
  score=$((score + 20))
  rewards+=("stage_guard_ok")
else
  penalties+=("stage_guard_failed")
  score=$((score - 20))
fi

if bash "$WORKSPACE/scripts/state-guard.sh" --validate "$STATE" >/dev/null 2>&1; then
  score=$((score + 15))
  rewards+=("state_guard_ok")
else
  penalties+=("state_guard_failed")
  score=$((score - 20))
fi

if echo "$next_cmd" | grep -Eq '^[[:space:]]*bash scripts/roger-swarm\.sh[[:space:]]*$'; then
  penalties+=("generic_swarm_drift")
  score=$((score - 25))
elif echo "$next_cmd" | grep -Eq '^(echo|printf|true|:)( |$)|(^| )(await|wait|monitor|check later)( |$)'; then
  penalties+=("passive_next_action")
  score=$((score - 25))
elif echo "$next_cmd" | grep -Eq '^[[:space:]]*(acp(_cli)? job active( --json)?|acp(_cli)? auth status|acp(_cli)? x status|openclaw status|gh auth status|qmd status)[[:space:]]*$'; then
  penalties+=("observation_only_next_action")
  score=$((score - 20))
else
  score=$((score + 15))
  rewards+=("next_action_executable")
fi

if (( bench_count <= 2 && research_count <= 2 )); then
  score=$((score + 10))
  rewards+=("anti_loop_within_budget")
else
  penalties+=("anti_loop_budget_exceeded")
  score=$((score - 10))
fi

if [[ -n "$ARTIFACT" ]]; then
  if [[ -e "$WORKSPACE/$ARTIFACT" || -e "$ARTIFACT" ]]; then
    score=$((score + 15))
    rewards+=("artifact_present")
  else
    penalties+=("artifact_missing")
  fi
fi

if [[ -n "$PROOF" ]]; then
  if [[ "$PROOF" =~ ^https?:// ]]; then
    score=$((score + 10))
    rewards+=("proof_url_present")
  elif [[ -e "$WORKSPACE/$PROOF" || -e "$PROOF" ]]; then
    score=$((score + 10))
    rewards+=("proof_path_present")
  else
    penalties+=("proof_missing")
  fi
fi

if [[ -n "$INPUT_REPORT" && -f "$INPUT_REPORT" ]]; then
  if rg -q 'ARTIFACT_DELTA|files_touched|proof_expected|Proof Paths|PROOF_PATHS' "$INPUT_REPORT"; then
    score=$((score + 5))
    rewards+=("report_contains_delta")
  fi
fi

if [[ -n "$STAGE_BEFORE" && -n "$STAGE_AFTER" && "$STAGE_BEFORE" != "$STAGE_AFTER" ]]; then
  score=$((score + 10))
  rewards+=("stage_advanced")
fi

if (( score >= 60 )); then
  status="strong"
elif (( score >= 30 )); then
  status="acceptable"
else
  status="weak"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "# Run Evaluator"
  echo
  echo "- timestamp: $TS"
  echo "- lane: $LANE"
  echo "- active_wedge: $active_id"
  echo "- next_action: $next_cmd"
  echo
  echo "## Score"
  echo "- score: $score"
  echo "- status: $status"
  echo
  echo "## Rewards"
  if ((${#rewards[@]})); then printf '%s\n' "${rewards[@]}" | sed 's/^/- /'; else echo "- none"; fi
  echo
  echo "## Penalties"
  if ((${#penalties[@]})); then printf '%s\n' "${penalties[@]}" | sed 's/^/- /'; else echo "- none"; fi
} > "$REPORT"

if [[ "$UPDATE_STATE" == true ]]; then
  tmp="$(mktemp)"
  jq \
    --arg ts "$TS" \
    --arg lane "$LANE" \
    --arg report_rel "${REPORT#$WORKSPACE/}" \
    --arg status "$status" \
    --argjson score "$score" \
    '.lastUpdated = $ts
    | .last_verified_at = $ts
    | .run_fitness = {score:$score, status:$status, lane:$lane, report:$report_rel, last_evaluated_at:$ts}' \
    "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
  rm -f "$tmp"
fi

if [[ "$JSON_OUT" == true ]]; then
  jq -n --arg report "$REPORT" --arg status "$status" --arg lane "$LANE" --argjson score "$score" '{report:$report, status:$status, lane:$lane, score:$score}'
else
  echo "RUN_EVALUATOR_OK score=$score status=$status report=$REPORT"
fi
