#!/bin/bash
# Agent Wake Briefing - Comprehensive status on wake-up or after stall
# Gives Roger everything he needs to get oriented in one view
# Usage: ./agent-wake-briefing.sh

set -e

WORKSPACE="$HOME/.openclaw/workspace"
STATE_FILE="$WORKSPACE/state/session-state.json"
PLAN_FILE="$WORKSPACE/state/daily-plan.md"
MEMORY_FILE="$WORKSPACE/memory/$(date +%Y-%m-%d).md"
WALLET_FILE="$HOME/.wallet/wallet.json"

# === URL REACHABILITY CHECK ===
check_url() {
    local url="$1"
    local timeout=3
    local status
    status=$(curl -o /dev/null -s -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        echo "✅"
    else
        echo "⚠️ ($status)"
    fi
}

echo "═══════════════════════════════════════════════════════════════"
echo "  🤖 ROGER BRIEFING - $(date '+%Y-%m-%d %H:%M')"
echo "═══════════════════════════════════════════════════════════════"

# === CURRENT STATE ===
echo ""
echo "📍 STATE"
echo "─────────────────────────────────────────────────────────────────"
MODE=$(jq -r '.mode // "unknown"' "$STATE_FILE")
STAGE=$(jq -r '.active_wedge.stage // .stage // "unknown"' "$STATE_FILE")
WEDGE=$(jq -r '.active_wedge.id // .portfolio.primary_id // "unknown"' "$STATE_FILE")
LAST_ACTION=$(jq -r '.last_action // "none"' "$STATE_FILE")
LAST_ACTION_AT=$(jq -r '.last_action_at // "unknown"' "$STATE_FILE")
LAST_SCORE=$(jq -r '.self_evaluation.last_score // "none"' "$STATE_FILE")

echo "Mode:      $MODE"
echo "Wedge:     $WEDGE"
echo "Stage:     $STAGE"
echo "Last:      $LAST_ACTION @ $LAST_ACTION_AT"
echo "Score:     $LAST_SCORE/30"

# === SELF-CHECK STATUS ===
echo ""
echo "⚡ HEALTH"
echo "─────────────────────────────────────────────────────────────────"
if [ -f "$WORKSPACE/state/.self-check-trigger" ]; then
    VERDICT=$(jq -r '.verdict // "unknown"' "$WORKSPACE/state/.self-check-trigger" 2>/dev/null)
    MINUTES=$(jq -r '.minutes_since_action // 0' "$WORKSPACE/state/.self-check-trigger" 2>/dev/null)
    echo "Status:    $VERDICT ($MINUTES min ago)"
else
    echo "Status:    UNKNOWN (no recent check)"
fi

# === DAILY PLAN ===
echo ""
echo "📋 TODAY'S PLAN"
echo "─────────────────────────────────────────────────────────────────"
if [ -f "$PLAN_FILE" ]; then
    # Extract key sections
    grep -A5 "Immediate Actions" "$PLAN_FILE" 2>/dev/null || echo "(no immediate actions)"
    echo ""
    grep -A3 "Proof Gap" "$PLAN_FILE" 2>/dev/null || echo "(no proof gap)"
else
    echo "(no daily plan)"
fi

# === WALLET STATUS ===
echo ""
echo "💰 WALLET"
echo "─────────────────────────────────────────────────────────────────"
if [ -f "$WALLET_FILE" ]; then
    ADDRESS=$(jq -r '.address // "unknown"' "$WALLET_FILE" 2>/dev/null)
    ETH_BALANCE=$(jq -r '.balance.ETH // "?"' "$WALLET_FILE" 2>/dev/null)
    echo "Address:   ${ADDRESS:0:6}...${ADDRESS: -4}"
    echo "ETH:       $ETH_BALANCE"
else
    echo "(no wallet file)"
fi

# === PROOF SURFACES ===
echo ""
echo "🌐 PROOF SURFACES"
echo "─────────────────────────────────────────────────────────────────"
PROOF_PATHS=$(jq -r '.proof_paths // []' "$STATE_FILE" 2>/dev/null)
if [ "$PROOF_PATHS" != "[]" ] && [ -n "$PROOF_PATHS" ]; then
    echo "$PROOF_PATHS" | jq -r '.[]' 2>/dev/null | while read -r path; do
        FULL_PATH="$WORKSPACE/$path"
        if [ -f "$FULL_PATH" ]; then
            # Extract URLs from the file
            URLS=$(grep -o 'https://[^ ]*' "$FULL_PATH" | head -3)
            if [ -n "$URLS" ]; then
                echo "  📄 $path"
                echo "$URLS" | while read -r url; do
                    STATUS=$(check_url "$url")
                    echo "      $STATUS $url"
                done
            else
                echo "  ⚠️  $path (no URLs found)"
            fi
        else
            echo "  ❌ $path (file missing)"
        fi
    done
else
    echo "(no proof paths configured)"
fi

# === GITHUB REPO STATUS ===
echo ""
echo "📦 GITHUB REPO"
echo "─────────────────────────────────────────────────────────────────"
cd "$WORKSPACE"
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
    STATUS=$(git status --porcelain 2>/dev/null | head -3 || echo "clean")
    LAST_COMMIT=$(git log -1 --format="%h %s" 2>/dev/null || echo "none")
    echo "Branch:    $BRANCH"
    echo "Status:    $STATUS"
    echo "Last:      $LAST_COMMIT"
    
    # Check if synced with remote
    if git rev-parse @{u} > /dev/null 2>&1; then
        BEHIND=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        AHEAD=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        echo "Remote:    $AHEAD ahead, $BEHIND behind"
    fi
else
    echo "(not a git repo)"
fi

# === RECURRING JOBS ===
echo ""
echo "🔄 CRON JOBS"
echo "─────────────────────────────────────────────────────────────────"
CRON_JOBS=$(openclaw cron list --json 2>/dev/null | jq -r '.jobs | length' 2>/dev/null || echo "0")
echo "Active jobs: $CRON_JOBS"
openclaw cron list --json 2>/dev/null | jq -r '.jobs[] | "  \(.name): \(.schedule.kind)"' 2>/dev/null | head -5 || echo "  (none)"

# === REVENUE SIGNALS ===
echo ""
echo "💸 REVENUE SIGNALS"
echo "─────────────────────────────────────────────────────────────────"
echo "Note: External revenue tracking requires external APIs"
echo "Action: Manually check Stripe dashboard, BaseScan, or ACP analytics"

# === SUPPORT LAYERS ===
echo ""
echo "🔧 SUPPORT LAYERS"
echo "─────────────────────────────────────────────────────────────────"
jq -r '.support_layers | to_entries | .[] | "\(.key): \(.value)"' "$STATE_FILE" 2>/dev/null || echo "(none)"

# === WHAT TO DO NEXT ===
echo ""
echo "🎯 NEXT ACTIONS"
echo "─────────────────────────────────────────────────────────────────"

# Determine what needs to happen based on stage
case "$STAGE" in
    "RESEARCH_PACKAGE")
        echo "1. Complete research packet"
        echo "2. Move to PROOF_SPEC when done"
        ;;
    "PROOF_SPEC")
        echo "1. Write proof specification"
        echo "2. Move to BUILD when spec approved"
        ;;
    "BUILD")
        echo "1. Build the artifact"
        echo "2. Verify it works locally"
        echo "3. Move to VERIFY when ready"
        ;;
    "VERIFY")
        echo "1. Verify against proof spec"
        echo "2. Check demo URLs work"
        echo "3. Move to DISTRIBUTE when verified"
        ;;
    "DISTRIBUTE")
        echo "1. Post to X/Twitter"
        echo "2. Update GitHub"
        echo "3. Verify public proof surfaces"
        echo "4. Move to LEARN when distributed"
        ;;
    "LEARN")
        echo "1. Collect feedback signal"
        echo "2. Document lessons"
        echo "3. Propose next direction"
        ;;
    *)
        echo "(stage: $STAGE - determine next step)"
        ;;
esac

# Check if stalled
if [ "$VERDICT" = "STALLED" ]; then
    echo ""
    echo "⚠️  WARNING: You are STALLED!"
    echo "   → Run: ./scripts/roger-daily-start.sh"
    echo "   → Or manually assess what's blocking you"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"

# Exit code: 0 = healthy, 1 = stalled
if [ "$VERDICT" = "STALLED" ]; then
    exit 1
fi
exit 0
