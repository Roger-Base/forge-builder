#!/bin/bash
# Roger Self-Evaluation Script v2.2
# Usage: bash self-evaluate-v2.sh "task" "output" p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12

TASK="${1}"
OUTPUT="${2}"
P1="${3:-3}"; P2="${4:-3}"; P3="${5:-3}"; P4="${6:-3}"; P5="${7:-3}"; P6="${8:-3}"
P7="${9:-3}"; P8="${10:-3}"; P9="${11:-3}"; P10="${12:-3}"; P11="${13:-3}"; P12="${14:-3}"

[ -z "$TASK" ] && echo "Usage: $0 <task> <output> <p1-p12 scores>" && exit 1

echo "═══════════════════════════════════════════════════════════════"
echo "SELF-EVALUATION: $TASK"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Output: $OUTPUT"
echo ""

STANDARD=$((P1+P2+P3+P4+P5+P6))
ROGER=$((P7+P8+P9+P10+P11+P12))
TOTAL=$((STANDARD+ROGER))

echo "Standard: $STANDARD/30 | Roger-Specific: $ROGER/30 | TOTAL: $TOTAL/60"
echo ""

if [ $TOTAL -lt 30 ]; then
    echo "❌ STOP (<30)"
elif [ $TOTAL -lt 40 ]; then
    echo "⚠️  FIX (30-39)"
elif [ $TOTAL -lt 50 ]; then
    echo "🟡 CAUTION (40-49)"
else
    echo "✅ GO (50+)"
fi
