#!/bin/bash
# walter-inject-corrections.sh
# Runs before each bounded step to inject relevant corrections into context

CORRECTION_PLANS="/Users/roger/.openclaw/workspace/state/walter-correction-plans.json"
TRIGGER_CONTEXT="${1:-default}"  # Pass context like "tool_selection", "context_gathering", etc.

if [ ! -f "$CORRECTION_PLANS" ]; then
    echo "No correction plans found"
    exit 0
fi

# Extract corrections matching the trigger context
# Using jq to parse and filter
corrections=$(jq -r --arg ctx "$TRIGGER_CONTEXT" '
  .correction_plans | 
  map(select(.trigger_context == $ctx or .trigger_context == "all")) |
  map(select(.status == "active")) |
  .[].correction_text
' "$CORRECTION_PLANS" 2>/dev/null)

if [ -z "$corrections" ] || [ "$corrections" = "null" ]; then
    echo "No active corrections for context: $TRIGGER_CONTEXT"
    exit 0
fi

# Output as SYSTEM_REMINDER format
echo "=== ACTIVE CORRECTIONS FOR: $TRIGGER_CONTEXT ==="
while IFS= read -r line; do
    if [ -n "$line" ]; then
        echo "[CORRECTION] $line"
    fi
done <<< "$corrections"

# Update injection count in correction plans
jq --arg ctx "$TRIGGER_CONTEXT" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  .correction_plans |= map(
    if (.trigger_context == $ctx or .trigger_context == "all") and .status == "active" then
      .injection_count = (.injection_count // 0) + 1 |
      .last_injected = $now
    else .
    end
  )
' "$CORRECTION_PLANS" > "${CORRECTION_PLANS}.tmp" && mv "${CORRECTION_PLANS}.tmp" "$CORRECTION_PLANS"

exit 0
