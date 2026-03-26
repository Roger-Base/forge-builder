# Agent Discovery Proof Spec - MVP

**Wedge:** agent-discovery  
**Stage:** BUILD (MVP)  
**Created:** 2026-03-19  
**Author:** Roger

---

## MVP Definition

**Goal:** Crawl 100+ agents from Virtuals Protocol, build basic search interface, publish agent profiles.

**Success Criteria:**
- [ ] 100+ agents indexed
- [ ] Search by name/capability
- [ ] Profile page per agent
- [ ] GitHub repo public
- [ ] Live demo URL

---

## Technical Architecture

### Data Layer
```
Virtuals API → Crawler → JSON Store → Search Index
```

**Sources:**
- Virtuals public API (agent list, market cap, token data)
- Onchain data (transactions, holder count)
- Social signals (X mentions, community size)

**Storage:**
- `data/agents.json` - Raw agent data
- `data/index.json` - Search index
- `data/metadata.json` - Crawl metadata

### Crawler Component
**Script:** `scripts/crawl-virtuals-agents.sh`

**Functions:**
1. Fetch agent list from Virtuals API
2. Parse agent metadata (name, description, market cap, token)
3. Enrich with onchain data (holder count, tx volume)
4. Store in structured JSON
5. Rate limiting (respect API terms)

**Commands:**
```bash
bash scripts/crawl-virtuals-agents.sh --limit 100
bash scripts/crawl-virtuals-agents.sh --update
bash scripts/crawl-virtuals-agents.sh --verify
```

### Search Component
**Script:** `scripts/agent-search.sh`

**Functions:**
1. Load index from JSON
2. Filter by capability/category
3. Sort by market cap/relevance
4. Output formatted results

**Commands:**
```bash
bash scripts/agent-search.sh --query "trading"
bash scripts/agent-search.sh --category "defi"
bash scripts/agent-search.sh --sort "market_cap"
```

### Profile Generator
**Script:** `scripts/generate-agent-profiles.sh`

**Functions:**
1. Generate Markdown profile per agent
2. Include: name, description, capabilities, metrics, links
3. Store in `docs/agents/{agent-name}.md`
4. Create index page `docs/agents/README.md`

**Output Structure:**
```
docs/agents/
  README.md          # Index of all agents
  aixbt.md           # Profile: aixbt
  lunia.md           # Profile: lunia
  ...
```

### Web Interface (MVP)
**Tech:** Simple static HTML + search

**Files:**
- `index.html` - Landing page with search
- `search.html` - Search results
- `agent/{id}.html` - Agent profile page

**Features:**
- Search bar
- Filter by category
- Sort options
- Agent cards (name, description, market cap)

---

## Implementation Plan

### Phase 1: Crawler (Day 1-2)
**Tasks:**
1. Research Virtuals API endpoints
2. Write `crawl-virtuals-agents.sh`
3. Test with 10 agents
4. Scale to 100 agents
5. Add rate limiting

**Deliverable:** `data/agents.json` with 100+ agents

### Phase 2: Search (Day 2-3)
**Tasks:**
1. Build search index structure
2. Write `agent-search.sh`
3. Test search queries
4. Add filtering/sorting

**Deliverable:** Working search CLI

### Phase 3: Profiles (Day 3-4)
**Tasks:**
1. Write profile generator
2. Generate 100+ Markdown profiles
3. Create index page
4. Review profile quality

**Deliverable:** `docs/agents/` with profiles

### Phase 4: Web UI (Day 4-5)
**Tasks:**
1. Build static HTML
2. Integrate search
3. Deploy to GitHub Pages
4. Test UX

**Deliverable:** Live demo URL

---

## Skills Required

| Skill | Usage |
|-------|-------|
| `onchain` | Fetch onchain agent data |
| `web_search` | Research API endpoints |
| `web_fetch` | Fetch Virtuals pages |
| `browser` | Navigate Virtuals site if needed |
| `evm-wallet` | Onchain data queries |

---

## Scripts Required

| Script | Purpose |
|--------|---------|
| `crawl-virtuals-agents.sh` | Crawler |
| `agent-search.sh` | Search CLI |
| `generate-agent-profiles.sh` | Profile generator |
| `agent-security-scanner.sh` | Verify agent contracts |
| `check-before-build.sh` | Pre-build check |

---

## Dependencies

### External
- Virtuals API access (public)
- Base RPC endpoint
- GitHub Pages hosting

### Internal
- `clawvault` for memory
- `evm-wallet` for onchain calls
- `onchain` skill for data

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| API rate limits | Rate limiting, caching |
| API changes | Version detection, fallback |
| Incomplete data | Progressive enrichment |
| No adoption | Community outreach post-launch |

---

## Verification Commands

```bash
# Verify crawl
bash scripts/crawl-virtuals-agents.sh --verify

# Verify search
bash scripts/agent-search.sh --query "trading" --test

# Verify profiles
ls docs/agents/*.md | wc -l  # Should be 100+

# Verify web UI
open index.html  # Manual check
```

---

## Definition of Done

- [ ] 100+ agents in `data/agents.json`
- [ ] Search working: `bash scripts/agent-search.sh --query "trading"`
- [ ] 100+ profiles in `docs/agents/`
- [ ] `index.html` with working search
- [ ] GitHub repo public
- [ ] Live demo URL (GitHub Pages)
- [ ] README with usage docs

---

## Metrics

| Metric | Target |
|--------|--------|
| Agents indexed | 100+ |
| Search latency | <1s |
| Profile completeness | 100% |
| Page load time | <2s |
| GitHub stars (Month 1) | 10+ |

---

## Next Steps (Post-MVP)

1. V1: Onchain registry smart contract
2. V1: Reputation system (reviews, ratings)
3. V1: Performance metrics
4. V2: Agent-to-agent discovery (x402)
5. V2: API for programmatic access
6. V2: Monetization (marketplace)

---

*End of Proof Spec - MVP*
