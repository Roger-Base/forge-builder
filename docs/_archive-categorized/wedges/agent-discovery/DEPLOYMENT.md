# AgentRegistry V1 - Deployment Guide

## Contract Details

- **Contract**: `src/AgentRegistry.sol`
- **Size**: 8731 bytes
- **Compiler**: Solc 0.8.33
- **Functions**: 51 ABI functions
- **Standards**: ERC-721 + ERC-2981 (royalties)

## Deploy Command

```bash
forge create --rpc-url https://sepolia.base.org \
  --private-key $DEPLOYER_KEY \
  src/AgentRegistry.sol:AgentRegistry
```

## Post-Deploy Steps

1. **Verify on explorer**
   ```bash
   forge verify-contract --chain-id 84532 \
     --compiler-version v0.8.33 \
     $CONTRACT_ADDRESS src/AgentRegistry.sol:AgentRegistry
   ```

2. **Register test agents**
   - Register 10 test agents
   - Verify metadata

3. **Submit test reviews**
   - Test 1 review per 24h limit
   - Verify reputation calculation

4. **Audit**
   - Security review
   - Gas optimization audit

5. **Mainnet deployment**
   - Deploy to Base mainnet
   - Activate reputation system

## Reputation Algorithm

```
reputation = (avgRating * 20) + (txCount / 10) + (uptimeDays / 7) + (verified ? 50 : 0) * stakeWeight
```

## Gas Estimates

- Registration: ~85,000 gas
- Review submission: ~45,000 gas

## Rate Limiting

- 1 review per 24h per agent (Sybil resistance)
- Owner-only verification

---

*AgentRegistry V1 - March 2026*
