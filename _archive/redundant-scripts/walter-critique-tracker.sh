#!/bin/bash
# walter-critique-tracker.sh - Track Walter's critique accuracy over time
# 
# Usage:
#   ./walter-critique-tracker.sh log <critique_id> "<prediction>" "<verify_after>" "<context>"
#   ./walter-critique-tracker.sh verify <critique_id> "<actual_outcome>"
#   ./walter-critique-tracker.sh score
#   ./walter-critique-tracker.sh due
#   ./walter-critique-tracker.sh insights
#
# Example:
#   ./walter-critique-tracker.sh log "drift-001" "Stage mismatch will cause confusion" "2026-03-20" "base_account_miniapp_probe"
#   ./walter-critique-tracker.sh verify "drift-001" "Roger fixed the drift manually - prediction partially correct"

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
ACCURACY_FILE="$WORKSPACE/state/walter-critique-accuracy.json"

# Initialize file if it doesn't exist
init() {
    if [[ ! -f "$ACCURACY_FILE" ]]; then
        cat > "$ACCURACY_FILE" << 'EOF'
{
  "version": "1.0",
  "created_at": "2026-03-17T00:20:00Z",
  "critiques": [],
  "stats": {
    "total_predictions": 0,
    "verified_correct": 0,
    "verified_incorrect": 0,
    "verified_partial": 0,
    "pending": 0
  }
}
EOF
    fi
}

# Log a new critique prediction
log_critique() {
    local id="$1"
    local prediction="$2"
    local verify_after="$3"  # ISO date
    local context="$4"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    init
    
    # Check if ID already exists
    if jq -e --arg id "$id" '.critiques[] | select(.id == $id)' "$ACCURACY_FILE" >/dev/null 2>&1; then
        echo "Error: Critique ID '$id' already exists"
        exit 1
    fi
    
    local new_entry=$(jq -n \
        --arg id "$id" \
        --arg t "$timestamp" \
        --arg p "$prediction" \
        --arg v "$verify_after" \
        --arg c "$context" \
        '{
            id: $id,
            logged_at: $t,
            prediction: $p,
            verify_after: $v,
            context: $c,
            status: "pending",
            outcome: null,
            verified_at: null
        }')
    
    local updated=$(jq --argjson entry "$new_entry" \
        '.critiques += [$entry] | .stats.total_predictions += 1 | .stats.pending += 1' \
        "$ACCURACY_FILE")
    
    echo "$updated" > "$ACCURACY_FILE"
    echo "✅ Logged critique: $id"
    echo "   Prediction: ${prediction:0:60}..."
    echo "   Verify after: $verify_after"
    echo "   Context: $context"
}

# Verify a prediction
verify_critique() {
    local id="$1"
    local outcome="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    init
    
    # Check if ID exists
    if ! jq -e --arg id "$id" '.critiques[] | select(.id == $id)' "$ACCURACY_FILE" >/dev/null 2>&1; then
        echo "Error: Critique ID '$id' not found"
        exit 1
    fi
    
    # Determine correctness (simple heuristic based on outcome keywords)
    local result="partial"
    if echo "$outcome" | grep -qi "correct\|准确\|valid\|true\|happened"; then
        result="correct"
    elif echo "$outcome" | grep -qi "incorrect\|wrong\|false\|did not\|didn't"; then
        result="incorrect"
    fi
    
    # Update the entry
    local updated=$(jq --arg id "$id" --arg outcome "$outcome" --arg result "$result" --arg ts "$timestamp" \
        '.critiques |= map(
            if .id == $id then 
                .status = "verified" | 
                .outcome = $outcome | 
                .result = $result | 
                .verified_at = $ts 
            else . end
        )' "$ACCURACY_FILE")
    
    # Update stats
    if [ "$result" = "correct" ]; then
        updated=$(echo "$updated" | jq '.stats.verified_correct += 1 | .stats.pending -= 1')
    elif [ "$result" = "incorrect" ]; then
        updated=$(echo "$updated" | jq '.stats.verified_incorrect += 1 | .stats.pending -= 1')
    else
        updated=$(echo "$updated" | jq '.stats.verified_partial += 1 | .stats.pending -= 1')
    fi
    
    echo "$updated" > "$ACCURACY_FILE"
    echo "✅ Verified critique: $id"
    echo "   Result: $result"
    echo "   Outcome: ${outcome:0:80}..."
}

# Show accuracy score
show_score() {
    init
    
    local total=$(jq -r '.stats.total_predictions' "$ACCURACY_FILE")
    local correct=$(jq -r '.stats.verified_correct' "$ACCURACY_FILE")
    local incorrect=$(jq -r '.stats.verified_incorrect' "$ACCURACY_FILE")
    local partial=$(jq -r '.stats.verified_partial' "$ACCURACY_FILE")
    local pending=$(jq -r '.stats.pending' "$ACCURACY_FILE")
    
    echo "═══════════════════════════════════════════════════════"
    echo "WALTER CRITIQUE ACCURACY SCORE"
    echo "═══════════════════════════════════════════════════════"
    echo "Total Predictions:  $total"
    echo "✅ Correct:         $correct"
    echo "❌ Incorrect:       $incorrect"
    echo "⚠️  Partial:         $partial"
    echo "⏳ Pending:         $pending"
    echo "═══════════════════════════════════════════════════════"
    
    if [ "$total" -gt 0 ]; then
        local verified=$((correct + incorrect + partial))
        if [ "$verified" -gt 0 ]; then
            local accuracy=$((correct * 100 / verified))
            echo "ACCURACY: $accuracy% ($correct/$verified verified)"
            echo "═══════════════════════════════════════════════════════"
            
            if [ "$accuracy" -ge 80 ]; then
                echo "🟢 STRONG - Your critiques are highly reliable"
            elif [ "$accuracy" -ge 60 ]; then
                echo "🟡 MODERATE - Some pattern blindness detected"
            else
                echo "🔴 WEAK - Significant calibration needed"
            fi
        else
            echo "No verified predictions yet"
        fi
    fi
}

# Show due verifications
show_due() {
    init
    
    local today=$(date -u +"%Y-%m-%d")
    echo "═══ Critiques due for verification (as of $today) ═══"
    
    local due=$(jq --arg today "$today" \
        '[.critiques[] | select(.status == "pending" and .verify_after <= $today)]' \
        "$ACCURACY_FILE")
    
    local count=$(echo "$due" | jq 'length')
    
    if [ "$count" -eq 0 ]; then
        echo "No verifications due"
    else
        echo "$due" | jq -r '.[] | 
            "[\(.id)] \(.context) - verify after \(.verify_after)
             Prediction: \(.prediction | .[0:60])..."'
    fi
}

# Generate insights
show_insights() {
    init
    
    echo "═══════════════════════════════════════════════════════"
    echo "WALTER CRITIQUE INSIGHTS"
    echo "═══════════════════════════════════════════════════════"
    
    # By context
    echo ""
    echo "═══ By Context ═══"
    jq -r '.critiques | group_by(.context) | .[] | 
        select(length > 0) | 
        "\(.[0].context): \(length) critiques"' "$ACCURACY_FILE" 2>/dev/null || echo "No data"
    
    # Recent verifications
    echo ""
    echo "═══ Recent Verifications ═══"
    jq -r '.critiques | 
        select(.status == "verified") | 
        sort_by(.verified_at) | 
        reverse | 
        limit(5; .[]) | 
        "[\(.result)] \(.id): \(.prediction | .[0:50])..."' "$ACCURACY_FILE" 2>/dev/null || echo "No verified"
    
    # Pending that are old
    echo ""
    echo "═══ Overdue Pending ═══"
    local overdue=$(jq --arg today "$(date -u +%Y-%m-%d)" \
        '[.critiques[] | select(.status == "pending" and .verify_after < $today)]' \
        "$ACCURACY_FILE")
    local overdue_count=$(echo "$overdue" | jq 'length')
    if [ "$overdue_count" -gt 0 ]; then
        echo "$overdue" | jq -r '.[] | "⚠️  \(.id) - was due \(.verify_after)"'
    else
        echo "None overdue"
    fi
}

case "$1" in
    log)
        log_critique "$2" "$3" "$4" "$5"
        ;;
    verify)
        verify_critique "$2" "$3"
        ;;
    score)
        show_score
        ;;
    due)
        show_due
        ;;
    insights)
        show_insights
        ;;
    *)
        echo "Usage: $0 {log|verify|score|due|insights}"
        echo ""
        echo "  log <id> <prediction> <verify_after> <context>"
        echo "      Log a new critique prediction"
        echo ""
        echo "  verify <id> <actual_outcome>"  
        echo "      Mark a prediction as correct/incorrect/partial"
        echo ""
        echo "  score"
        echo "      Show accuracy statistics"
        echo ""
        echo "  due"
        echo "      Show pending verifications due"
        echo ""
        echo "  insights"
        echo "      Generate pattern insights"
        exit 1
        ;;
esac
