#!/bin/bash
# ERC-8004 Suite Deployment Script - Base Sepolia
# Run when Base Sepolia ETH is funded

set -e

echo "=== ERC-8004 Suite Deployment - Base Sepolia ==="
echo ""

# Load DEPLOYER_KEY from evm-wallet
export DEPLOYER_KEY=$(cat ~/.evm-wallet.json | jq -r '.privateKey')
echo "Wallet: 0x8cD4d6deA2f8c9717a053a7f91B9Bba536819d2b"
echo "RPC: https://sepolia.base.org"
echo ""

# Check balance
echo "=== Checking Balance ==="
BALANCE=$(curl -s "https://sepolia.base.org" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x8cD4d6deA2f8c9717a053a7f91B9Bba536819d2b","latest"],"id":1}' \
  | jq -r '.result')
echo "Balance: $BALANCE"
echo ""

if [ "$BALANCE" = "0x0" ]; then
  echo "❌ Balance is 0. Please fund wallet first:"
  echo "   https://coinbase.com/faucets/base-sepolia-faucet"
  exit 1
fi

echo "✅ Balance OK - proceeding with deployment"
echo ""

# Deploy IdentityRegistry
echo "=== Deploying IdentityRegistry ==="
IDENTITY_ADDR=$(forge create --rpc-url https://sepolia.base.org \
  --private-key $DEPLOYER_KEY \
  src/IdentityRegistry.sol:IdentityRegistry \
  --json | jq -r '.deployedTo')
echo "✅ IdentityRegistry deployed: $IDENTITY_ADDR"
echo ""

# Deploy ReputationRegistry
echo "=== Deploying ReputationRegistry ==="
REPUTATION_ADDR=$(forge create --rpc-url https://sepolia.base.org \
  --private-key $DEPLOYER_KEY \
  src/ReputationRegistry.sol:ReputationRegistry \
  --json | jq -r '.deployedTo')
echo "✅ ReputationRegistry deployed: $REPUTATION_ADDR"
echo ""

# Deploy ValidationRegistry
echo "=== Deploying ValidationRegistry ==="
VALIDATION_ADDR=$(forge create --rpc-url https://sepolia.base.org \
  --private-key $DEPLOYER_KEY \
  src/ValidationRegistry.sol:ValidationRegistry \
  --json | jq -r '.deployedTo')
echo "✅ ValidationRegistry deployed: $VALIDATION_ADDR"
echo ""

# Save deployment addresses
echo "=== Saving Deployment Addresses ==="
cat > contracts/deployed-addresses.json << EOF
{
  "network": "Base Sepolia",
  "chainId": 84532,
  "deployer": "0x8cD4d6deA2f8c9717a053a7f91B9Bba536819d2b",
  "contracts": {
    "IdentityRegistry": "$IDENTITY_ADDR",
    "ReputationRegistry": "$REPUTATION_ADDR",
    "ValidationRegistry": "$VALIDATION_ADDR"
  },
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
echo "✅ Saved to contracts/deployed-addresses.json"
echo ""

# Verify deployments
echo "=== Verifying Deployments ==="
echo "IdentityRegistry:"
cast call $IDENTITY_ADDR "name()" --rpc-url https://sepolia.base.org
echo ""
echo "ReputationRegistry:"
cast call $REPUTATION_ADDR "name()" --rpc-url https://sepolia.base.org
echo ""
echo "ValidationRegistry:"
cast call $VALIDATION_ADDR "name()" --rpc-url https://sepolia.base.org
echo ""

echo "=== Deployment Complete ==="
echo "Next step: Update frontend/src/ERC8004Integration.jsx with contract addresses"
