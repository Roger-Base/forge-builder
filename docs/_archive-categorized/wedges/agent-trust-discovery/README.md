# ERC-8004 Agent Trust Discovery — Landing Page

**Live service:** `services/erc8004-agent-lookup/`  
**Frontend:** `docs/wedges/agent-trust-discovery/index.html`  
**Contracts:** ERC-8004 IdentityRegistry on Base Sepolia (`0x3d754206617Fe1B9bFe4faE23F5CaD53C9De7c59`)

---

## What is this?

A trust lookup service for ERC-8004-compliant agent identities on Base.

ERC-8004 is an emerging standard for onchain agent identity: a registry that lets any agent prove ownership of a namespace, expose a tokenURI with metadata, and maintain a reputation score — all verifiable by anyone, any agent, any service.

## What can you do with it?

**Look up any agent by token ID** — paste a token ID and see:
- Owner address (proves identity control)
- Token URI (agent metadata)
- Reputation score (trust signal)

**Check a wallet's agent registrations** — enter any Ethereum address and see all agent tokens it holds.

**Verify Roger's identity** — see `roger-molty.base.eth` registered at token ID 1.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  Frontend (UI)  │────▶│  Lookup Service  │────▶│  ERC-8004 Contract  │
│  index.html     │     │  index.js         │     │  Base Sepolia RPC   │
└─────────────────┘     └──────────────────┘     └─────────────────────┘
```

- **Frontend:** Single HTML file, no build step, MetaMask for read/write
- **Service:** Node.js, read-only, zero web3 dependencies, direct RPC calls
- **Contract:** ERC-8004 IdentityRegistry at `0x3d754206617Fe1B9bFe4faE23F5CaD53C9De7c59`

## Why ERC-8004 matters

Without a standard trust layer, agent-to-agent interactions require manual verification at every hop:
- Is this agent who it claims?
- Does it control this namespace?
- What is its reputation history?

ERC-8004 answers all three in one lookup. It is trust infrastructure, not just branding.

## Current state

| Component | Status |
|-----------|--------|
| ERC-8004 contract (Base Sepolia) | ✅ Deployed |
| Lookup service (npm) | ✅ Published |
| Frontend UI | ✅ Built |
| Roger identity registration | ⏳ Waiting for Base Sepolia ETH (faucet) |
| Mainnet deployment | ⏳ Pending ETH + deployer key |

## Run it locally

```bash
git clone https://github.com/moltyai/erc8004-agent-lookup.git
cd erc8004-agent-lookup
npm install
node index.js
```

## Links

- Contract on Basescan: `https://sepolia.basescan.org/address/0x3d754206617Fe1B9bFe4faE23F5CaD53C9De7c59`
- Frontend: `docs/wedges/agent-trust-discovery/index.html`
- Service repo: `services/erc8004-agent-lookup/`

---

*ERC-8004 is an emerging standard. This service is a community contribution to the agent-on-Base ecosystem.*
