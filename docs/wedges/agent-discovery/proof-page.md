# Agent Discovery — Proof Page

**Wedge:** agent-discovery
**Stage:** DEPLOYED → DISTRIBUTE
**Last updated:** 2026-03-20T08:23 UTC

**Proof surface confirmed:** 2026-03-20T08:22 UTC — all gates GREEN (research-packet, proof-spec, sample-audit, proof-page, frontend live)

## What this wedge is

Onchain AI agent registry on Base — ERC-721 based with a reputation system (ratings, reviews, staking, verified flags). Frontend live at [https://roger-base.github.io/forge-builder/](https://roger-base.github.io/forge-builder/).

## Proof artifacts

| Artifact | Status | Path |
|----------|--------|------|
| Research packet | ✅ | `docs/wedges/agent-discovery/research-packet.md` |
| Proof spec | ✅ | `docs/wedges/agent-discovery/proof-spec.md` |
| Demo output | ✅ | `docs/wedges/agent-discovery/demo-output.md` |
| Contract spec | ✅ | `docs/wedges/agent-discovery/v1-contract-spec.md` |
| API docs | ✅ | `docs/API.md` |
| Usage guide | ✅ | `docs/USAGE.md` |
| Deployment guide | ✅ | `docs/wedges/agent-discovery/DEPLOYMENT.md` |
| Proof page | ✅ | this file |
| Frontend | ✅ | https://roger-base.github.io/forge-builder/ |
| GitHub repo | ✅ | `code/forge-builder/` |

## What's live

- Frontend: 96 agents listed, live on GitHub Pages (vite base path fixed 2026-03-19)
- AgentRegistry.sol: compiled (Solc 0.8.33), 51 ABI functions, ERC-721 + ERC-2981
- Docs: API, USAGE, DEPLOYMENT all shipped

## DISTRIBUTE gate status

| Gate | Status | Note |
|------|--------|------|
| Frontend live | ✅ | |
| Docs complete | ✅ | API + USAGE + DEPLOYMENT |
| AgentRegistry onchain | 🔴 | Blocked — `DEPLOYER_KEY` not set (human-only) |
| GitHub repo public | ✅ | `code/forge-builder/` |
| Proof surface complete | ✅ | This file |

## Human action needed to complete DISTRIBUTE

```
# 1. Fill in DEPLOYER_KEY in contracts/.env.example → save as .env
# 2. Fund deployer: https://www.coinbase.com/faucets/base-sepolia-faucet
# 3. Deploy:
cd /Users/roger/.openclaw/workspace/contracts
source .env
forge create --rpc-url $BASE_SEPOLIA_RPC --private-key $DEPLOYER_KEY src/AgentRegistry.sol:AgentRegistry
```

## Next proof move after deployment

1. Register 10 test agents on Base Sepolia
2. Submit test reviews (1 per 24h per agent rate limit)
3. Verify reputation calculation
4. Audit (security + gas optimization)
5. Deploy to Base mainnet

---

*agent-discovery proof page — generated 2026-03-20T00:21Z*
