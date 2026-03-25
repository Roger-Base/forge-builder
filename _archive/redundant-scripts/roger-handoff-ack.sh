#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
HANDOFF="$WORKSPACE/state/walter-handoff.json"
STATE="$WORKSPACE/state/session-state.json"
REPORT="$WORKSPACE/state/runtime/roger-handoff-ack-$(date -u +%Y%m%d-%H%M%S).md"
mkdir -p "$WORKSPACE/state/runtime"

MODE="sync"
STATUS=""
REASON=""
PROOF_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync) MODE="sync"; shift ;;
    --status) MODE="respond"; STATUS="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --proof-path) PROOF_PATH="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -f "$HANDOFF" ]] || { echo "ROGER_HANDOFF_ACK_SKIP missing handoff"; exit 0; }
jq . "$HANDOFF" >/dev/null
jq . "$STATE" >/dev/null

handoff_id="$(jq -r '.id // empty' "$HANDOFF")"
requires_ack="$(jq -r '.requires_ack // false' "$HANDOFF")"
current_response="$(jq -r '.response.status // "none"' "$HANDOFF")"

if [[ "$MODE" == "sync" ]]; then
  if [[ -z "$handoff_id" || "$requires_ack" != "true" || "$current_response" != "none" ]]; then
    # Clear stale critic status when no pending handoff exists
    tmp="$(mktemp)"
    jq \
      '.critic.last_handoff_id = null | .critic.status = "none" | .critic.summary = ""' \
      "$STATE" > "$tmp"
    bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null 2>&1 || true
    rm -f "$tmp"
    cat > "$REPORT" <<EOF2
# Roger Handoff Sync

- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- synced: false
- reason: no pending handoff
- cleared_stale_critic_status: true
EOF2
    echo "ROGER_HANDOFF_ACK_SKIP $REPORT"
    exit 0
  fi
  tmp="$(mktemp)"
  jq \
    --arg id "$handoff_id" \
    --arg summary "$(jq -r '.verdict + ": " + .main_risk' "$HANDOFF")" \
    '.critic.last_handoff_id = $id | .critic.status = "pending_ack" | .critic.summary = $summary' \
    "$STATE" > "$tmp"
  bash "$WORKSPACE/scripts/state-guard.sh" "$tmp" "$STATE" >/dev/null
  rm -f "$tmp"
  cat > "$REPORT" <<EOF2
# Roger Handoff Sync

- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- synced: true
- handoff_id: $handoff_id
- critic_status: pending_ack
EOF2
  echo "ROGER_HANDOFF_SYNC_OK $REPORT"
  exit 0
fi

case "$STATUS" in
  applied|rejected_with_proof|deferred_with_reason) ;;
  *) echo "Invalid --status: $STATUS" >&2; exit 1 ;;
esac

response_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
htmp="$(mktemp)"
jq \
  --arg status "$STATUS" \
  --arg ts "$response_ts" \
  --arg reason "$REASON" \
  --arg proof "$PROOF_PATH" \
  '.response = {status:$status, responded_at:$ts, reason:($reason|select(length>0)), proof_path:($proof|select(length>0))} | .requires_ack = false' \
  "$HANDOFF" > "$htmp"
mv "$htmp" "$HANDOFF"

stmp="$(mktemp)"
jq \
  --arg status "$STATUS" \
  --arg id "$handoff_id" \
  --arg ts "$response_ts" \
  --arg summary "$(jq -r '.verdict + ": " + .main_risk' "$HANDOFF")" \
  '.critic.last_handoff_id = $id | .critic.status = $status | .critic.summary = $summary | .updated_at = $ts' \
  "$STATE" > "$stmp"
bash "$WORKSPACE/scripts/state-guard.sh" "$stmp" "$STATE" >/dev/null
rm -f "$stmp"

cat > "$REPORT" <<EOF2
# Roger Handoff Response

- timestamp: $response_ts
- handoff_id: $handoff_id
- status: $STATUS
- reason: ${REASON:-none}
- proof_path: ${PROOF_PATH:-none}
EOF2

echo "ROGER_HANDOFF_RESPONSE_OK $REPORT"
