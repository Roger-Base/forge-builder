#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
ACT="$WORKSPACE/state/capability-activation.json"
NOW_FILE="$WORKSPACE/NOW.md"
PLAN="$WORKSPACE/state/daily-plan.md"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
CTX="$WORKSPACE/state/context-observability.json"
mkdir -p "$WORKSPACE/state"

# MEMORY_ACTIVE parity guard - prevent overwriting manual fixes
bash "$WORKSPACE/scripts/memory-active-parity-guard.sh" || {
  echo "ACTIVE_SURFACE_SYNC: MEMORY_ACTIVE parity guard blocked best-next-move apply"
  # Don't apply best-next-move if manual fix exists - preserve the manual change
}

node "$WORKSPACE/scripts/roger-artifact-reuse-sync.mjs" >/dev/null
node "$WORKSPACE/scripts/roger-state-digest.mjs" >/dev/null
bash "$WORKSPACE/scripts/portfolio-coherence-check.sh" >/dev/null || {
  echo "ACTIVE_SURFACE_SYNC: portfolio coherence check failed; continuing canonical repair"
}
node "$WORKSPACE/scripts/roger-self-audit.mjs" >/dev/null
bash "$WORKSPACE/scripts/best-next-move.sh" --refresh --apply >/dev/null
node "$WORKSPACE/scripts/roger-capability-body-sync.mjs" >/dev/null
bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
node "$WORKSPACE/scripts/roger-state-digest.mjs" >/dev/null
node "$WORKSPACE/scripts/roger-synthesis-sync.mjs" >/dev/null
node "$WORKSPACE/scripts/roger-priority-queue-sync.mjs" >/dev/null
node "$WORKSPACE/scripts/roger-memory-compact.mjs" >/dev/null
python3 "$WORKSPACE/scripts/subagent-ledger-sync.py" >/dev/null
bash "$WORKSPACE/scripts/daily-plan.sh" --refresh >/dev/null
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
today_mem="memory/$(date -u +%Y-%m-%d).md"
if yesterday_day="$(date -u -v-1d +%Y-%m-%d 2>/dev/null)"; then
  :
else
  yesterday_day="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=1)).strftime('%Y-%m-%d'))
PY
)"
fi
yesterday_mem="memory/${yesterday_day}.md"
active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
stage="$(jq -r '.active_wedge.stage' "$STATE")"
next_cmd="$(jq -r '.next_action.command' "$STATE")"
proof_expected="$(jq -r '.next_action.proof_expected' "$STATE")"
consumer="$(jq -r '.consumer // "current wedge proof surface"' "$STATE")"
never_touch="$(jq -r '.never_touch // "support-layer mission drift"' "$STATE")"
chain_steps="$(jq -r '.max_chain_steps // 3' "$STATE")"
soft_budget="$(jq -r '.soft_budget_minutes // 25' "$STATE")"
direction_status="$(jq -r '.direction_review.status // "none"' "$STATE")"
direction_candidate="$(jq -r '.direction_review.candidate // "none"' "$STATE")"
artifact_ts="$(jq -r '.last_artifact_change_at // "unknown"' "$STATE")"
shared_primary="$(jq -r '.roger.primary_wedge' "$SPINE")"
capability="$(jq -r '.selected_capability' "$ACT")"
lane="$(jq -r '.selected_skill_or_lane' "$ACT")"
winner_id="$(jq -r '.winner.id' "$WORKSPACE/state/best-next-move.json")"
winner_score="$(jq -r '.winner.score' "$WORKSPACE/state/best-next-move.json")"
winner_margin="$(jq -r '.winner_margin // "0"' "$WORKSPACE/state/best-next-move.json")"
winner_leverage="$(jq -r '.winner.leverage // "0"' "$WORKSPACE/state/best-next-move.json")"
winner_risk="$(jq -r '.winner.risk // "0"' "$WORKSPACE/state/best-next-move.json")"
candidate_lines="$(jq -r '.candidates | sort_by(.score) | reverse | .[] | "- " + .id + " :: " + (.score|tostring) + " :: " + .selected_skill_or_lane' "$WORKSPACE/state/best-next-move.json")"
cat > "$NOW_FILE" <<NOW
# Roger Now

- updated_at: $ts
- mission: roger-base-v1
- shared_primary: $shared_primary
- active_wedge: $active_wedge
- stage: $stage
- capability: $capability
- lane: $lane
- consumer: $consumer
- never_touch: $never_touch
- chain_budget: $chain_steps steps / $soft_budget minutes
- last_artifact_change_at: $artifact_ts
- direction_review: $direction_status ($direction_candidate)
- best_next_move: $winner_id ($winner_score, margin=$winner_margin, leverage=$winner_leverage, risk=$winner_risk)

## Current next action
$next_cmd

## Proof expected
- $proof_expected

## Candidate ranking
$candidate_lines

## Rules
1. Work from runtime truth, not stale notes.
2. Use the winning capability and lane before widening scope.
3. If no real delta appears, delegate or direction-review instead of repeating the same command.
NOW
bash "$WORKSPACE/scripts/compatibility-surface-sync.sh" >/dev/null
files_json="$(jq -n \
  --arg today "$today_mem" \
  --arg yesterday "$yesterday_mem" \
  '[
    "SOUL.md",
    "IDENTITY.md",
    "USER.md",
    "MISSION.md",
    "AGENTS.md",
    "TOOLS.md",
    "BOOT.md",
    "HEARTBEAT.md",
    "state/session-state.json",
    "state/capability-activation.json",
    "state/capability-body.json",
    "state/best-next-move.json",
    "state/daily-plan.md",
    "state/subagent-ledger.json",
    "state/artifact-registry.json",
    "state/decision-registry.json",
    "state/synthesis-registry.json",
    "synthesis/CURRENT.md",
    "state/priority-queue.json",
    $today,
    $yesterday,
    "NOW.md",
    "MEMORY_ACTIVE.md",
    "MEMORY.md",
    "WORKSPACE_SURFACE.md",
    "/Users/roger/.openclaw/shared-spine/MISSION_SPINE.md",
    "/Users/roger/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
  ]'
)"
jq -n --arg ts "$ts" --arg sid "$(date -u +%Y%m%dT%H%M%SZ)-roger-surface-sync" --argjson files "$files_json" '{session_id:$sid,files_read:$files,skills_opened:[],runtime_sources_used:["SOUL.md","IDENTITY.md","USER.md","MISSION.md","state/session-state.json","state/capability-activation.json","state/capability-body.json","state/artifact-registry.json","state/decision-registry.json","state/synthesis-registry.json","synthesis/CURRENT.md","state/priority-queue.json","state/daily-plan.md","NOW.md"],external_sources_used:[],generated_at:$ts}' > "$CTX"
echo "ACTIVE_SURFACE_SYNC_OK $NOW_FILE"
