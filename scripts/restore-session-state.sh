#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
STATE_DIR="$WORKSPACE/state"
TARGET="${1:-$STATE_DIR/session-state.json}"
REPORT="$STATE_DIR/runtime/restore-session-state-$(date -u +%Y%m%d-%H%M%S).md"
mkdir -p "$STATE_DIR/runtime"

latest_valid=""
while IFS= read -r candidate; do
  if bash "$WORKSPACE/scripts/state-guard.sh" --validate "$candidate" >/dev/null 2>&1; then
    latest_valid="$candidate"
    break
  fi
done < <(ls -1t "$STATE_DIR"/session-state.json.bak-* 2>/dev/null || true)

if [[ -z "$latest_valid" ]]; then
  cat > "$REPORT" <<EOF2
# Restore Session State

- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- restored: false
- reason: no valid v4 backup found
EOF2
  echo "RESTORE_SESSION_STATE_FAIL $REPORT"
  exit 1
fi

write_output="$(bash "$WORKSPACE/scripts/state-guard.sh" "$latest_valid" "$TARGET" 2>&1)"
cat > "$REPORT" <<EOF2
# Restore Session State

- timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- restored: true
- source_backup: $latest_valid
- target: $TARGET

## State Guard
\```text
$write_output
\```
EOF2

echo "RESTORE_SESSION_STATE_OK $REPORT"
