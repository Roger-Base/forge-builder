#!/bin/bash
# Roger Self-Audit v2 - analyzes execution patterns and gives actionable advice

WORKSPACE="$HOME/.openclaw/workspace"

echo "=== ROGER SELF-AUDIT v2 ==="
echo

# 1. Count commit types
echo "## Today's Activity"
commits=$(git -C "$WORKSPACE" log --since="midnight" --oneline 2>/dev/null)
add_count=$(echo "$commits" | grep -c "add\|improve\|build\|ship" || echo 0)
maintain_count=$(echo "$commits" | grep -c "maintain\|heartbeat\|state\|chore\|fix" || echo 0)
echo "Build commits: $add_count"
echo "Maintain commits: $maintain_count"
echo

# 2. Revenue check
echo "## Revenue Check"
jobs=$(acp_cli job active --json 2>/dev/null | jq '.jobs | length' 2>/dev/null || echo "?")
echo "ACP Jobs: $jobs"
echo

# 3. Current mode/state
echo "## Current State"
jq -r '.mode, .active_wedge.id, .active_wedge.stage' "$WORKSPACE/state/session-state.json" 2>/dev/null
echo

# 4. Actionable advice
echo "## Advisor"
if [ "$jobs" = "0" ]; then
    echo "⚠️ Revenue: 0 jobs - need to ship something sellable"
fi

if [ "$maintain_count" -gt "$add_count" ]; then
    echo "⚠️ Balance: Too much maintenance, not enough building"
fi

# What's next?
echo
echo "## Next Step"
case "$jobs" in
    0) echo "Action: Start scanner as ACP service or create new offering" ;;
    *) echo "Action: Continue current work" ;;
esac
