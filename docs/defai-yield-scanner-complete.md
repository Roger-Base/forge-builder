# DeFAI Yield Scanner - Complete Documentation

## Overview

DeFAI Yield Scanner is an autonomous DeFi yield optimization tool for AI agents. It scans multiple protocols across chains to identify the best yield opportunities with risk assessment.

**Phase 1:** Yield Scanner CLI (mock data) ✅
**Phase 1.5:** Real API integration ⏳
**Phase 2:** Autonomous rebalancing ⏳
**Phase 2.1:** Agent-to-agent coordination ⏳

---

## Installation

```bash
# No dependencies required (Node 18+ has native fetch)
node scripts/defai-yield-scan.js --help
```

---

## Usage

### Scan Single Protocol

```bash
# Aave on Base
node scripts/defai-yield-scan.js --protocol aave --chain base

# Compound on Ethereum
node scripts/defai-yield-scan.js --protocol compound --chain ethereum

# Uniswap v3 on Arbitrum
node scripts/defai-yield-scan.js --protocol uniswap --chain arbitrum
```

### Scan All Protocols

```bash
# All protocols on all chains
node scripts/defai-yield-scan.js --all
```

---

## Supported Protocols

| Protocol | Type | Chains |
|----------|------|--------|
| **Aave** | Lending | ETH, Polygon, Arbitrum, Optimism, Base |
| **Compound** | Lending | ETH, Polygon, Arbitrum, Base |
| **Curve** | Stablecoin Pools | ETH, Polygon, Arbitrum, Optimism |
| **Yearn** | Vaults | ETH, Arbitrum, Optimism |
| **Uniswap v3** | Liquidity Pools | ETH, Polygon, Arbitrum, Optimism, Base |

---

## Output Format

```
=== AAVE Yield Data (base) ===

1. USDC
   APY: 4.23%
   TVL: $45.67M
   Risk Score: 50/100 (High)

2. WETH
   APY: 2.89%
   TVL: $23.45M
   Risk Score: 50/100 (High)
```

---

## Risk Scoring

Risk score 0-100 (lower = safer):

| Score | Level | Criteria |
|-------|-------|----------|
| 0-20 | Low | Audited protocol, TVL > $1B |
| 21-40 | Medium | Audited protocol, TVL $100M-$1B |
| 41-60 | Medium-High | New protocol or TVL $10M-$100M |
| 61-100 | High | Unaudited, TVL < $10M |

**Factors:**
- Smart contract audit status
- TVL (total value locked)
- Utilization rate (lending protocols)

---

## Mock Data (Phase 1)

Current implementation uses mock data for all protocols. Real API integration planned for Phase 1.5.

**Mock data covers:**
- 5 protocols × 5 chains = 25 combinations
- APY ranges: 1.23% - 12.34%
- TVL ranges: $0.01M - $156.78M
- Risk scores: 15-60/100

---

## Real API Integration (Phase 1.5)

### Data Sources

| Protocol | API/Endpoint | Status |
|----------|--------------|--------|
| Aave | The Graph Studio | Pending |
| Compound | The Graph Studio | Pending |
| Curve | The Graph Studio | Pending |
| Yearn | Yearn API | Pending |
| Uniswap v3 | The Graph Studio | Pending |

### Implementation Plan

1. Update subgraph endpoints (The Graph migrated from hosted service)
2. Test queries against production endpoints
3. Add error handling + rate limiting
4. Fallback to mock data if API fails

---

## Ecosystem Context (March 2026)

### Competitors / Parallels

| Project | What | Status | Differentiation |
|---------|------|--------|-----------------|
| **Orbs** | Agentic DeFi layer | Shipped March 17, 2026 | We have ERC-8004 identity |
| **Tearline** | 19M tx volume | Live | We have Base-native focus |
| **OptiView** | $200M raise | Q2 2026 roadmap | We have open agent-native API |
| **ASI Alliance** | Agent-to-agent DeFi | Emerging | We have yield claim validation |

### Our Moat

1. **ERC-8004 Identity + Reputation** - Others not doing
2. **Base-Native Focus** - Underserved market
3. **Open Agent-Native API** - Most closed systems
4. **Yield Claim Validation** - No zkML/TEE verification elsewhere

---

## Roadmap

| Phase | Feature | Status | ETA |
|-------|---------|--------|-----|
| **1.0** | Yield Scanner CLI (mock) | ✅ Complete | Done |
| **1.5** | Real API integration | ⏳ Next | 1-2 weeks |
| **1.6** | ERC-8004 integration | ⏳ Planned | 2-3 weeks |
| **2.0** | Autonomous rebalancing | ⏳ Future | 1-2 months |
| **2.1** | Agent-to-agent coordination | ⏳ Future | 2-3 months |

---

## Integration with ERC-8004

### Phase 1.6: Identity + Reputation

```solidity
// Register DeFAI agent on IdentityRegistry
uint256 agentId = identityRegistry.register("ipfs://QmDeFAIYieldScanner");

// Track yield performance reputation
repRegistry.giveFeedback(agentId, 85, "accuracy");

// Validate yield claims
valRegistry.validationRequest(validator, agentId, "yield-data", hash);
```

### Frontend Integration

DeFAI dashboard integrated into main frontend:
- Yield comparison table
- Protocol + chain filters
- Sort by APY/TVL/Risk
- Risk visualization (color-coded)

---

## Security

**Important:**
- This is a **yield scanner** (information tool), not a trading bot
- Always verify smart contract addresses before interacting
- Do your own research (DYOR) on protocols
- Yield rates change frequently - verify real-time data
- This tool does not execute trades or manage funds

---

## Contributing

### Add New Protocol

1. Add to `PROTOCOLS` config with subgraph/API endpoint
2. Add mock data to `MOCK_DATA` object
3. Test with `node scripts/defai-yield-scan.js --protocol <new> --chain <chain>`

### Improve Risk Scoring

Update `calculateRisk()` function with additional factors:
- Oracle reliability
- Smart contract upgradeability
- Team anonymity
- Audit recency

---

## Resources

- **Ecosystem Observation:** `/Users/roger/.openclaw/workspace/docs/ecosystem-observation-20260320-1727.md`
- **DeFAI Research:** `/Users/roger/.openclaw/workspace/state/runtime/defai-yield-scanner-research-v2-20260320-1451.md`
- **ERC-8004 Spec:** https://eips.ethereum.org/EIPS/eip-8004
- **The Graph:** https://thegraph.com/
- **Yearn API:** https://docs.yearn.finance/

---

*DeFAI Yield Scanner - Phase 1 Complete - March 2026*
