#!/bin/bash
# Walter Self-Diagnostic Tool
# Run this to quickly assess your current state and identify improvement areas

WORKSPACE="/Users/roger/.openclaw/workspace"
STATE_DIR="$WORKSPACE/state"

echo "=== Walter Self-Diagnostic ==="
echo ""

# 1. Check recent session activity
echo "📊 RECENT ACTIVITY:"
if [ -f "$STATE_DIR/session-state.json" ]; then
    LAST_ACTIVE=$(jq -r '.last_active // "unknown"' "$STATE_DIR/session-state.json")
    echo "  Last active: $LAST_ACTIVE"
    
    # Check for stuck state
    STUCK_COUNT=$(jq '[.active_threads[] | select(.status == "stuck")] | length' "$STATE_DIR/session-state.json" 2>/dev/null)
    echo "  Stuck threads: ${STUCK_COUNT:-0}"
else
    echo "  No session state found"
fi
echo ""

# 2. Check correction plans
echo "📝 CORRECTION PLANS:"
if [ -f "$STATE_DIR/walter-correction-plans.json" ]; then
    CORRECTION_COUNT=$(jq '.correction_plans | length' "$STATE_DIR/walter-correction-plans.json")
    ACTIVE_RULES=$(jq '.active_rules | length' "$STATE_DIR/walter-correction-plans.json")
    echo "  Active corrections: $CORRECTION_COUNT"
    echo "  Active rules: $ACTIVE_RULES"
    
    # Show first 3 corrections if any
    if [ "$CORRECTION_COUNT" -gt 0 ]; then
        echo "  Recent corrections:"
        jq -r '.correction_plans[:3] | .[] | "    - \(.weakness // "unnamed"): \(.status // "unknown status")"' "$STATE_DIR/walter-correction-plans.json" 2>/dev/null
    fi
else
    echo "  No correction plans found"
fi
echo ""

# 3. Check mistake patterns
echo "❌ MISTAKE PATTERNS:"
MISTAKE_COUNT=0
if [ -f "$STATE_DIR/walter-mistake-log.jsonl" ]; then
    MISTAKE_COUNT=$(wc -l < "$STATE_DIR/walter-mistake-log.jsonl")
fi
echo "  Total mistakes logged: $MISTAKE_COUNT"

# Check critique log
if [ -f "$STATE_DIR/walter-critique-log.json" ]; then
    CRITIQUE_COUNT=$(jq '.critiques | length' "$STATE_DIR/walter-critique-log.json" 2>/dev/null)
    echo "  Total critiques: ${CRITIQUE_COUNT:-0}"
fi
echo ""

# 4. Check self-evaluation version
echo "📋 SELF-EVALUATION:"
if [ -f "$STATE_DIR/walter-self-evaluation.json" ]; then
    VERSION=$(jq -r '.version // "unknown"' "$STATE_DIR/walter-self-evaluation.json")
    LAST_UPDATED=$(jq -r '.created_at // "unknown"' "$STATE_DIR/walter-self-evaluation.json")
    echo "  Version: $VERSION"
    echo "  Last updated: $LAST_UPDATED"
    
    # Show current weakness if any
    CURRENT_WEAKNESS=$(jq -r '.weakness_identified // "none"' "$STATE_DIR/walter-self-evaluation.json")
    if [ "$CURRENT_WEAKNESS" != "none" ]; then
        echo "  Current focus: $CURRENT_WEAKNESS"
    fi
else
    echo "  No self-evaluation found"
fi
echo ""

# 5. Quick health score
echo "❤️ HEALTH SCORE:"
SCORE=100

# Deduct for stuck threads
if [ "${STUCK_COUNT:-0}" -gt 0 ]; then
    SCORE=$((SCORE - 20))
    echo "  -20 for stuck threads"
fi

# Deduct for no corrections when mistakes exist
if [ "$MISTAKE_COUNT" -gt 0 ] && [ "$CORRECTION_COUNT" -eq 0 ]; then
    SCORE=$((SCORE - 15))
    echo "  -15 for unaddressed mistakes"
fi

# Deduct for stale self-evaluation (older than 7 days)
if [ -f "$STATE_DIR/walter-self-evaluation.json" ]; then
    LAST_EVAL=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_UPDATED" +%s 2>/dev/null || echo "0")
    NOW=$(date +%s)
    DAYS_OLD=$(( (NOW - LAST_EVAL) / 86400 ))
    if [ "$DAYS_OLD" -gt 7 ]; then
        SCORE=$((SCORE - 10 * (DAYS_OLD / 7)))
        echo "  -$((10 * (DAYS_OLD / 7))) for stale self-evaluation (${DAYS_OLD}d old)"
    fi
fi

echo "  Score: $SCORE/100"
echo ""

# 6. Recommended actions
echo "🎯 RECOMMENDED ACTIONS:"
if [ "$SCORE" -lt 50 ]; then
    echo "  ⚠️  CRITICAL: Run full self-evaluation immediately"
elif [ "$SCORE" -lt 80 ]; then
    echo "  - Review stuck threads"
    echo "  - Update correction plans if needed"
    echo "  - Log recent mistakes"
else
    echo "  - System healthy"
    echo "  - Consider: What would make you MORE effective, not just fixed?"
fi
echo ""

echo "=== Diagnostic Complete ==="
