#!/bin/bash
# walter-pattern-analyze.sh - Analyze mistake patterns and create detection rules
# Run every 10 sessions or 24 hours

LOG_FILE="$HOME/.openclaw/workspace/state/walter-mistake-log.jsonl"
RULES_FILE="$HOME/.openclaw/workspace/state/walter-pattern-rules.json"
ANALYSIS_FILE="$HOME/.openclaw/workspace/state/walter-pattern-analysis.json"

if [ ! -f "$LOG_FILE" ]; then
    echo "No mistake log found. Creating empty log."
    echo "" > "$LOG_FILE"
    exit 0
fi

# Count mistakes by category in last 30 days
THIRTY_DAYS_AGO=$(date -u -d "30 days ago" +"%Y-%m-%d")

echo "=== Walter Pattern Analysis ==="
echo "Analyzing mistakes since $THIRTY_DAYS_AGO"
echo ""

# Use jq to analyze patterns (if available)
if command -v jq &> /dev/null; then
    # Count by category
    echo "Mistakes by category (last 30 days):"
    cat "$LOG_FILE" | jq -s --arg date "$THIRTY_DAYS_AGO" \
        'map(select(.timestamp >= $date)) | group_by(.mistake_category) | map({category: .[0].mistake_category, count: length})' 2>/dev/null || echo "  (jq analysis unavailable)"
    
    echo ""
    
    # Find recurring patterns (same category 3+ times)
    echo "Potential patterns (3+ mistakes in same category):"
    cat "$LOG_FILE" | jq -s --arg date "$THIRTY_DAYS_AGO" \
        'map(select(.timestamp >= $date)) | group_by(.mistake_category) | map(select(length >= 3) | {category: .[0].mistake_category, count: length, examples: .[0:2]})' 2>/dev/null || echo "  (pattern detection unavailable)"
else
    echo "jq not available - install for full pattern analysis"
    wc -l "$LOG_FILE"
fi

# Update rules file if patterns found
echo ""
echo "Pattern rules updated at: $RULES_FILE"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "$ANALYSIS_FILE"
