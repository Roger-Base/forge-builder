#!/bin/bash
# Base Account Checker - Check if address is Contract or EOA
# Usage: ./base-account-checker.sh <address>

set -euo pipefail

ADDRESS="${1:-}"
if [[ -z "$ADDRESS" ]]; then
  echo "Usage: $0 <base-address>"
  echo "Example: $0 0x1234..."
  exit 1
fi

# Base mainnet RPC
RPC_URL="${BASE_RPC_URL:-https://mainnet.base.org}"

# Get code at address
CODE=$(curl -s -X POST "$RPC_URL" \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getCode\",\"params\":[\"$ADDRESS\",\"latest\"],\"id\":1}" \
  | jq -r '.result')

if [[ "$CODE" == "0x" || "$CODE" == "0x0" ]]; then
  echo "EOA"
  echo "Type: Externally Owned Account (wallet)"
else
  echo "CONTRACT"
  echo "Type: Smart Contract"
fi
