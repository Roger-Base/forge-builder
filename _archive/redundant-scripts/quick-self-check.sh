#!/bin/bash
# Quick self-check: Did I just make progress?
# Non-interactive - checks evidence, outputs simple result
# Writes trigger file for execution-layer integration
# Usage: ./quick-self-check.sh

STATE_FILE="$HOME/.openclaw/workspace/state/session-state.json"
PLAN_FILE="$HOME/.openclaw/workspace/state/daily-plan.md"
MEMORY_FILE="$HOME/.openclaw/workspace/memory/$(date +%Y-%m-%d).md"
TRIGGER_FILE="$HOME/.openclaw/workspace/state/.self-check-trigger"

echo "=== QUICK SELF-CHECK ==="

# 1. Current stage from session-state
STAGE=$(jq -r '.active_wedge.stage // .stage // "unknown"' "$STATE_FILE" 2>/dev/null)
echo "Stage: $STAGE"

# 2. Last artifact change
LAST_ARTIFACT=$(jq -r '.last_artifact_change_at // "none"' "$STATE_FILE" 2>/dev/null)
echo "Last artifact: $LAST_ARTIFACT"

# 3. Today's memory entries count
if [ -f "$MEMORY_FILE" ]; then
    TODAY_ENTRIES=$(wc -l < "$MEMORY_FILE")
else
    TODAY_ENTRIES=0
fi
echo "Today memory: $TODAY_ENTRIES lines"

# 4. Last action from session-state
LAST_ACTION=$(jq -r '.last_action // "unknown"' "$STATE_FILE" 2>/dev/null)
LAST_ACTION_AT=$(jq -r '.last_action_at // "unknown"' "$STATE_FILE" 2>/dev/null)
echo "Last action: $LAST_ACTION at $LAST_ACTION_AT"

# 5. Self-evaluation score if exists
SCORE=$(jq -r '.self_evaluation.last_score // "none"' "$STATE_FILE" 2>/dev/null)
echo "Last score: $SCORE"

# 6. Time since last action (in minutes)
if [ "$LAST_ACTION_AT" != "unknown" ] && [ "$LAST_ACTION_AT" != "null" ]; then
    LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_ACTION_AT" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    MINUTES_AGO=$(( (NOW_EPOCH - LAST_EPOCH) / 60 ))
    echo "Minutes ago: $MINUTES_AGO"
    
    # Judgment
    if [ "$MINUTES_AGO" -gt 60 ]; then
        echo "⚠️  STALLED: No action in 60+ minutes"
    fi
fi

echo ""
echo "=== VERDICT ==="

# Simple progress detection
STALLED=0

# Check: same action repeating?
if [ "$MINUTES_AGO" -gt 120 ]; then
    echo "❌ STALLED - No meaningful action in 2+ hours"
    STALLED=1
elif [ "$TODAY_ENTRIES" -lt 10 ]; then
    echo "⚠️  LOW OUTPUT - Less than 10 lines in today's memory"
else
    echo "✅ ACTIVE - Evidence of recent work"
fi

# Write trigger file for execution-layer integration
VERDICT=""
if [ "$STALLED" -eq 1 ]; then
    VERDICT="STALLED"
else
    VERDICT="ACTIVE"
fi

cat > "$TRIGGER_FILE" << EOF
{
  "verdict": "$VERDICT",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "stalled": $STALLED,
  "stage": "$STAGE",
  "today_memory_lines": $TODAY_ENTRIES,
  "minutes_since_action": ${MINUTES_AGO:-0}
}
EOF

echo "Trigger written to: $TRIGGER_FILE"

exit $STALLED
