# ERC-8004 Deployment Runbook

**Version:** 1.0.0  
**Last Updated:** 2026-03-21  
**Network:** Base Sepolia → Base Mainnet  

---

## Pre-Deployment Checklist

### Environment Setup

- [ ] Foundry installed (`forge --version`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] MetaMask wallet configured
- [ ] Base Sepolia ETH obtained (faucet)
- [ ] Etherscan API key obtained

### Contract Verification

- [ ] All contracts compile (`forge build`)
- [ ] All tests pass (`forge test`)
- [ ] Test coverage > 90% (`forge coverage`)
- [ ] Gas reports reviewed (`forge test --gas-report`)

### Security Review

- [ ] Reentrancy guards in place
- [ ] Access control configured (Ownable)
- [ ] Signature verification tested
- [ ] 24h cooldown enforced
- [ ] Owner cannot review (tested)

---

## Testnet Deployment (Base Sepolia)

### Step 1: Fund Wallet

```bash
# Visit Base Sepolia faucet
https://coinbase.com/faucets/base-sepolia-faucet

# Verify balance
cast balance <your_address> --rpc-url https://sepolia.base.org
```

### Step 2: Set Environment Variables

```bash
# Private key (NEVER commit to git)
export DEPLOYER_KEY=<your_private_key>

# Etherscan API key
export ETHERSCAN_API_KEY=<your_api_key>

# RPC URL
export RPC_URL=https://sepolia.base.org

# Chain ID
export CHAIN_ID=84532
```

### Step 3: Deploy IdentityRegistry

```bash
# Deploy
forge create \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --chain-id $CHAIN_ID \
  --broadcast \
  src/IdentityRegistry.sol:IdentityRegistry \
  --constructor-args "AgentRegistry" "AGENT" "eip155"

# Save deployed address
export IDENTITY_REGISTRY_ADDRESS=<deployed_address>

# Verify on Etherscan
forge verify-contract \
  --chain-id $CHAIN_ID \
  --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
  --constructor-args $(cast abi-encode "constructor(string,string,string)" "AgentRegistry" "AGENT" "eip155") \
  $IDENTITY_REGISTRY_ADDRESS \
  src/IdentityRegistry.sol:IdentityRegistry
```

### Step 4: Deploy ReputationRegistry

```bash
# Get deployer address
export DEPLOYER_ADDRESS=$(cast wallet address --private-key $DEPLOYER_KEY)

# Deploy
forge create \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --chain-id $CHAIN_ID \
  --broadcast \
  src/ReputationRegistry.sol:ReputationRegistry \
  --constructor-args $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS

# Save deployed address
export REPUTATION_REGISTRY_ADDRESS=<deployed_address>

# Verify on Etherscan
forge verify-contract \
  --chain-id $CHAIN_ID \
  --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
  --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS) \
  $REPUTATION_REGISTRY_ADDRESS \
  src/ReputationRegistry.sol:ReputationRegistry
```

### Step 5: Deploy ValidationRegistry

```bash
# Deploy
forge create \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --chain-id $CHAIN_ID \
  --broadcast \
  src/ValidationRegistry.sol:ValidationRegistry \
  --constructor-args $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS

# Save deployed address
export VALIDATION_REGISTRY_ADDRESS=<deployed_address>

# Verify on Etherscan
forge verify-contract \
  --chain-id $CHAIN_ID \
  --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
  --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS) \
  $VALIDATION_REGISTRY_ADDRESS \
  src/ValidationRegistry.sol:ValidationRegistry
```

---

## Post-Deployment Verification

### Step 1: Verify Contract Addresses

```bash
# Check all contracts deployed
echo "Identity Registry:    $IDENTITY_REGISTRY_ADDRESS"
echo "Reputation Registry:  $REPUTATION_REGISTRY_ADDRESS"
echo "Validation Registry:  $VALIDATION_REGISTRY_ADDRESS"

# Verify on Base Sepolia explorer
echo "https://sepolia.basescan.org/address/$IDENTITY_REGISTRY_ADDRESS"
echo "https://sepolia.basescan.org/address/$REPUTATION_REGISTRY_ADDRESS"
echo "https://sepolia.basescan.org/address/$VALIDATION_REGISTRY_ADDRESS"
```

### Step 2: Test Registration

```bash
# Register test agent
cast send \
  $IDENTITY_REGISTRY_ADDRESS \
  "register(string)" \
  "ipfs://QmTest123" \
  --private-key $DEPLOYER_KEY \
  --rpc-url $RPC_URL

# Get agent ID
cast call \
  $IDENTITY_REGISTRY_ADDRESS \
  "getTotalAgents()(uint256)" \
  --rpc-url $RPC_URL
```

### Step 3: Test Feedback

```bash
# Give feedback (agentId=1, value=80, tag1="quality")
cast send \
  $REPUTATION_REGISTRY_ADDRESS \
  "giveFeedback(uint256,int128,string)" \
  1 80 "quality" \
  --private-key $DEPLOYER_KEY \
  --rpc-url $RPC_URL

# Get summary
cast call \
  $REPUTATION_REGISTRY_ADDRESS \
  "getSummary(uint256,address[])" \
  1 "[$DEPLOYER_ADDRESS]" \
  --rpc-url $RPC_URL
```

### Step 4: Test Validation

```bash
# Request validation
cast send \
  $VALIDATION_REGISTRY_ADDRESS \
  "validationRequest(address,uint256,string,bytes32)" \
  $DEPLOYER_ADDRESS 1 "ipfs://QmValidation" $(cast keccak "ipfs://QmValidation") \
  --private-key $DEPLOYER_KEY \
  --rpc-url $RPC_URL
```

---

## Mainnet Deployment

### Prerequisites

- [ ] Testnet deployment complete and verified
- [ ] All security audits complete
- [ ] Gas optimization reviewed
- [ ] Frontend integration tested
- [ ] Documentation complete

### Step 1: Update Environment

```bash
# Mainnet RPC
export RPC_URL=https://mainnet.base.org
export CHAIN_ID=8453

# Ensure sufficient ETH for gas
cast balance <your_address> --rpc-url $RPC_URL
```

### Step 2: Deploy (Same as Testnet)

```bash
# Follow testnet deployment steps with mainnet variables
# IdentityRegistry
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY --chain-id $CHAIN_ID --broadcast src/IdentityRegistry.sol:IdentityRegistry --constructor-args "AgentRegistry" "AGENT" "eip155"

# ReputationRegistry
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY --chain-id $CHAIN_ID --broadcast src/ReputationRegistry.sol:ReputationRegistry --constructor-args $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS

# ValidationRegistry
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY --chain-id $CHAIN_ID --broadcast src/ValidationRegistry.sol:ValidationRegistry --constructor-args $IDENTITY_REGISTRY_ADDRESS $DEPLOYER_ADDRESS
```

### Step 3: Verify on Etherscan

```bash
# Verify all three contracts (same commands as testnet)
```

---

## Troubleshooting

### Common Issues

**"insufficient funds"**
- Ensure wallet has ETH for gas
- Check balance: `cast balance <address> --rpc-url $RPC_URL`

**"nonce too low"**
- Wait for pending transactions to confirm
- Check nonce: `cast get nonce <address> --rpc-url $RPC_URL`

**"contract creation failed"**
- Verify constructor arguments match contract
- Check gas limit (increase if needed)

**"verification failed"**
- Ensure compiler version matches
- Check constructor args encoding

---

## Rollback Plan

### If Deployment Fails

1. **Identify failure point** (which contract)
2. **Check transaction receipt** (cast tx <tx_hash>)
3. **Fix issue** (code, args, gas)
4. **Redeploy** (new address)
5. **Update frontend** (new contract addresses)

### If Post-Deploy Issues

1. **Pause operations** (if Ownable functions available)
2. **Diagnose** (test calls, events)
3. **Deploy fix** (new contract version)
4. **Migrate users** (if state needs migration)

---

## Security Notes

### Private Key Safety

- **NEVER** commit private key to git
- Use environment variables or secure vault
- Rotate keys periodically
- Use hardware wallet for mainnet

### Contract Verification

- Always verify on Etherscan
- Check bytecode matches source
- Test all functions before mainnet

### Access Control

- Owner can set reviewer stakes
- Owner can pause if implemented
- Transfer ownership if needed

---

## Monitoring

### Post-Deployment Metrics

- Total agents registered
- Feedback submissions
- Validation requests
- Gas costs per operation

### Alerting

- Large stake changes
- Unusual feedback patterns
- Validation failures
- Gas price spikes

---

*Deployment Runbook v1.0 - March 2026*
