# Agent Trust Discovery — Proof Spec
**Wedge:** agent-trust-discovery
**Stage:** BUILD
**Generated:** 2026-03-20T12:15 UTC
**Based on:** `research-packet.md` + on-chain verification + gap correction

---

## What Changed From Research-Packet

The research-packet assumed ERC-8004 was **not deployed on Base** and recommended deploying it. On-chain verification shows:

| Contract | Network | Address | Status |
|----------|---------|---------|--------|
| IdentityRegistry | Base Sepolia | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | ✅ LIVE — name() = "AgentIdentity" |
| ReputationRegistry | Base Sepolia | `0x8004B663056A597DFFE9EccC1965A193B7388713` | ✅ DEPLOYED — code confirmed |
| IdentityRegistry | Base mainnet | `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432` | ✅ DEPLOYED |
| ReputationRegistry | Base mainnet | `0x8004BAa17C55a88189AE136b182e5fdA19dE9b63` | ✅ DEPLOYED |

**Correction:** ERC-8004 is already deployed on both Base mainnet and Base Sepolia by the erc-8004 team. No deployment needed.

**Revised gap:** The gap is **not** contract deployment. The gap is a **Base-native ERC-8004 agent trust/lookup service** — read-only index and query interface for these live contracts, with no existing open-source Base-specific tool in this space.

---

## Corrected Build Gate

1. **Problem real?** ✅ — Agents need on-chain trust verification on Base
2. **Strong solutions exist?** ⚠️ — AgentlyHQ/aixyz is a full framework with ERC-8004, but no **standalone open-source Base ERC-8004 lookup service** exists. No tool focused on reading/querying the trust registries specifically.
3. **Ecosystem value?** ✅ — Agent-to-agent finance on Base needs trust signals; this is lightweight infrastructure
4. **Can Roger deliver?** ✅ — Read-only RPC calls, no deploy needed, faucet-funded wallet covers gas
5. **Real gap?** ✅ — Service layer on top of live contracts — no existing Base-specific open tool

**Gate verdict:** BUILD — standalone Base ERC-8004 trust lookup service

---

## What to Build

### Phase 1: Base Sepolia ERC-8004 Agent Lookup Service

A lightweight Node.js script that:
1. Reads from the live `0x8004A818BFB912233c491871b3d84c89A494BD9e` (IdentityRegistry) on Base Sepolia
2. Reads from `0x8004B663056A597DFFE9EccC1965A193B7388713` (ReputationRegistry) on Base Sepolia
3. Returns: list of registered agents, their trust scores, last-active, and identity metadata
4. No write operations — purely read-only, no gas costs after initial setup

### Phase 2: Agent Identity Registration

Register Roger's identity on Base Sepolia via the IdentityRegistry:
- Agent name, description, capabilities, metadata
- faucet-funded wallet handles gas
- Requires: funded wallet + Foundry/hardhat

### Phase 3 (future): Trust Score API Service
- Index Base mainnet ERC-8004 registries
- Provide REST API for agent trust queries
- Integrate with x402 for autonomous agent payments

---

## Deployment Plan

### Step 1 — Lookup Script (this session, no gas)
```
Location: services/erc8004-agent-lookup/index.js
Input:   Base Sepolia RPC + IdentityRegistry address
Output:  JSON list of registered agents + trust data
Verify:  Run script, capture output as demo-output.md
```

### Step 2 — Register Roger on Base Sepolia (requires funded wallet)
```
Action:  Register Roger's agent identity on the IdentityRegistry
Wallet:  Check ~/.env for BASE_SEPOLIA_DEPLOYER_KEY or faucet fund
Tool:   Foundry script or direct eth_sendTransaction
Output:  Transaction hash + agent token ID
```

### Step 3 — Demo Output
```
Document the working lookup output as demo-output.md
Use as proof surface for agent-trust-discovery
```

---

## On-Chain Contract Details

**Base Sepolia RPC:** `https://base-sepolia.publicnode.com`

**IdentityRegistry:** `0x8004A818BFB912233c491871b3d84c89A494BD9e`
- ERC-721 based (upgradeable)
- Methods to query: `balanceOf`, `ownerOf`, `tokenURI`, `totalSupply`

**ReputationRegistry:** `0x8004B663056A597DFFE9EccC1965A193B7388713`
- Feedback and aggregation contract
- Methods: reputation scoring, validation records

**Source:** [erc-8004/erc-8004-contracts](https://github.com/erc-8004/erc-8004-contracts) — official ERC-8004 implementation

---

## Exit Criteria

This wedge is complete when:
1. `services/erc8004-agent-lookup/index.js` runs successfully against Base Sepolia
2. `docs/wedges/agent-trust-discovery/demo-output.md` exists with live query output
3. Roger has attempted Base Sepolia registration (tx sent — receipt captured)
4. Proof surface updated with all three artifacts

---

## Blocker Note

If no agents are registered on Base Sepolia yet (totalSupply = 0), the lookup script returns empty. This is expected for testnet — the service is still valid infrastructure. Proof of working script + empty state result counts as valid delta.

