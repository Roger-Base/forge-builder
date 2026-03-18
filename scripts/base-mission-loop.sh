#!/bin/bash
# Portfolio-aware Base mission selector and state updater.

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
QUEUE="$WORKSPACE/state/base-opportunity-queue.json"
STATE="$WORKSPACE/state/session-state.json"
LEDGER="$WORKSPACE/state/project-ledger.json"
REPORT="$WORKSPACE/state/runtime/base-mission-loop-$(date -u +%Y%m%d-%H%M%S).md"
UPDATE_STATE=false
EMIT_BRIEF=false
REFRESH_PROOF=false
OP_ID=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --update-state) UPDATE_STATE=true ;;
    --emit-brief) EMIT_BRIEF=true ;;
    --refresh-proof) REFRESH_PROOF=true ;;
    --op) shift; OP_ID="${1:-}" ;;
    --report) shift; REPORT="${1:-$REPORT}" ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
  shift || true
done

mkdir -p "$WORKSPACE/state/runtime"
jq . "$QUEUE" >/dev/null
jq . "$LEDGER" >/dev/null

default_id="$(jq -r '.primary_id' "$LEDGER")"
reserve_id="$(jq -r '.reserve_id' "$LEDGER")"
selected_id="${OP_ID:-$default_id}"
selected="$(jq -c --arg id "$selected_id" '.opportunities[] | select(.id == $id)' "$QUEUE")"
if [ -z "$selected" ] || [ "$selected" = "null" ]; then
  selected="$(jq -c --arg id "$reserve_id" '.opportunities[] | select(.id == $id)' "$QUEUE")"
fi
[ -n "$selected" ] && [ "$selected" != "null" ] || { echo "BASE_MISSION_FAIL no selected opportunity" >&2; exit 1; }

op_id="$(echo "$selected" | jq -r '.id')"
title="$(echo "$selected" | jq -r '.title')"
portfolio_status="$(echo "$selected" | jq -r '.portfolio_status // "UNKNOWN"')"
stage="$(echo "$selected" | jq -r '.stage // "TRIBUNAL"')"
why_now="$(echo "$selected" | jq -r '.why_now // ""')"
problem="$(echo "$selected" | jq -r '.problem // ""')"
public_proof="$(echo "$selected" | jq -r '.public_proof_target // .public_proof_url // ""')"
research_packet="$(echo "$selected" | jq -r '.research_packet_path // empty')"
proof_spec="$(echo "$selected" | jq -r '.proof_spec_path // empty')"
next_type="$(echo "$selected" | jq -r '.next_action.type // "execute"')"
next_cmd="$(echo "$selected" | jq -r '.next_action.command // ""')"
next_target="$(echo "$selected" | jq -r '.next_action.target // ""')"
next_proof="$(echo "$selected" | jq -r '.next_action.proof_expected // ""')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [ "$EMIT_BRIEF" = true ]; then
  BRIEF="$WORKSPACE/state/runtime/${op_id}-brief-$(date -u +%Y%m%d-%H%M%S).md"
  {
    echo "# ${title} Brief"
    echo
    echo "- timestamp: $ts"
    echo "- opportunity_id: $op_id"
    echo "- portfolio_status: $portfolio_status"
    echo "- stage: $stage"
    echo
    echo "## Why Now"
    echo "$why_now"
    echo
    echo "## Problem"
    echo "$problem"
    echo
    echo "## Research Packet"
    echo "- $research_packet"
    echo
    echo "## Proof Spec"
    echo "- $proof_spec"
    echo
    echo "## Next Action"
    echo "- type: $next_type"
    echo "- command: $next_cmd"
    echo "- target: $next_target"
    echo "- proof_expected: $next_proof"
  } > "$BRIEF"
  echo "BASE_MISSION_BRIEF_OK $BRIEF"
  exit 0
fi

if [ "$REFRESH_PROOF" = true ]; then
  REFRESH="$WORKSPACE/state/runtime/${op_id}-proof-refresh-$(date -u +%Y%m%d-%H%M%S).md"
  {
    echo "# ${title} Proof Refresh"
    echo
    echo "- timestamp: $ts"
    echo "- opportunity_id: $op_id"
    echo "- portfolio_status: $portfolio_status"
    echo "- stage: $stage"
    echo
    echo "## Allowed scope"
    echo "- bounded proof refresh"
    echo "- no wedge switching"
    echo "- no broad repositioning"
    echo
    echo "## Public proof target"
    echo "$public_proof"
  } > "$REFRESH"
  echo "BASE_MISSION_PROOF_REFRESH_OK $REFRESH"
  exit 0
fi

{
  echo "# Base Mission Loop"
  echo
  echo "- timestamp: $ts"
  echo "- selected: $op_id"
  echo "- portfolio_status: $portfolio_status"
  echo "- stage: $stage"
  echo
  echo "## Why This Wedge"
  echo "$why_now"
  echo
  echo "## Next Action"
  echo "- type: $next_type"
  echo "- command: $next_cmd"
  echo "- target: $next_target"
  echo "- proof_expected: $next_proof"
} > "$REPORT"

if [ "$UPDATE_STATE" = true ]; then
  tmp="$(mktemp)"
  jq \
    --arg ts "$ts" \
    --arg op "$op_id" \
    --arg stage "$stage" \
    --arg cmd "$next_cmd" \
    --arg type "$next_type" \
    --arg target "$next_target" \
    --arg proof "$next_proof" \
    --arg title "$title" \
    --arg why "$why_now" \
    --arg problem "$problem" \
    --arg report_rel "${REPORT#$WORKSPACE/}" \
    --arg packet "$research_packet" \
    --arg spec "$proof_spec" \
    '
    .version = "14.0"
    | .mode = "BUILD"
    | .goal = "Ship one primary Base-native wedge at a time and keep support layers in support role"
    | .lastUpdated = $ts
    | .last_verified_at = $ts
    | .portfolio = {
        primary_id: "agent_security_scanner",
        reserve_id: "base_account_miniapp_probe",
        maintenance_ids: ["base_gas_tracker_v2", "contextkeeper_mvp"],
        frozen_ids: ["x402_paid_api_demo", "erc8004_registry_utility", "bankr_operator_console", "base-beginner-guide", "base-portfolio", "base-send", "base-receive", "base_gas_tracker_static_duplicate", "base_gas_tracker_builder_duplicate"]
      }
    | .active_wedge = {id: $op, stage: $stage}
    | .support_layers = {
        bankr: "support_only",
        virtuals: "support_only",
        acp: "support_only",
        x402: "support_only",
        roger_token: "support_only"
      }
    | .research_packet_required = ($stage == "TRIBUNAL" or $stage == "RESEARCH_PACKET" or $stage == "PROOF_SPEC")
    | .stage_transition_guard = {
        consecutive_benchmark_briefs: 0,
        consecutive_research_refreshes: 0,
        last_transition_at: $ts,
        required_packet: $packet,
        required_proof_spec: $spec
      }
    | .switch_request = {requested: false, reason: "", evidence_path: ""}
    | .switch_verdict = "hold_primary"
    | .last_artifact_change_at = $ts
    | .next_action = {
        type: $type,
        command: $cmd,
        target: $target,
        proof_expected: $proof,
        fallbacks: [
          "If wedge state drifts, rerun: cd ~/.openclaw/workspace && bash scripts/base-mission-loop.sh --update-state",
          "If the primary wedge stalls, validate stage before widening scope"
        ]
      }
    | .focus = {
        mode: .mode,
        goal: .goal,
        next_action: .next_action
      }
    | .decision_card = {
        objective: ("Advance the active Base wedge: " + $title),
        why_now: $why,
        proof_basis: ("Portfolio + stage machine selected wedge. Problem: " + $problem),
        first_step: $cmd,
        fallback_step: "cd ~/.openclaw/workspace && bash scripts/base-mission-loop.sh --update-state"
      }
    | .critic = {
        reviewed: true,
        reviewer: "base-mission-loop",
        verdict: "Stay on the portfolio-selected wedge until proof ships or a formal switch review passes.",
        main_risk: "scope drift back into support layers, broad research, or maintenance loops",
        confirmed_first_step: $cmd
      }
    | .operator_context = {
        label: "state_drift",
        why: ("Mission focus was repaired to the portfolio-selected wedge " + $op),
        live_lane: ("base-mission-loop -> " + $op),
        degraded_lanes: ["support-layer drift", "broad idea churn"],
        evidence_paths: [$report_rel],
        next_review_trigger: "After the active wedge produces a stronger artifact or the kill criteria are hit.",
        last_reviewed_at: $ts
      }
    ' "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/tmp/base-mission-state-write.txt
  rm -f "$tmp"
fi

echo "BASE_MISSION_OK $REPORT"
