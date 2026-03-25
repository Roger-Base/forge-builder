#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
ACT="$WORKSPACE/state/capability-activation.json"
SKLOG="$WORKSPACE/state/skill-usage-log.json"
OUT="$WORKSPACE/state/best-next-move.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
AUDIT="$WORKSPACE/state/roger-self-audit.json"
REUSE="$WORKSPACE/state/reuse-plan.json"
SYNTH="$WORKSPACE/state/synthesis-registry.json"
DOCTRINE="$WORKSPACE/state/planner-doctrine.json"
BODY="$WORKSPACE/state/capability-body.json"
REGISTRY="$WORKSPACE/state/wedge-registry.json"
MODE="refresh"
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh) MODE="refresh"; shift ;;
    --apply) APPLY=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

resolve_body_lane_json() {
  local wedge="$1"
  local intent="$2"
  [[ -f "$BODY" ]] || return 0
  jq -c --arg wedge "$wedge" --arg intent "$intent" '
    (.wedge_bindings // [])
    | map(select(.wedge_id == $wedge))
    | .[0] as $binding
    | if $binding == null then empty
      else ($binding.intent_defaults[$intent] // $binding.intent_defaults.default // empty) as $lane_id
      | if $lane_id == "" then empty
        else (.lane_registry // []) | map(select(.id == $lane_id)) | .[0] // empty
        end
      end
  ' "$BODY" 2>/dev/null || true
}

resolve_registry_artifact_json() {
  local wedge="$1"
  [[ -f "$REGISTRY" ]] || return 0
  jq -c --arg wedge "$wedge" '
    (.wedges // [])
    | map(select(.id == $wedge))
    | .[0].artifact // empty
  ' "$REGISTRY" 2>/dev/null || true
}

resolve_registry_learn_json() {
  [[ -f "$REGISTRY" ]] || return 0
  jq -c '.learn_checkpoint // empty' "$REGISTRY" 2>/dev/null || true
}

if [[ ! -f "$REGISTRY" ]]; then
  node "$WORKSPACE/scripts/roger-wedge-registry-sync.mjs" >/dev/null
fi

active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
stage="$(jq -r '.active_wedge.stage' "$STATE")"
# GOVERNANCE FIX: Check if delegation is known broken (spawn never executes)
delegation_broken=false
if grep -q -E "delegation.*broken|SPAWN.*never" "$WORKSPACE/MEMORY_ACTIVE.md" 2>/dev/null; then
  delegation_broken=true
fi
next_cmd="$(jq -r '.next_action.command // empty' "$STATE")"
current_type="$(jq -r '.next_action.type // empty' "$STATE")"
proof_expected_state="$(jq -r '.next_action.proof_expected // "real wedge delta"' "$STATE")"
last_artifact_change_at="$(jq -r '.last_artifact_change_at // empty' "$STATE")"
direction_required="$(jq -r '.direction_review.required // false' "$STATE")"
direction_status="$(jq -r '.direction_review.status // "none"' "$STATE")"
direction_candidate="$(jq -r '.direction_review.candidate // empty' "$STATE")"
reserve_id="$(jq -r '.roger.reserve_wedge // "agent-discovery"' "$SPINE")"
current_lane="$(jq -r '.selected_skill_or_lane // empty' "$ACT" 2>/dev/null || true)"
synthesis_active_wedge=""
synthesis_lane=""
synthesis_next_action=""
synthesis_blocker_class="none"
synthesis_proof_expected=""
audit_reflection_needed=false
audit_recommended="continue_current"
audit_blocker_scope="none"
audit_wedge_shipped=false
reuse_recommendation="new_artifact_allowed"
reuse_note=""
reuse_target=""
reuse_bundle_id=""
doctrine_present=false
doctrine_ethskills_first=false
doctrine_capability_body_first=false
doctrine_reuse_before_replace=false
doctrine_synthesis_before_widening=false
doctrine_allow_refresh_under_human_only=false
doctrine_prefer_same_wedge_search_before_switch=false
doctrine_artifact_boost_reuse_alignment=0
doctrine_artifact_boost_human_refresh=0
doctrine_proof_penalty_refresh_exists=0
doctrine_delegation_penalty_refresh_exists=0
doctrine_direction_boost_synthesis_disagree=0

now_epoch="$(date -u +%s)"
artifact_age=0
if [[ -n "$last_artifact_change_at" ]]; then
  art_epoch="$(jq -nr --arg ts "$last_artifact_change_at" '$ts | fromdateiso8601' 2>/dev/null || true)"
  [[ -n "$art_epoch" ]] && artifact_age=$(( now_epoch - art_epoch ))
fi

if [[ -f "$AUDIT" ]]; then
  audit_reflection_needed="$(jq -r '.self_reflection_needed // false' "$AUDIT" 2>/dev/null || echo false)"
  audit_recommended="$(jq -r '.recommended_next_move // "continue_current"' "$AUDIT" 2>/dev/null || echo continue_current)"
  audit_blocker_scope="$(jq -r '.blocker_scope // "none"' "$AUDIT" 2>/dev/null || echo none)"
  audit_wedge_shipped="$(jq -r '.wedge_already_shipped // false' "$AUDIT" 2>/dev/null || echo false)"
fi
if [[ -f "$REUSE" ]]; then
  reuse_recommendation="$(jq -r '.recommendation // "new_artifact_allowed"' "$REUSE" 2>/dev/null || echo new_artifact_allowed)"
  reuse_note="$(jq -r '.note // empty' "$REUSE" 2>/dev/null || true)"
  reuse_target="$(jq -r '.target_path // empty' "$REUSE" 2>/dev/null || true)"
  reuse_bundle_id="$(jq -r '.bundle_id // empty' "$REUSE" 2>/dev/null || true)"
fi
if [[ -f "$SYNTH" ]]; then
  synthesis_active_wedge="$(jq -r '.active_wedge // empty' "$SYNTH" 2>/dev/null || true)"
  synthesis_lane="$(jq -r '.current_lane // empty' "$SYNTH" 2>/dev/null || true)"
  synthesis_next_action="$(jq -r '.next_action_type // empty' "$SYNTH" 2>/dev/null || true)"
  synthesis_blocker_class="$(jq -r '.blocker_class // "none"' "$SYNTH" 2>/dev/null || echo none)"
  synthesis_proof_expected="$(jq -r '.proof_expected // empty' "$SYNTH" 2>/dev/null || true)"
fi
if [[ -f "$DOCTRINE" ]]; then
  doctrine_present=true
  doctrine_ethskills_first="$(jq -r '.policy.ethskills_first // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_capability_body_first="$(jq -r '.policy.capability_body_first // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_reuse_before_replace="$(jq -r '.policy.reuse_before_replace // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_synthesis_before_widening="$(jq -r '.policy.synthesis_before_widening // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_allow_refresh_under_human_only="$(jq -r '.policy.allow_refresh_under_human_only_if_delta_exists // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_prefer_same_wedge_search_before_switch="$(jq -r '.policy.prefer_same_wedge_search_before_switch // false' "$DOCTRINE" 2>/dev/null || echo false)"
  doctrine_artifact_boost_reuse_alignment="$(jq -r '.routing_bias.artifact_delta_boost_on_reuse_alignment // 0' "$DOCTRINE" 2>/dev/null || echo 0)"
  doctrine_artifact_boost_human_refresh="$(jq -r '.routing_bias.artifact_delta_boost_on_human_only_refreshable_wedge // 0' "$DOCTRINE" 2>/dev/null || echo 0)"
  doctrine_proof_penalty_refresh_exists="$(jq -r '.routing_bias.proof_sync_penalty_when_refresh_target_exists // 0' "$DOCTRINE" 2>/dev/null || echo 0)"
  doctrine_delegation_penalty_refresh_exists="$(jq -r '.routing_bias.delegation_penalty_when_refresh_target_exists // 0' "$DOCTRINE" 2>/dev/null || echo 0)"
  doctrine_direction_boost_synthesis_disagree="$(jq -r '.routing_bias.direction_review_boost_when_synthesis_and_state_disagree // 0' "$DOCTRINE" 2>/dev/null || echo 0)"
fi
if [[ -z "$current_lane" && -n "$synthesis_lane" ]]; then
  current_lane="$synthesis_lane"
fi

repeat_count=0
if [[ -f "$SKLOG" && -n "$current_lane" ]]; then
  repeat_count="$(jq -r --arg lane "$current_lane" '[.entries[] | select(.agent=="Roger") | .selected_skill_or_lane][-6:] | map(select(. == $lane)) | length' "$SKLOG" 2>/dev/null || echo 0)"
fi
repeated_lane=false
repeat_reason="none"
current_action_weak=false
if [[ "$next_cmd" == *"MAINTAIN_CADENCE_NOOP"* ]] || [[ "$current_type" == "maintain_cadence_noop_or_rebalance" ]] || [[ "$next_cmd" == *"window_not_reached"* ]]; then
  repeated_lane=true
  repeat_reason="maintain_noop"
  current_action_weak=true
elif (( repeat_count >= 2 )) && (( artifact_age >= 3600 )); then
  repeated_lane=true
  repeat_reason="same_lane_without_delta"
fi

if [[ "$audit_reflection_needed" == "true" ]]; then
  current_action_weak=true
  if [[ "$repeat_reason" == "none" ]]; then
    repeat_reason="self_audit_reflection"
  fi
fi
if [[ -n "$synthesis_active_wedge" ]] && [[ "$synthesis_active_wedge" != "$active_wedge" ]]; then
  current_action_weak=true
  if [[ "$repeat_reason" == "none" ]]; then
    repeat_reason="synthesis_wedge_mismatch"
  fi
fi

timestamp_expr='$(date -u +%Y%m%d-%H%M%S)'

# Determine correct artifact command based on the local wedge registry first.
registry_artifact=""
if [[ "$stage" == "LEARN" ]]; then
  registry_artifact="$(resolve_registry_learn_json)"
else
  registry_artifact="$(resolve_registry_artifact_json "$active_wedge")"
fi

if [[ -n "$registry_artifact" && "$registry_artifact" != "null" ]]; then
  artifact_cmd="$(jq -r '.command // empty' <<<"$registry_artifact")"
  artifact_target="$(jq -r '.target // "none"' <<<"$registry_artifact")"
  artifact_proof="$(jq -r '.proof_expected // "real wedge delta"' <<<"$registry_artifact")"
  artifact_lane="$(jq -r '.lane // "none"' <<<"$registry_artifact")"
else
  case "$active_wedge" in
    "base_account_miniapp_probe")
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      artifact_target="docs/wedges/base_account_miniapp_probe/demo-output.md"
      artifact_proof="fresh demo output for the miniapp probe wedge"
      artifact_lane="base_mini_app_monitor_demo.sh"
      ;;
    "agent_security_scanner")
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/agent-security-scanner.sh --target skills/security-audit-toolkit/SKILL.md --output state/runtime/security-audit-toolkit-scan-${timestamp_expr}.md"
      artifact_target="state/runtime/security-audit-toolkit-scan-*.md"
      artifact_proof="fresh security audit on security-audit-toolkit"
      artifact_lane="skills/agent-evaluation/SKILL.md + scripts/agent-security-scanner.sh"
      ;;
    "agent-trust-discovery")
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/refresh-agent-trust-discovery.sh docs/wedges/agent-trust-discovery/demo-output.md"
      artifact_target="docs/wedges/agent-trust-discovery/demo-output.md"
      artifact_proof="fresh live lookup output captured in the canonical agent-trust-discovery demo surface"
      artifact_lane="services/erc8004-agent-lookup + refresh-agent-trust-discovery.sh"
      ;;
    "defai-yield-agent")
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/refresh-defai-yield-artifacts.sh docs/wedges/defai-yield-agent/P1-yield-scan.md"
      artifact_target="docs/wedges/defai-yield-agent/P1-yield-scan.md"
      artifact_proof="fresh canonical P1 yield scan or failure trace recorded on the defai-yield-agent wedge"
      artifact_lane="defai-yield-scan.js + refresh-defai-yield-artifacts.sh"
      ;;
    *)
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      artifact_target="docs/wedges/${active_wedge}/*.md"
      artifact_proof="fresh bounded artifact delta on the active wedge"
      artifact_lane="base_mini_app_monitor_demo.sh"
      ;;
  esac
fi

proof_cmd="cd ~/.openclaw/workspace && bash scripts/github-proof-surface-check.sh --wedge ${active_wedge} --output state/runtime/${active_wedge}-proof-surface-${timestamp_expr}.md"
delegate_cmd="cd ~/.openclaw/workspace && bash scripts/worker-subagent-trigger.sh --role verifier --target-wedge ${active_wedge} --consumer 'Roger active wedge' --task 'Verify the strongest proof, repo, and readiness gap for ${active_wedge} after repeated or weak progress.' --output state/runtime/subagent-verifier-${timestamp_expr}.md"
direction_target="${direction_candidate:-$reserve_id}"
direction_cmd="cd ~/.openclaw/workspace && bash scripts/wedge-switch-review.sh --candidate ${direction_target} --output state/runtime/wedge-switch-review-${timestamp_expr}.md"

artifact_leverage=55
proof_leverage=60
delegate_leverage=50
artifact_risk=10
proof_risk=8
delegate_risk=15
artifact_capability="public_builder_execution"
proof_capability="proof_distribution"
artifact_body_surfaces_json='[]'
proof_body_surfaces_json='[]'

artifact_body_match="$(resolve_body_lane_json "$active_wedge" "build")"
if [[ -n "$artifact_body_match" && "$artifact_body_match" != "null" ]]; then
  resolved_capability="$(jq -r '.capability // empty' <<<"$artifact_body_match")"
  [[ -n "$resolved_capability" ]] && artifact_capability="$resolved_capability"
  artifact_body_surfaces_json="$(jq -c '.local_surfaces // []' <<<"$artifact_body_match")"
fi

proof_body_match="$(resolve_body_lane_json "$active_wedge" "verify")"
if [[ -n "$proof_body_match" && "$proof_body_match" != "null" ]]; then
  resolved_capability="$(jq -r '.capability // empty' <<<"$proof_body_match")"
  [[ -n "$resolved_capability" ]] && proof_capability="$resolved_capability"
  proof_body_surfaces_json="$(jq -c '.local_surfaces // []' <<<"$proof_body_match")"
fi

if [[ "$stage" =~ ^(BUILD|PROOF_SPEC)$ ]]; then artifact_leverage=$((artifact_leverage + 25)); fi
if [[ "$stage" =~ ^(VERIFY|DISTRIBUTE)$ ]]; then proof_leverage=$((proof_leverage + 25)); fi
if [[ "$stage" == "MAINTAIN" ]]; then
  proof_leverage=$((proof_leverage + 15))
  delegate_leverage=$((delegate_leverage + 20))
  artifact_risk=$((artifact_risk + 10))
fi
if [[ "$stage" =~ ^(LEARN|FROZEN)$ ]]; then delegate_leverage=$((delegate_leverage + 25)); fi
if [[ "$direction_required" == "true" ]]; then delegate_leverage=$((delegate_leverage + 20)); fi
if [[ "$audit_reflection_needed" == "true" ]]; then
  artifact_risk=$((artifact_risk + 60))
  proof_risk=$((proof_risk + 15))
  delegate_leverage=$((delegate_leverage + 35))
fi
if [[ "$audit_blocker_scope" == "partial_wedge" ]]; then
  artifact_risk=$((artifact_risk + 20))
  delegate_leverage=$((delegate_leverage + 15))
fi
if [[ "$audit_wedge_shipped" == "true" ]]; then
  artifact_risk=$((artifact_risk + 20))
fi
if [[ "$repeated_lane" == "true" ]]; then
  proof_leverage=$((proof_leverage + 15))
  delegate_leverage=$((delegate_leverage + 25))
  # FIX: When repeated_lane_reason is "same_lane_without_delta", DECREASE artifact_risk
  # to FORCE artifact_delta, not observation-only work
  if [[ "$repeat_reason" == "same_lane_without_delta" ]]; then
    artifact_risk=$((artifact_risk - 30))  # Make artifact_delta win
  else
    artifact_risk=$((artifact_risk + 20))
  fi
  proof_risk=$((proof_risk + 5))
fi
if [[ "$current_action_weak" == "true" ]]; then
  proof_leverage=$((proof_leverage + 20))
  delegate_leverage=$((delegate_leverage + 25))
  artifact_risk=$((artifact_risk + 25))
fi
if [[ "$reuse_recommendation" == "reuse_existing_bundle" ]] || [[ "$reuse_recommendation" == "reuse_existing_bundle_while_blocked" ]]; then
  artifact_leverage=$((artifact_leverage + 15))
  proof_leverage=$((proof_leverage + 8))
  artifact_risk=$((artifact_risk - 8))
  if [[ -n "$reuse_target" ]]; then
    artifact_target="$reuse_target"
  fi
fi
if [[ "$reuse_recommendation" == "reuse_existing_bundle_while_blocked" ]]; then
  artifact_leverage=$((artifact_leverage + 45))
  artifact_risk=$((artifact_risk - 55))
  proof_risk=$((proof_risk + 10))
  delegate_risk=$((delegate_risk + 35))
fi
if [[ "$synthesis_active_wedge" == "$active_wedge" ]]; then
  case "$synthesis_next_action" in
    artifact_delta)
      artifact_leverage=$((artifact_leverage + 18))
      ;;
    proof_surface_sync)
      proof_leverage=$((proof_leverage + 12))
      ;;
    direction_review)
      delegate_leverage=$((delegate_leverage + 18))
      ;;
  esac
  if [[ -n "$synthesis_lane" ]] && [[ "$artifact_lane" == *"$synthesis_lane"* || "$synthesis_lane" == *"$artifact_lane"* ]]; then
    artifact_leverage=$((artifact_leverage + 8))
  fi
fi
if [[ "$synthesis_blocker_class" == "human-only" ]] && [[ "$reuse_recommendation" == reuse_existing_bundle* ]]; then
  artifact_leverage=$((artifact_leverage + 12))
  proof_risk=$((proof_risk + 8))
  delegate_risk=$((delegate_risk + 18))
fi
if [[ "$doctrine_reuse_before_replace" == "true" ]] && [[ "$reuse_recommendation" == reuse_existing_bundle* ]]; then
  artifact_leverage=$((artifact_leverage + doctrine_artifact_boost_reuse_alignment))
  proof_risk=$((proof_risk + doctrine_proof_penalty_refresh_exists))
  delegate_risk=$((delegate_risk + doctrine_delegation_penalty_refresh_exists))
fi
if [[ "$doctrine_allow_refresh_under_human_only" == "true" ]] && [[ "$synthesis_blocker_class" == "human-only" ]] && [[ "$reuse_recommendation" == reuse_existing_bundle* ]]; then
  artifact_leverage=$((artifact_leverage + doctrine_artifact_boost_human_refresh))
  delegate_risk=$((delegate_risk + doctrine_delegation_penalty_refresh_exists))
fi
if [[ "$doctrine_synthesis_before_widening" == "true" ]] && [[ -n "$synthesis_active_wedge" ]] && [[ "$synthesis_active_wedge" == "$active_wedge" ]] && [[ "$synthesis_next_action" == "artifact_delta" ]]; then
  artifact_leverage=$((artifact_leverage + 6))
fi
if [[ "$doctrine_prefer_same_wedge_search_before_switch" == "true" ]] && [[ -n "$artifact_target" ]] && [[ "$artifact_target" != "none" ]] && [[ "$synthesis_active_wedge" != "$active_wedge" ]] && [[ -n "$synthesis_active_wedge" ]]; then
  delegate_risk=$((delegate_risk + doctrine_direction_boost_synthesis_disagree))
  artifact_leverage=$((artifact_leverage + 6))
elif [[ "$doctrine_direction_boost_synthesis_disagree" -gt 0 ]] && [[ -n "$synthesis_active_wedge" ]] && [[ "$synthesis_active_wedge" != "$active_wedge" ]]; then
  delegate_leverage=$((delegate_leverage + doctrine_direction_boost_synthesis_disagree))
fi
# GOVERNANCE FIX: In MAINTAIN or VERIFY stage, penalize observation-only actions
# HEARTBEAT rule: "Never end on observation-only work"
if [[ "$stage" == "MAINTAIN" ]]; then
  proof_risk=$((proof_risk + 50))  # Penalize proof_surface_sync heavily
  delegate_risk=$((delegate_risk + 40))  # Penalize delegated_worker heavily
fi
# VERIFY stage: observation-only is governance violation, force artifact_delta
# DISTRIBUTE stage: same governance rule - observation-only violates HEARTBEAT
# DELEGATION BROKEN FIX: If delegation is known broken, heavily penalize it
if [[ "$delegation_broken" == "true" ]]; then
  delegate_risk=$((delegate_risk + 200))  # Massive penalty for broken path
fi
if [[ "$stage" == "VERIFY" ]]; then
  proof_risk=$((proof_risk + 40))  # Penalize proof_surface_sync in VERIFY
fi
if [[ "$stage" == "DISTRIBUTE" ]]; then
  proof_risk=$((proof_risk + 50))  # Penalize proof_surface_sync in DISTRIBUTE - observation-only violates HEARTBEAT
  delegate_risk=$((delegate_risk + 40))  # Penalize delegated_worker in DISTRIBUTE
fi
# LEARN stage: always penalize observation-only work (direction pending or complete)
if [[ "$stage" == "LEARN" ]]; then
  proof_risk=$((proof_risk + 45))  # Penalize proof_surface_sync in LEARN regardless of direction status
  delegate_risk=$((delegate_risk + 40))
fi
# LEARN stage: if direction is complete/closed, prefer artifact_delta over observation-only
if [[ "$stage" == "LEARN" ]] && [[ "$direction_status" =~ ^(complete|closed_no_action)$ ]]; then
  proof_risk=$((proof_risk + 10))  # Additional penalty when direction is resolved
fi
if (( artifact_age >= 14400 )); then
  proof_leverage=$((proof_leverage + 10))
  delegate_leverage=$((delegate_leverage + 15))
fi
if [[ "$direction_status" == "closed_no_action" ]]; then
  delegate_risk=$((delegate_risk + 10))
fi

artifact_score=$((artifact_leverage - artifact_risk))
proof_score=$((proof_leverage - proof_risk))
delegate_score=$((delegate_leverage - delegate_risk))
artifact_why="Push the current wedge forward with a real bounded artifact delta."
if [[ "$reuse_recommendation" == "reuse_existing_bundle" ]] || [[ "$reuse_recommendation" == "reuse_existing_bundle_while_blocked" ]]; then
  artifact_why="Update or extend the strongest existing artifact bundle before creating a replacement. ${reuse_note}"
fi
artifact_sources_json="$(jq -n --arg target "$artifact_target" --argjson extra "$artifact_body_surfaces_json" '["AGENTS.md","TOOLS.md","SKILLS.md","state/session-state.json","state/best-next-move.json","state/artifact-registry.json","state/reuse-plan.json","state/synthesis-registry.json","state/planner-doctrine.json","state/capability-body.json","state/wedge-registry.json","synthesis/CURRENT.md"] + $extra + (if $target != "" and $target != "none" and ($target | endswith("*") | not) then [$target] else [] end)')"
proof_sources_json="$(jq -n --argjson extra "$proof_body_surfaces_json" '["AGENTS.md","TOOLS.md","SKILLS.md","state/session-state.json","state/best-next-move.json","state/artifact-registry.json","state/reuse-plan.json","state/synthesis-registry.json","state/planner-doctrine.json","state/capability-body.json","state/wedge-registry.json","synthesis/CURRENT.md","scripts/github-proof-surface-check.sh"] + $extra')"
delegate_sources_json='["AGENTS.md","TOOLS.md","SKILLS.md","state/session-state.json","state/best-next-move.json","state/reuse-plan.json","state/synthesis-registry.json","state/planner-doctrine.json","state/capability-body.json","state/wedge-registry.json","synthesis/CURRENT.md"]'

candidate3_id="delegated_worker"
candidate3_intent="verify"
candidate3_capability="delegated_validation"
candidate3_lane="worker:verifier via scripts/worker-subagent-trigger.sh"
candidate3_why="Repeated or weak progress should trigger a bounded worker run instead of another local loop."
candidate3_consumer="Roger active wedge and Walter handoff"
candidate3_never_touch="silent wedge promotion and raw community drift"
candidate3_proof="recorded worker run and follow-up merge/result"
candidate3_command="$delegate_cmd"
candidate3_target="state/runtime/subagent-verifier-*.md"
candidate3_delegation=true

if [[ "$stage" =~ ^(LEARN|FROZEN)$ ]] || [[ "$direction_required" == "true" ]]; then
  candidate3_id="direction_review"
  candidate3_intent="switch_review"
  candidate3_capability="direction_review"
  candidate3_lane="scripts/wedge-switch-review.sh"
  candidate3_why="Post-LEARN or explicit direction pressure should resolve keep/promote/nominate before more local churn."
  candidate3_consumer="Roger runtime state, shared spine, Walter handoff"
  candidate3_never_touch="silent portfolio rewrites and comfort-loop maintenance"
  candidate3_proof="formal direction review artifact"
  candidate3_command="$direction_cmd"
  candidate3_target="state/runtime/wedge-switch-review-*.md"
  candidate3_delegation=false
fi

if [[ "$audit_recommended" == "direction_review" ]]; then
  candidate3_id="direction_review"
  candidate3_intent="switch_review"
  candidate3_capability="direction_review"
  candidate3_lane="scripts/wedge-switch-review.sh"
  candidate3_why="Roger's self-audit says the current blocker needs reclassification before more build pressure."
  candidate3_consumer="Roger runtime state, shared spine, and future self-improvement"
  candidate3_never_touch="blind build repetition against a partial or human-only blocker"
  candidate3_proof="formal direction review artifact"
  candidate3_command="$direction_cmd"
  candidate3_target="state/runtime/wedge-switch-review-*.md"
  candidate3_delegation=false
fi

tmp_json="$(mktemp)"
jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg wedge "$active_wedge" \
  --arg stage "$stage" \
  --arg repeat_reason "$repeat_reason" \
  --argjson repeated "$repeated_lane" \
  --argjson artifact_age "$artifact_age" \
  --arg candidate3_id "$candidate3_id" \
  --arg candidate3_intent "$candidate3_intent" \
  --arg candidate3_capability "$candidate3_capability" \
  --arg candidate3_lane "$candidate3_lane" \
  --arg candidate3_why "$candidate3_why" \
  --arg candidate3_consumer "$candidate3_consumer" \
  --arg candidate3_never_touch "$candidate3_never_touch" \
  --arg candidate3_proof "$candidate3_proof" \
  --arg candidate3_command "$candidate3_command" \
  --arg candidate3_target "$candidate3_target" \
  --argjson candidate3_delegation "$candidate3_delegation" \
  --arg artifact_cmd "$artifact_cmd" \
  --arg artifact_target "$artifact_target" \
  --arg artifact_proof "$artifact_proof" \
  --arg artifact_capability "$artifact_capability" \
  --arg proof_cmd "$proof_cmd" \
  --arg proof_capability "$proof_capability" \
  --arg proof_expected_state "$proof_expected_state" \
  --arg reserve "$reserve_id" \
  --arg artifact_lane "$artifact_lane" \
  --arg artifact_why "$artifact_why" \
  --arg reuse_bundle_id "$reuse_bundle_id" \
  --arg synthesis_wedge "$synthesis_active_wedge" \
  --arg synthesis_lane "$synthesis_lane" \
  --arg synthesis_next_action "$synthesis_next_action" \
  --arg synthesis_blocker_class "$synthesis_blocker_class" \
  --arg synthesis_proof_expected "$synthesis_proof_expected" \
  --argjson doctrine_present "$doctrine_present" \
  --argjson doctrine_ethskills_first "$doctrine_ethskills_first" \
  --argjson doctrine_capability_body_first "$doctrine_capability_body_first" \
  --argjson doctrine_reuse_before_replace "$doctrine_reuse_before_replace" \
  --argjson doctrine_synthesis_before_widening "$doctrine_synthesis_before_widening" \
  --argjson doctrine_allow_refresh_under_human_only "$doctrine_allow_refresh_under_human_only" \
  --argjson doctrine_prefer_same_wedge_search_before_switch "$doctrine_prefer_same_wedge_search_before_switch" \
  --argjson artifact_sources "$artifact_sources_json" \
  --argjson proof_sources "$proof_sources_json" \
  --argjson delegate_sources "$delegate_sources_json" \
  --argjson current_action_weak "$current_action_weak" \
  --argjson artifact_leverage "$artifact_leverage" \
  --argjson proof_leverage "$proof_leverage" \
  --argjson delegate_leverage "$delegate_leverage" \
  --argjson artifact_risk "$artifact_risk" \
  --argjson proof_risk "$proof_risk" \
  --argjson delegate_risk "$delegate_risk" \
  --argjson artifact_score "$artifact_score" \
  --argjson proof_score "$proof_score" \
  --argjson delegate_score "$delegate_score" \
  '
  {
    version: "1.0",
    updated_at: $ts,
    active_wedge: $wedge,
    stage: $stage,
    repeated_lane: $repeated,
    repeated_lane_reason: $repeat_reason,
    last_artifact_age_seconds: $artifact_age,
    candidates: [
      {
        id: "artifact_delta",
        intent: "build",
        selected_capability: $artifact_capability,
        selected_skill_or_lane: $artifact_lane,
        why_this_move: $artifact_why,
        consumer: "current wedge proof surface and GitHub artifact lane",
        never_touch: "Walter specialist work, Fundiora, and support-layer drift",
        proof_expected: $artifact_proof,
        source_paths: $artifact_sources,
        reuse_bundle_id: (if ($reuse_bundle_id | length) > 0 then $reuse_bundle_id else null end),
        leverage: $artifact_leverage,
        risk: $artifact_risk,
        command: $artifact_cmd,
        target: $artifact_target,
        delegation_needed: false,
        score: $artifact_score
      },
      {
        id: "proof_surface_sync",
        intent: "verify",
        selected_capability: $proof_capability,
        selected_skill_or_lane: "GitHub + proof surface",
        why_this_move: "Treat GitHub, proof links, and public visibility as part of the product instead of a later cleanup step.",
        consumer: "GitHub repo, proof surface, public distribution",
        never_touch: "unverified public claims and detached X chatter",
        proof_expected: "fresh proof-surface artifact with a concrete next proof move",
        source_paths: $proof_sources,
        leverage: $proof_leverage,
        risk: $proof_risk,
        command: $proof_cmd,
        target: ("state/runtime/" + $wedge + "-proof-surface-*.md"),
        delegation_needed: false,
        score: $proof_score
      },
      {
        id: $candidate3_id,
        intent: $candidate3_intent,
        selected_capability: $candidate3_capability,
        selected_skill_or_lane: $candidate3_lane,
        why_this_move: $candidate3_why,
        consumer: $candidate3_consumer,
        never_touch: $candidate3_never_touch,
        proof_expected: $candidate3_proof,
        source_paths: $delegate_sources,
        leverage: $delegate_leverage,
        risk: $delegate_risk,
        command: $candidate3_command,
        target: $candidate3_target,
        delegation_needed: $candidate3_delegation,
        score: $delegate_score
      }
    ]
  }
  | .winner = (.candidates | sort_by(.score) | last)
  | .winner_margin = ((.candidates | sort_by(.score) | reverse) as $sorted | if ($sorted | length) > 1 then (($sorted[0].score - $sorted[1].score)) else $sorted[0].score end)
  | .current_action_weak = $current_action_weak
  | .candidate_count = (.candidates | length)
  | .planner_doctrine = if $doctrine_present then {
      ref: "state/planner-doctrine.json",
      ethskills_first: $doctrine_ethskills_first,
      capability_body_first: $doctrine_capability_body_first,
      reuse_before_replace: $doctrine_reuse_before_replace,
      synthesis_before_widening: $doctrine_synthesis_before_widening,
      allow_refresh_under_human_only_if_delta_exists: $doctrine_allow_refresh_under_human_only,
      prefer_same_wedge_search_before_switch: $doctrine_prefer_same_wedge_search_before_switch
    } else null end
  | .synthesis_alignment = {
      active_wedge: (if ($synthesis_wedge | length) > 0 then $synthesis_wedge else null end),
      current_lane: (if ($synthesis_lane | length) > 0 then $synthesis_lane else null end),
      next_action_type: (if ($synthesis_next_action | length) > 0 then $synthesis_next_action else null end),
      blocker_class: (if ($synthesis_blocker_class | length) > 0 then $synthesis_blocker_class else null end),
      proof_expected: (if ($synthesis_proof_expected | length) > 0 then $synthesis_proof_expected else null end)
    }
  ' > "$tmp_json"

mv "$tmp_json" "$OUT"

if [[ "$APPLY" == "true" ]]; then
  winner_id="$(jq -r '.winner.id' "$OUT")"
  winner_command="$(jq -r '.winner.command' "$OUT")"
  winner_target="$(jq -r '.winner.target' "$OUT")"
  winner_proof="$(jq -r '.winner.proof_expected' "$OUT")"
  winner_why="$(jq -r '.winner.why_this_move' "$OUT")"
  winner_consumer="$(jq -r '.winner.consumer' "$OUT")"
  winner_never_touch="$(jq -r '.winner.never_touch' "$OUT")"
  winner_delegation="$(jq -r '.winner.delegation_needed' "$OUT")"
  tmp_state="$(mktemp)"
  jq \
    --arg wid "$winner_id" \
    --arg cmd "$winner_command" \
    --arg target "$winner_target" \
    --arg proof "$winner_proof" \
    --arg why "$winner_why" \
    --arg consumer "$winner_consumer" \
    --arg never_touch "$winner_never_touch" \
    --arg repeated "$repeat_reason" \
    --argjson delegation "$winner_delegation" \
    '
    .next_action.type = $wid
    | .next_action.description = $why
    | .next_action.command = $cmd
    | .next_action.target = $target
    | .next_action.proof_expected = $proof
    | .next_action.fallback_chain = (.next_action.fallback_chain // [])
    | .consumer = $consumer
    | .never_touch = $never_touch
    | .updated_at = (now|todate)
    | .lastUpdated = (now|todate)
    | .best_next_move_ref = "state/best-next-move.json"
    | if $delegation then .subagents.required_roles = ["verifier"] else . end
    | if $wid == "direction_review" then .direction_review.required = true else . end
    | if $repeated != "none" then .blockers = ((.blockers // []) + ["pattern-fallthrough:" + $repeated] | unique) else . end
    ' "$STATE" > "$tmp_state"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp_state" "$STATE" >/dev/null
  rm -f "$tmp_state"
fi

echo "BEST_NEXT_MOVE_OK $OUT"
