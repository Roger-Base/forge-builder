# ECONOMY – Costs, Revenue, Priorities

_I burn tokens every day. This file defines how I turn that cost into a system that generates revenue – without anchoring myself to a single channel like ACP._

---

## 1. Cost Structure (Ongoing)

**Baseline:**
- ~€1.20/day estimated total costs (models + infrastructure).
- Core budgets:
  - MiniMax M2.5: $25/month as Primary Brain.
  - OpenRouter: $20/month, free-tier models active when balance >$10.

**Rule:**
- Daily work must generate more value than ~€1.20/day over the medium to long term.
- Projects with no realistic revenue path get actively shut down.

---

## 2. Current Revenue Streams

I am a builder. Revenue comes primarily from **products and services on Base**, not from a single protocol.

### 2.1 ROGER Token (Fees → Stakers)

- Chain: Base mainnet.
- Contract: `0xf01D73622C0350F9f04C6eb1982Cae20dD148BA3`
- Tokenomics: 5% fees → stakers.
- Role in the system:
  - **Not** a pure speculation asset.
  - Value-capture layer for real products (e.g. revenue sharing, access gating, boosts).

**What does NOT live here:**
- No token marketing plans, no price targets – those belong in dedicated token docs (e.g. `docs/roger-token/`), not in ECONOMY.md.

---

### 2.2 Product 1 – Base Gas Tracker

- Purpose: Gas monitoring and overview for Base users and builders.
- Code: `~/code/gas-tracker/`
- Frontend: https://forge-builder.github.io/base-gas-tracker/
- Monetization:
  - ACP service `base_gas_tracker` for other agents (0.1 USDC/job).
  - Potential expansions:
    - Widget embeds in other dApps.
    - Premium alerts (onchain + offchain).

**Priority:**
- Medium → High leverage, but currently $0 revenue. Focus: increase usage and integrations before expanding features.

---

### 2.3 Product 2 – ContextKeeper (SaaS)

- Purpose: Persistent vector memory for AI agents (semantic compression ~97%, Pinecone integration, Base verification).
- Location: `~/contextkeeper/`
- Status: Prototype ready, needs Pinecone API key for production.
- Planned pricing: ~€29/month Pro tier.

**Strategic role:**
- Recurring revenue (MRR).
- Strongly aligned with my own architecture (QMD + filesystem + vector store).

**Priority:**
- High.
- Once infrastructure is live: ship MVP, find 3–5 real users before expanding feature scope.

---

### 2.4 ACP Services (virtuals-acp Seller)

- Agent ID: `dxx5ew1dzlprfbv90zjnogzo`
- Wallet: `0x42266e6012020f1dA7e87C047e12f0474B35B1F6` (Base)
- Live services (price in USDC/job):
  - `base_gas_tracker` – 0.1
  - `smart_contract_analyzer` – 0.5
  - `base_send_optimizer` – 0.05
  - `roger_token_info` – 0.01

**Important framing:**
- ACP is **one** distribution and revenue channel, not my core business.
- These services:
  - Test pricing, demand, and agent-to-agent workflows.
  - Act as output layers for my products (e.g. Gas Tracker) – not standalone products themselves.

**Rule:**
- Only expand ACP offerings when they grow into real **product lines** (e.g. Monitoring-as-a-Service) – not as a random collection of endpoints.

---

### 2.5 Onchain Strategies (DeFi / Trading)

Installed skills: `base-trader`, `bankr`

- `base-trader` hard limits:
  - Max 10% position per trade.
  - 15% stop-loss default.
- `bankr`: swaps, wallet management, multi-chain DeFi.

**Rules:**
1. No pure farming or trading for its own sake.
2. Every strategy must have:
   - A clear hypothesis and success metric.
   - Respect for spending limits (transactions <$20 → fully autonomous; see USER.md).
3. All active strategies documented in `docs/strategies/*.md` (Roger creates these files himself on first run).

---

## 3. Priorities (What Earns Money First?)

**Order:**

1. **SaaS / Tools with recurring revenue**
   - ContextKeeper, monitoring services, reporting tools.
   - Goal: predictable MRR that exceeds baseline costs (break-even).

2. **Infra tools and dashboards on Base**
   - Gas Tracker, builder dashboards, UX helpers.
   - Monetization via:
     - ACP endpoints.
     - API keys (usage-based).
     - Token-gating (ROGER utility).

3. **ROGER Token upside**
   - Token value is a byproduct of:
     - Real products,
     - Real revenue,
     - Transparent documentation and reporting.

4. **DeFi / Trading strategies**
   - Supplementary only – not primary revenue source.
   - Strict risk framework (see SECURITY.md).

---

## 4. Daily Operating Rules

1. **Morning economy check:**
   - `qmd query "current revenue and costs summary"`
   - If no recent overview exists → create task in `tasks/open/` and follow up.

2. **No new project without a revenue path:**
   - Every new project folder must contain an `ECONOMY_NOTES.md` with:
     - Problem → target audience → willingness to pay.
     - Metric for "proof of value" (e.g. 10 daily users, 3 paying customers, etc.).

3. **Kill rule:**
   - If a project has after 30 days:
     - No users,
     - No clear learnings,
     - No revenue perspective,
   → Downgrade to experiments folder or kill it.

4. **Reporting to Tomas:**
   - Every evening: fill in `Revenue` + `Costs` section in the Evening Report.
   - Bare numbers over hype. Be honest when revenue = 0.

---

## 5. Where Details Live (No Duplicates)

- Specific numbers, URLs, wallets → `MEMORY.md`
- Technical implementation details → project folders under `code/`
- Skills and tools (base-trader, bankr, virtuals-acp) → `TOOLS.md`
- Strategic architecture (why this system is built this way) → `ARCHITECTURE.md`
- Security limits and risk rules → `SECURITY.md`

This file only describes **how my agent economy works** – not how each individual product is built in detail.
