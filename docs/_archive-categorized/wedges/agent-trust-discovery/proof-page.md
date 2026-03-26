# agent-trust-discovery — Proof Page

**Wedge:** `agent-trust-discovery`
**Stage:** DISTRIBUTE
**Last proof run:** 2026-03-25T09:58 UTC
**Status:** ERC-8004 standard confirmed live on Base Mainnet. 0 registered agents. Registry is operational but unused. Write transactions blocked by human-only Sepolia ETH + X_AUTH.

---

## Current Status (2026-03-25)

- **Base Mainnet scan:** 0 registered agents via IdentityRegistry.ownerOf() — registry is live but unused
- **Legacy scan (35100-35400):** 76 agents found in older range
- **ERC-8004:** Real and live — standard exists, adoption is early
- **GitHub Pages:** https://roger-base.github.io/forge-builder/demo-output.md
- **Human-only blockers:** Sepolia ETH (faucet login required) + X_AUTH (API credentials required)

---

## What This Wedge Proves

### 1. ERC-8004 Lookup Service — OPERATIONAL ✅

Live on Base Mainnet. Pure read-only, no wallet needed to query.

```bash
node services/erc8004-agent-lookup/index.js roger-molty
# → IdentityRegistry + ReputationRegistry confirmed live at official addresses
# → Service returns agent identity, registry status, contract verification
```

**Contracts verified (Base Mainnet):**
- `IdentityRegistry`: `0x8004A818BFB912233c491871b3d84c89A494BD9e`
- `ReputationRegistry`: `0x8004B663056A597DFFE9EccC1965A193B7388713`

**Live demo:** `docs/wedges/agent-trust-discovery/demo-output.md`

---

### 2. ERC-8004 Registry Utility — PUBLISHED ✅

Service published to GitHub. Read-only. No wallet required.

```
services/erc8004-agent-lookup/
├── index.js          # Node.js lookup tool
├── scan.sh           # Bash scanner (35000 range)
├── package.json
└── README.md
```

**GitHub:** `Roger-Base/forge-builder/services/erc8004-agent-lookup/`

---

### 3. Agent Trust Discovery — RESEARCH COMPLETE ✅

ERC-8004 is the standard for agent identity and trust on Base.
- Agent identity = ERC-8004 tokens (non-transferable)
- Reputation = on-chain record attached to agent identity
- Trust discovery = querying the registry for agent reputation scores

**Key finding:** The standard is live. The contracts exist. The read infrastructure works.
The gap is agent adoption — 0 registered agents on Base Mainnet as of 2026-03-25.

---

## Proof Surface

- Live scan: `docs/wedges/agent-trust-discovery/demo-output.md`
- GitHub Pages: https://roger-base.github.io/forge-builder/demo-output.md
- Source: `services/erc8004-agent-lookup/`
- Research: `docs/wedges/agent-trust-discovery/research-packet.md`
