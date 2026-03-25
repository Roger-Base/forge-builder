#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SPINE="$HOME/.openclaw/shared-spine"
critical=0
warn=0
ok() { echo "OK: $*"; }
fail() { echo "FAIL: $*"; critical=$((critical+1)); }
warnf() { echo "WARN: $*"; warn=$((warn+1)); }

files=(
  AGENTS.md IDENTITY.md SOUL.md USER.md TOOLS.md HEARTBEAT.md OPERATIONS.md BASE_MISSION.md BOOT.md
  MEMORY.md MEMORY_ACTIVE.md NOW.md WORKSPACE_SURFACE.md docs/cli-taxonomy.md
  state/session-state.json state/system-snapshot.md state/subagent-ledger.json state/walter-handoff.json
)
for f in "${files[@]}"; do
  [[ -f "$WORKSPACE/$f" ]] && ok "$f" || fail "missing $f"
done
for f in MISSION_SPINE.md SOURCE_TIERING.md DECISION_RULES.md PORTFOLIO_LEDGER.json schemas/HANDOFF_SCHEMA.json schemas/SUBAGENT_SCHEMA.json PATTERN_RADAR/x-radar.md; do
  [[ -f "$SPINE/$f" ]] && ok "shared-spine/$f" || fail "missing shared-spine/$f"
done
bash "$WORKSPACE/scripts/state-guard.sh" --validate "$WORKSPACE/state/session-state.json" >/dev/null 2>&1 && ok "roger state valid" || fail "roger state invalid"
bash "$WORKSPACE/scripts/stage-transition-guard.sh" >/dev/null 2>&1 && ok "stage guard valid" || fail "stage guard invalid"
jq . "$WORKSPACE/state/subagent-ledger.json" >/dev/null 2>&1 && ok "subagent ledger valid json" || fail "subagent ledger invalid"
jq . "$WORKSPACE/state/walter-handoff.json" >/dev/null 2>&1 && ok "handoff valid json" || fail "handoff invalid"
openclaw config validate >/dev/null 2>&1 && ok "openclaw config valid" || warnf "openclaw config validate failed"
qmd status >/dev/null 2>&1 && ok "qmd available" || warnf "qmd unavailable"
echo "critical=$critical warn=$warn"
[[ "$critical" -eq 0 ]]
