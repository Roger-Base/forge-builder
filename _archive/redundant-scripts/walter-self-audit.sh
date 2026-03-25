#!/bin/bash
# Walter Self-Audit Script
# Analyzes critique outputs for hedging patterns and confidence indicators
# Part of walter-self-evaluation.json improvement cycle

HEDGE_WORDS=("however" "but" "on the other hand" "it depends" "could be" "might" "perhaps" "possibly" "generally" "typically" "although" "whereas" "while" "alternatively")
CONFIDENCE_PATTERN="(confidence|rating)[:\s]*([1-5])"

analyze_text() {
    local text="$1"
    local hedge_count=0
    local hedge_found=()
    
    for word in "${HEDGE_WORDS[@]}"; do
        count=$(echo "$text" | grep -oi "$word" | wc -l)
        if [ "$count" -gt 0 ]; then
            hedge_found+=("$word:$count")
            hedge_count=$((hedge_count + count))
        fi
    done
    
    # Extract confidence ratings (case-insensitive)
    confidence=$(echo "$text" | grep -Eoi "confidence.*[0-9]" | head -1)
    
    echo "{\"hedgeCount\": $hedge_count, \"hedgingWords\": [\"${hedge_found[*]}\"], \"confidence\": \"$confidence\"}"
}

# Default: analyze stdin or file
if [ -p /dev/stdin ]; then
    content=$(cat -)
    analyze_text "$content"
elif [ -f "$1" ]; then
    analyze_text "$(cat "$1")"
else
    echo "Usage: $0 <file> or pipe text to stdin"
    echo "Analyzes text for hedging patterns and confidence ratings"
fi
