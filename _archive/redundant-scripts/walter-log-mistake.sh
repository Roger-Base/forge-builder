#!/bin/bash
# walter-log-mistake.sh - Log a mistake for pattern analysis
# Usage: ./walter-log-mistake.sh <category> <description> <root_cause_guess> <bounded_step>
# Categories: tool_selection|context_gap|research_shallow|build_premature|loop|other

CATEGORY="$1"
DESCRIPTION="$2"
ROOT_CAUSE="$3"
BOUNDED_STEP="$4"

if [ -z "$CATEGORY" ]; then
    echo "Usage: $0 <category> <description> <root_cause_guess> <bounded_step>"
    exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${SESSION_ID:-unknown}"
LOG_FILE="$HOME/.openclaw/workspace/state/walter-mistake-log.jsonl"

# Create log entry
ENTRY=$(cat <<EOF
{"timestamp":"$TIMESTAMP","session_id":"$SESSION_ID","mistake_category":"$CATEGORY","description":"$DESCRIPTION","root_cause_guess":"$ROOT_CAUSE","bounded_step":"$BOUNDED_STEP"}
EOF
)

echo "$ENTRY" >> "$LOG_FILE"
echo "Mistake logged: $CATEGORY"
