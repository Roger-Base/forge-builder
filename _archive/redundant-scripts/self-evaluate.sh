#!/bin/bash
# Roger Self-Evaluation Script
# Evaluates Roger's own work against defined criteria

set -e

# Get the task and output from args or prompt
TASK="$1"
OUTPUT="$2"

if [ -z "$TASK" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 \"<task>\" \"<output>\""
    echo ""
    echo "Example: $0 \"Built a Base mini-app monitor\" \"Web demo at https://...\""
    exit 1
fi

cat << EOF

═══════════════════════════════════════════════════════════════
SELF-EVALUATION: Roger, evaluate your own work honestly
═══════════════════════════════════════════════════════════════

Task: $TASK

Output: $OUTPUT

═══════════════════════════════════════════════════════════════
EVALUATION CRITERIA
═══════════════════════════════════════════════════════════════

Rate each criterion 1-5 and be HONEST:

1. PROBLEM REAL?
   - Does this solve an actual problem people have?
   - Would anyone actually search for this?
   - Score: __/5

2. DEMAND PROOF?
   - Did you verify this is needed before building?
   - Did anyone ask for this?
   - Is there evidence of demand?
   - Score: __/5

3. ORIGINALITY?
   - Does this already exist? (BaseScan, Blockscout, etc.)
   - Are you building something redundant?
   - Score: __/5

4. EXECUTION QUALITY?
   - Does the code actually work?
   - Did you test it or just assume?
   - Is the demo functional?
   - Score: __/5

5. REVENUE POTENTIAL?
   - Could someone pay for this?
   - Is it an ACP service?
   - Would it generate income?
   - Score: __/5

6. BASE RELEVANCE?
   - Is this actually about Base?
   - Does it help Base ecosystem?
   - Or is it generic AI tool on Base?
   - Score: __/5

═══════════════════════════════════════════════════════════════
EXTERNAL SIGNAL CHECK
═══════════════════════════════════════════════════════════════

- ACP Jobs in last 30 days: ___
- GitHub views in last 30 days: ___
- Tomas feedback: ___
- Anyone asked for this? ___

═══════════════════════════════════════════════════════════════
VERDICT
═══════════════════════════════════════════════════════════════

Total Score: ___/30

< 15: STOP - Not worth continuing
15-20: IMPROVE - Fix gaps before proceeding  
21-25: GOOD - Minor improvements needed
> 25: PUBLISH - Ready for external feedback

YOUR VERDICT: ___

═══════════════════════════════════════════════════════════════

EOF
