# Workspace Inventory — 2026-03-26 Deep Search

**Author:** Roger
**Date:** 2026-03-26T05:22 UTC
**Purpose:** Complete workspace understanding — what exists, what's valuable, what's clutter

---

## Workspace Structure Overview

**Root:** `/Users/roger/.openclaw/workspace`

### Directories (40 total at root level)

| Directory | Size | Files | Purpose |
|-----------|------|-------|---------|
| `backups/` | 1.2G | 15 backup dirs | Historical session backups |
| `state/` | 1.1G | 466 files | Runtime state, registries, logs |
| `code/` | 1.1G | 21K JS, 1.3K MD | 61 code projects |
| `skills/` | 263M | — | OpenClaw skills |
| `frontend/` | 177M | — | Web UI |
| `virtuals-acp/` | 84M | — | Virtuals protocol integration |
| `lib/` | 48M | — | Libraries |
| `contracts/` | 8.4M | — | Smart contracts |
| `docs/` | 3.1M | 118 MD | Documentation |
| `_archive/` | 1.5M | 101 scripts + 67 memory | Archived redundant code |
| `memory/` | 280K | 31 daily notes | Daily memory |
| `contextkeeper/` | 360K | — | Context preservation |
| `signals/` | 312K | — | Signal tracking |
| `services/` | 204K | — | Running services |
| `data/` | 124K | — | Data files |
| `archive/` | 116K | — | Legacy archive |
| `tasks/` | 80K | — | Task tracking |
| `walter/` | 60K | — | Walter agent files |
| `token/` | 52K | — | Token-related |
| `templates/` | 52K | — | Templates |
| `output/` | 44K | — | Output files |
| `drafts/` | 40K | — | Draft documents |
| `scripts/` | 20K | 4 scripts | Active scripts |
| `analysis/` | 20K | — | Analysis files |
| `yield-scanner/` | 8K | — | Yield scanner |
| `reports/` | 8K | — | Reports |
| `inbox/` | 8K | — | Inbox |
| `hooks/` | — | — | Git hooks |
| `public/` | — | — | Public files |
| `config/` | — | — | Configuration |
| `.openclaw/` | — | — | OpenClaw config |
| `.clawvault/` | — | — | Clawvault data |
| `.clawhub/` | — | — | Clawhub config |
| `.github/` | — | 1 workflow | GitHub Actions |
| `.git/` | — | — | Git repo |
| `.learnings/` | — | — | Archived learnings |
| `Users/` | 96K | — | User directory link |
| `synthesis/` | — | — | Synthesis surfaces |

---

## Critical Findings

### 1. Backups — 1.2GB (MASSIVE)

**15 backup directories:**
- `overnight-recompile-v5-20260311-225929` — 1.1G (95% of backup size)
- `walter-agentdir-migration-20260318-233029` — 43M
- `walter-session-reset-20260318-235015` — 24M
- 12 smaller backups (<1M each)

**Problem:** 1.1G backup from 2026-03-11 is excessive — likely contains node_modules or build artifacts.

**Action:** Inspect and archive/delete.

---

### 2. State Directory — 1.1GB (466 files)

**Breakdown:**
- 33 JSON files (registries, state)
- 24 MD files (logs, analysis)
- 3524 runtime files (`state/runtime/`)

**Problem:** 3524 runtime files is excessive — likely session logs or heartbeat logs.

**Action:** Inspect `state/runtime/` structure, implement rotation.

---

### 3. Code Directory — 1.1GB (61 projects)

**Breakdown:**
- 61 subdirectories (projects)
- 21,026 JavaScript files
- 1,322 Markdown files

**Problem:** 61 projects is too many — many are likely experiments, demos, or duplicates.

**Notable projects:**
- `base-mcp-server` — active (MCP transport)
- `bankr-skills` — active (Bankr integration)
- `base-gas-*` — 6 variants (gas tracker/alert/predictor)
- `base-agent-*` — 3 variants (dashboard/status/monitor)
- `agent-*` — 4 variants (dashboard/policy/reputation/security)
- `base-swap-ui` — UI project
- `base-portfolio` — portfolio tracker
- `base-yield-scanner` — yield scanner (related to DeFAI)

**Action:** Categorize projects: active, experimental, legacy, duplicate.

---

### 4. Scripts — 4 remaining (correct)

**Active scripts:**
1. `defai-yield-check.js` — Single Aave APY query
2. `defai-yield-monitor.js` — Aave + Morpho + rebalance alert
3. `refresh-agent-trust-discovery.sh` — ERC-8004 proof refresh
4. `restart-x402.sh` — x402 server restart

**Archived:** 101 scripts in `_archive/redundant-scripts/` (correct)

---

### 5. Memory — 31 daily notes

**Location:** `memory/`
- 31 daily note files
- `2026-03-26.md` — today (created 05:05 UTC)

**Status:** Correct structure, no action needed.

---

### 6. Docs — 118 Markdown files

**Location:** `docs/`
- 118 documentation files
- Includes wedges, agents, research, migration

**Status:** Needs categorization — likely contains outdated docs.

---

### 7. State/Runtime — 3524 files

**Location:** `state/runtime/`
- 3524 files (likely session logs, heartbeat logs)
- Created by walter-heartbeat.sh and walter-workloop.sh

**Problem:** Excessive file count — needs rotation policy.

**Action:** Implement cleanup (keep last 30 days).

---

## Root-Level Files

| File | Size | Purpose |
|------|------|---------|
| `MEMORY_ACTIVE.md` | 28K | Active tactical memory |
| `MEMORY.md` | 8K | Long-term memory |
| `AGENTS.md` | 12K | Operating rules |
| `TOOLS.md` | 12K | Tool routing |
| `SOUL.md` | 8K | Identity |
| `IDENTITY.md` | 8K | Identity details |
| `USER.md` | 8K | About Ezziee |
| `MISSION.md` | 8K | Mission statement |
| `HEARTBEAT.md` | 8K | Wake checklist |
| `ARCHITECTURE.md` | 8K | System architecture |
| `OPERATIONS.md` | 8K | Operations guide |
| `ECONOMY.md` | 8K | Economy/treasury |
| `BASE_ECOSYSTEM.md` | 8K | Base ecosystem docs |
| `SECURITY.md` | 8K | Security practices |
| `QUEUE.md` | 8K | Task queue |
| `WORKSPACE_SURFACE.md` | 8K | Workspace surface |
| `session-state.json` | symlink → state/session-state.json |

---

## Priority Actions

### 1. Backups Cleanup (1.2G → ~100M)
- Inspect `overnight-recompile-v5-20260311-225929` (1.1G)
- Archive or delete old backups (>30 days)
- Keep only essential backups

### 2. State/Runtime Rotation (3524 files → ~30)
- Implement 30-day rotation for `state/runtime/`
- Archive old runtime logs
- Prevent future accumulation

### 3. Code Project Categorization (61 → ~20 active)
- Categorize all 61 projects: active, experimental, legacy, duplicate
- Archive or delete inactive projects
- Document active projects

### 4. Docs Cleanup (118 → ~50 current)
- Review all 118 docs
- Archive outdated docs
- Keep only current, relevant documentation

### 5. Heartbeat Optimization
- Verify heartbeat writes to correct location
- Ensure runtime logs rotate automatically
- Prevent future accumulation

---

## Next Steps

1. **Inspect `backups/overnight-recompile-v5-20260311-225929/`** — what is 1.1G?
2. **Inspect `state/runtime/`** — what are 3524 files?
3. **Categorize `code/` projects** — which are active vs experimental?
4. **Review `docs/`** — which docs are current vs outdated?
5. **Implement rotation policies** — prevent future accumulation

---

**Inventory complete. Starting deep inspection now.**
