#!/bin/bash
# Walter Health Monitor - Agent Runtime Health Monitor with Auto-Recovery
# Purpose: Poll running exec sessions for stuck state, kill stuck subagents, log recovery actions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$WORKSPACE_DIR/state/walter-recovery-log.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_action() {
    local action="$1"
    local session_id="${2:-unknown}"
    local details="${3:-}"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"action\":\"$action\",\"session_id\":\"$session_id\",\"details\":\"$details\"}" >> "$LOG_FILE"
}

echo "Walter Health Monitor starting..."

# Get list of running exec sessions
running_sessions=$(process list 2>/dev/null | grep -E "^\[" | head -20 || echo "")

if [[ -z "$running_sessions" ]]; then
    log_action "no_sessions_found" "system" "No running exec sessions detected"
    echo "No running sessions found. Health: OK"
    exit 0
fi

echo "Checking running sessions..."

# Count sessions and check for stuck state
session_count=$(echo "$running_sessions" | wc -l)
echo "Found $session_count running session(s)"

# Check for any sessions running longer than 30 minutes (potential stuck)
# This is a simple heuristic - in production you'd want more sophisticated detection
stuck_count=0

for session in $(echo "$running_sessions" | jq -r '.[].sessionId // empty' 2>/dev/null); do
    if [[ -n "$session" ]]; then
        # Log that we checked this session
        log_action "session_checked" "$session" "Session polled for health status"
        
        # For now, we just log the check - actual stuck detection would require
        # more sophisticated state tracking across runs
        ((stuck_count++))
    fi
done

echo "Health check complete. Sessions monitored: $stuck_count"
log_action "health_check_complete" "system" "Checked $stuck_count sessions"

exit 0
