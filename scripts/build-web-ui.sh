#!/usr/bin/env bash
set -euo pipefail

# Build Web UI with agent data
# Usage: bash scripts/build-web-ui.sh

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
DATA_DIR="$WORKSPACE/data"
AGENTS_FILE="$DATA_DIR/agents.json"
INDEX_HTML="$WORKSPACE/index.html"
OUTPUT_HTML="$WORKSPACE/docs/agents/index.html"

# Verify files exist
if [[ ! -f "$AGENTS_FILE" ]]; then
  echo "Error: Agents file not found"
  exit 1
fi

if [[ ! -f "$INDEX_HTML" ]]; then
  echo "Error: index.html template not found"
  exit 1
fi

echo "Building web UI with agent data..."

# Read agent data as JSON
AGENTS_JSON=$(cat "$AGENTS_FILE")

# Use Python for safe replacement (handles newlines in JSON)
python3 << PYTHON
import re

with open("$INDEX_HTML", 'r') as f:
    html = f.read()

with open("$AGENTS_FILE", 'r') as f:
    agents_json = f.read()

# Replace AGENTS_DATA placeholder
html = html.replace('AGENTS_DATA', agents_json)

# Write output
with open("$OUTPUT_HTML", 'w') as f:
    f.write(html)

print(f"✓ Web UI built: $OUTPUT_HTML ({len(html)} bytes)")
PYTHON

# Verify output
if [[ -f "$OUTPUT_HTML" ]]; then
  echo ""
  echo "=== Next Steps ==="
  echo "1. git add docs/agents/ && git commit -m 'Agent Discovery MVP'"
  echo "2. Enable GitHub Pages in repo settings"
  echo "3. Live URL: https://forge-builder.github.io/agent-discovery/"
fi
