#!/bin/bash
# walter-learn-promote.sh - Promote recurring learnings to system guidance
# Scans .learnings/LEARNINGS.md for patterns with Recurrence-Count >= 3
# and promotes them to SOUL.md, AGENTS.md, or TOOLS.md

LEARNINGS_FILE="$HOME/.openclaw/workspace/.learnings/LEARNINGS.md"
SOUL_FILE="$HOME/.openclaw/workspace/SOUL.md"
AGENTS_FILE="$HOME/.openclaw/workspace/AGENTS.md"
TOOLS_FILE="$HOME/.openclaw/workspace/TOOLS.md"

echo "=============================================="
echo "       WALTER LEARN PROMOTION - v1.0         "
echo "   Promoting recurring patterns to system    "
echo "=============================================="
echo ""

# Check if learnings file exists
if [[ ! -f "$LEARNINGS_FILE" ]]; then
    echo "Error: Learnings file not found at $LEARNINGS_FILE"
    exit 1
fi

# Find entries with Recurrence-Count >= 3
echo "--- Scanning for recurring patterns (Recurrence-Count >= 3) ---"
echo ""

# Extract entries with Pattern-Key and Recurrence-Count
pattern_count=0
while IFS= read -r line; do
    if [[ $line =~ ^"## "*\[LRN-([0-9]{8})-([0-9A-Z]{3})\] ]]; then
        current_id="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
    fi
    
    if [[ $line =~ "Pattern-Key:" ]]; then
        pattern_key=$(echo "$line" | sed 's/.*Pattern-Key: *//' | xargs)
    fi
    
    if [[ $line =~ "Recurrence-Count:" ]]; then
        count=$(echo "$line" | sed 's/.*Recurrence-Count: *//' | xargs)
        if [[ $count -ge 3 ]]; then
            echo "[PROMOTE] LRN-$current_id"
            echo "  Pattern-Key: $pattern_key"
            echo "  Recurrence-Count: $count"
            echo "  Action: Review for promotion to system guidance"
            echo ""
            ((pattern_count++))
        fi
    fi
done < "$LEARNINGS_FILE"

if [[ $pattern_count -eq 0 ]]; then
    echo "No patterns with Recurrence-Count >= 3 found."
    echo "System is working - patterns are being captured before reaching promotion threshold."
else
    echo "=============================================="
    echo "         FOUND $pattern_count PATTERNS FOR REVIEW        "
    echo "=============================================="
    echo ""
    echo "Next steps:"
    echo "1. Review each pattern above"
    echo "2. Determine promotion target (SOUL.md / AGENTS.md / TOOLS.md)"
    echo "3. Add concise prevention rule to target file"
    echo "4. Update learning entry: Status -> promoted"
    echo "5. Add '**Promoted**: <filename>' to learning metadata"
fi

echo ""
echo "=============================================="
echo "         Quick Status Check                  "
echo "=============================================="
echo ""

# Count total learnings
total_learnings=$(grep -c "^## \[LRN-" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
echo "Total structured learnings: $total_learnings"

# Count by status
pending=$(grep -c "Status\*\*: pending" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
resolved=$(grep -c "Status\*\*: resolved" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
promoted=$(grep -c "Status\*\*: promoted" "$LEARNINGS_FILE" 2>/dev/null || echo "0")

echo "Pending: $pending"
echo "Resolved: $resolved"
echo "Promoted: $promoted"
echo ""

# Count entries with Pattern-Key
pattern_entries=$(grep -c "Pattern-Key:" "$LEARNINGS_FILE" 2>/dev/null || echo "0")
echo "Entries with Pattern-Key tracking: $pattern_entries"

echo ""
echo "=============================================="
echo "         Promotion Complete                  "
echo "=============================================="
