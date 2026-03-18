#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
primary="$(jq -r '.roger.primary_wedge' "$SPINE")"
reserve="$(jq -r '.roger.reserve_wedge // "base_account_miniapp_probe"' "$SPINE")"
current_primary="$(jq -r '.portfolio.primary_id' "$STATE")"
current_reserve="$(jq -r '.portfolio.reserve_id' "$STATE")"
if [[ "$current_primary" == "$primary" && "$current_reserve" == "$reserve" ]]; then
  echo "PORTFOLIO_COHERENCE_OK $STATE"
  exit 0
fi
tmp="$(mktemp)"
jq --arg primary "$primary" --arg reserve "$reserve" '
  .portfolio.primary_id = $primary
  | .portfolio.reserve_id = $reserve
  | .updated_at = (now|todate)
  | .lastUpdated = (now|todate)
' "$STATE" > "$tmp"
bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
rm -f "$tmp"
echo "PORTFOLIO_COHERENCE_FIXED primary=$primary reserve=$reserve"
