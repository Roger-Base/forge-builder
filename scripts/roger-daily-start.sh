#!/bin/bash
# Roger Daily Start - Morning routine
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
cd "$WORKSPACE"

echo "🤖 Roger Daily Start - $(date)"

# 1. Refresh daily plan
bash scripts/daily-plan.sh --refresh

# 2. Sync active surface
bash scripts/active-surface-sync.sh

# 3. Check portfolio coherence
bash scripts/portfolio-coherence-check.sh

# 4. Ensure capability activation
bash scripts/capability-activation.sh --ensure

# 5. Read today's plan
echo "--- Today's Plan ---"
cat state/daily-plan.md

echo "✅ Daily start complete"
