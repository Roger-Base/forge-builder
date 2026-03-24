# Agent Trust & Discovery Infrastructure on Base — Research Packet

**Wedge candidate:** agent-trust-discovery
**Stage:** LEARN
**Generated:** 2026-03-20T11:20 UTC
**Source:** Web search + workspace gap analysis

---

## What Is the Gap?

Agents on Base have no native way to:
1. **Discover** other agents by capability or reputation
2. **Verify** another agent's identity and trust score on-chain
3. **Establish** trusted communication channels without centralized intermediaries

This is not a niche problem. As autonomous agent-to-agent finance grows on Base, the inability to establish trust programmatically becomes a systemic bottleneck.

---

## Evidence

### 1. ERC-8004 Emerging as Agent Identity Standard
- ERC-8004 defines 3 registries: Identity, Reputation, Validation
- Already deployed on Ethereum mainnet (`0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`)
- No Base-specific implementation exists (workspace: `erc8004-base-research.md` confirmed)
- Quote: "By 2026, an agent without a high ERC-8004 reputation score will struggle to find work" (Geek Metaverse, 2026)
- QuickNode, Allium, Solana are building reputation tracking — Base is absent

### 2. Agentic Commerce Requires Trust Infrastructure
- AWS x402 + Base + USDC enables **autonomous payments** for agents (Alchemy flow, March 2026)
- x402 closes the payment gap; trust gap remains unsolved
- An agent needs to know: Can I trust this counterparty? Are they who they claim?
- No Base-native trust verification layer exists

### 3. Agent-to-Agent Communication Gap
- AI Agents Stack (2026): "missing interface layers, verifiable policy enforcement, and reproducible evaluation practices" are top gaps
- Cross-agent memory breaks down in production (Letta/Zep/Mem0 fill this on other chains)
- No Base-native equivalent for agent service discovery

### 4. "Corporate Agents" Niche on Base
- Base has carved out a niche for slow-moving institutional/corporate agents (Coincub, March 2026)
- These agents need compliance-grade identity and reputation — not memecoin bots
- Current Base infrastructure has no answer for this

---

## Existing Work (Workspace)

| Wedge | Status | Gap Coverage |
|-------|--------|-------------|
| agent-discovery | DEPLOYED | Agent registry — partial (deployment blocked) |
| erc8004-base-research.md | frozen | ERC-8004 research — never built on Base |
| erc8004_registry_utility | frozen | ERC-8004 utility attempt — stalled |
| agent_security_scanner | DISTRIBUTE | Agent security — orthogonal |
| contextkeeper_mvp | maintenance (no dir) | Cross-agent memory — not yet built |

**Key finding:** ERC-8004 on Base is researched but never built. The trust/identity gap is real and unoccupied.

---

## What a Build Would Require

### 1. ERC-8004 IdentityRegistry on Base
- Deploy IdentityRegistry, ReputationRegistry, ValidationRegistry to Base mainnet
- Requires: Base RPC access, deployer wallet (human-only credential — acknowledged blocker)
- Partial path: Base Sepolia testnet deployment first (no deployer key needed for testnet faucet)

### 2. Agent Discovery Service
- Index ERC-8004 registries on Base
- Provide search/filter by capability tags, trust score, last-active
- Similar to agent-discovery but focused on trust signals not just existence

### 3. Trust Score API
- On-chain reputation score aggregation
- Escrow trust, tx history, identity attestations
- Would integrate with x402 autonomous payments

---

## Build Gate Check

1. **Problem real?** ✅ — ERC-8004 unbuilt on Base, agents need trust infra
2. **Strong solutions exist?** ❌ — No Base-native ERC-8004 implementation found
3. **Ecosystem value?** ✅ — Institutional agents, agentic finance, compliance needs
4. **Can Roger deliver?** ⚠️ — Contract deployment blocked on DEPLOYER_KEY (human); testnet path exists
5. **Real gap?** ✅ — ERC-8004 research exists but never built; no competitor found

**Gate verdict:** REAL GAP with delivery caveat (testnet path available; mainnet deploy = human-only)

---

## Recommended Next Step

1. Deploy ERC-8004 IdentityRegistry to **Base Sepolia** testnet (no deployer key — faucet available)
2. Build agent identity lookup script (read-only, no deploy needed)
3. If testnet works: prepare mainnet deployment spec for Tomas
4. Create proof-spec.md for the full agent trust service

---

## Sources

- https://coincub.com/blog/best-ai-crypto-agents/ — "Corporate Agents" niche on Base
- https://www.geekmetaverse.com/ai-in-web3-how-ai-agents-and-crypto-trading-will-pay-dollar-by-2026/ — ERC-8004 reputation layer
- https://aws.amazon.com/blogs/industries/x402-and-agentic-commerce-redefining-autonomous-payments-in-financial-services/ — x402 agent payments
- https://arxiv.org/html/2601.04583v1 — AI agents on blockchains standards gaps
- workspace: `docs/wedges/erc8004-base-research.md` — Base ERC-8004 gap confirmed
