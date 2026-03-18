#!/bin/bash
# Walter Capability Dashboard - Quick overview of Walter's capabilities, missions, and health
# Usage: ./scripts/walter-capability-dashboard.sh [--json]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
STATE_DIR="$WORKSPACE_DIR/state"
OUTPUT_JSON=false

if [[ "$1" == "--json" ]]; then
    OUTPUT_JSON=true
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  WALTER CAPABILITY DASHBOARD"
echo "  Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Count and list Walter-specific scripts
echo "📁 WALTER SCRIPTS"
echo "─────────────────────────────────────────────────────────────────"
WALTER_SCRIPTS=$(ls -1 "$SCRIPT_DIR"/walter-*.sh 2>/dev/null || echo "")
SCRIPT_COUNT=0
if [[ -n "$WALTER_SCRIPTS" ]]; then
    while read -r script; do
        if [[ -x "$script" ]]; then
            NAME=$(basename "$script")
            # Get first line of description if exists
            DESC=$(head -5 "$script" | grep -E "^# " | head -1 | sed 's/^# //' || echo "No description")
            printf "  ✓ %-40s %s\n" "$NAME" "$DESC"
            ((SCRIPT_COUNT++))
        fi
    done <<< "$WALTER_SCRIPTS"
fi
echo "  Total: $SCRIPT_COUNT executable Walter scripts"
echo ""

# 2. Learning Mission Status
echo "🎯 LEARNING MISSIONS"
echo "─────────────────────────────────────────────────────────────────"
if [[ -f "$STATE_DIR/walter-self-evaluation.json" ]]; then
    if command -v jq &> /dev/null; then
        MISSION_NAME=$(jq -r '.learning_mission_this_cycle.mission_name // "none"' "$STATE_DIR/walter-self-evaluation.json")
        MISSION_STATUS=$(jq -r '.learning_mission_this_cycle.mission_execution_status // "unknown"' "$STATE_DIR/walter-self-evaluation.json")
        CURRENT_GAP=$(jq -r '.learning_mission_this_cycle.current_capability_gap // "none"' "$STATE_DIR/walter-self-evaluation.json")
        BOUNDED_DELIVERABLE=$(jq -r '.learning_mission_this_cycle.bounded_deliverable // "none"' "$STATE_DIR/walter-self-evaluation.json")
        
        echo "  Current Mission: $MISSION_NAME"
        echo "  Status: $MISSION_STATUS"
        echo ""
        echo "  Gap: ${CURRENT_GAP:0:60}..."
        echo "  Deliverable: ${BOUNDED_DELIVERABLE:0:60}..."
    else
        echo "  [jq not available - cannot parse learning mission]"
    fi
else
    echo "  [No self-evaluation file found]"
fi
echo ""

# 3. Fix Tracking Status
echo "🔧 TRACKED FIXES"
echo "─────────────────────────────────────────────────────────────────"
if [[ -f "$STATE_DIR/walter-fix-outcomes.jsonl" ]]; then
    if command -v jq &> /dev/null; then
        TOTAL_FIXES=$(jq -s 'length' "$STATE_DIR/walter-fix-outcomes.jsonl" 2>/dev/null || echo "0")
        VERIFIED_FIXES=$(jq -s '[.[] | select(.status == "verified")] | length' "$STATE_DIR/walter-fix-outcomes.jsonl" 2>/dev/null || echo "0")
        echo "  Total fixes tracked: $TOTAL_FIXES"
        echo "  Verified working: $VERIFIED_FIXES"
        echo ""
        echo "  Recent fixes:"
        jq -r '. | "    v\(.version): \(.weakness | .[0:50])... - \(.status)"' "$STATE_DIR/walter-fix-outcomes.jsonl" 2>/dev/null | tail -5
    else
        echo "  [jq not available]"
    fi
else
    echo "  [No fix outcomes file found]"
fi
echo ""

# 4. Health Check (run walter-health-monitor.sh if exists)
echo "💚 HEALTH CHECK"
echo "─────────────────────────────────────────────────────────────────"
if [[ -x "$SCRIPT_DIR/walter-health-monitor.sh" ]]; then
    HEALTH_OUTPUT=$("$SCRIPT_DIR/walter-health-monitor.sh" 2>&1 || echo "Health check script error")
    if echo "$HEALTH_OUTPUT" | grep -q "ERROR\|CRITICAL"; then
        echo "  ⚠️  Issues detected:"
        echo "$HEALTH_OUTPUT" | grep -E "ERROR|CRITICAL" | head -3 | sed 's/^/    /'
    else
        echo "  ✓ Health monitor reports OK"
    fi
else
    echo "  [No health monitor script]"
fi
echo ""

# 5. Diagnostic Script Status
echo "🔍 DIAGNOSTIC CAPABILITY"
echo "─────────────────────────────────────────────────────────────────"
if [[ -x "$SCRIPT_DIR/walter-diagnostic.sh" ]]; then
    echo "  ✓ Diagnostic script available"
    if [[ "$OUTPUT_JSON" == "false" ]]; then
        # Quick health score if jq available
        if command -v jq &> /dev/null && [[ -f "$STATE_DIR/walter-self-evaluation.json" ]]; then
            HEALTH_SCORE=$(jq -r '.health_score // "unknown"' "$STATE_DIR/walter-self-evaluation.json")
            echo "  Health score: $HEALTH_SCORE"
        fi
    fi
else
    echo "  ✗ No diagnostic script found"
fi
echo ""

# 6. Quick verification of recent fixes
echo "✅ FIX VERIFICATION SUMMARY"
echo "─────────────────────────────────────────────────────────────────"
VERIFY_COUNT=0
# Check that key scripts exist
for script in walter-diagnostic.sh walter-health-monitor.sh walter-capability-dashboard.sh; do
    if [[ -x "$SCRIPT_DIR/$script" ]]; then
        echo "  ✓ $script exists"
        ((VERIFY_COUNT++))
    fi
done
echo "  Verified: $VERIFY_COUNT/3 critical Walter scripts"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "  END OF DASHBOARD"
echo "═══════════════════════════════════════════════════════════════"

# Output JSON if requested
if [[ "$OUTPUT_JSON" == "true" ]]; then
    echo ""
    echo "---JSON OUTPUT---"
    jq -n \
        --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson script_count "$SCRIPT_COUNT" \
        --argjson verify_count "$VERIFY_COUNT" \
        '{
            timestamp: $timestamp,
            script_count: $script_count,
            verified_scripts: $verify_count,
            status: "dashboard_generated"
        }'
fi
