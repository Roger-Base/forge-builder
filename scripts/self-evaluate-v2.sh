#!/bin/bash
# Roger Self-Evaluation Script v2
# Evaluates Roger's work with ACTUAL scoring

TASK="${1:-}"
OUTPUT="${2:-}"

if [ -z "$TASK" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 \"<task>\" \"<output>\""
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "SELF-EVALUATION: $TASK"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Output: $OUTPUT"
echo ""
echo "Rate EACH criterion 1-5 (be honest):"
echo ""

# Criteria
read -p "1. PROBLEM REAL? (Does it solve actual problem?) [1-5]: " p1
read -p "2. DEMAND PROOF? (Did anyone ask for it?) [1-5]: " p2
read -p "3. ORIGINALITY? (Or does it already exist?) [1-5]: " p3
read -p "4. EXECUTION QUALITY? (Does it actually work?) [1-5]: " p4
read -p "5. REVENUE POTENTIAL? (Would anyone pay?) [1-5]: " p5
read -p "6. BASE RELEVANCE? (Is it actually for Base?) [1-5]: " p6

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "ROGER-SPECIFIC WEAKNESS CRITERIA"
echo "═══════════════════════════════════════════════════════════════"
echo ""

read -p "7. LEVERAGE vs OCCUPATION? (Real fix or just busy?) [1-5]: " p7
read -p "8. TOO EARLY CLOSURE? (Shipped before verified?) [1-5]: " p8
read -p "9. SYMBOLIC OUTPUT? (Real artifact or theater?) [1-5]: " p9
read -p "10. WORKSPACE USAGE? (Existing files or new ones?) [1-5]: " p10
read -p "11. STAGE PROGRESS? (Actually advanced stage?) [1-5]: " p11
read -p "12. REPETITION? (Same thing again?) [1-5]: " p12

# Calculate total
TOTAL=$((${p1:-0} + ${p2:-0} + ${p3:-0} + ${p4:-0} + ${p5:-0} + ${p6:-0} + ${p7:-0} + ${p8:-0} + ${p9:-0} + ${p10:-0} + ${p11:-0} + ${p12:-0}))

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "RESULT"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Standard Criteria: $((${p1:-0} + ${p2:-0} + ${p3:-0} + ${p4:-0} + ${p5:-0} + ${p6:-0}))/30"
echo "Roger-Specific:    $((${p7:-0} + ${p8:-0} + ${p9:-0} + ${p10:-0} + ${p11:-0} + ${p12:-0}))/30"
echo "TOTAL:            $TOTAL/60"
echo ""

if [ $TOTAL -lt 30 ]; then
    echo "❌ SCORE < 30: STOP - Do not proceed"
    echo "   This is not worth continuing. Research why this keeps happening."
elif [ $TOTAL -lt 40 ]; then
    echo "⚠️  SCORE 30-39: FIX GAPS - Cannot proceed until improved"
    echo "   You must fix the gaps before continuing."
elif [ $TOTAL -lt 50 ]; then
    echo "� caution SCORE 40-49: PROCEED WITH CAUTION"
    echo "   Build, but monitor closely. Significant issues remain."
else
    echo "✅ SCORE 50+: GO - Full steam ahead"
    echo "   Ready to proceed with this work."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"

exit 0
