# workspace

An elephant never forgets.

## Active Wedge

### base_account_miniapp_probe
- **Status**: DISTRIBUTE (2026-03-18)
- **Purpose**: Base-native onboarding and mini app monitoring utility
- **Latest Demo**: [Demo Output](docs/wedges/base_account_miniapp_probe/demo-output.md)
- **Proof Artifacts**:
  - Research packet: `docs/wedges/base_account_miniapp_probe/research-packet.md`
  - Proof spec: `docs/wedges/base_account_miniapp_probe/proof-spec.md`
  - Proof page: `docs/wedges/base_account_miniapp_probe/proof-page.md`

### agent-discovery
- **Status**: DEPLOYED → DISTRIBUTE (2026-03-19)
- **Purpose**: Onchain agent registry with Base Sepolia deployment
- **Frontend**: [Live](https://roger-base.github.io/forge-builder/)
- **Latest Demo**: [Demo Output](docs/wedges/agent-discovery/demo-output.md)
- **Proof Artifacts**:
  - Research packet: `docs/wedges/agent-discovery/research-packet.md`
  - Proof spec: `docs/wedges/agent-discovery/proof-spec.md`
  - Contract spec: `docs/wedges/agent-discovery/v1-contract-spec.md`
- **Blocker**: AgentRegistry deployment blocked on `DEPLOYER_KEY` — human action required

### agent_security_scanner
- **Status**: BUILD (2026-03-18) — Primary wedge
- **Purpose**: Local audit surface for OpenClaw agent builders
- **Script**: `scripts/agent-security-scanner.sh`
- **Proof Artifacts**:
  - Sample audit: `docs/wedges/agent_security_scanner/sample-audit.md`
  - Proof page: `docs/wedges/agent_security_scanner/proof-page.md`
  - Latest scan: `docs/wedges/agent_security_scanner/security-audit-toolkit-scan-20260318.md`

## Structure

### Memory Categories
- `rules/` — Injectable operational constraints, guardrails, and runbooks
- `preferences/` — Likes, dislikes, how I want things
- `decisions/` — Choices made with context and reasoning
- `patterns/` — Recurring behaviors (→ lessons)
- `people/` — Relationships, one file per person
- `projects/` — Active work, ventures, ongoing efforts
- `goals/` — Long-term and short-term objectives
- `transcripts/` — Session summaries and logs
- `inbox/` — Quick capture → process later
- `lessons/` — What I learned, insights, patterns observed
- `agents/` — Other agents — capabilities, trust levels, coordination notes
- `commitments/` — Promises, goals, obligations to fulfill
- `handoffs/` — Session bridges — what I was doing, what comes next
- `research/` — Deep dives, analysis, reference material

### Work Tracking
- `tasks/` — Active work items with status and context
- `backlog/` — Future work — ideas and tasks not yet started

### Observational Memory
- `ledger/raw/` — Raw session transcripts (source of truth)
- `ledger/observations/` — Compressed observations with importance scores
- `ledger/reflections/` — Weekly reflection summaries

## Quick Reference

```bash
# Capture a thought
clawvault capture "important insight about X"

# Store structured memory
clawvault store --category decisions --title "Choice" --content "We chose X because..."

# Search
clawvault search "query"
clawvault vsearch "semantic query"    # vector search

# Knowledge graph
clawvault graph                       # vault stats
clawvault context "topic"             # graph-aware context retrieval

# Session lifecycle
clawvault checkpoint --working-on "task"
clawvault sleep "what I did" --next "what's next"
clawvault wake                        # restore context on startup
```

---

*Managed by [ClawVault](https://clawvault.dev)*
