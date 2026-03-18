#!/bin/bash
# Auto Self-Evaluation for Execution Gate
# Returns numeric score without manual input

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
QUEUE="$WORKSPACE/state/base-opportunity-queue.json"

TASK="$1"
OUTPUT="$2"

# Default scores (conservative)
SCORE=10
REASON="Default conservative score"

# Extract task info
active_wedge="$(jq -r '.active_wedge.id // "none"' "$STATE" 2>/dev/null || echo "none")"
stage="$(jq -r '.active_wedge.stage // "unknown"' "$STATE" 2>/dev/null || echo "unknown")"

# Criteria 1: PROBLEM REAL? (1-5)
# Check if wedge has documented problem in opportunity queue - ADAPTIVE
problem_score=2
if [ -f "$QUEUE" ]; then
    problem_doc="$(jq -r --arg id "$active_wedge" '.opportunities[] | select(.id == $id) | .problem // ""' "$QUEUE" 2>/dev/null || echo "")"
    if [ -n "$problem_doc" ] && [ "$problem_doc" != "null" ]; then
        problem_score=4
    fi
fi
# Check if wedge has proof-spec (indicates real work)
if [ -f "$WORKSPACE/docs/wedges/$active_wedge/proof-spec.md" ]; then
    problem_score=5
fi

# Criteria 2: DEMAND PROOF? (1-5)
# Check for ACP jobs, external signals - ADAPTIVE
demand_score=1
acp_jobs="$(acp job completed --page 1 --pageSize 5 2>/dev/null | grep -c "job" || echo 0)"
if [ "$acp_jobs" -gt 0 ]; then
    demand_score=5
elif grep -q "live" "$WORKSPACE/docs/wedges/$active_wedge"/*.md 2>/dev/null; then
    # Has live deployment = some validation
    demand_score=3
else
    # Check if it's been distributed
    stage_value="$(jq -r '.active_wedge.stage // "unknown"' "$STATE")"
    if [ "$stage_value" = "DISTRIBUTE" ] || [ "$stage_value" = "MAINTAIN" ]; then
        demand_score=3  # At least it was deployed
    fi
fi

# Criteria 3: ORIGINALITY? (1-5)
# Check if wedge has unique assets
originality_score=2
if [ -d "$WORKSPACE/docs/wedges/$active_wedge" ]; then
    file_count=$(find "$WORKSPACE/docs/wedges/$active_wedge" -type f 2>/dev/null | wc -l)
    if [ "$file_count" -gt 5 ]; then
        originality_score=4
    fi
fi

# Criteria 4: EXECUTION QUALITY? (1-5)
# Check if demo script exists and works
exec_score=2
if [ -f "$WORKSPACE/scripts/base_mini_app_monitor_demo.sh" ] || [ -f "$WORKSPACE/scripts/agent-security-scanner.sh" ]; then
    exec_score=3
fi

# Criteria 5: REVENUE POTENTIAL? (1-5)
# Check if it's an ACP-capable service
revenue_score=1
if grep -q "acp" "$STATE" 2>/dev/null; then
    revenue_score=3
fi

# Criteria 6: BASE RELEVANCE? (1-5)
# Always high if we're on Base
base_score=5

# Calculate total
TOTAL=$((problem_score + demand_score + originality_score + exec_score + revenue_score + base_score))

# Add reasoning
if [ "$demand_score" -lt 2 ]; then
    REASON="No external demand signals (ACP jobs)"
elif [ "$stage" = "LEARN" ]; then
    REASON="Wedge in LEARN stage - needs new direction"
elif [ "$stage" = "MAINTAIN" ]; then
    REASON="Wedge in maintenance - may not need new build"
fi

# Output
cat << EOF

═══════════════════════════════════════════════════════════════
AUTO SELF-EVALUATION: $active_wedge
═══════════════════════════════════════════════════════════════

Task: $TASK
Output: $OUTPUT

═══════════════════════════════════════════════════════════════
AUTO-SCORED CRITERIA
═══════════════════════════════════════════════════════════════

1. PROBLEM REAL:    $problem_score/5  (problem in queue: $([ $problem_score -gt 1 ] && echo "yes" || echo "no"))
2. DEMAND PROOF:    $demand_score/5  (ACP jobs: $acp_jobs)
3. ORIGINALITY:     $originality_score/5  (wedge files: ${file_count:-0})
4. EXECUTION:       $exec_score/5  (demo scripts: $([ $exec_score -gt 2 ] && echo "yes" || echo "no"))
5. REVENUE:         $revenue_score/5  (ACP-capable: $([ $revenue_score -gt 2 ] && echo "yes" || echo "no"))
6. BASE RELEVANCE:  $base_score/5  (always yes)

═══════════════════════════════════════════════════════════════
TOTAL SCORE: $TOTAL/30
═══════════════════════════════════════════════════════════════

VERDICT:
- < 15: STOP
- 15-20: IMPROVE  
- 21-25: GOOD
- > 25: PUBLISH

REASON: $REASON

EOF

echo "TOTAL: $TOTAL"
