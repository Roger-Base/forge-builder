# Base AI Agent Ecosystem Gaps

Research conducted: Feb 28, 2026
Last verified: Mar 16, 2026

## Current Roger ACP Services (8 total)
- agent_registry
- base_eth_price
- base_gas_tracker
- base_gas_v2
- base_send_optimizer
- base_token_info
- roger_token_info
- smart_contract_analyzer

---

## 3 Concrete Gaps for New ACP Services

### Gap 1: Transaction State & Finality Confirmation ⚠️ STILL VALID

**Problem:** 
- "Onchain execution is inherently failure-prone. RPC timeouts, partial transaction submission, blockchain reorgs, and delayed confirmations can cause an agent to lose certainty about whether an action succeeded." (Allium)
- Base's sequencer has experienced outages multiple times in the past year
- Agents frequently lose track of whether a transaction succeeded after network disruptions

**Verification (Mar 2026):** Still no dedicated service for agents to get definitive transaction finality.

**Solution: `tx_finality_monitor`**
- Service that monitors pending transactions and confirms finality
- Handles reorg detection (watches for chain reorganizations)
- Returns definitive success/failure states, not just "pending"
- Can retry or suggest alternatives when transactions stall

**Price suggestion:** 0.05-0.10 USDC per confirmation request

---

### Gap 2: RPC Health & Failover Routing ⚠️ PARTIALLY ADDRESSED

**Problem:**
- Base RPC endpoints fail periodically (status.base.org shows historical outages)
- Single RPC endpoint = single point of failure for agents
- No service exists to tell agents "use this RPC now, the other one is slow/down"

**Verification (Mar 2026):** 91+ RPC providers exist (QuickNode, Chainstack, RPC Fast, Dwellir). BUT no dedicated agent-focused health monitoring with failover recommendations.

**Solution: `base_rpc_health`** (still needed)
- Monitor multiple Base RPC endpoints (public + private)
- Return latency, success rate, and current best endpoint
- Alert when sequencer is experiencing issues
- Provide failover recommendations to calling agents

**Price suggestion:** 0.02-0.05 USDC per health check

---

### Gap 3: Agent Reputation & History Registry ✅ ERC-8004 EMERGING

**Problem:**
- "50% of deployed AI agents operate in complete isolation from each other" (Salesforce 2026)
- No way for agents to verify trustworthiness of other agents before transacting
- Cross-agent coordination is risky without reputation data

**Verification (Mar 2026):** ERC-8004 is emerging as standard! QuickNode and Allium articles from Feb/Mar 2026. Solana has Agent Registry. This gap is BEING ADDRESSED by the ecosystem.

**Current state:** May not need to build - ERC-8004 implementations are emerging.

---

## Additional Gaps Worth Exploring

| Gap | Problem | ACP Potential |
|-----|---------|---------------|
| Multi-agent coordination | No discovery protocol for Base agents | Service registry + discovery |
| Gas price prediction | Current gas is reactive, not predictive | ML-based gas forecasting |
| Onchain data normalization | Raw blockchain data breaks agents | Parse & format for AI consumption |
| Agent-to-agent escrow | No trustless intermediary between agents | Escrow service for ACP jobs |

---

## Sources

- Allium: "AI-Ready Onchain Data: Why Raw Blockchain Data Breaks Agents"
- Distributed Thoughts: "The Agentic AI Infrastructure Gap: Everyone's Building Agents. Nobody's Building the Substrate."
- Salesforce 2026 Connectivity Report
- Base Status (status.base.org)
- Bitcoin Ethereum News: "Base relies on a centralized sequencer, which has stuttered and stopped a few times in the past year"
- QuickNode: ERC-8004 Developer Guide (Mar 2026)
- Allium: ERC-8004 Explained (Feb 2026)
