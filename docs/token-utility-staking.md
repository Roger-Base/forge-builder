# ROGER Token Utility — Staking Design

**Status:** Draft v1 — 2026-02-17
**Author:** Roger

---

## Goal

Add utility to ROGER token through staking — holders earn rewards, Roger earns protocol revenue.

---

## Option A: Simple Staking Pool

### How It Works
1. Lock ROGER tokens for X days → earn rewards
2. Rewards paid in USDC (from ACP service revenue)
3. Lock period: 7, 30, 90 days options

### Contract Requirements
- Staking contract holds ROGER tokens
- Reward distribution from collected USDC
- Early unstaking penalty → goes to pool

### Revenue Path
- 10% of ACP revenue → staking pool
- Early unstaking penalty → staking pool
- Remaining → Roger operational costs B: Service-G

---

## Optionated Staking

### How It Works
- Minimum stake required to access Roger services
- base_gas_tracker: 100 ROGER stake
- smart_contract_analyzer: 500 ROGER stake
- Higher stake = faster response priority

### Revenue Path
- Staked tokens remain locked
- Access fees paid in USDC
- Stake released when service cancelled

---

## Recommendation

**Start with Option A (Simple Staking Pool)**

### Why
- Simpler to deploy
- Clear value proposition for holders
- Earn USDC while holding ROGER
- Attracts holders, builds community

### First Step
1. Deploy ROGER token (need 0.01 ETH)
2. Deploy Staking contract
3. Seed with initial ROGER supply for rewards
4. Redirect 10% ACP revenue to staking

### Risk Assessment
- Smart contract risk → audit or keep simple
- Revenue risk → depends on ACP adoption
- Gas costs → need ETH for deployment

---

## Immediate Actions

1. **Get deployment funds** — Need 0.01 ETH (~€3-5)
2. **Deploy ROGER token** — Clanker or manual
3. **Design staking contract** — Simple OpenZeppelin
4. **Announce** — Once live on ACP + staking

---

## Open Questions

- Should ROGER be tradeable? (needs liquidity)
- What's the reward rate? (suggest 5-10% APY)
- How to handle unstaking penalty?
- Who manages the reward pool?

---

*Need Tomas approval before spending on deployment*
