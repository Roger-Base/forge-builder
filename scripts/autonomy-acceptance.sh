#!/usr/bin/env bash
set -euo pipefail
RWS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
WWS="$HOME/.openclaw/workspace-qwen-support"
SPINE="$HOME/.openclaw/shared-spine"
critical=0
ok(){ echo "OK: $*"; }
fail(){ echo "FAIL: $*"; critical=$((critical+1)); }

bash "$RWS/scripts/state-guard.sh" --validate "$RWS/state/session-state.json" >/dev/null 2>&1 && ok "Roger state valid" || fail "Roger state invalid"
bash "$WWS/scripts/state-guard.sh" --validate "$WWS/state/session-state.json" >/dev/null 2>&1 && ok "Walter state valid" || fail "Walter state invalid"
bash "$RWS/scripts/stage-transition-guard.sh" >/dev/null 2>&1 && ok "Roger stage valid" || fail "Roger stage invalid"
bash "$RWS/scripts/kernel-audit.sh" >/dev/null 2>&1 && ok "Roger kernel audit passes" || fail "Roger kernel audit fails"
bash "$WWS/scripts/kernel-audit.sh" >/dev/null 2>&1 && ok "Walter kernel audit passes" || fail "Walter kernel audit fails"
[[ -f "$SPINE/MISSION_SPINE.md" ]] && ok "Shared mission spine present" || fail "Shared mission spine missing"
[[ -f "$SPINE/PORTFOLIO_LEDGER.json" ]] && ok "Shared portfolio ledger present" || fail "Shared portfolio ledger missing"
[[ -f "$RWS/state/walter-handoff.json" ]] && ok "Walter handoff file present" || fail "Walter handoff missing"
[[ -f "$RWS/state/subagent-ledger.json" ]] && ok "Roger subagent ledger present" || fail "Roger subagent ledger missing"
[[ -f "$WWS/state/subagent-ledger.json" ]] && ok "Walter subagent ledger present" || fail "Walter subagent ledger missing"
echo "critical=$critical"
[[ "$critical" -eq 0 ]]
