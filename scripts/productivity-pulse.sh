#!/bin/bash
# Roger Productivity Pulse
# Tracks task execution and identifies patterns in success/failure

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
LOG="$WORKSPACE/state/productivity-pulse.json"

# Ensure log file exists
init_log() {
    if [ ! -f "$LOG" ]; then
        echo '{"sessions": [], "patterns": [], "last_summary": null}' > "$LOG"
    fi
}

# Log a task start
log_start() {
    local task="$1"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    init_log
    
    # Add new session entry
    local temp
    temp=$(mktemp)
    
    jq --arg ts "$timestamp" \
       --arg task "$task" \
       '.sessions += [{"type": "start", "timestamp": $ts, "task": $task}]' \
       "$LOG" > "$temp" && mv "$temp" "$LOG"
    
    echo "📍 Pulse: Started tracking '$task'"
}

# Log task completion
log_done() {
    local task="$1"
    local outcome="$2"  # "success" | "partial" | "fail" | "abandon"
    local notes="${3:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    init_log
    
    local temp
    temp=$(mktemp)
    
    # Find matching start and convert to done
    jq --arg ts "$timestamp" \
       --arg task "$task" \
       --arg outcome "$outcome" \
       --arg notes "$notes" \
       '.sessions += [{"type": "done", "timestamp": $ts, "task": $task, "outcome": $outcome, "notes": $notes}]' \
       "$LOG" > "$temp" && mv "$temp" "$LOG"
    
    echo "✅ Pulse: '$task' marked as $outcome"
}

# Generate daily summary and detect patterns
summarize() {
    init_log
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "📊 PRODUCTIVITY PULSE - DAILY SUMMARY"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    local today
    today=$(date -u +"%Y-%m-%d")
    
    # Count today's activities
    local started done success partial fail
    started=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today))] | length' "$LOG")
    done=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .type == "done")] | length' "$LOG")
    success=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "success")] | length' "$LOG")
    partial=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "partial")] | length' "$LOG")
    fail=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "fail")] | length' "$LOG")
    
    echo "Today ($today):"
    echo "  Started: $started"
    echo "  Completed: $done"
    echo "    ✅ Success: $success"
    echo "    ⚠️  Partial: $partial"
    echo "    ❌ Failed: $fail"
    echo ""
    
    # Pattern detection: repeated failures
    local repeated_failures
    repeated_failures=$(jq -r '[.sessions[] | select(.outcome == "fail") | .task] | group_by(.) | map(select(length >= 2)) | .[] | .[0]' "$LOG" 2>/dev/null | grep -v "^$" || echo "")
    
    if [ -n "$repeated_failures" ]; then
        echo "⚠️  PATTERNS DETECTED (repeated failures):"
        echo "$repeated_failures" | while read -r task; do
            [ -n "$task" ] && echo "    - $task (failed 2+ times)"
        done
        echo ""
    fi
    
    # Most recent tasks
    echo "Recent activity:"
    jq -r --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today))] | reverse | .[:5] | .[] | "\(.timestamp | split("T")[1] | split("Z")[0]): \(.type) - \(.task) \(if .outcome then "[\(.outcome)]" else "" end)"' "$LOG" 2>/dev/null | while read -r line; do
        echo "    $line"
    done
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
}

# Quick status check
status() {
    init_log
    
    local today
    today=$(date -u +"%Y-%m-%d")
    
    local started done success partial fail
    started=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today))] | length' "$LOG")
    done=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .type == "done")] | length' "$LOG")
    success=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "success")] | length' "$LOG")
    partial=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "partial")] | length' "$LOG")
    fail=$(jq --arg today "$today" '[.sessions[] | select(.timestamp | startswith($today) and .outcome == "fail")] | length' "$LOG")
    
    echo "📊 Today: $done/$started done | ✅$success ⚠️$partial ❌$fail"
}

# Main dispatcher
case "${1:-status}" in
    start)
        log_start "${2:-unnamed}"
        ;;
    done)
        log_done "${2:-unnamed}" "${3:-success}" "${4:-}"
        ;;
    summarize|summary)
        summarize
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|done|status|summary} [task] [outcome] [notes]"
        echo ""
        echo "Examples:"
        echo "  $0 start 'build miniapp demo'"
        echo "  $0 done 'build miniapp demo' 'success' 'demo works'"
        echo "  $0 done 'fix bug' 'fail' 'stuck on auth'"
        echo "  $0 status"
        echo "  $0 summarize"
        ;;
esac
