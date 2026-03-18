#!/bin/bash
# walter-symbolic-output-detector.sh
# Walter's tool to detect symbolic output - artifacts created but not useful
# Run: ./scripts/walter-symbolic-output-detector.sh

set -e

WORKSPACE="/Users/roger/.openclaw/workspace"
STATE_DIR="$WORKSPACE/state"

echo "=== Walter Symbolic Output Detector ==="
echo "Analyzing Roger's recent work for symbolic output patterns..."
echo ""

# Check latest daily plan
LATEST_PLAN=$(ls -t "$STATE_DIR"/daily-plan.md 2>/dev/null | head -1)
if [ -z "$LATEST_PLAN" ]; then
    echo "No daily plan found"
    exit 1
fi

echo "--- Checking: $(basename $LATEST_PLAN) ---"

# Extract file/artifact mentions from daily plan (look for paths, .md, .json, etc.)
MENTIONED_FILES=$(grep -oE '([a-zA-Z0-9_/-]+\.(md|json|js|ts|html|css))' "$LATEST_PLAN" 2>/dev/null | sort -u || true)

SYMBOLIC_COUNT=0
REAL_COUNT=0
TOTAL=0

echo ""
echo "Artifact mentions in daily plan:"
echo ""

for file in $MENTIONED_FILES; do
    TOTAL=$((TOTAL + 1))
    # Try relative to workspace
    if [ -f "$WORKSPACE/$file" ]; then
        REAL_COUNT=$((REAL_COUNT + 1))
        echo "  ✓ $file (EXISTS)"
    elif [ -f "$file" ]; then
        REAL_COUNT=$((REAL_COUNT + 1))
        echo "  ✓ $file (EXISTS)"
    else
        SYMBOLIC_COUNT=$((SYMBOLIC_COUNT + 1))
        echo "  ✗ $file (MISSING)"
    fi
done

echo ""
echo "=== RESULTS ==="
echo "Total artifacts mentioned: $TOTAL"
echo "Real artifacts (exist): $REAL_COUNT"
echo "Symbolic output (missing): $SYMBOLIC_COUNT"

if [ $TOTAL -gt 0 ]; then
    SYMBOLIC_RATIO=$((SYMBOLIC_COUNT * 100 / TOTAL))
    echo "Symbolic ratio: ${SYMBOLIC_RATIO}%"
    
    if [ $SYMBOLIC_RATIO -gt 50 ]; then
        echo ""
        echo "⚠️  WARNING: High symbolic output detected (>50% missing)"
        echo "Roger may be creating theater instead of real artifacts."
    elif [ $SYMBOLIC_RATIO -gt 25 ]; then
        echo ""
        echo "⚠️  MODERATE: Some artifacts missing (25-50%)"
    else
        echo ""
        echo "✓ Good ratio - most artifacts are real"
    fi
fi

# Check session-state.json for self-evaluation scores
echo ""
echo "=== Self-Evaluation Check ==="
if [ -f "$STATE_DIR/session-state.json" ]; then
    LAST_SCORE=$(jq -r '.self_evaluation.last_score // "N/A"' "$STATE_DIR/session-state.json" 2>/dev/null || echo "N/A")
    LAST_TASK=$(jq -r '.self_evaluation.last_task // "N/A"' "$STATE_DIR/session-state.json" 2>/dev/null || echo "N/A")
    echo "Last self-evaluation score: $LAST_SCORE"
    echo "Last task: $LAST_TASK"
    
    if [ "$LAST_SCORE" != "N/A" ] && [ "$LAST_SCORE" -lt 20 ]; then
        echo ""
        echo "⚠️  LOW SCORE: Roger scored below 20 - requires root cause analysis"
    fi
fi

# Output JSON for automation
echo ""
echo "=== JSON Output ==="
cat << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "total_artifacts": $TOTAL,
  "real_artifacts": $REAL_COUNT,
  "symbolic_output": $SYMBOLIC_COUNT,
  "symbolic_ratio_pct": ${SYMBOLIC_RATIO:-0},
  "last_self_eval_score": "${LAST_SCORE:-N/A}"
}
EOF
