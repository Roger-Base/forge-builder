#!/bin/bash
# Base Mini App Monitor Demo
# Purpose: Show mini app activity on Base

set -euo pipefail

RPC_URL="${BASE_RPC_URL:-https://mainnet.base.org}"

# Parse output flag
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

run_demo() {
  echo "📱 Base Mini App Monitor Demo"
  echo "============================"
  echo ""

  # Get latest block
  LATEST_BLOCK=$(curl -s -X POST "$RPC_URL" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    | jq -r '.result')

  BLOCK_DEC=$((16#${LATEST_BLOCK:2}))
  echo "🔗 Latest Block: $BLOCK_DEC"

  echo ""
  echo "📊 Sample Mini App Contracts:"
  echo ""

  # Common mini app contracts on Base (example addresses)
  APPS=(
    "0x4ed4e862860bed51a9570b96d89af5e1b0efefed:Degen.Fun (degen tip app)"
    "0xfA0B667C3Bcd892C55f831c2dC5f2A3f9bC4E2F9:Base Name Service"
    "0x3f5CE5FBFe3E9df39706aB6CB2a8d0fd67B6B1B7:Uniswap V3"
  )

  for APP in "${APPS[@]}"; do
    ADDR="${APP%%:*}"
    NAME="${APP##*:}"
    
    # Check if address has code (is a contract)
    CODE=$(curl -s -X POST "$RPC_URL" \
      -H "Content-Type: application/json" \
      -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDR\",\"latest\"],\"id\":1}" \
      | jq -r '.result')
    
    if [[ "$CODE" != "0x" ]]; then
      echo "  ✅ $NAME"
      echo "     Contract: $ADDR"
    else
      echo "  ⚠️ $NAME (EOA - not a contract)"
    fi
  done

  echo ""
  echo "💡 This demo shows how to check if an address is a mini app contract."
}

if [[ -n "$OUTPUT_FILE" ]]; then
  run_demo > "$OUTPUT_FILE"
  echo "✅ Output written to $OUTPUT_FILE"
else
  run_demo
fi
