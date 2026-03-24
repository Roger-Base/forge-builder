#!/bin/bash
set -euo pipefail

# Roger scout, grounded in canonical runtime truth.

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
BEST="$WORKSPACE/state/best-next-move.json"
QUEUE="$WORKSPACE/state/priority-queue.json"
SYNTH="$WORKSPACE/state/synthesis-registry.json"
ACT="$WORKSPACE/state/capability-activation.json"
DATE="$(date +%Y-%m-%d)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
MODE="generic"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-generic}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$WORKSPACE/signals"
OUTPUT_FILE="$WORKSPACE/signals/scout-$DATE.md"

active_wedge="$(jq -r '.active_wedge.id // "unknown"' "$STATE" 2>/dev/null || echo unknown)"
stage="$(jq -r '.active_wedge.stage // "unknown"' "$STATE" 2>/dev/null || echo unknown)"
next_type="$(jq -r '.next_action.type // "unknown"' "$STATE" 2>/dev/null || echo unknown)"
next_target="$(jq -r '.next_action.target // "none"' "$STATE" 2>/dev/null || echo none)"
winner_id="$(jq -r '.winner.id // "unknown"' "$BEST" 2>/dev/null || echo unknown)"
winner_lane="$(jq -r '.winner.selected_skill_or_lane // "unknown"' "$BEST" 2>/dev/null || echo unknown)"
winner_margin="$(jq -r '.winner_margin // "0"' "$BEST" 2>/dev/null || echo 0)"
primary_queue_id="$(jq -r '.primary[0].id // "none"' "$QUEUE" 2>/dev/null || echo none)"
primary_queue_status="$(jq -r '.primary[0].status // "none"' "$QUEUE" 2>/dev/null || echo none)"
secondary_ready_id="$(jq -r '.secondary[] | select(.status|startswith("ready")) | .id' "$QUEUE" 2>/dev/null | head -n 1 || true)"
synth_focus="$(jq -r '.active_wedge // empty' "$SYNTH" 2>/dev/null || true)"
capability="$(jq -r '.selected_capability // "unknown"' "$ACT" 2>/dev/null || echo unknown)"

blocker_lines="$(jq -r '
  (.blockers // []) as $b
  | if ($b | length) == 0 then empty
    else $b[] | if type=="string" then . else (.id // .type // "blocker") + (if .classification then " (" + .classification + ")" else "" end) end
    end
' "$STATE" 2>/dev/null || true)"

external_news="$(mktemp)"
if command -v web_search >/dev/null 2>&1; then
  web_search --query "Base blockchain news 2026" --freshness "week" --count 3 >"$external_news" 2>/dev/null || true
fi

recent_local="$(find "$WORKSPACE" \
  \( -path "$WORKSPACE/docs/wedges/$active_wedge/*" -o -path "$WORKSPACE/services/*" -o -path "$WORKSPACE/code/base-mcp-server/*" -o -path "$WORKSPACE/code/erc8004-base/*" \) \
  -type f -newermt "$DATE 00:00:00" ! -path '*/.git/*' -print 2>/dev/null | sed "s|$WORKSPACE/||" | sort | tail -n 8)"

{
  echo "# Scout Report — $DATE"
  echo
  echo "- mode: $MODE"
  echo "- generated_at: $TS"
  echo "- active_wedge: $active_wedge"
  echo "- stage: $stage"
  echo "- best_next_move: $winner_id"
  echo "- selected_lane: $winner_lane"
  echo "- capability: $capability"
  echo "- queue_primary: $primary_queue_id ($primary_queue_status)"
  echo "- synthesis_focus: ${synth_focus:-none}"
  echo
  echo "## External Signals"
  if [[ -s "$external_news" ]]; then
    sed -n '1,20p' "$external_news"
  else
    echo "- No fresh verified Base news found via scout runtime."
  fi
  echo
  echo "## Canonical Runtime Truth"
  echo "- next_action: $next_type"
  echo "- next_target: $next_target"
  echo "- winner_margin: $winner_margin"
  if [[ -n "$blocker_lines" ]]; then
    echo "- blockers:"
    while IFS= read -r line; do
      [[ -n "$line" ]] && echo "  - $line"
    done <<< "$blocker_lines"
  else
    echo "- blockers: none"
  fi
  echo
  echo "## Local Work Detected Today"
  if [[ -n "$recent_local" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && echo "- $line"
    done <<< "$recent_local"
  else
    echo "- No fresh local wedge/code surfaces detected today."
  fi
  echo
  echo "## Recommendations"
  echo "- Stay aligned to the canonical winner: \`$winner_id\` on \`$winner_lane\` for \`$active_wedge\`."
  if [[ "$primary_queue_status" == ready* ]]; then
    echo "- Respect queue primary \`$primary_queue_id\` before widening scope."
  fi
  if [[ -n "$secondary_ready_id" ]] && [[ "$secondary_ready_id" != "$primary_queue_id" ]]; then
    echo "- Secondary ready lane exists: \`$secondary_ready_id\`, but only touch it if the primary becomes truly non-executable."
  fi
  echo "- Do not re-open stale narratives like \`base_rpc_health\` unless they reappear in queue, synthesis, or active wedge truth."
} > "$OUTPUT_FILE"

rm -f "$external_news"
echo "Scout report written to $OUTPUT_FILE"
cat "$OUTPUT_FILE"
