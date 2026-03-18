#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
OUT=""
CANDIDATE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --candidate)
      CANDIDATE="${2:-}"
      shift 2
      ;;
    --output)
      OUT="${2:-}"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--candidate wedge_id] --output path" >&2
      exit 1
      ;;
  esac
done

[[ -n "$OUT" ]] || { echo "Missing --output" >&2; exit 1; }

primary="$(jq -r '.roger.primary_wedge // "agent_security_scanner"' "$SPINE")"
reserve="$(jq -r '.roger.reserve_wedge // "base_account_miniapp_probe"' "$SPINE")"
candidate="${CANDIDATE:-$reserve}"
active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
active_stage="$(jq -r '.active_wedge.stage' "$STATE")"
last_artifact="$(jq -r '.last_artifact_change_at // "unknown"' "$STATE")"

candidate_packet="$WORKSPACE/docs/wedges/$candidate/research-packet.md"
candidate_spec="$WORKSPACE/docs/wedges/$candidate/proof-spec.md"
current_spec="$WORKSPACE/docs/wedges/$primary/proof-spec.md"
candidate_packet_ok="no"
candidate_spec_ok="no"
[[ -f "$candidate_packet" ]] && candidate_packet_ok="yes"
[[ -f "$candidate_spec" ]] && candidate_spec_ok="yes"

recommendation="KEEP_PRIMARY"
reason="Current primary should remain active until the candidate proves a stronger concrete plan and a formal switch review passes."

if [[ "$candidate" == "$primary" ]]; then
  recommendation="KEEP_PRIMARY"
  reason="Candidate equals the current shared primary wedge."
elif [[ "$candidate_packet_ok" == "yes" && "$candidate_spec_ok" == "yes" && ( "$active_stage" == "LEARN" || "$active_stage" == "FROZEN" || "$active_wedge" == "$candidate" ) ]]; then
  recommendation="SWITCH_REVIEW_READY"
  reason="Candidate has both research packet and proof spec. Walter sign-off and shared-spine update are still required before BUILD."
fi

mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<EOF
# Wedge Switch Review

- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- current_primary: $primary
- current_active_wedge: $active_wedge
- current_stage: $active_stage
- last_artifact_change_at: $last_artifact
- candidate_wedge: $candidate
- candidate_packet: $candidate_packet_ok
- candidate_spec: $candidate_spec_ok
- recommendation: $recommendation

## Reason
$reason

## Rules
1. Roger may explore a candidate wedge in research/spec mode.
2. Roger may not silently promote a candidate wedge to primary.
3. BUILD and later stages require shared-spine truth or an explicitly approved switch review.
4. Walter may confirm, correct, or veto the switch based on evidence.

## Evidence paths
- current proof spec: \`$current_spec\`
- candidate research packet: \`$candidate_packet\`
- candidate proof spec: \`$candidate_spec\`
EOF

echo "WEDGE_SWITCH_REVIEW_OK $OUT"
