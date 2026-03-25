#!/usr/bin/env bash
# Memory-active parity guard - prevents best-next-move from overwriting manual fixes
# Returns exit 1 if fix was applied (so active-surface-sync skips best-next-move)
# Returns exit 0 if no fix to apply

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
MEMORY_ACTIVE="$WORKSPACE/MEMORY_ACTIVE.md"
STATE="$WORKSPACE/state/session-state.json"

echo "MEMORY_PARITY_GUARD: Checking for recent fixes..."

# Get first fix entry only
latest_fix=$(grep -A 5 "^## Guard Fix Applied" "$MEMORY_ACTIVE" 2>/dev/null | head -6 || true)

if [[ -z "$latest_fix" ]]; then
  echo "MEMORY_PARITY_GUARD: No recent fixes in MEMORY_ACTIVE, allowing best-next-move"
  exit 0
fi

# Check for blocker clear
if echo "$latest_fix" | grep -qi "Cleared blockers\|Cleared blocker"; then
  current_blockers=$(jq -r '.blockers | length' "$STATE" 2>/dev/null || echo "0")
  if [[ "$current_blockers" -gt 0 ]]; then
    echo "MEMORY_PARITY_GUARD: Fix detected - clearing blockers, blocking best-next-move"
    jq '.blockers = []' "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"
    exit 1
  fi
fi

# Check for stage change
if echo "$latest_fix" | grep -qi "stage.*LEARN\|stage.*BUILD\|stage.*DISTRIBUTE"; then
  fix_stage=$(echo "$latest_fix" | grep -io "stage.*" | head -1 | grep -oE "LEARN|BUILD|DISTRIBUTE|MAINTAIN" | tail -1)
  if [[ -n "$fix_stage" ]]; then
    current_stage=$(jq -r '.stage' "$STATE" 2>/dev/null || echo "")
    if [[ "$current_stage" != "$fix_stage" ]]; then
      echo "MEMORY_PARITY_GUARD: Fix detected - stage change to $fix_stage, blocking best-next-move"
      jq ".stage = \"$fix_stage\" | .active_wedge.stage = \"$fix_stage\"" "$STATE" > "${STATE}.tmp" && mv "${STATE}.tmp" "$STATE"
      exit 1
    fi
  fi
fi

echo "MEMORY_PARITY_GUARD: No recent fixes needing apply"
exit 0
