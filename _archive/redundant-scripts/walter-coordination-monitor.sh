#!/bin/bash
# Walter-Roger Coordination Monitor
# Tracks handoffs, detects Roger availability, and triggers autonomous research
# Usage: ./walter-coordination-monitor.sh [command]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="/Users/roger/.openclaw/workspace/state"
WALTER_DIR="/Users/roger/.openclaw/workspace/walter"
LOG_FILE="$STATE_DIR/walter-coordination-log.json"
ROGER_ACTIVITY_FILE="$STATE_DIR/roger-activity-cache.json"
CONFIG_FILE="$STATE_DIR/walter-coordination-config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Initialize files
init() {
    # Coordination log
    if [[ ! -f "$LOG_FILE" ]]; then
        cat > "$LOG_FILE" << 'EOF'
{
  "created": "",
  "lastUpdated": "",
  "handoffs": [],
  "rogerActivity": {
    "lastSeen": "",
    "status": "unknown",
    "minutesIdle": 0
  },
  "autonomousQueue": [],
  "metrics": {
    "totalHandoffs": 0,
    "responseRate": 0,
    "avgResponseTimeMinutes": 0,
    "escalationsToTomas": 0
  }
}
EOF
        echo "Created coordination log"
    fi

    # Roger activity cache
    if [[ ! -f "$ROGER_ACTIVITY_FILE" ]]; then
        cat > "$ROGER_ACTIVITY_FILE" << 'EOF'
{
  "lastActivity": "",
  "lastSessionKey": "",
  "lastChannel": "",
  "activeThreads": [],
  "cachedAt": ""
}
EOF
        echo "Created Roger activity cache"
    fi

    # Config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
  "idleThresholdMinutes": 30,
  "responseTimeoutHours": 4,
  "escalationThresholdHours": 12,
  "autonomousResearchWhenIdle": true,
  "notifyOnIdle": true,
  "preferredResearchSources": ["protocol_analysis", "ecosystem_mapping"]
}
EOF
        echo "Created config file"
    fi
}

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_epoch() {
    date +%s
}

# Log a handoff to Roger
log_handoff() {
    local handoff_file="$1"
    local description="$2"
    local requires_response="${3:-true}"
    local priority="${4:-normal}"
    
    if [[ ! -f "$handoff_file" ]]; then
        echo -e "${RED}Handoff file not found: $handoff_file${NC}"
        return 1
    fi

    local timestamp=$(get_timestamp)
    local epoch=$(get_epoch)
    local handoff_id="handoff-$(date +%s)"

    # Extract key info from handoff file if JSON
    local handoff_content=$(cat "$handoff_file")
    
    local entry=$(cat << EOF
{
  "id": "$handoff_id",
  "timestamp": "$timestamp",
  "epoch": $epoch,
  "handoffFile": "$handoff_file",
  "description": "$description",
  "requiresResponse": $requires_response,
  "priority": "$priority",
  "status": "pending",
  "response": {
    "respondedAt": "",
    "responder": "",
    "feedback": "",
    "actionTaken": ""
  },
  "escalation": {
    "escalated": false,
    "escalatedAt": "",
    "reason": ""
  }
}
EOF
)

    # Add to log
    local temp_file=$(mktemp)
    jq --argjson newEntry "$entry" --arg ts "$timestamp" '
        .handoffs += [$newEntry] |
        .lastUpdated = $ts |
        .metrics.totalHandoffs += 1
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"

    echo -e "${GREEN}✓ Logged handoff: $description${NC}"
    echo "  ID: $handoff_id"
    echo "  File: $handoff_file"
    echo "  Status: pending"
    
    if [[ "$requires_response" == "true" ]]; then
        echo -e "${YELLOW}  Waiting for Roger response (timeout: 4 hours)${NC}"
    fi
}

# Record Roger response
record_response() {
    local handoff_id="$1"
    local responder="$2"
    local feedback="$3"
    local action_taken="${4:-}"
    local timestamp=$(get_timestamp)

    local temp_file=$(mktemp)
    jq --arg id "$handoff_id" \
       --arg ts "$timestamp" \
       --arg responder "$responder" \
       --arg feedback "$feedback" \
       --arg action "$action_taken" '
        .handoffs |= map(
            if .id == $id then
                .status = "responded" |
                .response.respondedAt = $ts |
                .response.responder = $responder |
                .response.feedback = $feedback |
                .response.actionTaken = $action
            else
                .
            end
        )
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"

    echo -e "${GREEN}✓ Recorded response for handoff $handoff_id${NC}"
}

# Update Roger activity
update_roger_activity() {
    local channel="${1:-unknown}"
    local activity_type="${2:-message}"
    local timestamp=$(get_timestamp)

    # Update activity cache
    cat > "$ROGER_ACTIVITY_FILE" << EOF
{
  "lastActivity": "$timestamp",
  "activityType": "$activity_type",
  "channel": "$channel",
  "cachedAt": "$timestamp"
}
EOF

    # Update coordination log
    local temp_file=$(mktemp)
    jq --arg ts "$timestamp" --arg activity "$activity_type" '
        .rogerActivity.lastSeen = $ts |
        .rogerActivity.status = "active" |
        .rogerActivity.minutesIdle = 0 |
        .rogerActivity.lastActivityType = $activity
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"
}

# Sync Roger activity from OpenClaw sessions_list
# Note: This requires the node script walter-sync-activity.js to process session data
sync_from_openclaw() {
    local timestamp=$(get_timestamp)
    
    # The actual session query must be done via OpenClaw tool context
    # This function reads from the cache that should be updated by:
    # 1. A cron job that runs sessions_list and pipes to walter-sync-activity.js
    # 2. Manual update via: openclaw sessions list --active-minutes 60 | node walter-sync-activity.js
    
    # Check if we have recent cached data
    if [[ -f "$ROGER_ACTIVITY_FILE" ]]; then
        local cached_time=$(jq -r '.cachedAt // empty' "$ROGER_ACTIVITY_FILE")
        if [[ -n "$cached_time" && "$cached_time" != "null" ]]; then
            # Check if cache is fresh (less than 5 minutes old)
            local cache_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${cached_time:0:19}" +%s 2>/dev/null || date -d "$cached_time" +%s 2>/dev/null || echo "0")
            local now_epoch=$(get_epoch)
            local cache_age=$(( (now_epoch - cache_epoch) / 60 ))
            
            if [[ $cache_age -lt 5 ]]; then
                # Cache is fresh, use it
                local status=$(jq -r '.status // "unknown"' "$ROGER_ACTIVITY_FILE")
                local minutes=$(jq -r '.minutesIdle // 0' "$ROGER_ACTIVITY_FILE")
                echo -e "${GREEN}✓ Using fresh cache: $status (${minutes}m idle, ${cache_age}m ago)${NC}" >&2
                return 0
            fi
        fi
    fi
    
    # Cache is stale or missing - update coordination log to reflect unknown status
    local temp_file=$(mktemp)
    jq --arg ts "$timestamp" '
        .rogerActivity.status = "unknown" |
        .rogerActivity.lastSyncAttempt = $ts
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"
    
    echo -e "${YELLOW}⚠ Cache stale. Run: openclaw sessions list --active-minutes 60 | node $SCRIPT_DIR/walter-sync-activity.js${NC}" >&2
    return 1
}

# Check Roger idle status
check_idle_status() {
    # First try to sync from OpenClaw
    sync_from_openclaw >/dev/null 2>&1
    
    local config=$(cat "$CONFIG_FILE")
    local idle_threshold=$(echo "$config" | jq -r '.idleThresholdMinutes')
    
    local last_activity=$(jq -r '.rogerActivity.lastSeen // empty' "$LOG_FILE")
    
    if [[ -z "$last_activity" || "$last_activity" == "null" ]]; then
        echo "unknown"
        return
    fi

    local last_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$last_activity" +%s 2>/dev/null || date -d "$last_activity" +%s 2>/dev/null || echo "0")
    local now_epoch=$(get_epoch)
    local minutes_idle=$(( (now_epoch - last_epoch) / 60 ))

    # Update minutes idle in log
    local temp_file=$(mktemp)
    jq --argjson minutes "$minutes_idle" '
        .rogerActivity.minutesIdle = $minutes
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"

    if [[ $minutes_idle -ge $idle_threshold ]]; then
        echo "idle:$minutes_idle"
    else
        echo "active:$minutes_idle"
    fi
}

# Add autonomous research task
add_research_task() {
    local type="$1"
    local description="$2"
    local target="${3:-}"
    local priority="${4:-normal}"
    local timestamp=$(get_timestamp)
    local task_id="research-$(date +%s)"

    local entry=$(cat << EOF
{
  "id": "$task_id",
  "timestamp": "$timestamp",
  "type": "$type",
  "description": "$description",
  "target": "$target",
  "priority": "$priority",
  "status": "queued",
  "startedAt": "",
  "completedAt": "",
  "outputFile": ""
}
EOF
)

    local temp_file=$(mktemp)
    jq --argjson newEntry "$entry" --arg ts "$timestamp" '
        .autonomousQueue += [$newEntry] |
        .lastUpdated = $ts
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"

    echo -e "${GREEN}✓ Added research task: $description${NC}"
    echo "  ID: $task_id"
    echo "  Type: $type"
    echo "  Priority: $priority"
}

# Get next research task
get_next_task() {
    local queued_tasks=$(jq '[.autonomousQueue[] | select(.status == "queued")] | sort_by(.priority) | sort_by(.timestamp)' "$LOG_FILE")
    
    if [[ "$queued_tasks" == "[]" || -z "$queued_tasks" ]]; then
        echo ""
        return
    fi

    echo "$queued_tasks" | jq -r '.[0] | @json'
}

# Mark task started
mark_task_started() {
    local task_id="$1"
    local timestamp=$(get_timestamp)

    local temp_file=$(mktemp)
    jq --arg id "$task_id" --arg ts "$timestamp" '
        .autonomousQueue |= map(
            if .id == $id then
                .status = "in_progress" |
                .startedAt = $ts
            else
                .
            end
        )
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"
}

# Mark task completed
mark_task_completed() {
    local task_id="$1"
    local output_file="$2"
    local timestamp=$(get_timestamp)

    local temp_file=$(mktemp)
    jq --arg id "$task_id" --arg ts "$timestamp" --arg output "$output_file" '
        .autonomousQueue |= map(
            if .id == $id then
                .status = "completed" |
                .completedAt = $ts |
                .outputFile = $output
            else
                .
            end
        )
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"
}

# Check for escalations
check_escalations() {
    local config=$(cat "$CONFIG_FILE")
    local escalation_threshold=$(echo "$config" | jq -r '.escalationThresholdHours')
    local now_epoch=$(get_epoch)

    local pending_handoffs=$(jq -r --argjson threshold "$escalation_threshold" --argjson now "$now_epoch" '
        [.handoffs[] | select(.status == "pending" and .requiresResponse == true)] |
        map(select((($now - (.epoch // 0)) / 3600) > $threshold))
    ' "$LOG_FILE")

    local count=$(echo "$pending_handoffs" | jq 'length')
    
    if [[ "$count" -gt 0 ]]; then
        echo -e "${YELLOW}⚠ $count handoffs require escalation${NC}"
        echo "$pending_handoffs" | jq -r '.[] | "  - \(.id): \(.description) (\((now - .epoch) / 3600 | floor)h ago)"'
        return 1
    fi

    return 0
}

# Calculate metrics
calculate_metrics() {
    local total=$(jq '[.handoffs[]] | length' "$LOG_FILE")
    local responded=$(jq '[.handoffs[] | select(.status == "responded")] | length' "$LOG_FILE")
    local pending=$(jq '[.handoffs[] | select(.status == "pending" and .requiresResponse == true)] | length' "$LOG_FILE")
    
    local response_rate=0
    if [[ $total -gt 0 ]]; then
        response_rate=$(( responded * 100 / total ))
    fi

    # Calculate avg response time
    local avg_response=$(jq -r '
        [.handoffs[] | select(.status == "responded" and .response.respondedAt != "")] |
        map((.response.respondedAt | fromdateiso8601) - (.timestamp | fromdateiso8601)) |
        if length > 0 then (add / length / 60) else 0 end
    ' "$LOG_FILE" 2>/dev/null || echo "0")

    # Update metrics
    local temp_file=$(mktemp)
    jq --argjson total "$total" \
       --argjson responded "$responded" \
       --argjson rate "$response_rate" \
       --argjson avg "$avg_response" '
        .metrics.totalHandoffs = $total |
        .metrics.responseRate = $rate |
        .metrics.avgResponseTimeMinutes = $avg
    ' "$LOG_FILE" > "$temp_file" && mv "$temp_file" "$LOG_FILE"

    echo "Total handoffs: $total"
    echo "Response rate: ${response_rate}%"
    echo "Pending responses: $pending"
    echo "Avg response time: ${avg_response} minutes"
}

# Dashboard view
dashboard() {
    local idle_status=$(check_idle_status)
    local idle_state=$(echo "$idle_status" | cut -d: -f1)
    local idle_minutes=$(echo "$idle_status" | cut -d: -f2)

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           WALTER-ROGER COORDINATION DASHBOARD                 ║"
    echo "╠════════════════════════════════════════════════════════════════╣"

    # Roger status
    if [[ "$idle_state" == "idle" ]]; then
        echo -e "║  Roger Status: ${YELLOW}IDLE${NC} (${idle_minutes}m)                                  ║"
    else
        echo -e "║  Roger Status: ${GREEN}ACTIVE${NC} (${idle_minutes}m ago)                              ║"
    fi

    # Pending handoffs
    local pending=$(jq '[.handoffs[] | select(.status == "pending" and .requiresResponse == true)] | length' "$LOG_FILE")
    echo "║  Pending Handoffs: $pending                                          ║"

    # Research queue
    local queued=$(jq '[.autonomousQueue[] | select(.status == "queued")] | length' "$LOG_FILE")
    local in_progress=$(jq '[.autonomousQueue[] | select(.status == "in_progress")] | length' "$LOG_FILE")
    echo "║  Research Queue: $queued queued, $in_progress in progress                    ║"

    # Metrics
    local response_rate=$(jq -r '.metrics.responseRate // 0' "$LOG_FILE")
    echo "║  Response Rate: ${response_rate}%                                          ║"

    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║  Recent Handoffs:                                              ║"
    jq -r '.handoffs[-3:] | reverse | .[] | 
        "║    • " + .timestamp[:10] + " " + .timestamp[11:16] + " | " + 
        (.status | if . == "responded" then "✓" elif . == "pending" then "⏳" else "?" end) + 
        " | " + (.description | if length > 35 then .[:35] + "..." else . end)' "$LOG_FILE" 2>/dev/null | 
        while read line; do
            printf "%-65s║\n" "$line"
        done

    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║  Next Research Task:                                             ║"
    local next_task=$(get_next_task)
    if [[ -z "$next_task" || "$next_task" == "null" ]]; then
        echo "║    (none queued)                                               ║"
    else
        local task_desc=$(echo "$next_task" | jq -r '.description')
        local task_type=$(echo "$next_task" | jq -r '.type')
        printf "║    • [%s] %s\n" "$task_type" "${task_desc:0:50}"
    fi

    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
}

# Command handler
case "${1:-}" in
    init)
        init
        echo -e "${GREEN}Walter-Roger Coordination Monitor initialized${NC}"
        ;;
    handoff)
        log_handoff "$2" "$3" "${4:-true}" "${5:-normal}"
        ;;
    respond)
        record_response "$2" "$3" "$4" "${5:-}"
        ;;
    activity)
        update_roger_activity "$2" "${3:-message}"
        ;;
    status)
        check_idle_status
        ;;
    add-task)
        add_research_task "$2" "$3" "${4:-}" "${5:-normal}"
        ;;
    start-task)
        mark_task_started "$2"
        ;;
    complete-task)
        mark_task_completed "$2" "$3"
        ;;
    next-task)
        get_next_task | jq -r '.id // "No tasks queued"'
        ;;
    check-escalate)
        check_escalations
        ;;
    sync)
        sync_from_openclaw
        ;;
    metrics)
        calculate_metrics
        ;;
    dashboard|dash)
        dashboard
        ;;
    help|--help|-h)
        echo "Walter-Roger Coordination Monitor"
        echo ""
        echo "Commands:"
        echo "  init                           - Initialize monitor"
        echo "  dashboard                      - Show coordination dashboard"
        echo "  handoff <file> <desc> [resp]   - Log handoff to Roger"
        echo "  respond <id> <who> <feedback>  - Record response"
        echo "  activity <channel> [type]      - Record Roger activity"
        echo "  status                         - Check Roger idle status"
        echo "  add-task <type> <desc> [tgt]   - Add research task"
        echo "  start-task <id>                - Mark task started"
        echo "  complete-task <id> <output>    - Mark task completed"
        echo "  next-task                      - Get next queued task"
        echo "  check-escalate                 - Check for escalations"
        echo "  metrics                        - Calculate coordination metrics"
        echo ""
        echo "Examples:"
        echo "  ./walter-coordination-monitor.sh handoff handoff.json "Build X analysis" true"
        echo "  ./walter-coordination-monitor.sh activity telegram message"
        echo "  ./walter-coordination-monitor.sh add-task protocol_analysis "Analyze Base L2 upgrades""
        echo "  ./walter-coordination-monitor.sh dashboard"
        ;;
    *)
        init
        dashboard
        ;;
esac
