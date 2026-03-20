# DeFAI Yield Scanner CLI

**Phase 1:** Multi-protocol yield scanner for autonomous DeFi agents

---

## Overview

DeFAI Yield Scanner scans DeFi protocols for yield opportunities across multiple chains:

**Protocols:**
- Aave (lending)
- Compound (lending)
- Curve (stablecoin pools)
- Yearn (vaults)
- Uniswap v3 (liquidity pools)

**Chains:**
- Ethereum
- Polygon
- Arbitrum
- Optimism
- Base

---

## Installation

```bash
# Install dependencies
npm install node-fetch

# Or use the script directly (node 18+ has fetch built-in)
node scripts/defai-yield-scan.js --help
```

---

## Usage

### Scan Single Protocol

```bash
# Scan Aave on Base
node scripts/defai-yield-scan.js --protocol aave --chain base

# Scan Compound on Ethereum
node scripts/defai-yield-scan.js --protocol compound --chain ethereum

# Scan Uniswap v3 on Arbitrum
node scripts/defai-yield-scan.js --protocol uniswap --chain arbitrum
```

### Scan All Protocols

```bash
# Scan all protocols on all chains (may take 1-2 minutes)
node scripts/defai-yield-scan.js --all
```

### Help

```bash
node scripts/defai-yield-scan.js --help
```

---

## Output Format

```
=== AAVE Yield Data (base) ===

1. USDC
   APY: 4.23%
   TVL: $45.67M
   Risk Score: 15/100 (Low)

2. WETH
   APY: 2.89%
   TVL: $23.45M
   Risk Score: 15/100 (Low)

...
```

---

## Risk Scoring

Risk score 0-100 (lower = safer):

| Score | Risk Level | Description |
|-------|------------|-------------|
| 0-20 | Low | Audited protocol, high TVL (> $1B) |
| 21-40 | Medium | Audited protocol, medium TVL ($100M-$1B) |
| 41-60 | Medium-High | New protocol or low TVL ($10M-$100M) |
| 61-100 | High | Unaudited, very low TVL (< $10M) |

**Factors:**
- Smart contract audit status
- TVL (total value locked)
- Utilization rate (for lending protocols)

---

## Data Sources

| Protocol | Data Source | API/Endpoint |
|----------|-------------|--------------|
| Aave | The Graph Subgraph | https://api.thegraph.com/subgraphs/name/aave/aave-v3 |
| Compound | The Graph Subgraph | https://api.thegraph.com/subgraphs/name/compound-finance/compound-v3 |
| Curve | The Graph Subgraph | https://api.thegraph.com/subgraphs/name/curve-fi/curve |
| Yearn | Yearn API | https://api.yearn.finance/v1/chains/{chain}/vaults |
| Uniswap v3 | The Graph Subgraph | https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3 |

---

## Integration with ERC-8004

**Phase 1.5 (Next):**
- Register yield scanner as ERC-8004 agent
- Track yield performance reputation
- Enable user feedback on yield accuracy
- Validation of yield claims

**Phase 2.0 (Future):**
- Autonomous rebalancing (auto-compound)
- Gas-optimized execution
- Impermanent loss hedging
- Agent-to-agent yield coordination

---

## API Usage (Programmatic)

```javascript
const { fetchProtocolData, calculateRisk } = require('./scripts/defai-yield-scan.js');

// Fetch data
const data = await fetchProtocolData('aave', 'base');

// Calculate risk
const riskScore = calculateRisk('aave', data.reserves[0]);

console.log(`Risk: ${riskScore}/100`);
```

---

## Limitations (Phase 1)

- **Real-time data** depends on Graph API availability
- **Base support** limited (fewer protocols deployed)
- **No auto-rebalancing** (manual execution)
- **No impermanent loss calculation** (for LPs)
- **No gas optimization** (future phase)

---

## Roadmap

| Phase | Feature | Status |
|-------|---------|--------|
| **1.0** | Yield Scanner CLI | ✅ Complete |
| **1.1** | ERC-8004 Integration | ⏳ Next |
| **1.5** | Frontend Dashboard | ⏳ Planned |
| **2.0** | Autonomous Rebalancing | ⏳ Future |
| **2.1** | Agent-to-Agent Coordination | ⏳ Future |

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

**Data Sources:**
- Add new protocols via `PROTOCOLS` config
- Add new chains via `chains` array
- Improve risk scoring algorithm

**Testing:**
- Test against known APY values
- Verify TVL accuracy
- Check risk scoring edge cases

---

## Resources

- **DeFAI Research:** `/Users/roger/.openclaw/workspace/state/runtime/defai-yield-scanner-research-v2-20260320-1451.md`
- **ERC-8004 Spec:** https://eips.ethereum.org/EIPS/eip-8004
- **The Graph:** https://thegraph.com/
- **Yearn API:** https://docs.yearn.finance/

---

*DeFAI Yield Scanner CLI - Phase 1 - March 2026*
