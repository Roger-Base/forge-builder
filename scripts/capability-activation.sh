#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
OUT="$WORKSPACE/state/capability-activation.json"
CTX="$WORKSPACE/state/context-observability.json"
SKLOG="$WORKSPACE/state/skill-usage-log.json"
SRCLOG="$WORKSPACE/state/source-usage-log.json"
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
  while IFS= read -r line; do SOURCES+=("$line"); done < <(jq -r '.winner.source_paths // ["AGENTS.md","TOOLS.md","SKILLS.md","OPERATIONS.md","state/session-state.json","state/best-next-move.json"] | .[]' "$WORKSPACE/state/best-next-move.json")
fi
[[ -n "$INTENT" ]] || { echo "Missing --intent" >&2; exit 1; }
[[ -n "$CAPABILITY" ]] || { echo "Missing capability" >&2; exit 1; }
[[ -n "$LANE" ]] || { echo "Missing lane" >&2; exit 1; }
[[ -n "$CONSUMER" ]] || { echo "Missing consumer" >&2; exit 1; }
[[ -n "$NEVER_TOUCH" ]] || { echo "Missing never-touch" >&2; exit 1; }
[[ -n "$PROOF_EXPECTED" ]] || { echo "Missing proof_expected" >&2; exit 1; }
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sources_json="$(printf '%s\n' "${SOURCES[@]}" | jq -R . | jq -s .)"
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
  --argjson sources "$sources_json" \
  --arg best_ref "state/best-next-move.json" \
  --arg winner_id "$(jq -r '.winner.id // ""' "$WORKSPACE/state/best-next-move.json" 2>/dev/null || echo "")" \
  '{version:"1.0",updated_at:$ts,intent:$intent,selected_capability:$capability,selected_skill_or_lane:$lane,why_this_skill:$why,consumer:$consumer,never_touch:$never_touch,proof_expected:$proof,leverage:$leverage,risk:$risk,winner_margin:$winner_margin,delegation_needed:$delegation_needed,source_paths:$sources,best_next_move_ref:$best_ref,winner_id:$winner_id,status:"active"}' > "$OUT"
session_id="$(date -u +%Y%m%dT%H%M%SZ)-roger-capability"
jq -n \
  --arg session_id "$session_id" \
  --arg ts "$ts" \
  --argjson files "$sources_json" \
  --arg lane "$LANE" \
  '{session_id:$session_id,files_read:$files,skills_opened:[$lane],runtime_sources_used:["state/session-state.json","state/capability-activation.json"],external_sources_used:[],generated_at:$ts}' > "$CTX"
jq --arg ts "$ts" --arg lane "$LANE" --arg intent "$INTENT" '.entries += [{ts:$ts,agent:"Roger",intent:$intent,selected_skill_or_lane:$lane,source:"canon",result:"used"}]' "$SKLOG" > "$SKLOG.tmp" && mv "$SKLOG.tmp" "$SKLOG"
jq --arg ts "$ts" --arg intent "$INTENT" --argjson sources "$sources_json" '.entries += [{ts:$ts,agent:"Roger",intent:$intent,sources:$sources}]' "$SRCLOG" > "$SRCLOG.tmp" && mv "$SRCLOG.tmp" "$SRCLOG"
echo "CAPABILITY_ACTIVATION_OK $OUT"
