#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
REPORT="${1:-$WORKSPACE/state/runtime/session-start-$(date -u +%Y%m%d-%H%M%S).md}"
mkdir -p "$(dirname "$REPORT")"
critical=0
warn=0
run() {
  local level="$1" name="$2"; shift 2
  local tmp
  tmp="$(mktemp)"
  if "$@" >"$tmp" 2>&1; then
    echo "- $name: ok" >> "$REPORT"
    sed -n '1,8p' "$tmp" | sed 's/^/  /' >> "$REPORT"
  else
    echo "- $name: failed" >> "$REPORT"
    sed -n '1,12p' "$tmp" | sed 's/^/  /' >> "$REPORT"
    if [[ "$level" == "critical" ]]; then critical=$((critical+1)); else warn=$((warn+1)); fi
  fi
  rm -f "$tmp"
}
cat > "$REPORT" <<EOF2
# Roger Session Start

- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- workspace: $WORKSPACE

## Checks
EOF2
run critical runtime_enforcer bash "$WORKSPACE/scripts/runtime-enforcer.sh"
run critical state_guard bash "$WORKSPACE/scripts/state-guard.sh" --validate "$WORKSPACE/state/session-state.json"
run critical stage_transition_guard bash "$WORKSPACE/scripts/stage-transition-guard.sh"
run warn handoff_sync bash "$WORKSPACE/scripts/roger-handoff-ack.sh" --sync
run warn kernel_audit bash "$WORKSPACE/scripts/kernel-audit.sh"
echo >> "$REPORT"
echo '## Summary' >> "$REPORT"
echo "- critical: $critical" >> "$REPORT"
echo "- warnings: $warn" >> "$REPORT"
echo "- next_action: $(jq -r '.next_action.command' "$WORKSPACE/state/session-state.json")" >> "$REPORT"
if [[ "$critical" -gt 0 ]]; then
  echo "SESSION_START_FAIL $REPORT"
  exit 1
fi
echo "SESSION_START_OK $REPORT"
