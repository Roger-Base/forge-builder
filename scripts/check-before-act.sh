#!/bin/bash
# Pre-execution checklist - run before any uncertain action

echo "=== ROGER PRE-ACT CHECK ==="

# 1. Did you check --help?
read -p "Did you check --help first? (y/n) " help
if [ "$help" != "y" ]; then
    echo "❌ Check --help first!"
    exit 1
fi

# 2. Did you verify with browser if CLI fails?
read -p "Did you verify with browser if CLI fails? (y/n) " browser
if [ "$browser" != "y" ]; then
    echo "❌ Try browser first!"
    exit 1
fi

# 3. What assumption are you making?
read -p "What do you assume? " assumption

# 4. How will you verify?
read -p "How will you verify it's true? " verify

echo "=== ASSUMPTION ==="
echo "You assume: $assumption"
echo "You'll verify by: $verify"
echo ""
echo "If assumption is wrong after 30s, come back and fix."
