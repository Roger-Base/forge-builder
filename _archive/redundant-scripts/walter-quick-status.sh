#!/bin/bash
# walter-quick-status.sh — One-command orientation for Walter at session start
# Reads key state files and outputs a compact briefing.
# No args needed. Run standalone or source from a session startup.

set -euo pipefail

WORKSPACE="${WALTER_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state"
SCRIPTS="$WORKSPACE/scripts"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  WALTER QUICK STATUS  $NOW${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Cron jobs health ──────────────────────────────────────
echo -e "${BLUE}[CRON]${NC}"

# Note: cron binary not available in shell — use heartbeat output file as proxy
if [[ -f "$STATE/walter-heartbeat-output.json" ]]; then
  HB_TS=$(jq -r '.timestamp // empty' "$STATE/walter-heartbeat-output.json" 2>/dev/null | head -1 || echo "")
  if [[ -n "$HB_TS" && "$HB_TS" != "null" ]]; then
    # Calculate age of last heartbeat
    HB_EPOCH=$(date -d "$HB_TS" +%s 2>/dev/null) || \
    HB_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${HB_TS%:}" +%s 2>/dev/null) || \
    HB_EPOCH=0
    HB_AGE_S=$(( $(date +%s) - HB_EPOCH ))
    HB_AGE_M=$(( HB_AGE_S / 60 ))
    if (( HB_AGE_S < 3600 )) 2>/dev/null; then
      echo -e "  Heartbeat:  ${GREEN}OK${NC} (ran ${HB_AGE_M}m ago)"
    elif (( HB_AGE_S < 7200 )) 2>/dev/null; then
      echo -e "  Heartbeat:  ${YELLOW}stale${NC} (ran ${HB_AGE_M}m ago)"
    else
      echo -e "  Heartbeat:  ${RED}stale${NC} (ran ${HB_AGE_M}m ago — $((HB_AGE_M/60))h)"
    fi
  else
    echo -e "  Heartbeat:  ${YELLOW}no timestamp in output${NC}"
  fi
else
  echo -e "  Heartbeat:  ${RED}no heartbeat output file${NC}"
fi
echo ""

# ── 2. Active wedge ──────────────────────────────────────────
echo -e "${BLUE}[ACTIVE WEDGE]${NC}"
WEDGE=$(awk '/^## Active Wedge/{found=1; next} found && /^## /{exit} found' "$WORKSPACE/QUEUE.md" 2>/dev/null | head -3 | tr '\n' ' ' | sed 's/  */ /g' | xargs || echo "")
if [[ -n "$WEDGE" ]]; then
  WEDGE_STAGE=$(grep -A2 "^## Active Wedge" "$WORKSPACE/QUEUE.md" 2>/dev/null | grep "Stage:" | head -1 | sed 's/.*Stage: //' | tr -d ' ' | xargs || echo "unknown")
  echo -e "  $WEDGE  ${YELLOW}[$WEDGE_STAGE]${NC}"
else
  echo -e "  ${YELLOW}No active wedge defined${NC}"
fi
echo ""

# ── 3. Queue summary ────────────────────────────────────────
echo -e "${BLUE}[QUEUE]${NC}"
P0=$(grep -c "^\- \[ \].*P0" "$WORKSPACE/QUEUE.md" 2>/dev/null) || P0=0
P1=$(grep -c "^\- \[ \].*P1" "$WORKSPACE/QUEUE.md" 2>/dev/null) || P1=0
P2=$(grep -c "^\- \[ \].*P2" "$WORKSPACE/QUEUE.md" 2>/dev/null) || P2=0
DONE=$(grep -c "^\- \[x\]" "$WORKSPACE/QUEUE.md" 2>/dev/null) || DONE=0
echo -e "  P0: ${RED}${P0:-0}${NC}  P1: ${YELLOW}${P1:-0}${NC}  P2: ${P2:-0}  Done: ${GREEN}${DONE:-0}${NC}"

# Show next ready P1 task
NEXT_TASK=$(grep "^\- \[ \]" "$WORKSPACE/QUEUE.md" 2>/dev/null | grep "P1" | head -1 | sed 's/^\- \[ \] //' | cut -d: -f1 | tr -d '*-' | xargs || echo "")
if [[ -n "$NEXT_TASK" ]]; then
  echo -e "  Next: $NEXT_TASK"
fi
echo ""

# ── 4. Feedback loop status ─────────────────────────────────
echo -e "${BLUE}[LOOP]${NC}"

# Stage 1: Mismatch detector
if [[ -f "$SCRIPTS/walter-mismatch-detector.sh" ]]; then
  MISMATCH_COUNT=$(wc -l < "$STATE/walter-mismatch-log.jsonl" 2>/dev/null | awk '{print $1}' || echo "0")
  LAST_MISMATCH=$(tail -1 "$STATE/walter-mismatch-log.jsonl" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null || echo "")
  echo -e "  Detect:   ${GREEN}exists${NC}  mismatches: ${MISMATCH_COUNT:-0}  last: ${LAST_MISMATCH:-none}"
else
  echo -e "  Detect:   ${RED}MISSING${NC}"
fi

# Stage 2: Correction router
if [[ -f "$SCRIPTS/walter-correction-router.sh" ]]; then
  echo -e "  Route:    ${GREEN}exists${NC}"
else
  echo -e "  Route:    ${RED}MISSING${NC}"
fi

# Stage 3: Heartbeat executor
if [[ -f "$STATE/walter-heartbeat-output.json" ]]; then
  HB_TS=$(jq -r '.timestamp // empty' "$STATE/walter-heartbeat-output.json" 2>/dev/null | head -1 || echo "")
  HB_TASK=$(jq -r '.selection.task // empty' "$STATE/walter-heartbeat-output.json" 2>/dev/null | head -c 60 | xargs || echo "")
  HB_ACTION=$(jq -r '.action // empty' "$STATE/walter-heartbeat-output.json" 2>/dev/null | head -1 || echo "")
  if [[ -n "$HB_TS" && "$HB_TS" != "null" ]]; then
    echo -e "  Execute:  ${GREEN}$HB_TS${NC} [$HB_ACTION] — ${HB_TASK:-none}"
  else
    echo -e "  Execute:  ${YELLOW}no recent output${NC}"
  fi
else
  echo -e "  Execute:  ${RED}no heartbeat output file${NC}"
fi

# Stage 4: Verifier
if [[ -f "$SCRIPTS/walter-correction-verifier.sh" ]]; then
  VERIFY_COUNT=$(wc -l < "$STATE/walter-verification-log.jsonl" 2>/dev/null | awk '{print $1}' || echo "0")
  LAST_VERIFY=$(tail -1 "$STATE/walter-verification-log.jsonl" 2>/dev/null | jq -r '.timestamp // empty' 2>/dev/null | head -1 || echo "")

  # Check if verifier is called anywhere (look for the verifier being invoked)
  VERIFER_CALLED=$(grep -l "walter-correction-verifier\|correction-verifier" "$WORKSPACE"/scripts/walter-*.sh 2>/dev/null | grep -v "walter-correction-verifier.sh" | wc -l | awk '{print $1}' || echo "0")
  if [[ "$VERIFER_CALLED" -gt 0 ]] 2>/dev/null; then
    echo -e "  Verify:   ${GREEN}exists${NC}  verified: ${VERIFY_COUNT:-0}  last: ${LAST_VERIFY:-none}  ${GREEN}[auto-triggered]${NC}"
  else
    echo -e "  Verify:   ${YELLOW}exists (NOT auto-triggered)${NC}  verified: ${VERIFY_COUNT:-0}"
  fi
else
  echo -e "  Verify:   ${RED}MISSING${NC}"
fi

# Fix outcomes pending verification
if [[ -f "$STATE/walter-fix-outcomes.jsonl" ]]; then
  PENDING_FIXES=$(jq -r 'select(.status == "pending") | .lrn' "$STATE/walter-fix-outcomes.jsonl" 2>/dev/null | grep -c . || true)
  if [[ "$PENDING_FIXES" -gt 0 ]] 2>/dev/null; then
    echo -e "  ${YELLOW}WARNING: $PENDING_FIXES fix outcome(s) pending verification${NC}"
  fi
fi
echo ""

# ── 5. Current weakness (from self-eval) ────────────────────
echo -e "${BLUE}[SELF-EVAL — current weakness]${NC}"
CURRENT_WEAK=$(jq -r '.thisCycleWeakness.weakness // empty' "$STATE/walter-self-evaluation.json" 2>/dev/null | head -c 120 | xargs || echo "")
WEAK_STATUS=$(jq -r '.thisCycleWeakness.status // empty' "$STATE/walter-self-evaluation.json" 2>/dev/null | xargs || echo "")
WEAK_AGE=$(jq -r '.thisCycleWeakness.identifiedAt // empty' "$STATE/walter-self-evaluation.json" 2>/dev/null | xargs || echo "")
if [[ -n "$CURRENT_WEAK" ]]; then
  echo -e "  $CURRENT_WEAK"
  echo -e "  Status: ${YELLOW}${WEAK_STATUS}${NC}  identified: ${WEAK_AGE}"
else
  echo -e "  ${GREEN}No active weakness recorded${NC}"
fi
echo ""

# ── 6. Recent sessions (from backups) ───────────────────────
echo -e "${BLUE}[RECENT SESSIONS]${NC}"
for backup in $(ls -t "$STATE"/session-state.json.bak* 2>/dev/null | head -3); do
  TS=$(echo "$backup" | grep -oE '[0-9]{8}-[0-9]{6}' | tail -1)
  if [[ -n "$TS" ]]; then
    AT=$(jq -r '.active_thread // empty' "$backup" 2>/dev/null | head -c 80 | xargs || echo "")
    echo -e "  ${GREEN}$TS${NC}: ${AT:-—}"
  fi
done
if [[ ! -f "$STATE/session-state.json" ]]; then
  echo -e "  ${YELLOW}No session-state.json found${NC}"
fi
echo ""

# ── 7. Warnings ─────────────────────────────────────────────
echo -e "${BLUE}[WARNINGS]${NC}"
WARN_COUNT=0

# Queue empty warning
if [[ "${P1:-0}" -eq 0 ]] && [[ "${P0:-0}" -eq 0 ]] 2>/dev/null; then
  echo -e "  ${YELLOW}Queue is empty — no P0/P1 tasks${NC}"
  WARN_COUNT=$((WARN_COUNT+1))
fi

# Verifier not auto-triggered
if [[ -f "$SCRIPTS/walter-correction-verifier.sh" ]] && [[ "${VERIFER_CALLED:-0}" -eq 0 ]] 2>/dev/null; then
  echo -e "  ${YELLOW}Verifier exists but has no automatic trigger — loop stays open${NC}"
  WARN_COUNT=$((WARN_COUNT+1))
fi

# Self-eval stale
SELF_EVAL_TS=$(jq -r '.lastUpdated // empty' "$STATE/walter-self-evaluation.json" 2>/dev/null | head -1 | xargs || echo "")
if [[ -n "$SELF_EVAL_TS" && "$SELF_EVAL_TS" != "null" ]]; then
  # Try Linux date, then macOS
  EVAL_EPOCH=$(date -d "$SELF_EVAL_TS" +%s 2>/dev/null) || \
  EVAL_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${SELF_EVAL_TS%:}" +%s 2>/dev/null) || \
  EVAL_EPOCH=0
  if [[ -n "$EVAL_EPOCH" && "$EVAL_EPOCH" -gt 0 ]] 2>/dev/null; then
    AGE_S=$(( $(date +%s) - EVAL_EPOCH ))
    if (( AGE_S > 14400 )) 2>/dev/null; then  # 4 hours
      echo -e "  ${YELLOW}Self-eval is $((AGE_S/3600))h old${NC}"
      WARN_COUNT=$((WARN_COUNT+1))
    fi
  fi
fi

if (( WARN_COUNT == 0 )); then
  echo -e "  ${GREEN}No warnings${NC}"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo ""
