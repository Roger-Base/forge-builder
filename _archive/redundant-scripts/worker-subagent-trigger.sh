#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
ROLE=""
TASK=""
TARGET_WEDGE=""
CONSUMER=""
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --task) TASK="${2:-}"; shift 2 ;;
    --target-wedge) TARGET_WEDGE="${2:-}"; shift 2 ;;
    --wedge) TARGET_WEDGE="${2:-}"; shift 2 ;;
    --goal) shift 2 ;;
    --consumer) CONSUMER="${2:-}"; shift 2 ;;
    --output) OUT="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -n "$ROLE" ]] || { echo "Missing --role" >&2; exit 1; }
[[ -n "$TASK" ]] || { echo "Missing --task" >&2; exit 1; }
[[ -n "$TARGET_WEDGE" ]] || { echo "Missing --target-wedge" >&2; exit 1; }
[[ -n "$CONSUMER" ]] || CONSUMER="Roger active wedge"
[[ -n "$OUT" ]] || OUT="$WORKSPACE/state/runtime/subagent-$ROLE-$(date -u +%Y%m%d-%H%M%S).md"

mkdir -p "$(dirname "$OUT")"
spawn_output="$(bash "$WORKSPACE/scripts/spawn-controller.sh" --role "$ROLE" --task "$TASK" --target-wedge "$TARGET_WEDGE" --consumer "$CONSUMER" --result-path "${OUT#$WORKSPACE/}")"
run_id="$(printf '%s\n' "$spawn_output" | sed -n 's/.*id=\([^ ]*\).*/\1/p')"

cat > "$OUT" <<EOF
# Worker Subagent Trigger

- generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- owner: Roger
- role: $ROLE
- target_wedge: $TARGET_WEDGE
- consumer: $CONSUMER
- run_id: $run_id

## Task
$TASK

## Spawn output
\`\`\`
$spawn_output
\`\`\`

## Contract
- This artifact exists so delegation is visible and canonical.
- If no follow-up merge or result appears, the subagent run remains incomplete.
EOF

echo "WORKER_SUBAGENT_TRIGGER_OK $OUT"
