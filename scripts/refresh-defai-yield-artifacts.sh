#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
OUT="${1:-$WORKSPACE/docs/wedges/defai-yield-agent/P1-yield-scan.md}"
TMP="$(mktemp)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
CMD=(node "$WORKSPACE/scripts/defai-yield-scan.js" --all)

mkdir -p "$(dirname "$OUT")"

set +e
"${CMD[@]}" >"$TMP" 2>&1
EXIT_CODE=$?
set -e

STATUS="FAILED"
[[ "$EXIT_CODE" -eq 0 ]] && STATUS="OK"

cat > "$OUT" <<EOF
# DeFAI Yield Scan — Refreshed

**Last run:** $TS
**Command:** \`node scripts/defai-yield-scan.js --all\`
**Status:** $STATUS
**Exit code:** $EXIT_CODE

## Raw output

\`\`\`
$(cat "$TMP")
\`\`\`

## Reuse note

- This file is the canonical P1 scan surface for the defai-yield-agent wedge.
- Refresh this scan before creating a parallel yield-scan artifact with the same purpose.
EOF

rm -f "$TMP"
echo "REFRESH_DEFAI_YIELD_OK $OUT"
