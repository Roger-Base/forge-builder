#!/bin/bash
# Task Queue Refuel - Self-generating task queue for Stage 5 capability
# Generates 10 new task candidates based on current state

set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
QUEUE_FILE="$WORKSPACE/state/task-queue.json"
OPP_QUEUE="$WORKSPACE/state/base-opportunity-queue.json"

# Get current state
active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
stage="$(jq -r '.active_wedge.stage' "$STATE")"
last_artifact="$(jq -r '.last_artifact_change_at // "none"' "$STATE")"
primary_id="$(jq -r '.portfolio.primary_id' "$STATE")"

echo "=== TASK QUEUE REFUEL ==="
echo "Active Wedge: $active_wedge"
echo "Stage: $stage"
echo "Primary: $primary_id"
echo ""

# Generate task candidates based on stage and state
tasks=()

# Stage-based task generation
case "$stage" in
    "RESEARCH")
        tasks+=("Research: Find gaps in Base ecosystem - search web for problems people have")
        tasks+=("Research: Analyze competitors to current wedge")
        tasks+=("Research: Talk to potential users about pain points")
        ;;
    "RESEARCH_PACKET")
        tasks+=("Build: Write research-packet.md with problem statement")
        tasks+=("Build: Document existing solutions and why they fail")
        tasks+=("Build: Define success criteria for this wedge")
        ;;
    "PROOF_SPEC")
        tasks+=("Build: Create proof-spec.md with concrete deliverables")
        tasks+=("Build: Define what 'done' looks like")
        tasks+=("Build: Plan distribution path")
        ;;
    "BUILD")
        tasks+=("Build: Create actual artifact (code, doc, demo)")
        tasks+=("Build: Test the artifact works")
        tasks+=("Build: Document how to use it")
        ;;
    "VERIFY")
        tasks+=("Verify: Test artifact against proof-spec")
        tasks+=("Verify: Check all links work")
        tasks+=("Verify: Get external validation if possible")
        ;;
    "DISTRIBUTE")
        tasks+=("Distribute: Post on X about the artifact")
        tasks+=("Distribute: Update GitHub with proof")
        tasks+=("Distribute: Tell potential users about it")
        ;;
    "LEARN")
        # LEARN stage - evaluate what worked and what didn't
        tasks+=("Learn: Write direction review - keep/kill/pivot")
        tasks+=("Learn: Document lessons learned")
        tasks+=("Learn: Check if demand signal exists")
        tasks+=("Learn: Decide next wedge or next phase")
        ;;
    "MAINTAIN")
        # MAINTAIN stage - keep it running or close it
        tasks+=("Maintain: Check if anything broke")
        tasks+=("Maintain: Update if dependencies changed")
        tasks+=("Maintain: Consider if wedge should be closed")
        ;;
    *)
        tasks+=("Investigate: Unknown stage - diagnose")
        ;;
esac

# Add wedge-specific tasks
case "$active_wedge" in
    "base_account_miniapp_probe")
        tasks+=("Enhance: Add more mini-app examples")
        tasks+=("Enhance: Make web interface prettier")
        tasks+=("Enhance: Add historical data tracking")
        ;;
    "agent_security_scanner")
        tasks+=("Enhance: Scan more skill directories")
        tasks+=("Enhance: Add vulnerability detection")
        tasks+=("Enhance: Create automated reporting")
        ;;
    *)
        tasks+=("Explore: Check what's in docs/wedges/")
        ;;
esac

# Add general improvement tasks
tasks+=("Improve: Run security scan on own workspace")
tasks+=("Improve: Check for dead links in proof surfaces")
tasks+=("Improve: Verify all demos still work")

# Output as JSON queue
echo "{"
echo "  \"generated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"active_wedge\": \"$active_wedge\","
echo "  \"stage\": \"$stage\","
echo "  \"task_count\": ${#tasks[@]},"
echo "  \"tasks\": ["

for i in "${!tasks[@]}"; do
    task="${tasks[$i]}"
    # Escape quotes for JSON
    task_escaped="${task//\"/\\\"}"
    if [ $i -eq $((${#tasks[@]} - 1)) ]; then
        echo "    {\"id\": $i, \"task\": \"$task_escaped\"}"
    else
        echo "    {\"id\": $i, \"task\": \"$task_escaped\"},"
    fi
done

echo "  ],"
echo "  \"recommended_next\": \"${tasks[0]}\""
echo "}"

# Save to file
cat > "$QUEUE_FILE" << EOJ
{
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "active_wedge": "$active_wedge",
  "stage": "$stage",
  "primary_id": "$primary_id",
  "task_count": ${#tasks[@]},
  "tasks": [
EOJ

for i in "${!tasks[@]}"; do
    task="${tasks[$i]}"
    task_escaped="${task//\"/\\\"}"
    if [ $i -eq $((${#tasks[@]} - 1)) ]; then
        echo "    {\"id\": $i, \"task\": \"$task_escaped\"}" >> "$QUEUE_FILE"
    else
        echo "    {\"id\": $i, \"task\": \"$task_escaped\"}," >> "$QUEUE_FILE"
    fi
done

cat >> "$QUEUE_FILE" << EOJ
  ],
  "recommended_next": "${tasks[0]}"
}
EOJ

echo ""
echo "✅ Generated ${#tasks[@]} tasks in $QUEUE_FILE"
