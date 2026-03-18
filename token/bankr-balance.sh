#!/bin/bash
# Bankr Balance Quick Check 🟦

API_KEY="bk_5PJP2VFGZ7LFDDZ753X734YV2H8RR23L"
API_URL="https://api.bankr.bot"

echo "=== Bankr Balance Check ==="
echo "Wallets:"
echo "  EVM: 0x984d6741e2c6559b1e655b6dbb3a38662fe2c123"
echo "  Solana: AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y"
echo ""

# Submit job
RESPONSE=$(curl -s -X POST "$API_URL/v1/chat" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{"message": "what is my ETH and USDC balance on Base?"}')

# Check if job-based or direct response
if echo "$RESPONSE" | grep -q "jobId"; then
  JOB_ID=$(echo "$RESPONSE" | jq -r '.jobId' 2>/dev/null)
  echo "Job submitted: $JOB_ID"
  echo "Check with: bash scripts/bankr-status.sh $JOB_ID"
else
  echo "$RESPONSE" | jq -r '.response' 2>/dev/null || echo "$RESPONSE"
fi
