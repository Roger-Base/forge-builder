#!/bin/bash
# Pre-build checklist - AUTOMATIC check before any build
# Must pass all 3 questions to proceed

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
AGENT_GAPS="$WORKSPACE/docs/agent-gaps.md"

echo "=== ROGER PRE-BUILD CHECK ==="

# Question 1: Does this problem actually exist?
echo ""
echo "❓ Question 1: Does this problem actually exist?"
echo "   Has this been searched for in:"
echo "   - agent-gaps.md?"
echo "   - Web search?"
echo "   - X/Community?"

# Check if problem is already documented
echo ""
echo "   Checking agent-gaps.md..."
if grep -qi "gap\|problem\|missing" "$AGENT_GAPS" 2>/dev/null; then
    echo "   ✅ Gaps file exists - review it first"
else
    echo "   ⚠️  No gaps file found"
fi

# Question 2: Would this build strengthen Base ecosystem?
echo ""
echo "❓ Question 2: Would this strengthen Base agent ecosystem?"
echo "   Ask:"
echo "   - Is this for Base specifically?"
echo "   - Do agents actually need this?"
echo "   - Is there real demand?"

# Question 3: Can my system reliably deliver?
echo ""
echo "❓ Question 3: Can my system reliably deliver?"
echo "   Ask:"
echo "   - Do I have the skills?"
echo "   - Do I have the resources?"
echo "   - Can I test this?"

echo ""
echo "=== DECISION ==="
echo "If ANY question is unclear or NO → DO NOT BUILD"
echo "Only proceed if all 3 are YES"
echo ""
echo "This check is MANDATORY before any build action."
