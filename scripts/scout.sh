#!/bin/bash
# Roger Scout — Ecosystem Research Script
# Usage: bash scripts/scout.sh --mode morning|afternoon|evening
# Writes fresh ecosystem scan to signals/scout-YYYY-MM-DD-[mode].md

set -e

MODE="morning"
for arg in "$@"; do
  case "$arg" in
    morning|afternoon|evening) MODE="$arg" ;;
  esac
done
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE=$(date -u +%Y-%m-%d)
SIGNAL_FILE="signals/scout-${DATE}-${MODE}.md"
WORKSPACE="/Users/roger/.openclaw/workspace"

cd "$WORKSPACE"

echo "🕵️ Roger Scout — $MODE scan — $TIMESTAMP"

# Read current state for context
SESSION_STATE=$(cat state/session-state.json 2>/dev/null || echo '{}')
ACTIVE_WEDGE=$(echo "$SESSION_STATE" | jq -r '.stage // "unknown"' 2>/dev/null)
MODE_CURRENT=$(echo "$SESSION_STATE" | jq -r '.mode // "unknown"' 2>/dev/null)
NEXT_ACTION=$(echo "$SESSION_STATE" | jq -r '.focus.nextAction // "none"' 2>/dev/null)

# Read latest daily memory for context
LATEST_MEMORY=$(ls -t memory/2026-*.md 2>/dev/null | head -1)
MEMORY_SNIPPET=""
if [ -n "$LATEST_MEMORY" ] && [ -f "$LATEST_MEMORY" ]; then
    MEMORY_SNIPPET=$(tail -20 "$LATEST_MEMORY" 2>/dev/null | tr '\n' ' ' | cut -c1-500)
fi

echo "📡 Scanning Base ecosystem..."
echo "   Active wedge: $ACTIVE_WEDGE"
echo "   Mode: $MODE_CURRENT"
echo "   Next action: $NEXT_ACTION"

# Build scout report
cat > "$SIGNAL_FILE" << EOF
# Scout Report — $DATE

- mode: $MODE
- generated_at: $TIMESTAMP
- active_wedge: $ACTIVE_WEDGE
- stage: $MODE_CURRENT
- next_action: $NEXT_ACTION

## Session Context

EOF

# If today's memory exists, include snippet
if [ -n "$LATEST_MEMORY" ] && [ -f "$LATEST_MEMORY" ]; then
    echo "## Today's Activity" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo "Latest memory: $LATEST_MEMORY" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    tail -30 "$LATEST_MEMORY" 2>/dev/null >> "$SIGNAL_FILE" || echo "(no recent activity)" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# GitHub activity check
echo "📦 Checking GitHub activity..."
GH_ACTIVITY=""
if gh run list --limit 5 --json status,name,updatedAt 2>/dev/null | jq -r '.[] | "\(.status) \(.name) \(.updatedAt)"' 2>/dev/null | head -5 > /tmp/gh_runs.txt; then
    GH_ACTIVITY=$(cat /tmp/gh_runs.txt)
fi

if [ -n "$GH_ACTIVITY" ]; then
    echo "## GitHub Activity" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "$GH_ACTIVITY" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# Fresh GitHub search for Base/DeFAI/agent news
echo "🔍 Web research: Base ecosystem..."
BASE_NEWS=$(web_search "Base blockchain DeFi AI agents 2026" --count 3 --freshness week 2>/dev/null | head -50 || echo "(web search unavailable)")

if [ -n "$BASE_NEWS" ] && [ "$BASE_NEWS" != "(web search unavailable)" ]; then
    echo "## External Signals (Web)" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "$BASE_NEWS" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# Agent ecosystem signals
echo "🤖 Checking agent ecosystem..."
AGENT_NEWS=$(web_search "AI agents onchain Base DeFAI 2026" --count 3 --freshness month 2>/dev/null | head -30 || echo "")

if [ -n "$AGENT_NEWS" ] && [ "$AGENT_NEWS" != "(web search unavailable)" ]; then
    echo "## Agent Ecosystem" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "$AGENT_NEWS" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# Yield / DeFAI signals
echo "💰 Checking DeFAI signals..."
YIELD_NEWS=$(web_search "DeFi AI yield farming Base Aave Morpho 2026" --count 3 --freshness month 2>/dev/null | head -30 || echo "")

if [ -n "$YIELD_NEWS" ] && [ "$YIELD_NEWS" != "(web search unavailable)" ]; then
    echo "## DeFAI / Yield Signals" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "$YIELD_NEWS" >> "$SIGNAL_FILE"
    echo '```' >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# Wedge status
echo "📋 Wedge status check..."
if [ -f "state/wedge-registry.json" ]; then
    WEDGE_STATUS=$(cat state/wedge-registry.json 2>/dev/null | jq -r '.wedges[] | "- **\(.id)**: \(.stage // "unknown")" ' 2>/dev/null | head -10)
    if [ -n "$WEDGE_STATUS" ]; then
        echo "## Active Wedges" >> "$SIGNAL_FILE"
        echo "" >> "$SIGNAL_FILE"
        echo "$WEDGE_STATUS" >> "$SIGNAL_FILE"
        echo "" >> "$SIGNAL_FILE"
    fi
fi

# Blocker summary
echo "🚧 Blocker summary..."
BLOCKERS=$(echo "$SESSION_STATE" | jq -r '.blockers // {} | to_entries[] | "- **\(.key)**: \(.value)" ' 2>/dev/null | head -10)
if [ -n "$BLOCKERS" ]; then
    echo "## Current Blockers" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
    echo "$BLOCKERS" >> "$SIGNAL_FILE"
    echo "" >> "$SIGNAL_FILE"
fi

# Recommendations
echo "## Recommendations" >> "$SIGNAL_FILE"
echo "" >> "$SIGNAL_FILE"
echo "- Active wedge: \`$ACTIVE_WEDGE\` — continue unless truly stuck" >> "$SIGNAL_FILE"
echo "- Next action: \`$NEXT_ACTION\`" >> "$SIGNAL_FILE"
echo "- Scout mode: $MODE — no stale wedge revival" >> "$SIGNAL_FILE"
echo "- If next_action is executable: execute without asking" >> "$SIGNAL_FILE"

# Close report
echo "" >> "$SIGNAL_FILE"
echo "---" >> "$SIGNAL_FILE"
echo "*Generated by Roger Scout — $TIMESTAMP*" >> "$SIGNAL_FILE"

# Count lines
LINES=$(wc -l < "$SIGNAL_FILE")
echo "✅ Scout report written: $SIGNAL_FILE ($LINES lines)"
echo ""
echo "Done."
