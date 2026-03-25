#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"

wedge_id="$(jq -r '.active_wedge.id' "$STATE")"
stage="$(jq -r '.active_wedge.stage' "$STATE")"
primary_id="$(jq -r '.primary_id' "$SPINE")"
reserve_id="$(jq -r '.reserve_id // empty' "$SPINE")"
packet="$WORKSPACE/docs/wedges/$wedge_id/research-packet.md"
spec="$WORKSPACE/docs/wedges/$wedge_id/proof-spec.md"

case "$stage" in
  TRIBUNAL|RESEARCH_PACKET|PROOF_SPEC|BUILD|VERIFY|DISTRIBUTE|LEARN|MAINTAIN|FROZEN) ;;
  *) echo "STAGE_GUARD_FAIL invalid stage: $stage" >&2; exit 1 ;;
esac

if [[ "$wedge_id" != "$primary_id" ]]; then
  if [[ "$wedge_id" == "$reserve_id" ]]; then
    case "$stage" in
      TRIBUNAL|RESEARCH_PACKET|PROOF_SPEC|FROZEN) ;;
      *)
        echo "STAGE_GUARD_FAIL reserve wedge may not enter $stage before formal promotion: $wedge_id" >&2
        exit 1
        ;;
    esac
  else
    echo "STAGE_GUARD_FAIL active wedge differs from shared primary without reserve/switch-review path: $wedge_id != $primary_id" >&2
    exit 1
  fi
fi

if [[ "$stage" == "BUILD" || "$stage" == "VERIFY" || "$stage" == "DISTRIBUTE" || "$stage" == "LEARN" || "$stage" == "MAINTAIN" ]]; then
  [[ -f "$packet" ]] || { echo "STAGE_GUARD_FAIL missing research packet: $packet" >&2; exit 1; }
  [[ -f "$spec" ]] || { echo "STAGE_GUARD_FAIL missing proof spec: $spec" >&2; exit 1; }
  [[ "$wedge_id" == "$primary_id" ]] || { echo "STAGE_GUARD_FAIL only shared primary may enter $stage: $wedge_id" >&2; exit 1; }
fi

echo "STAGE_GUARD_OK wedge=$wedge_id stage=$stage"
