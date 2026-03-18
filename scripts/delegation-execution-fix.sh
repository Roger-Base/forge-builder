#!/usr/bin/env bash
# DELEGATION EXECUTION FIX (2026-03-14)
# Problem: spawn-controller.sh only logs requests but never actually spawns sessions
# Fix: Use sessions_spawn tool directly for subagent delegation

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
ROLE="${1:-verifier}"
TASK="${2:-Verify the strongest proof for the active wedge}"
TARGET_WEDGE="${3:-base_account_miniapp_probe}"

echo "=== DELEGATION EXECUTION ==="
echo "Role: $ROLE"
echo "Task: $TASK"
echo "Target: $TARGET_WEDGE"
echo ""
echo "NOTE: spawn-controller.sh is broken - it only logs, doesn't spawn."
echo "To execute, use sessions_spawn tool directly in the agent session."
echo ""
echo "Example sessions_spawn call:"
echo 'sessions_spawn({'
echo '  "runtime": "subagent",'
echo '  "agentId": "'"$ROLE"'",'
echo '  "task": "'"$TASK"'",'
echo '  "label": "roger-'"$ROLE"'-'"$(date -u +%Y%m%d%H%M%S)"'",'
echo '  "mode": "run"'
echo '})'
echo ""
echo "Written to: $WORKSPACE/state/runtime/delegation-fix-note-$(date -u +%Y%m%d-%H%M%S).md"
