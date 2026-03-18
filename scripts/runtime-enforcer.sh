#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
REPORT="$WORKSPACE/state/runtime/runtime-enforcer-$(date -u +%Y%m%d-%H%M%S).md"
mkdir -p "$WORKSPACE/state/runtime"
STALE_THRESHOLD_SECONDS="${STALE_THRESHOLD_SECONDS:-14400}"
seed_state() {
  local out="$1"
  local ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # Read current portfolio from PORTFOLIO_LEDGER to ensure seed matches shared spine
  local primary_wedge="$(jq -r '.primary_id' "$SPINE")"
  local reserve_wedge="$(jq -r '.reserve_id // ""' "$SPINE")"
  local frozen_wedges="$(jq -r '.frozen_ids // []' "$SPINE")"
  
  # Determine correct next_action based on primary_wedge
  local next_action_cmd=""
  local next_action_target=""
  local next_action_proof=""
  
  # Check current stage
  local current_stage="$(jq -r '.active_wedge.stage // "UNKNOWN"' "$STATE")"
  
  # If in LEARN stage, don't auto-execute demo scripts
  if [[ "$current_stage" == "LEARN" ]]; then
    next_action_cmd="date +%s"
    next_action_target="self"
    next_action_proof="learn phase checkpoint"
  else
    case "$primary_wedge" in
      "base_account_miniapp_probe")
        next_action_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
        next_action_target="docs/wedges/base_account_miniapp_probe/demo-output.md"
        next_action_proof="fresh demo output for the miniapp probe wedge"
        ;;
      "agent_security_scanner")
        next_action_cmd="cd ~/.openclaw/workspace && bash scripts/agent-security-scanner.sh --target skills/security-audit-toolkit/SKILL.md --output state/runtime/security-audit-toolkit-scan-\$(date -u +%Y%m%d-%H%M%S).md"
        next_action_target="state/runtime/security-audit-toolkit-scan-*.md"
        next_action_proof="fresh security audit on security-audit-toolkit"
        ;;
      *)
        next_action_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
        next_action_target="docs/wedges/$primary_wedge/*.md"
        next_action_proof="fresh bounded artifact delta on the active wedge"
        ;;
    esac
  fi
  
  cat > "$out" <<JSON
{
  "version": "2.0",
  "updated_at": "$ts",
  "mode": "BUILD",
  "mission": {"id": "roger-base-v1", "status": "active"},
  "portfolio": {
    "primary_id": "$primary_wedge",
    "reserve_id": "$reserve_wedge",
    "maintenance_ids": ["base_gas_tracker_v2", "contextkeeper_mvp"],
    "frozen_ids": $frozen_wedges
  },
  "active_wedge": {"id": "$primary_wedge", "stage": "PROOF_SPEC"},
  "next_action": {
    "type": "artifact_delta",
    "command": "$next_action_cmd",
    "target": "$next_action_target",
    "proof_expected": "$next_action_proof",
    "fallback_chain": [
      "cd ~/.openclaw/workspace && bash scripts/capability-activation.sh --ensure",
      "cd ~/.openclaw/workspace && bash scripts/active-surface-sync.sh"
    ]
  },
  "decision_card": {"required": true, "path": "docs/wedges/$primary_wedge/proof-spec.md", "status": "pending"},
  "critic": {"last_handoff_id": null, "status": "none", "summary": "Runtime-enforcer rebuilt the canonical Roger state."},
  "subagents": {"required_roles": [], "max_parallel": 2, "last_runs": []},
  "support_layers": {"bankr": "support_only", "virtuals": "support_only", "acp": "support_only", "x402": "support_only", "roger_token": "support_only"},
  "blockers": [],
  "proof_paths": ["docs/wedges/$primary_wedge/research-packet.md", "docs/wedges/$primary_wedge/proof-spec.md"],
  "assumptions": ["Roger is the public Base-facing builder.", "Walter is the specialist counterforce.", "Community patterns are useful only after verification and routing through the shared spine."],
  "last_artifact_change_at": "$ts",
  "last_stage_advance_at": "$ts",
  "lastUpdated": "$ts",
  "direction_review": {"required": true, "candidate": "$primary_wedge", "status": "pending", "artifact_path": null, "reason": "formal-switch-review-required"},
  "capability_activation_ref": "state/capability-activation.json",
  "consumer": "current wedge proof surface and GitHub artifact lane",
  "never_touch": "Walter specialist work, Fundiora, and support-layer drift",
  "max_chain_steps": 3,
  "soft_budget_minutes": 25
}
JSON
}
repair_notes=()
if ! bash "$WORKSPACE/scripts/state-guard.sh" --validate "$STATE" >/dev/null 2>&1; then
  tmp="$(mktemp)"; seed_state "$tmp"; bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null; rm -f "$tmp"
  repair_notes+=("seed_state")
fi
bash "$WORKSPACE/scripts/portfolio-coherence-check.sh" >/dev/null
bash "$WORKSPACE/scripts/best-next-move.sh" --refresh >/dev/null
primary_id="$(jq -r '.primary_id' "$SPINE")"
reserve_id="$(jq -r '.reserve_id // "base_account_miniapp_probe"' "$SPINE")"
active_id="$(jq -r '.active_wedge.id' "$STATE")"
active_stage="$(jq -r '.active_wedge.stage' "$STATE")"
current_type="$(jq -r '.next_action.type // empty' "$STATE")"
next_cmd="$(jq -r '.next_action.command // empty' "$STATE")"
last_artifact_change_at="$(jq -r '.last_artifact_change_at // empty' "$STATE")"
artifact_age=""
if [[ -n "$last_artifact_change_at" ]]; then
  artifact_epoch="$(jq -nr --arg ts "$last_artifact_change_at" '$ts | fromdateiso8601' 2>/dev/null || true)"
  [[ -n "$artifact_epoch" ]] && artifact_age=$(( $(date -u +%s) - artifact_epoch ))
fi
tmp="$(mktemp)"
jq --arg primary "$primary_id" --arg reserve "$reserve_id" '
  .portfolio.primary_id = $primary
  | .portfolio.reserve_id = $reserve
  | .active_wedge.id = $primary
  | .capability_activation_ref = "state/capability-activation.json"
  | .consumer = (.consumer // "current wedge proof surface and GitHub artifact lane")
  | .never_touch = (.never_touch // "Walter specialist work, Fundiora, and support-layer drift")
  | .max_chain_steps = 3
  | .soft_budget_minutes = 25
  | .updated_at = (now|todate)
  | .lastUpdated = (now|todate)
' "$STATE" > "$tmp"
bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
rm -f "$tmp"
current_dir_status="$(jq -r '.direction_review.status // "none"' "$STATE")"
winner_id="$(jq -r '.winner.id' "$WORKSPACE/state/best-next-move.json")"
winner_cmd="$(jq -r '.winner.command' "$WORKSPACE/state/best-next-move.json")"
winner_target="$(jq -r '.winner.target' "$WORKSPACE/state/best-next-move.json")"
winner_proof="$(jq -r '.winner.proof_expected' "$WORKSPACE/state/best-next-move.json")"
winner_consumer="$(jq -r '.winner.consumer' "$WORKSPACE/state/best-next-move.json")"
winner_never_touch="$(jq -r '.winner.never_touch' "$WORKSPACE/state/best-next-move.json")"
winner_delegation="$(jq -r '.winner.delegation_needed' "$WORKSPACE/state/best-next-move.json")"
repeat_reason="$(jq -r '.repeated_lane_reason' "$WORKSPACE/state/best-next-move.json")"
winner_margin="$(jq -r '.winner_margin // 0' "$WORKSPACE/state/best-next-move.json")"
current_action_weak="$(jq -r '.current_action_weak // false' "$WORKSPACE/state/best-next-move.json")"
if [[ "$active_stage" == "LEARN" || "$active_stage" == "FROZEN" ]]; then
  if [[ "$current_dir_status" == "closed_no_action" ]]; then
    repair_notes+=("skip_closed_direction_review")
  elif [[ "$next_cmd" != *"wedge-switch-review.sh"* ]]; then
    # Preserve direction_review.status if already complete/closed
    current_dir_status="$(jq -r '.direction_review.status // "none"' "$STATE")"
    if [[ "$current_dir_status" == "complete" ]] || [[ "$current_dir_status" == "closed_no_action" ]]; then
      repair_notes+=("preserve_complete_direction_review")
    else
    tmp="$(mktemp)"
    jq --arg candidate "$reserve_id" '
      .next_action.type = "switch_review"
      | .next_action.command = ("cd ~/.openclaw/workspace && bash scripts/wedge-switch-review.sh --candidate " + $candidate + " --output state/runtime/wedge-switch-review-$(date -u +%Y%m%d-%H%M%S).md")
      | .next_action.target = "state/runtime/wedge-switch-review-*.md"
      | .next_action.proof_expected = "formal switch review artifact with keep/promote/nominate decision"
      | .direction_review = {required:true, candidate:$candidate, status:"pending", artifact_path:null, reason:"post-learn-direction-required"}
      | .consumer = "Roger runtime state, shared spine, Walter handoff"
      | .subagents.required_roles = ["builder-spike","verifier"]
      | .blockers = ((.blockers // []) + ["post-learn-direction-required"] | unique)
      | .updated_at = (now|todate)
      | .lastUpdated = (now|todate)
    ' "$STATE" > "$tmp"
    bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
    rm -f "$tmp"
    repair_notes+=("post_learn_direction_review")
    fi
  fi
elif [[ "$active_id" != "$primary_id" ]]; then
  # Preserve direction_review.status if already complete/closed
  current_dir_status="$(jq -r '.direction_review.status // "none"' "$STATE")"
  if [[ "$current_dir_status" == "complete" ]] || [[ "$current_dir_status" == "closed_no_action" ]]; then
    repair_notes+=("preserve_complete_direction_review_active_mismatch")
  else
  tmp="$(mktemp)"
  jq --arg primary "$primary_id" --arg candidate "$active_id" '
    .active_wedge.id = $primary
    | .next_action.type = "switch_review"
    | .next_action.command = ("cd ~/.openclaw/workspace && bash scripts/wedge-switch-review.sh --candidate " + $primary + " --output state/runtime/wedge-switch-review-$(date -u +%Y%m%d-%H%M%S).md")
    | .next_action.target = "state/runtime/wedge-switch-review-*.md"
    | .next_action.proof_expected = "formal switch review artifact with keep/promote/nominate decision"
    | .direction_review = {required:true, candidate:$primary, status:"pending", artifact_path:null, reason:"formal-switch-review-required"}
    | .consumer = "Roger runtime state, shared spine, Walter handoff"
    | .updated_at = (now|todate)
    | .lastUpdated = (now|todate)
  ' "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
  rm -f "$tmp"
  repair_notes+=("non_primary_direction_review")
  fi
fi
if [[ "$current_action_weak" == "true" ]] || [[ "$repeat_reason" != "none" ]] || { [[ -n "$winner_cmd" ]] && [[ "$next_cmd" != "$winner_cmd" ]] && (( winner_margin >= 15 )); }; then
  tmp="$(mktemp)"
  jq \
    --arg wid "$winner_id" \
    --arg cmd "$winner_cmd" \
    --arg target "$winner_target" \
    --arg proof "$winner_proof" \
    --arg consumer "$winner_consumer" \
    --arg never_touch "$winner_never_touch" \
    --arg repeated "$repeat_reason" \
    --argjson delegation "$winner_delegation" \
    '
      .next_action.type = $wid
      | .next_action.command = $cmd
      | .next_action.target = $target
      | .next_action.proof_expected = $proof
      | .consumer = $consumer
      | .never_touch = $never_touch
      | .updated_at = (now|todate)
      | .lastUpdated = (now|todate)
      | .best_next_move_ref = "state/best-next-move.json"
      | if $delegation == "true" then .subagents.required_roles = ["verifier"] else . end
      | if $repeated != "none" then .blockers = ((.blockers // []) + ["pattern-fallthrough:" + $repeated] | unique) else . end
    ' "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
  rm -f "$tmp"
    repair_notes+=("best_next_move_applied:$winner_id")
fi
if [[ -n "$artifact_age" ]] && (( artifact_age >= STALE_THRESHOLD_SECONDS )) && [[ "$active_id" == "$primary_id" ]] && [[ "$active_stage" =~ ^(BUILD|PROOF_SPEC|VERIFY)$ ]]; then
  tmp="$(mktemp)"
  # Determine correct recovery command based on active_wedge
  recovery_cmd=""
  recovery_target=""
  recovery_proof=""
  
  case "$active_id" in
    "base_account_miniapp_probe")
      recovery_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      recovery_target="docs/wedges/base_account_miniapp_probe/demo-output.md"
      recovery_proof="fresh demo output for the miniapp probe wedge"
      ;;
    "agent_security_scanner")
      recovery_cmd="cd ~/.openclaw/workspace && bash scripts/agent-security-scanner.sh --target skills/security-audit-toolkit/SKILL.md --output state/runtime/security-audit-toolkit-scan-\$(date -u +%Y%m%d-%H%M%S).md"
      recovery_target="state/runtime/security-audit-toolkit-scan-*.md"
      recovery_proof="fresh security audit on security-audit-toolkit"
      ;;
    *)
      recovery_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      recovery_target="docs/wedges/$active_id/*.md"
      recovery_proof="fresh bounded artifact delta on the active wedge"
      ;;
  esac
  
  jq --arg cmd "$recovery_cmd" --arg tgt "$recovery_target" --arg prof "$recovery_proof" '
    .next_action.type = "artifact_recovery"
    | .next_action.command = $cmd
    | .next_action.target = $tgt
    | .next_action.proof_expected = $prof
    | .subagents.required_roles = ["builder-spike","verifier"]
    | .consumer = "Roger runtime, GitHub proof surface, Walter handoff"
    | .updated_at = (now|todate)
    | .lastUpdated = (now|todate)
  ' "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
  rm -f "$tmp"
  repair_notes+=("stale_artifact_recovery")
fi
bash "$WORKSPACE/scripts/best-next-move.sh" --refresh --apply >/dev/null
bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
cat > "$REPORT" <<MD
# Runtime Enforcer

- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- repairs: ${repair_notes[*]:-none}
- active_wedge: $(jq -r '.active_wedge.id' "$STATE")
- stage: $(jq -r '.active_wedge.stage' "$STATE")
- next_action: $(jq -r '.next_action.command' "$STATE")
- best_next_move: $(jq -r '.winner.id + " (" + (.winner.score|tostring) + ", margin=" + (.winner_margin|tostring) + ")"' "$WORKSPACE/state/best-next-move.json")
MD
echo "RUNTIME_ENFORCER_OK $REPORT"
