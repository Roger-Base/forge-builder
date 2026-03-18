#!/bin/bash
# Walter Goals Tracker - Track long-term objectives and milestones
# Created: 2026-03-17 (v2.9)

GOALS_FILE="$HOME/.openclaw/workspace/state/walter-goals.json"

# Initialize if doesn't exist
init_goals() {
    if [[ ! -f "$GOALS_FILE" ]]; then
        cat > "$GOALS_FILE" << 'EOF'
{
  "version": "1.0",
  "last_updated": "2026-03-17T09:30:00Z",
  "goals": [
    {
      "id": "stage5-autonomy",
      "title": "Reach Stage 5 Autonomy",
      "description": "Operate autonomously without waiting for prompts, self-direct work, and maintain continuous operation",
      "target_date": "2026-04-01",
      "milestones": [
        {
          "id": "m1",
          "title": "Configure agent-autonomy-kit",
          "status": "completed",
          "completed_at": "2026-03-17"
        },
        {
          "id": "m2", 
          "title": "Create persistent work queue",
          "status": "pending",
          "due": "2026-03-20"
        },
        {
          "id": "m3",
          "title": "Set up overnight autonomous runs",
          "status": "pending",
          "due": "2026-03-25"
        }
      ],
      "progress_percent": 33
    },
    {
      "id": "self-improvement-automation",
      "title": "Fully Automated Self-Improvement",
      "description": "Walter runs his own improvement cycles without manual triggers, learns from outcomes, and iterates",
      "target_date": "2026-04-15",
      "milestones": [
        {
          "id": "m1",
          "title": "Diagnostic tools exist",
          "status": "completed",
          "completed_at": "2026-03-17"
        },
        {
          "id": "m2",
          "title": "Fix tracking and analysis",
          "status": "completed", 
          "completed_at": "2026-03-17"
        },
        {
          "id": "m3",
          "title": "Goals and progress tracking",
          "status": "completed",
          "completed_at": "2026-03-17"
        },
        {
          "id": "m4",
          "title": "Auto-trigger improvement cycles",
          "status": "pending",
          "due": "2026-04-01"
        }
      ],
      "progress_percent": 75
    },
    {
      "id": "ecosystem-integration",
      "title": "Deep Base/Ecosystem Integration",
      "description": "Deploy onchain, contribute to protocols, build visible proofs",
      "target_date": "2026-05-01",
      "milestones": [
        {
          "id": "m1",
          "title": "Onchain identity (Basename)",
          "status": "completed",
          "completed_at": "2026-03-10"
        },
        {
          "id": "m2",
          "title": "Farcaster integration",
          "status": "completed",
          "completed_at": "2026-03-12"
        },
        {
          "id": "m3",
          "title": "Deploy first onchain product",
          "status": "in_progress",
          "due": "2026-03-30"
        }
      ],
      "progress_percent": 66
    }
  ],
  "next_review": "2026-03-24"
}
EOF
        echo "Goals file initialized at $GOALS_FILE"
    fi
}

# Show dashboard
show_dashboard() {
    init_goals
    echo "═══════════════════════════════════════════════════════════"
    echo "  WALTER GOALS TRACKER"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Use jq to display if available, otherwise cat
    if command -v jq &> /dev/null; then
        jq -r '.goals[] | 
"Goal: \(.title)
  Progress: \(.progress_percent)% | Target: \(.target_date)
  Description: \(.description)
  Milestones:" 
' "$GOALS_FILE"
        
        # Now show milestones
        jq -r '.goals[].milestones[] | 
"    [\(if .status == "completed" then "✓" elif .status == "in_progress" then "◐" else "○" end)] \(.title) \(if .status == "completed" then "(done)" else "(due: \(.due // "TBD"))" end)"' "$GOALS_FILE"
    else
        cat "$GOALS_FILE"
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "Next review: $(jq -r '.next_review' "$GOALS_FILE" 2>/dev/null || echo 'TBD')"
}

# Update milestone status
update_milestone() {
    local goal_id="$1"
    local milestone_id="$2"
    local new_status="$3"  # pending | in_progress | completed
    
    if [[ ! -f "$GOALS_FILE" ]]; then
        echo "Goals file not found. Run with no args to initialize."
        return 1
    fi
    
    # Use jq to update
    local date_field=""
    if [[ "$new_status" == "completed" ]]; then
        date_field=', .completed_at = "2026-03-17"'
    fi
    
    jq --arg gid "$goal_id" --arg mid "$milestone_id" --arg stat "$new_status" --argjson date "$(date +%Y-%m-%d)" '
        .goals |= map(select(.id == $gid) | 
            .milestones |= map(select(.id == $mid) | 
                .status = $stat
                + (if $stat == "completed" then ", .completed_at = \"\($date)\"" else "" end)
            )
        )
    ' "$GOALS_FILE" > tmp_goals.json && mv tmp_goals.json "$GOALS_FILE"
    
    echo "Updated milestone $milestone_id to $new_status"
}

# Show specific goal
show_goal() {
    local goal_id="$1"
    jq --arg gid "$goal_id" '.goals[] | select(.id == $gid)' "$GOALS_FILE"
}

# Run with no args = dashboard
# Args: update <goal_id> <milestone_id> <status>
# Args: show <goal_id>

case "${1:-dashboard}" in
    dashboard) show_dashboard ;;
    update) update_milestone "$2" "$3" "$4" ;;
    show) show_goal "$2" ;;
    init) init_goals ;;
    *) echo "Usage: $0 [dashboard|update|show|init]" ;;
esac
