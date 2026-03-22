#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
OUT="${1:-$WORKSPACE/docs/wedges/agent-trust-discovery/demo-output.md}"
TMP="$(mktemp)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$OUT")"

set +e
NETWORK=mainnet node "$WORKSPACE/services/erc8004-agent-lookup/index.js" >"$TMP" 2>&1
EXIT_CODE=$?
set -e

STATUS="FAILED"
[[ "$EXIT_CODE" -eq 0 ]] && STATUS="OK"

cat > "$OUT" <<EOF
# agent-trust-discovery — Demo Output

**Last run:** $TS
**Service:** \`services/erc8004-agent-lookup/index.js\`
**Status:** $STATUS
**Exit code:** $EXIT_CODE

## Live run output

\`\`\`
$(cat "$TMP")
\`\`\`

## Reuse note

- This file is the canonical live demo surface for the agent-trust-discovery wedge.
- Refresh this file before creating a new proof fragment for the same lookup flow.
EOF

rm -f "$TMP"
echo "REFRESH_AGENT_TRUST_DISCOVERY_OK $OUT"
