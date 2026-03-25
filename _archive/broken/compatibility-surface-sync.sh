#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
ROOT_STATE="$WORKSPACE/session-state.json"
ACTIVE_WEDGE="$WORKSPACE/active-wedge.json"
MISSION_JSON="$WORKSPACE/mission.json"
MISSION_MD="$WORKSPACE/MISSION.md"

if [[ ! -f "$STATE" ]]; then
  echo "compatibility-surface-sync: missing canonical state at $STATE" >&2
  exit 1
fi

if [[ ! -L "$ROOT_STATE" ]] || [[ "$(readlink "$ROOT_STATE" 2>/dev/null || true)" != "state/session-state.json" ]]; then
  if [[ -e "$ROOT_STATE" ]] && [[ ! -L "$ROOT_STATE" ]]; then
    mv "$ROOT_STATE" "$ROOT_STATE.pre-canonical.$(date -u +%Y%m%dT%H%M%SZ).bak"
  else
    rm -f "$ROOT_STATE"
  fi
  ln -s "state/session-state.json" "$ROOT_STATE"
fi

jq '{
  compatibility_shim: true,
  authoritative_source: "state/session-state.json",
  updated_at: .updated_at,
  active_wedge: {
    id: .active_wedge.id,
    stage: .active_wedge.stage
  },
  next_action: {
    type: .next_action.type,
    command: .next_action.command
  },
  blockers: (.blockers // [])
}' "$STATE" > "$ACTIVE_WEDGE"

jq -n \
  --arg source "MISSION.md" \
  --arg mission_id "$(jq -r '.mission.id // "roger-base-v1"' "$STATE")" \
  --arg updated_at "$(jq -r '.updated_at // empty' "$STATE")" \
  --arg summary "Roger builds real Base-native agent infrastructure and services through research-first, gap-validated, proof-backed execution." \
  '{
    compatibility_shim: true,
    authoritative_source: $source,
    mission_id: $mission_id,
    updated_at: $updated_at,
    summary: $summary,
    note: "Use MISSION.md for the full mission text. Do not treat this file as a second authority."
  }' > "$MISSION_JSON"

if [[ ! -f "$MISSION_MD" ]]; then
  echo "compatibility-surface-sync: missing canonical mission at $MISSION_MD" >&2
  exit 1
fi

echo "COMPATIBILITY_SURFACE_SYNC_OK"
