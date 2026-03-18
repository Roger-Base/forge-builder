#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
PLAN="$WORKSPACE/state/daily-plan.md"
NOW_FILE="$WORKSPACE/NOW.md"
STATE="$WORKSPACE/state/session-state.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
today="$(date +%F)"
need_refresh=false
[[ -f "$PLAN" ]] || need_refresh=true
[[ -f "$NOW_FILE" ]] || need_refresh=true
if [[ "$need_refresh" == false ]] && ! rg -q "^# Daily Plan - $today$" "$PLAN"; then need_refresh=true; fi
if [[ "$need_refresh" == false ]]; then
  state_wedge="$(jq -r '.active_wedge.id' "$STATE")"
  state_stage="$(jq -r '.active_wedge.stage' "$STATE")"
  state_primary="$(jq -r '.portfolio.primary_id' "$STATE")"
  shared_primary="$(jq -r '.roger.primary_wedge' "$SPINE")"
  plan_wedge="$(sed -n 's/^- active_wedge: //p' "$PLAN" | head -n1)"
  plan_stage="$(sed -n 's/^- stage: //p' "$PLAN" | head -n1)"
  plan_primary="$(sed -n 's/^- shared_primary: //p' "$PLAN" | head -n1)"
  [[ "$state_wedge" == "$plan_wedge" && "$state_stage" == "$plan_stage" && "$shared_primary" == "$plan_primary" && "$state_primary" == "$shared_primary" ]] || need_refresh=true
fi
if [[ "$need_refresh" == true ]]; then
  bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
  echo "DAILY_PLAN_GUARD_REFRESH"
else
  echo "DAILY_PLAN_GUARD_OK $PLAN"
fi
