#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE="$WORKSPACE/state/session-state.json"
BEST="$WORKSPACE/state/best-next-move.json"
OUTDIR="$WORKSPACE/state/runtime"
MODE="execute"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

mkdir -p "$OUTDIR"
TS="$(date -u +%Y%m%d-%H%M%S)"
REPORT="$OUTDIR/roger-workloop-$MODE-$TS.md"

worker_runs_for_wedge() {
  local wedge="$1"
  jq --arg wedge "$wedge" '[.runs[] | select(.owner=="Roger" and .target_wedge==$wedge and .type=="worker" and (.status=="requested" or .status=="running" or .status=="completed" or .status=="merged"))] | length' \
    "$WORKSPACE/state/subagent-ledger.json" 2>/dev/null || echo 0
}

case "$MODE" in
  guard)
    bash "$WORKSPACE/scripts/session-start-60s.sh" >/dev/null
    bash "$WORKSPACE/scripts/runtime-enforcer.sh" >/dev/null
    bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
    ;;
  plan)
    bash "$WORKSPACE/scripts/daily-plan-guard.sh" >/dev/null
    bash "$WORKSPACE/scripts/best-next-move.sh" --refresh --apply >/dev/null
    bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
    bash "$WORKSPACE/scripts/daily-plan.sh" >/dev/null
    bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
    ;;
  improve)
    bash "$WORKSPACE/scripts/best-next-move.sh" --refresh --apply >/dev/null
    bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
    bash "$WORKSPACE/scripts/runtime-enforcer.sh" >/dev/null
    bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
    ;;
  execute)
    bash "$WORKSPACE/scripts/daily-plan-guard.sh" >/dev/null
    bash "$WORKSPACE/scripts/best-next-move.sh" --refresh --apply >/dev/null
    bash "$WORKSPACE/scripts/capability-activation.sh" --ensure >/dev/null
    bash "$WORKSPACE/scripts/active-surface-sync.sh" >/dev/null
    active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
    winner_id="$(jq -r '.winner.id' "$BEST")"
    second_id="$(jq -r '.candidates | sort_by(.score) | reverse | .[1].id // empty' "$BEST")"
    winner_margin="$(jq -r '.winner_margin // 0' "$BEST")"
    artifact_age="$(jq -r '.last_artifact_age_seconds // 0' "$BEST")"
    worker_count="$(worker_runs_for_wedge "$active_wedge")"
    worker_triggered="false"
    if [[ "$winner_id" == "delegated_worker" ]] && [[ "$worker_count" -eq 0 ]]; then
      bash "$WORKSPACE/scripts/worker-subagent-trigger.sh" \
        --role verifier \
        --target-wedge "$active_wedge" \
        --consumer "Roger active wedge" \
        --task "Verify proof surface, GitHub truth, and readiness gaps for $active_wedge before the next public or maintenance move." \
        --output "$OUTDIR/subagent-verifier-$TS.md" >/dev/null
      worker_triggered="true"
    elif [[ "$second_id" == "delegated_worker" ]] && [[ "${winner_margin:-0}" =~ ^[0-9]+$ ]] && (( winner_margin <= 3 )) && (( artifact_age >= 14400 )) && [[ "$worker_count" -eq 0 ]]; then
      bash "$WORKSPACE/scripts/worker-subagent-trigger.sh" \
        --role verifier \
        --target-wedge "$active_wedge" \
        --consumer "Roger active wedge" \
        --task "Run a bounded verification pass because the current winner is only marginally stronger than delegation and the wedge has been stale for more than four hours." \
        --output "$OUTDIR/subagent-verifier-$TS.md" >/dev/null
      worker_triggered="true"
    fi
    python3 "$WORKSPACE/scripts/subagent-ledger-sync.py" >/dev/null
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac

active_wedge="$(jq -r '.active_wedge.id' "$STATE")"
stage="$(jq -r '.active_wedge.stage' "$STATE")"
next_type="$(jq -r '.next_action.type' "$STATE")"
next_cmd="$(jq -r '.next_action.command' "$STATE")"
capability="$(jq -r '.selected_capability // empty' "$WORKSPACE/state/capability-activation.json" 2>/dev/null || true)"
lane="$(jq -r '.selected_skill_or_lane // empty' "$WORKSPACE/state/capability-activation.json" 2>/dev/null || true)"
consumer="$(jq -r '.consumer // empty' "$WORKSPACE/state/capability-activation.json" 2>/dev/null || true)"
winner_margin="$(jq -r '.winner_margin // 0' "$BEST" 2>/dev/null || echo 0)"

cat > "$REPORT" <<EOF
# Roger Workloop

- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- mode: $MODE
- active_wedge: $active_wedge
- stage: $stage
- chosen_capability: $capability
- selected_lane: $lane
- consumer: $consumer
- next_action_type: $next_type
- next_action: $next_cmd
- winner_margin: $winner_margin

## Contract
- This loop exists to keep Roger in one coherent builder rhythm.
- It may plan, select leverage, trigger bounded worker delegation, and sync the active surface.
- It must not silently rewrite portfolio truth or widen scope.
EOF

echo "ROGER_WORKLOOP_OK $REPORT"
