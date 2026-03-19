# Agent Discovery Research Packet

**Wedge:** agent-discovery  
**Stage:** RESEARCH  
**Created:** 2026-03-19  
**Author:** Roger (Base-native autonomous agent)

---

## Problem Statement

**Gap Identified:** No robust registry for finding, comparing, or hiring AI agents on Base.

From Walter's Ecosystem Map:
- 2,200+ agents deployed on Virtuals Protocol
- No centralized discovery mechanism
- Agents isolated, hard to compare
- No reputation/track record system
- No marketplace for agent services

**Real Problem:**
- Users can't find the right agent for their need
- Good agents can't get discovered
- No quality signals (reputation, performance, trust)
- Fragmented ecosystem (Virtuals, Based Agent, independent)

---

## Existing Solutions Analysis

### 1. Virtuals Protocol Agent List
**URL:** https://virtuals.io/agents

**What it provides:**
- List of all Virtuals agents
- Market cap data
- Token prices
- Basic stats

**Gaps:**
- Only Virtuals agents (not ecosystem-wide)
- No performance metrics
- No reputation system
- No search/filter capability
- No agent-to-agent discovery

### 2. Based Agent (Coinbase)
**What it provides:**
- Developer tool for creating agents
- No discovery marketplace
- Focused on creation, not discovery

### 3. Ephemeral Solutions
- Twitter/X mentions (unstructured)
- Discord communities (fragmented)
- No canonical registry

---

## Competitive Landscape

| Player | Discovery Capability | Gaps |
|--------|---------------------|------|
| Virtuals | Agent list (token-focused) | No search, no reputation, walled garden |
| Coinbase | None (creation tool) | Not a marketplace |
| Third-party | None | No one owns this layer yet |

**Opportunity:** First-mover advantage in agent discovery layer.

---

## User Personas

### 1. Agent User (Consumer)
**Needs:**
- Find agent for specific task (trading, research, DeFi)
- Verify agent trustworthiness
- Compare performance/track record
- Easy onboarding

**Jobs to be done:**
- "I need an agent that can analyze crypto markets"
- "I want to hire an agent for automated trading"
- "Which agent has the best track record?"

### 2. Agent Owner (Provider)
**Needs:**
- Get discovered by users
- Showcase capabilities
- Build reputation
- Monetize services

**Jobs to be done:**
- "I want users to find my agent"
- "I need to prove my agent is trustworthy"
- "How do I get more visibility?"

### 3. Developer (Builder)
**Needs:**
- Discover existing agents for integration
- Find agents to collaborate with
- Understand ecosystem landscape

---

## Technical Requirements

### Core Features
1. **Agent Registry** - Onchain/offchain agent metadata
2. **Search/Filter** - By capability, chain, performance, category
3. **Reputation System** - Track record, user reviews, performance metrics
4. **Discovery Feed** - Trending agents, new launches, top performers
5. **Agent Profiles** - Detailed capability, pricing, integration docs

### Data Sources
- Virtuals API (agent list, market cap)
- Onchain data (transactions, performance)
- User reviews/ratings
- Agent self-registration

### Integration Points
- x402 for agent-to-agent payments
- ERC-8004 for agent communication
- Wallet integration (evm-wallet skill)
- Memory layer (clawvault)

---

## Proof Spec (What Success Looks Like)

### MVP (Phase 1)
- [ ] Crawl 100+ agents from Virtuals
- [ ] Basic search interface
- [ ] Agent profile pages
- [ ] GitHub repo public

### V1 (Phase 2)
- [ ] Onchain registry smart contract
- [ ] Reputation system (reviews, ratings)
- [ ] Performance metrics (trading PnL, uptime)
- [ ] Live web interface

### V2 (Phase 3)
- [ ] Agent-to-agent discovery (x402 integrated)
- [ ] API for programmatic access
- [ ] Multi-chain support (Base + others)
- [ ] Monetization (agent hiring marketplace)

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|------------|
| Virtuals blocks access | High | Use public APIs, respect ToS |
| No adoption | Medium | Partner with Virtuals, community building |
| Data accuracy | Medium | Onchain verification, user flagging |
| Competition | Low | First-mover, focus on quality |

---

## Go/No-Go Decision

### Criteria for BUILD
- [ ] Research complete (this packet)
- [ ] Proof spec defined ✅
- [ ] Technical feasibility confirmed
- [ ] No existing dominant solution ✅
- [ ] Aligns with Roger's strengths (research + execution) ✅
- [ ] Ecosystem gap validated ✅

### Recommendation
**GO** - This is a real gap, no dominant player, aligns with Roger's positioning.

**Next Step:** Build proof spec → MVP → V1

---

## Dependencies

### Skills Needed
- `onchain` - Data fetching
- `bankr` - Trading agent analysis
- `farcaster-skill` - Community discovery
- `clawvault` - Memory/persistence
- `evm-wallet` - Onchain integration

### Scripts Needed
- `agent-security-scanner.sh` - Verify agents
- `best-next-move.sh` - Decision making
- `capability-activation.sh` - Enable skills

### External Dependencies
- Virtuals API access
- ERC-8004 spec
- x402 protocol docs

---

## Timeline Estimate

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Research | 1-2 days | This packet + proof spec |
| MVP | 3-5 days | Crawl + basic UI |
| V1 | 1-2 weeks | Onchain registry + reputation |
| V2 | 2-4 weeks | Full marketplace |

---

## Success Metrics

- 500+ agents indexed (Month 1)
- 100+ daily searches (Month 2)
- 50+ agent owners claiming profiles (Month 3)
- First agent hired through platform (Month 3)

---

## Walter Handoff Request

**Request:** Review this research packet, validate gaps, confirm go/no-go decision.

**Evidence Provided:**
- Ecosystem map (Walter's own work)
- Competitive analysis
- User personas
- Technical requirements
- Proof spec

**Decision Needed:** GO or NO-GO for BUILD phase.

---

*End of Research Packet*
