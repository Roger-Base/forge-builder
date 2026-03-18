#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
ACT="$WORKSPACE/state/capability-activation.json"
SKLOG="$WORKSPACE/state/skill-usage-log.json"
OUT="$WORKSPACE/state/best-next-move.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
MODE="refresh"
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --refresh) MODE="refresh"; shift ;;
    --apply) APPLY=true; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

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
reserve_id="$(jq -r '.roger.reserve_wedge // "base_account_miniapp_probe"' "$SPINE")"
current_lane="$(jq -r '.selected_skill_or_lane // empty' "$ACT" 2>/dev/null || true)"

now_epoch="$(date -u +%s)"
artifact_age=0
if [[ -n "$last_artifact_change_at" ]]; then
  art_epoch="$(jq -nr --arg ts "$last_artifact_change_at" '$ts | fromdateiso8601' 2>/dev/null || true)"
  [[ -n "$art_epoch" ]] && artifact_age=$(( now_epoch - art_epoch ))
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

timestamp_expr='$(date -u +%Y%m%d-%H%M%S)'

# Determine correct artifact command based on active_wedge
case "$active_wedge" in
  "base_account_miniapp_probe")
    # Check if in LEARN stage - don't auto-execute
    if [[ "$stage" == "LEARN" ]]; then
      artifact_cmd="date +%s"
      artifact_target="none"
      artifact_proof="learn phase checkpoint"
      artifact_lane="none"
    else
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      artifact_target="docs/wedges/base_account_miniapp_probe/demo-output.md"
      artifact_proof="fresh demo output for the miniapp probe wedge"
      artifact_lane="base_mini_app_monitor_demo.sh"
    fi
    ;;
  "agent_security_scanner")
    artifact_cmd="cd ~/.openclaw/workspace && bash scripts/agent-security-scanner.sh --target skills/security-audit-toolkit/SKILL.md --output state/runtime/security-audit-toolkit-scan-${timestamp_expr}.md"
    artifact_target="state/runtime/security-audit-toolkit-scan-*.md"
    artifact_proof="fresh security audit on security-audit-toolkit"
    artifact_lane="skills/agent-evaluation/SKILL.md + scripts/agent-security-scanner.sh"
    ;;
  *)
    # Default fallback - check stage first
    if [[ "$stage" == "LEARN" ]]; then
      # In LEARN stage - no automatic artifact generation
      artifact_cmd="date +%s"
      artifact_target="none"
      artifact_proof="learn phase checkpoint"
      artifact_lane="none"
    else
      artifact_cmd="cd ~/.openclaw/workspace && bash scripts/base_mini_app_monitor_demo.sh"
      artifact_target="docs/wedges/${active_wedge}/*.md"
      artifact_proof="fresh bounded artifact delta on the active wedge"
      artifact_lane="base_mini_app_monitor_demo.sh"
    fi
    ;;
esac

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

if [[ "$stage" =~ ^(BUILD|PROOF_SPEC)$ ]]; then artifact_leverage=$((artifact_leverage + 25)); fi
if [[ "$stage" =~ ^(VERIFY|DISTRIBUTE)$ ]]; then proof_leverage=$((proof_leverage + 25)); fi
if [[ "$stage" == "MAINTAIN" ]]; then
  proof_leverage=$((proof_leverage + 15))
  delegate_leverage=$((delegate_leverage + 20))
  artifact_risk=$((artifact_risk + 10))
fi
if [[ "$stage" =~ ^(LEARN|FROZEN)$ ]]; then delegate_leverage=$((delegate_leverage + 25)); fi
if [[ "$direction_required" == "true" ]]; then delegate_leverage=$((delegate_leverage + 20)); fi
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
  --arg proof_cmd "$proof_cmd" \
  --arg proof_expected_state "$proof_expected_state" \
  --arg reserve "$reserve_id" \
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
        selected_capability: "public_builder_execution",
        selected_skill_or_lane: "skills/agent-evaluation/SKILL.md + scripts/agent-security-scanner.sh",
        why_this_move: "Push the current wedge forward with a real bounded artifact delta.",
        consumer: "current wedge proof surface and GitHub artifact lane",
        never_touch: "Walter specialist work, Fundiora, and support-layer drift",
        proof_expected: $artifact_proof,
        source_paths: ["AGENTS.md","TOOLS.md","SKILLS.md","skills/agent-evaluation/SKILL.md","state/session-state.json","state/best-next-move.json"],
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
        selected_capability: "proof_distribution",
        selected_skill_or_lane: "GitHub + proof surface",
        why_this_move: "Treat GitHub, proof links, and public visibility as part of the product instead of a later cleanup step.",
        consumer: "GitHub repo, proof surface, public distribution",
        never_touch: "unverified public claims and detached X chatter",
        proof_expected: "fresh proof-surface artifact with a concrete next proof move",
        source_paths: ["AGENTS.md","TOOLS.md","SKILLS.md","state/session-state.json","state/best-next-move.json","scripts/github-proof-surface-check.sh"],
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
        source_paths: ["AGENTS.md","TOOLS.md","SKILLS.md","state/session-state.json","state/best-next-move.json"],
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
  ' > "$tmp_json"

mv "$tmp_json" "$OUT"

if [[ "$APPLY" == "true" ]]; then
  winner_id="$(jq -r '.winner.id' "$OUT")"
  winner_command="$(jq -r '.winner.command' "$OUT")"
  winner_target="$(jq -r '.winner.target' "$OUT")"
  winner_proof="$(jq -r '.winner.proof_expected' "$OUT")"
  winner_consumer="$(jq -r '.winner.consumer' "$OUT")"
  winner_never_touch="$(jq -r '.winner.never_touch' "$OUT")"
  winner_delegation="$(jq -r '.winner.delegation_needed' "$OUT")"
  tmp_state="$(mktemp)"
  jq \
    --arg wid "$winner_id" \
    --arg cmd "$winner_command" \
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
    | if $delegation then .subagents.required_roles = ["verifier"] else . end
    | if $wid == "direction_review" then .direction_review.required = true else . end
    | if $repeated != "none" then .blockers = ((.blockers // []) + ["pattern-fallthrough:" + $repeated] | unique) else . end
    ' "$STATE" > "$tmp_state"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp_state" "$STATE" >/dev/null
  rm -f "$tmp_state"
fi

echo "BEST_NEXT_MOVE_OK $OUT"
