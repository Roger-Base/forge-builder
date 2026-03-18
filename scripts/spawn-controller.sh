#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
LEDGER="$WORKSPACE/state/subagent-ledger.json"
PENDING_TRIGGER="$WORKSPACE/state/.subagent-pending-trigger"
ROLE=""
TASK=""
TARGET_WEDGE=""
RESULT_PATH=""
OWNER="Roger"
CONSUMER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --task) TASK="${2:-}"; shift 2 ;;
    --target-wedge) TARGET_WEDGE="${2:-}"; shift 2 ;;
    --result-path) RESULT_PATH="${2:-}"; shift 2 ;;
    --owner) OWNER="${2:-}"; shift 2 ;;
    --consumer) CONSUMER="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$ROLE" in
  scout) TYPE="worker" ;;
  verifier) TYPE="worker" ;;
  builder-spike) TYPE="worker" ;;
  *) echo "Invalid Roger role: $ROLE" >&2; exit 1 ;;
esac

[[ -n "$TASK" ]] || { echo "Missing --task" >&2; exit 1; }
[[ -n "$TARGET_WEDGE" ]] || { echo "Missing --target-wedge" >&2; exit 1; }
[[ -n "$RESULT_PATH" ]] || RESULT_PATH="state/runtime/subagent-${ROLE}-$(date -u +%Y%m%d-%H%M%S).md"
[[ -n "$CONSUMER" ]] || CONSUMER="Roger active wedge"

# Initialize ledger if missing
[[ -f "$LEDGER" ]] || echo '{"version":"1.2","runs":[]}' > "$LEDGER"

owner_slug="$(printf '%s' "$OWNER" | tr '[:upper:]' '[:lower:]')"
run_id="${owner_slug}-${ROLE}-$(date -u +%Y%m%d%H%M%S)"
requested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Log the request with status=requested
jq --arg id "$run_id" --arg owner "$OWNER" --arg role "$ROLE" --arg type "$TYPE" --arg wedge "$TARGET_WEDGE" --arg task "$TASK" --arg result "$RESULT_PATH" --arg consumer "$CONSUMER" --arg requested_at "$requested_at" \
  '.version="1.2" | .runs += [{id:$id,owner:$owner,role:$role,type:$type,target_wedge:$wedge,task:$task,allowed_tools:[],depth:1,status:"requested",result_path:$result,consumer:$consumer,proof_paths:[],evidence_paths:[],spawned_session:false,requested_at:$requested_at,merge_decision:null,merge_reason:null,merged_at:null}]' \
  "$LEDGER" > "$LEDGER.tmp" && mv "$LEDGER.tmp" "$LEDGER"

# Write pending trigger file for guard/cron to detect and spawn
mkdir -p "$(dirname "$PENDING_TRIGGER")"
cat > "$PENDING_TRIGGER" <<EOF
{
  "run_id": "$run_id",
  "role": "$ROLE",
  "task": "$TASK",
  "target_wedge": "$TARGET_WEDGE",
  "result_path": "$RESULT_PATH",
  "consumer": "$CONSUMER",
  "requested_at": "$requested_at"
}
EOF

echo "SPAWN_REQUEST_ACCEPTED id=$run_id role=$ROLE result_path=$RESULT_PATH"
echo "PENDING_TRIGGER_WRITTEN - guard/cron will detect and spawn session"
