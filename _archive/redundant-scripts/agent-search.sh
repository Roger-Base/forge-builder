#!/usr/bin/env bash
set -euo pipefail

# Agent Search CLI for Virtuals Protocol agents
# Usage: bash scripts/agent-search.sh --query "trading" [--category defi] [--sort market_cap]

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
DATA_DIR="$WORKSPACE/data"
INDEX_FILE="$DATA_DIR/index.json"
QUERY=""
CATEGORY=""
SORT="market_cap"
LIMIT=10

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      QUERY="${2:-}"
      shift 2
      ;;
    --category)
      CATEGORY="${2:-}"
      shift 2
      ;;
    --sort)
      SORT="${2:-market_cap}"
      shift 2
      ;;
    --limit)
      LIMIT="${2:-10}"
      shift 2
      ;;
    --test)
      echo "Running test query..."
      QUERY="trading"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Verify index exists
if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Error: Index file not found: $INDEX_FILE"
  echo "Run crawl-virtuals-agents.sh first"
  exit 1
fi

# Main search logic
echo "=== Agent Search ==="
echo "Query: ${QUERY:-all}"
echo "Category: ${CATEGORY:-all}"
echo "Sort: $SORT"
echo "Limit: $LIMIT"
echo ""

# Build search using jq
if [[ -n "$CATEGORY" && -n "$QUERY" ]]; then
  # Filter by category AND query
  RESULTS=$(jq --arg cat "$CATEGORY" --arg q "$QUERY" \
    '[.[] | select(.category == $cat) | select(.searchable_text | contains($q))] | sort_by(-.market_cap) | .[:$LIMIT]' \
    "$INDEX_FILE")
elif [[ -n "$CATEGORY" ]]; then
  # Filter by category only
  RESULTS=$(jq --arg cat "$CATEGORY" \
    '[.[] | select(.category == $cat)] | sort_by(-.market_cap) | .[:10]' \
    "$INDEX_FILE")
elif [[ -n "$QUERY" ]]; then
  # Filter by query only
  RESULTS=$(jq --arg q "$QUERY" \
    '[.[] | select(.searchable_text | contains($q))] | sort_by(-.market_cap) | .[:10]' \
    "$INDEX_FILE")
else
  # No filter, just sort and limit
  RESULTS=$(jq 'sort_by(-.market_cap) | .[:10]' "$INDEX_FILE")
fi

COUNT=$(echo "$RESULTS" | jq 'length')

echo "Found $COUNT agents"
echo ""

if [[ "$COUNT" -gt 0 ]]; then
  echo "$RESULTS" | jq -r '.[] | "**\(.name)** (\(.category)) - \(.description | .[0:80])..."'
  echo ""
  echo "=== Full JSON Results ==="
  echo "$RESULTS"
else
  echo "No agents found matching criteria"
fi
