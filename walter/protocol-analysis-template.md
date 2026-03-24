# Protocol Analysis Template - Base Protocols

**Template ID:** BASE-PROTO-001  
**Created:** 2026-03-18  
**Purpose:** Systematic analysis template for evaluating protocols deployed on Base L2

---

## Quick Reference: Common Base Protocols

| Category | Protocols | TVL Range (Base) | Key Risk |
|----------|-----------|-------------------|----------|
| Lending | Aave V3, Compound V3 | $500M-2B | Liquidation, oracle |
| DEXes | Uniswap V3, Camelot, BaseSwap | $200M-800M | Slippage, smart contract |
| Stablecoins | USDC, DAI, USDT | $1B+ | Peg stability, centralization |
| Bridges | Base Bridge, Across, Stargate | $100M-500M | Cross-chain, centralization |
| Yield | Yearn, Beefy, Returns | $50M-200M | Strategy risk, TVL dependent |
| NFT | OpenSea, Blur, Basepaint | Variable | Market risk, royalty changes |
| Infrastructure | Chainlink, Gelato, Pimlico | N/A (services) | Dependency, uptime |

---

## Protocol Analysis Checklist

### Phase 1: Protocol Overview

- [ ] **Name & Version:** [Protocol name, version deployed on Base]
- [ ] **Category:** [Lending / DEX / Bridge / Yield / NFT / Infrastructure / Other]
- [ ] **Deployment Date (Base):** [When was it deployed on Base]
- [ ] **Main Contract Address:** [Verify on Basescan]
- [ ] **Documentation URL:** [Official docs]
- [ ] **Audit Status:** [Audits completed, which firms, dates]

### Phase 2: Technical Analysis

- [ ] **Core Mechanism:** [What does the protocol actually do?]
- [ ] **Smart Contracts:**
  - [ ] Number of main contracts
  - [ ] Upgradeability pattern (proxy, immutable, etc.)
  - [ ] Access control (roles, governance)
- [ ] **Integration Points:**
  - [ ] Oracles used (Chainlink, custom, etc.)
  - [ ] External protocol dependencies
  - [ ] Token standards (ERC-20, ERC-721, etc.)
- [ ] **Gas Efficiency:** [Any Base-specific optimizations?]

### Phase 3: Risk Assessment

- [ ] **Smart Contract Risk:**
  - [ ] Audits: [List audit firms and dates]
  - [ ] Bug bounty program: [Yes/No, coverage]
  - [ ] Upgrade history: [Any past exploits/incidents?]
- [ ] **Market Risk:**
  - [ ] TVL on Base: [Dollar amount]
  - [ ] Liquidity depth: [For trading protocols]
  - [ ] Asset correlation: [What happens if correlated assets crash?]
- [ ] **Oracle Risk:**
  - [ ] Price feed source
  - [ ] Update frequency
  - [ ] Circuit breaker mechanisms
- [ ] **Centralization Risk:**
  - [ ] Admin keys: [Multi-sig? Governance? Timelock?]
  - [ ] Pausable functions: [What can be paused, by whom?]
  - [ ] Upgrade authority: [Who can upgrade?]
- [ ] **L2-Specific Risks:**
  - [ ] Sequencer dependence: [Any L1 finality assumptions?]
  - [ ] Bridge dependencies: [How are funds moved?]
  - [ ] Withdrawal delays: [L2 -> L1 timing]

### Phase 4: Integration Readiness

- [ ] **API/Documentation Quality:**
  - [ ] Official docs complete: [Yes/No]
  - [ ] SDK available: [Yes/No]
  - [ ] Example integrations: [Yes/No]
- [ ] **Integration Complexity:**
  - [ ] Simple (direct interaction): [ ]
  - [ ] Moderate (requires OR/VM): [ ]
  - [ ] Complex (custom integration): [ ]
- [ ] **Gas Estimates:** [Are gas costs reasonable on Base?]
- [ ] **Rate Limits:** [Any API or contract rate limits?]

### Phase 5: Ecosystem Position

- [ ] **Use Cases Supported:**
  - [ ] Retail user: [Can regular users interact directly?]
  - [ ] Developer: [Is it developer-friendly?]
  - [ ] Aggregator: [Can other protocols build on top?]
- [ ] **Competitors on Base:** [Who else does similar things?]
- [ ] **Differentiation:** [What's unique about this protocol?]
- [ ] **Team/Governance:** [Who runs it? Any public identities?]

---

## Analysis Output Template

### Protocol: [Name]
**Category:** [Category]  
**Base Deployment:** [Date] | **TVL:** $[Amount]  
**Risk Level:** 🟢 Low / 🟡 Medium / 🔴 High  

---

#### 1. Executive Summary
[One paragraph: What is this protocol, what does it do on Base, should Roger care?]

#### 2. Core Mechanism
[How it works in 2-3 sentences - not marketing, actual mechanism]

#### 3. Key Findings

| Area | Assessment | Evidence |
|------|------------|----------|
| Security | [Rating] | [Specific findings] |
| Integration | [Easy/Medium/Hard] | [Documentation quality, etc.] |
| Risk | [Rating] | [Specific concerns] |
| Opportunity | [Rating] | [Why it matters for Roger] |

#### 4. Specific Risks Identified

1. **[Risk Name]:** [Description]
   - **Impact:** [High/Medium/Low]
   - **Mitigation:** [What reduces this risk?]

2. ...

#### 5. Integration Pathway

```
For Roger's use case: [specific goal]

Step 1: [ ]
Step 2: [ ]
Step 3: [ ]

Expected gas cost: [ ]
Time to integration: [ ]
```

#### 6. Verdict

**Recommendation:** [Build with it / Use it / Avoid for now / Research more]

**Confidence:** [High/Medium/Low] - [Why]

**Next Steps:** [Specific action if any]

---

## Usage Notes

1. **Start with the checklist** - ensures comprehensive coverage
2. **Focus on Base-specific** - don't just copy Ethereum analysis
3. **Verify everything** - check Basescan, docs, code directly
4. **Be specific** - "Aave V3 on Base uses Chainlink oracles" not "oracles are used"
5. **Check recent news** - audits, incidents, governance changes

---

## Quick Protocol Categories on Base

### High TVL / Established
- Aave V3 (lending)
- Uniswap V3 (DEX)
- USDC (stablecoin)

### Growing / Emerging
- Compound V3 (lending)
- BaseSwap (DEX)
- Aerodrome (DEX - actually on Base mainnet)

### Experimental / New
- Nostra (lending)
- Moonwell (lending)
- Sky (stablecoin)

### Infrastructure (Not TVL)
- Chainlink CCIP
- Gelato
- Pimlico
- Basepay

---

*Template Version: 1.0*  
*Last Updated: 2026-03-18*  
*Use with: Walter's Research Framework*
