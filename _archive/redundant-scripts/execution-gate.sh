#!/bin/bash
# Execution Gate - Binding Self-Evaluation before any execution
# This MUST run before next_action.command

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
GATE_LOG="$WORKSPACE/state/runtime/execution-gate-$(date -u +%Y%m%d).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date -u +%H:%M:%S)] $1" | tee -a "$GATE_LOG"
}

# Get current action info
next_cmd="$(jq -r '.next_action.command // empty' "$STATE" 2>/dev/null || echo "")"
task_type="$(jq -r '.next_action.type // "unknown"' "$STATE" 2>/dev/null || echo "unknown")"
active_wedge="$(jq -r '.active_wedge.id // "none"' "$STATE" 2>/dev/null || echo "none")"

if [ -z "$next_cmd" ] || [ "$next_cmd" = "null" ]; then
    log "⚠️ No next_action.command found in session-state.json"
    echo "HEARTBEAT_OK"
    exit 0
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔒 EXECUTION GATE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Wedge: $active_wedge"
log "Task Type: $task_type"
log "Command: $next_cmd"

# STAGE 1: Check if we need to refuel the task queue
QUEUE_FILE="$WORKSPACE/state/task-queue.json"
last_queue_gen=$(jq -r '.generated_at // "1970-01-01T00:00:00Z"' "$QUEUE_FILE" 2>/dev/null || echo "1970-01-01T00:00:00Z")
queue_age_seconds=$(($(date -u +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_queue_gen" +%s 2>/dev/null || echo 0)))

if [ -z "$last_queue_gen" ] || [ "$last_queue_gen" = "null" ] || [ "$queue_age_seconds" -gt 3600 ]; then
    log "📋 Task queue stale (age: ${queue_age_seconds}s) - refueling..."
    bash "$WORKSPACE/scripts/task-queue-refuel.sh" > /dev/null
    log "   Queue refueled with fresh tasks"
    
    # Update next_action from queue recommendation
    recommended=$(jq -r '.recommended_next // empty' "$QUEUE_FILE" 2>/dev/null || echo "")
    if [ -n "$recommended" ]; then
        log "   Recommended: $recommended"
    fi
else
    log "📋 Task queue fresh (age: ${queue_age_seconds}s)"
fi

# Check for NOOP/maintenance tasks - these skip PRE evaluation
if [[ "$next_cmd" == *"MAINTAIN"* ]] || [[ "$next_cmd" == *"NOOP"* ]] || [[ "$task_type" == "maintenance" ]]; then
    log "⚠️ Maintenance/NOOP task detected - skipping PRE evaluation"
    echo "EXECUTE: $next_cmd"
    exit 0
fi

# Check for repeated commands (repetition detection)
repeat_count="$(jq -r --arg cmd "$next_cmd" '[.skill_usage_log[]?][-10:] | map(select(. == $cmd)) | length' "$STATE" 2>/dev/null || echo 0)"
if [ "$repeat_count" -ge 3 ]; then
    log "⚠️ WARNING: Same command executed $repeat_count times recently"
    log "   Command: $next_cmd"
fi

# PRE SELF-EVALUATION - Must pass before execution
# Use AUTO-EVALUATE for scoring (no manual input needed)
echo ""
log "📋 Running PRE Auto-Evaluation..."

PRE_OUTPUT=$(cd "$WORKSPACE" && bash scripts/auto-evaluate.sh \
    "Execute: $next_cmd" \
    "Planned action on wedge $active_wedge, type $task_type" 2>&1 || true)

echo "$PRE_OUTPUT" | tee -a "$GATE_LOG"

# Parse score from output - macOS compatible
SCORE=$(echo "$PRE_OUTPUT" | grep "TOTAL:" | grep -oE '[0-9]+' | tail -1 || echo "0")

log ""
if [ -z "$SCORE" ] || [ "$SCORE" = "null" ]; then
    SCORE=0
fi

log "📊 PRE Score: $SCORE/30"

# DECISION
echo ""
if [ "$SCORE" -lt 15 ]; then
    log "${RED}🚫 STOPPED: Score $SCORE < 15${NC}"
    log "   Reason: Task fails fundamental criteria"
    echo "BLOCKED: Score $SCORE - insufficient quality"
    echo ""
    echo "Run 'self-evaluate.sh' manually to see what needs fixing."
    exit 1
elif [ "$SCORE" -lt 20 ]; then
    log "${YELLOW}⚠️ WARNING: Score $SCORE < 20${NC}"
    log "   Reason: Significant gaps - proceed with caution"
    log "   Action: Will execute but flag for review"
    echo "EXECUTE_WITH_CAUTION: Score $SCORE"
else
    log "${GREEN}✅ PASSED: Score $SCORE >= 20${NC}"
    log "   Task is approved for execution"
    echo "EXECUTE: $next_cmd"
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
