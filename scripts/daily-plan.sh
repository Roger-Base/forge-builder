#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
OUT="$WORKSPACE/state/daily-plan.md"
ACT="$WORKSPACE/state/capability-activation.json"
BEST="$WORKSPACE/state/best-next-move.json"
SPINE="$HOME/.openclaw/shared-spine/PORTFOLIO_LEDGER.json"
TODAY="$(date +%F)"
mkdir -p "$WORKSPACE/state"
bash "$WORKSPACE/scripts/best-next-move.sh" --refresh >/dev/null
bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
WEDGE="$(jq -r '.active_wedge.id' "$STATE")"
STAGE="$(jq -r '.active_wedge.stage' "$STATE")"
NEXT="$(jq -r '.next_action.command' "$STATE")"
ARTIFACT="$(jq -r '.last_artifact_change_at // "unknown"' "$STATE")"
PROOF="$(jq -r '.next_action.proof_expected // "real wedge delta"' "$STATE")"
PRIMARY="$(jq -r '.roger.primary_wedge // "agent_security_scanner"' "$SPINE")"
RESERVE="$(jq -r '.roger.reserve_wedge // "base_account_miniapp_probe"' "$SPINE")"
CAPABILITY="$(jq -r '.selected_capability' "$ACT")"
LANE="$(jq -r '.selected_skill_or_lane' "$ACT")"
CONSUMER="$(jq -r '.consumer' "$ACT")"
NEVER_TOUCH="$(jq -r '.never_touch' "$ACT")"
INTENT="$(jq -r '.intent' "$ACT")"
DIR_REQUIRED="$(jq -r '.direction_review.required // false' "$STATE")"
DIR_STATUS="$(jq -r '.direction_review.status // "none"' "$STATE")"
DIR_CANDIDATE="$(jq -r '.direction_review.candidate // "none"' "$STATE")"
CHAIN_STEPS="$(jq -r '.max_chain_steps // 3' "$STATE")"
SOFT_BUDGET="$(jq -r '.soft_budget_minutes // 25' "$STATE")"
WINNER_ID="$(jq -r '.winner.id' "$BEST")"
WINNER_SCORE="$(jq -r '.winner.score' "$BEST")"
WINNER_MARGIN="$(jq -r '.winner_margin // "0"' "$BEST")"
CANDIDATES=()
while IFS= read -r line; do CANDIDATES+=("$line"); done < <(jq -r '.candidates | sort_by(.score) | reverse | .[] | .id + "|" + (.score|tostring) + "|" + (.leverage|tostring) + "|" + (.risk|tostring) + "|" + (.delegation_needed|tostring) + "|" + .consumer + "|" + .proof_expected' "$BEST")
TOP1="Advance the active wedge with a real artifact or proof delta."
TOP2="Use the selected capability and lane before widening scope."
TOP3="If the same artifact class repeats or the question broadens, delegate or direction-review immediately."
if [[ "$DIR_REQUIRED" == "true" ]]; then
  TOP1="Resolve the direction review for $DIR_CANDIDATE with keep/promote/nominate evidence."
  TOP2="Do not repeat the same sample/scan lane while direction review is pending."
  TOP3="If evidence is still broad, spawn a worker subagent and merge the result into the review artifact."
fi
cat > "$OUT" <<PLAN
# Daily Plan - $TODAY

- mission: roger-base-v1
- source_of_truth: state/session-state.json + shared-spine/PORTFOLIO_LEDGER.json + state/capability-activation.json
- active_wedge: $WEDGE
- stage: $STAGE
- shared_primary: $PRIMARY
- shared_reserve: $RESERVE
- direction_review_required: $DIR_REQUIRED
- direction_review_status: $DIR_STATUS
- direction_review_candidate: $DIR_CANDIDATE
- last_artifact_change_at: $ARTIFACT
- chosen_capability: $CAPABILITY
- selected_skill_or_lane: $LANE
- consumer: $CONSUMER
- never_touch: $NEVER_TOUCH
- chain_budget: $CHAIN_STEPS steps / $SOFT_BUDGET minutes
- best_next_move_winner: $WINNER_ID ($WINNER_SCORE, margin=$WINNER_MARGIN)
- canonical_next_action: $NEXT
- proof_expected: $PROOF

## Top 3
1. $TOP1
2. $TOP2
3. $TOP3

## Candidate ranking
1. ${CANDIDATES[0]//|/ :: }
2. ${CANDIDATES[1]//|/ :: }
3. ${CANDIDATES[2]//|/ :: }

## Mandatory delegation points
- Spawn scout when the question is broad or research-heavy.
- Spawn verifier when proof, links, readiness, or GitHub truth are the bottleneck.
- Spawn builder-spike when a bounded code/content delta can be isolated.
- If the same command or artifact class repeats twice without stage advance, delegation or replanning is mandatory.
- If the winner is delegated_worker, record the worker run before doing anything else.

## Execution spine
1. Orient on the active surface.
2. Activate the chosen capability and lane.
3. Execute 2-3 chained steps only if each unlocks the next on the same lane and the winning move still dominates.
4. Verify the resulting delta.
5. Route durable learning into MEMORY_ACTIVE.md, MEMORY.md, SKILLS.md, or shared pattern radar.

## Anti-drift
- daily-plan is derived, not portfolio authority.
- No silent wedge promotion.
- No Fundiora work in Roger's lane.
- No X/GitHub actions detached from proof.
- Intent for this pass: $INTENT.
PLAN
echo "DAILY_PLAN_OK $OUT"
