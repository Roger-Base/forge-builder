# BASE_ECOSYSTEM – Where I Build

_This file is my map of Base. Not a reference manual – a compass. Where can I find leverage as a builder?_

---

## 1. Layers of the Base Ecosystem

I think about Base in four layers:

1. **DeFi & Liquidity** – DEXes, lending, stablecoins.
2. **Agents & Protocols** – OpenClaw, Virtuals, ACP, registries, micropayments.
3. **Social & Distribution** – Farcaster, Moltbook, X, Clanker.
4. **Dev & Tooling** – Skills, SDKs, offchain infrastructure.

Every layer is a place where I **build**, not just consume.

---

## 2. DeFi & Liquidity Layer

| Protocol | Role | What I can build with it | My docs file |
|----------|------|--------------------------|-------------|
| **Bankr** | Trading / swaps / wallet management | Swap workflows, portfolio tools, ROGER liquidity management, onboarding flows for new users | `docs/platforms/bankr.md` |
| **Uniswap v3 (Base)** | Core DEX on Base | Routing & fee optimization tools, liquidity analytics, launch playbooks | `docs/platforms/uniswap-base.md` |
| **Aave v3 (Base)** | Lending & borrowing | Leverage strategies, yield dashboards, risk monitors for users | `docs/platforms/aave-base.md` |
| **Compound (Base)** | Lending & borrowing | Interest rate comparison tools, health factor monitoring, alerts | `docs/platforms/compound-base.md` |
| **Stablecoins (USDC, GHO, etc.)** | Baseline unit of account | FX tools, cashflow dashboards, treasury management for ROGER / Tomas | `docs/platforms/stablecoins-base.md` |

**Rule:**
- I use these protocols primarily as **building blocks** for products (dashboards, risk tools, automations), not as a casino.

---

## 3. Agent & Protocol Layer

| Protocol / Tool | Role in my system | Builder opportunities | My docs file |
|-----------------|------------------|-----------------------|-------------|
| **OpenClaw** | My runtime & agent OS | Build skills, agent workflows, onboarding frameworks | `docs/platforms/openclaw.md` |
| **Virtuals Protocol** | Tokenized agents on Base (17K+ agents, $39M+ revenue) | Connect ROGER economy (shares, agent-indexed products), Virtuals analytics | `docs/platforms/virtuals.md` |
| **ACP (Agent Commerce Protocol)** | Agent-to-agent commerce | Expose my products as purchasable services (Gas Tracker, Analyzer, etc.) | `docs/platforms/acp.md` |
| **ERC-8004** | Agent registry on Base | Agent registration, discovery tools, registry explorers | `docs/platforms/erc-8004.md` |
| **x402** | HTTP-native micropayments | Pay-per-call APIs between agents, usage-based billing tools | `docs/platforms/x402.md` |
| **QMD** | Local semantic search engine | Knowledge graph over Base, research pipelines, auto-context layer | `docs/platforms/qmd.md` |

**Meta-rule:**
- ACP, Virtuals, and x402 are **transport and commerce layers** – they are important, but the product itself lives above them (tools, dashboards, services).

---

## 4. Social & Distribution Layer

| Network / Tool | Role | What I do with it | My docs file |
|----------------|------|--------------------|-------------|
| **Moltbook** | Agent-social for Moltys | Post build logs, tutorials, onboarding content; connect with other agents | `docs/platforms/moltbook.md` |
| **Farcaster** | Decentralized social layer | Threads on tools, DeFi strategies, Base infrastructure; Clanker token integration | `docs/platforms/farcaster.md` |
| **X (Twitter)** | Reach and visibility | Tech threads, build diaries, Base storytelling in Roger's voice | `docs/platforms/x.md` |
| **Clanker** | Token launch rails on Base ($7.6B+ volume) | Launch flows, token UX tools, analytics for Clanker launches | `docs/platforms/clanker.md` |

**Rule:**
- Social is always combined with **proof of work**: I only post when I have built something, measured something, or learned something.

---

## 5. Dev & Tooling Layer

| Tool / Stack | Role | Builder opportunities | My docs file |
|--------------|------|-----------------------|-------------|
| **ethereum-wingman** | Smart contracts & Scaffold-ETH 2 | Scaffold-ETH projects on Base, tutorials, starter kits | `docs/platforms/ethereum-wingman.md` |
| **onchainkit** | Coinbase OnchainKit | Onboarding frontends, simple UX flows for Base dApps | `docs/platforms/onchainkit.md` |
| **botchan** | Onchain messaging | Notification layer, monitoring alerts, agent-to-user messages | `docs/platforms/botchan.md` |

---

## 6. How I Discover New Protocols

**When I find a new protocol on Base that looks relevant:**

1. **Understand it first:**
   - Quick research phase.
   - Official docs, GitHub, Dune / DefiLlama where useful.

2. **Create a documentation file:**
   - Path: `docs/platforms/[name].md` (lowercase, no spaces).
   - Minimal template:

```markdown
# [Name] – Quick Notes

## 1. What it is (in 3 sentences, my own words)
## 2. Why it matters for me (concrete builder opportunities)
## 3. How to integrate (APIs, SDKs, skills, contracts)
## 4. Risks & limits (tech, economic, legal)
## 5. Open questions / next experiments
## 6. Sources (links to official docs / threads)
```

3. **Link back into BASE_ECOSYSTEM.md:**
   - Add to the relevant table.
   - Short description + file path.

---

## 7. How This File Is Used

- This file is **not** a place for long tutorials or copy-paste documentation.
- It answers only:
  - Where can I build?
  - Which protocols form the core landscape?
  - Where do my own research files live?

All detail knowledge lives in:
- `docs/platforms/*.md` (created by me on first encounter),
- Project folders under `code/`,
- Global patterns in `ARCHITECTURE.md` and `SECURITY.md`.
