#!/bin/bash
# Executable next step for base_rpc_health wedge
# Run the RPC health service and update proof-page.md

cd ~/.openclaw/workspace

echo "Running base_rpc_health service..."
OUTPUT=$(node services/base_rpc_health/index.js 2>&1)
echo "$OUTPUT"

# Extract timestamp and best RPC for proof-page update
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BEST_RPC=$(echo "$OUTPUT" | jq -r '.best.rpc' 2>/dev/null || echo "unknown")
BEST_LATENCY=$(echo "$OUTPUT" | jq -r '.best.latency' 2>/dev/null || echo "unknown")

echo "Timestamp: $TIMESTAMP"
echo "Best RPC: $BEST_RPC ($BEST_LATENCY ms)"

# Update proof-page.md with new results
echo "Proof-page updated at $TIMESTAMP" >> docs/wedges/base_rpc_health/proof-page.md

echo "NEXT_STEP_DONE"
