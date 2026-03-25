#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
OUT="$WORKSPACE/state/capability-activation.json"
CTX="$WORKSPACE/state/context-observability.json"
SKLOG="$WORKSPACE/state/skill-usage-log.json"
SRCLOG="$WORKSPACE/state/source-usage-log.json"
BODY="$WORKSPACE/state/capability-body.json"
DOCTRINE="$WORKSPACE/state/planner-doctrine.json"
QUEUE="$WORKSPACE/state/priority-queue.json"
SPINE="$HOME/.openclaw/shared-spine"
ACTION="ensure"
INTENT=""
CAPABILITY=""
LANE=""
WHY=""
CONSUMER=""
NEVER_TOUCH=""
PROOF_EXPECTED=""
LEVERAGE=""
RISK=""
WINNER_MARGIN=""
DELEGATION_NEEDED=""
DECISION_BASIS=""
CAPABILITY_BODY_REF=""
DOMAIN_SPINE=""
LANE_ID=""
ACTOR_IDENTITY=""
CANONICAL_LANE_SURFACE=""
RESOLUTION_STRATEGY=""
ACTIVE_WEDGE=""
QUEUE_PRIMARY_ID=""
SOURCES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ensure) ACTION="ensure"; shift ;;
    --activate) ACTION="activate"; shift ;;
    --intent) INTENT="${2:-}"; shift 2 ;;
    --capability) CAPABILITY="${2:-}"; shift 2 ;;
    --lane) LANE="${2:-}"; shift 2 ;;
    --why) WHY="${2:-}"; shift 2 ;;
    --consumer) CONSUMER="${2:-}"; shift 2 ;;
    --never-touch) NEVER_TOUCH="${2:-}"; shift 2 ;;
    --proof-expected) PROOF_EXPECTED="${2:-}"; shift 2 ;;
    --source-path) SOURCES+=("${2:-}"); shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done
mkdir -p "$(dirname "$OUT")"
[[ -f "$SKLOG" ]] || echo '{"entries":[]}' > "$SKLOG"
[[ -f "$SRCLOG" ]] || echo '{"entries":[]}' > "$SRCLOG"
if [[ ! -f "$BODY" ]]; then
  node "$WORKSPACE/scripts/roger-capability-body-sync.mjs" >/dev/null
fi
if [[ "$ACTION" == "ensure" ]]; then
  bash "$WORKSPACE/scripts/best-next-move.sh" --refresh >/dev/null
  INTENT="$(jq -r '.winner.intent' "$WORKSPACE/state/best-next-move.json")"
  CAPABILITY="$(jq -r '.winner.selected_capability' "$WORKSPACE/state/best-next-move.json")"
  LANE="$(jq -r '.winner.selected_skill_or_lane' "$WORKSPACE/state/best-next-move.json")"
  WHY="$(jq -r '.winner.why_this_move' "$WORKSPACE/state/best-next-move.json")"
  CONSUMER="$(jq -r '.winner.consumer' "$WORKSPACE/state/best-next-move.json")"
  NEVER_TOUCH="$(jq -r '.winner.never_touch' "$WORKSPACE/state/best-next-move.json")"
  PROOF_EXPECTED="$(jq -r '.winner.proof_expected' "$WORKSPACE/state/best-next-move.json")"
  LEVERAGE="$(jq -r '.winner.leverage // ""' "$WORKSPACE/state/best-next-move.json")"
  RISK="$(jq -r '.winner.risk // ""' "$WORKSPACE/state/best-next-move.json")"
  WINNER_MARGIN="$(jq -r '.winner_margin // ""' "$WORKSPACE/state/best-next-move.json")"
  DELEGATION_NEEDED="$(jq -r '.winner.delegation_needed // false' "$WORKSPACE/state/best-next-move.json")"
  while IFS= read -r line; do SOURCES+=("$line"); done < <(jq -r '.winner.source_paths // ["SOUL.md","IDENTITY.md","USER.md","MISSION.md","AGENTS.md","TOOLS.md","SKILLS.md","MEMORY_ACTIVE.md","MEMORY.md","state/session-state.json","state/context-observability.json","state/artifact-registry.json","state/decision-registry.json","state/priority-queue.json","state/best-next-move.json","config/mcporter.json","skills/ethskills/SKILL.md"] | .[]' "$WORKSPACE/state/best-next-move.json")
fi
[[ -n "$INTENT" ]] || { echo "Missing --intent" >&2; exit 1; }
[[ -n "$CAPABILITY" ]] || { echo "Missing capability" >&2; exit 1; }
[[ -n "$LANE" ]] || { echo "Missing lane" >&2; exit 1; }
[[ -n "$CONSUMER" ]] || { echo "Missing consumer" >&2; exit 1; }
[[ -n "$NEVER_TOUCH" ]] || { echo "Missing never-touch" >&2; exit 1; }
[[ -n "$PROOF_EXPECTED" ]] || { echo "Missing proof_expected" >&2; exit 1; }
if [[ -f "$BODY" ]]; then
  ACTIVE_WEDGE="$(jq -r '.active_wedge.id // empty' "$STATE" 2>/dev/null || true)"
  QUEUE_PRIMARY_ID="$(jq -r '.primary[0].id // empty' "$QUEUE" 2>/dev/null || true)"
  CAPABILITY_BODY_REF="state/capability-body.json"
  DOMAIN_SPINE="$(jq -r '.domain_spine.path // "skills/ethskills/SKILL.md"' "$BODY" 2>/dev/null || echo "skills/ethskills/SKILL.md")"
  lane_match="$(jq -c --arg lane "$LANE" --arg cap "$CAPABILITY" '
    (.lane_registry // [])
    | map(. as $item | select(($item.capability == $cap) or ($item.id == $lane) or ($lane | contains($item.path // "")) or ($lane | contains($item.id // ""))))
    | .[0] // empty
  ' "$BODY" 2>/dev/null || true)"
  if [[ -n "$lane_match" && "$lane_match" != "null" ]]; then
    RESOLUTION_STRATEGY="explicit-lane-or-capability-match"
  fi
  if [[ -z "$lane_match" || "$lane_match" == "null" ]] && [[ -n "$ACTIVE_WEDGE" ]]; then
    lane_match="$(jq -c --arg wedge "$ACTIVE_WEDGE" --arg intent "$INTENT" '
      (.wedge_bindings // [])
      | map(select(.wedge_id == $wedge))
      | .[0] as $binding
      | if $binding == null then empty
        else ($binding.intent_defaults[$intent] // $binding.intent_defaults.default // empty) as $lane_id
        | if $lane_id == "" then empty
          else (.lane_registry // []) | map(select(.id == $lane_id)) | .[0] // empty
          end
        end
    ' "$BODY" 2>/dev/null || true)"
    if [[ -n "$lane_match" && "$lane_match" != "null" ]]; then
      RESOLUTION_STRATEGY="wedge-binding:${ACTIVE_WEDGE}:${INTENT}"
    fi
  fi
  if [[ -z "$lane_match" || "$lane_match" == "null" ]]; then
    lane_match="$(jq -c --arg cap "$CAPABILITY" '
      (.lane_registry // [])
      | map(select(.capability == $cap))
      | .[0] // empty
    ' "$BODY" 2>/dev/null || true)"
    if [[ -n "$lane_match" && "$lane_match" != "null" ]]; then
      RESOLUTION_STRATEGY="capability-fallback:${CAPABILITY}"
    fi
  fi
  if [[ -z "$lane_match" || "$lane_match" == "null" ]]; then
    lane_match="$(jq -c --arg intent "$INTENT" '
      (.intent_defaults[$intent] // .intent_defaults.default // empty) as $lane_id
      | if $lane_id == "" then empty
        else (.lane_registry // []) | map(select(.id == $lane_id)) | .[0] // empty
        end
    ' "$BODY" 2>/dev/null || true)"
    if [[ -n "$lane_match" && "$lane_match" != "null" ]]; then
      RESOLUTION_STRATEGY="intent-default:${INTENT}"
    fi
  fi
  if [[ -n "$lane_match" && "$lane_match" != "null" ]]; then
    LANE_ID="$(jq -r '.id // empty' <<<"$lane_match")"
    ACTOR_IDENTITY="$(jq -r '.identity // empty' <<<"$lane_match")"
    CANONICAL_LANE_SURFACE="$(jq -r '.path // empty' <<<"$lane_match")"
    resolved_capability="$(jq -r '.capability // empty' <<<"$lane_match")"
    [[ -n "$resolved_capability" ]] && CAPABILITY="$resolved_capability"
    while IFS= read -r line; do
      [[ -n "$line" ]] && SOURCES+=("$line")
    done < <(jq -r '.local_surfaces[]? // empty' <<<"$lane_match")
  fi
  [[ -n "$LANE_ID" ]] && DECISION_BASIS="ethskills-first -> ${LANE_ID}"
  [[ -n "$DECISION_BASIS" ]] || DECISION_BASIS="ethskills-first -> ${CAPABILITY}"
  SOURCES+=("$CAPABILITY_BODY_REF" "$DOMAIN_SPINE")
fi
[[ -f "$DOCTRINE" ]] && SOURCES+=("state/planner-doctrine.json")
[[ -f "$QUEUE" ]] && SOURCES+=("state/priority-queue.json")
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sources_json="$(printf '%s\n' "${SOURCES[@]}" | awk 'NF && !seen[$0]++' | jq -R . | jq -s .)"
jq -n \
  --arg ts "$ts" \
  --arg intent "$INTENT" \
  --arg capability "$CAPABILITY" \
  --arg lane "$LANE" \
  --arg why "$WHY" \
  --arg consumer "$CONSUMER" \
  --arg never_touch "$NEVER_TOUCH" \
  --arg proof "$PROOF_EXPECTED" \
  --arg leverage "$LEVERAGE" \
  --arg risk "$RISK" \
  --arg winner_margin "$WINNER_MARGIN" \
  --arg delegation_needed "$DELEGATION_NEEDED" \
  --arg decision_basis "$DECISION_BASIS" \
  --arg capability_body_ref "$CAPABILITY_BODY_REF" \
  --arg domain_spine "$DOMAIN_SPINE" \
  --arg lane_id "$LANE_ID" \
  --arg actor_identity "$ACTOR_IDENTITY" \
  --arg canonical_lane_surface "$CANONICAL_LANE_SURFACE" \
  --arg resolution_strategy "$RESOLUTION_STRATEGY" \
  --arg active_wedge "$ACTIVE_WEDGE" \
  --arg queue_primary_id "$QUEUE_PRIMARY_ID" \
  --argjson sources "$sources_json" \
  --arg best_ref "state/best-next-move.json" \
  --arg winner_id "$(jq -r '.winner.id // ""' "$WORKSPACE/state/best-next-move.json" 2>/dev/null || echo "")" \
  '{version:"1.0",updated_at:$ts,intent:$intent,selected_capability:$capability,selected_skill_or_lane:$lane,why_this_skill:$why,consumer:$consumer,never_touch:$never_touch,proof_expected:$proof,leverage:$leverage,risk:$risk,winner_margin:$winner_margin,delegation_needed:$delegation_needed,decision_basis:$decision_basis,capability_body_ref:$capability_body_ref,domain_spine:$domain_spine,lane_id:(if $lane_id == "" then null else $lane_id end),actor_identity:(if $actor_identity == "" then null else $actor_identity end),canonical_lane_surface:(if $canonical_lane_surface == "" then null else $canonical_lane_surface end),resolution_strategy:(if $resolution_strategy == "" then null else $resolution_strategy end),active_wedge:(if $active_wedge == "" then null else $active_wedge end),queue_primary_id:(if $queue_primary_id == "" then null else $queue_primary_id end),source_paths:$sources,best_next_move_ref:$best_ref,winner_id:$winner_id,status:"active"}' > "$OUT"
session_id="$(date -u +%Y%m%dT%H%M%SZ)-roger-capability"
jq -n \
  --arg session_id "$session_id" \
  --arg ts "$ts" \
  --argjson files "$sources_json" \
  --arg lane "$LANE" \
  '{session_id:$session_id,files_read:$files,skills_opened:[$lane],runtime_sources_used:["SOUL.md","IDENTITY.md","USER.md","MISSION.md","state/session-state.json","state/capability-activation.json","state/capability-body.json","state/planner-doctrine.json","state/context-observability.json","state/artifact-registry.json","state/decision-registry.json","state/priority-queue.json"],external_sources_used:[],generated_at:$ts}' > "$CTX"
jq --arg ts "$ts" --arg lane "$LANE" --arg intent "$INTENT" '.entries += [{ts:$ts,agent:"Roger",intent:$intent,selected_skill_or_lane:$lane,source:"canon",result:"used"}]' "$SKLOG" > "$SKLOG.tmp" && mv "$SKLOG.tmp" "$SKLOG"
jq --arg ts "$ts" --arg intent "$INTENT" --argjson sources "$sources_json" '.entries += [{ts:$ts,agent:"Roger",intent:$intent,sources:$sources}]' "$SRCLOG" > "$SRCLOG.tmp" && mv "$SRCLOG.tmp" "$SRCLOG"
echo "CAPABILITY_ACTIVATION_OK $OUT"
