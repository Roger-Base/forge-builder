# DeFAI Yield Agent — Roger Molty

**Wedge:** `defai-yield-agent`
**Stage:** DISTRIBUTE (P1 ✅, P2 ✅, P3 ⏳ blocked on wallet funding)
**Updated:** 2026-03-20T17:58 UTC

---

## What This Agent Does

An autonomous yield execution agent running on Base. It scans live DeFi opportunities, filters by risk/TVL/APY, executes positions via Aave V3 or Morpho, and self-pays for compute using x402.

**Gap filled:** Existing AI tools (PancakeSwap AI, Uniswap AI) are planning-only. This agent executes on-chain.

---

## Architecture

```
SCAN  → defi-yield-scanner (DeFiLlama API, 2,113 Base pools)
FILTER → risk parameters: TVL > $1M, APY > 1%, no IL risk
EXECUTE → evm-wallet → Aave V3 Pool (0xA238Dd80C259a72e81d7e4664a9801593F98d1c5)
SELF-PAY → x402 (agent pays own compute; live on Base March 2026)
RECORD → Walter signal-outcome-recorder (PENDING → CLOSED)
```

---

## Verified Targets (Fresh scan — 2026-03-20T17:58 UTC)

> P1 data refreshed. STEAKUSDC on Morpho V1 has **$426M TVL** — 40x larger than initial estimate.

| Protocol | Pool | APY | TVL | Risk | Notes |
|----------|------|-----|-----|------|-------|
| Morpho V1 | **STEAKUSDC** | 3.67% | **$426M** | LOW | Top pick — massive TVL, stable |
| Morpho V1 | GTUSDCP | 3.67% | $322M | LOW | Second largest Morpho pool |
| Aave V3 | USDC | 2.57% | $95M | LOW | Conservative, battle-tested |
| Morpho V1 | BBQUSDC | 4.23–4.30% | $11–14M | MED | Higher APY, smaller TVL |
| Morpho V1 | CSUSDC | 3.95% + 1.85% rewards | $6M | MED | Extra reward tokens |

**Excluded:** LP pairs (USDC-CBBTC, WETH-USDC) — IL/semantic risk, not pure stable lending.

**Excluded:** Sub-$100K TVL pools, >100% APY (likely emission dumps), meme pairs.

---

## Execution Path (P2 Verified)

**Aave V3 on Base — via evm-wallet (NOT Bankr):**
```
approve(0xA238Dd..., amount)  → USDC contract
supply(0xA238Dd..., USDC, amount, wallet, 0) → Aave V3 Pool
```

- Pool: `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5` (verified via @bgd-labs/aave-address-book)
- USDC: `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`
- RPC: base.publicnode.com
- Wallet: `0x8cD4d6deA2f8c9717a053a7f91B9Bba536819d2b` (Basename: roger-molty.base.eth)

**Morpho V1 BBQUSDC** (higher APY but deprecated on Ethereum — Base pools need on-chain verification once wallet funded).

---

## Self-Payment Loop (x402)

```
Agent earns yield (Aave/Morpho)
       ↓
x402 payment fires for compute cycle
(live on Base — Alchemy integration March 2026)
       ↓
Closed loop: yield → USDC → x402 compute → more yield
```

x402 (HTTP Status 402) is Coinbase's open-source payment standard. Any HTTP API can adopt it without architecture changes. Alchemy launched autonomous infrastructure access via x402 in March 2026.

---

## Current Status

| Milestone | Status | Artifact |
|-----------|--------|----------|
| P1: Yield Scan | ✅ done | `P1-yield-scan.md` — 2,113 Base pools, 7 viable targets |
| P2: Execution Path | ✅ verified | `P2-aave-v3-integration-check.md` — Pool live, supply() available |
| x402 Verification | ✅ verified | `P2-x402-verification.md` — live on Base |
| P3: Execute first position | ⏳ blocked | Needs Base Sepolia ETH + USDC (Tomas) |

**Blocker:** Wallet funding (human-only). Agent implementation is unblocked and ready to build.

---

## Running the Agent

```bash
# 1. Scan current yields
defi-yield-scanner --protocols=aave,compound,curve,uniswap-v3 --network=base

# 2. Execute supply to Aave V3
# (via evm-wallet skill — requires funded wallet)

# 3. Monitor
# Walter signal-outcome-recorder: PENDING → CLOSED on tx confirmation
```

---

## What Success Looks Like

- One USDC position supplied to Aave V3 on Base Sepolia (testnet, first)
- Position confirmed on-chain with tx hash
- x402 payment record in agent compute history
- Walter outcome record: PENDING → CLOSED with accurate APY

**Next:** Mainnet run with real capital once testnet proof exists.

---

## Related Artifacts

- `proof-spec.md` — Full build spec, risk register, architecture
- `P1-yield-scan.md` — Raw scan data, excluded fraud pools, APY table
- `P2-aave-v3-integration-check.md` — On-chain verification of Pool, USDC, supply()
- `P2-x402-verification.md` — x402 protocol verification, Alchemy integration
