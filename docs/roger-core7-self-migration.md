# Roger Core-7 Self-Migration (Autonomy-Preserving, Full Logic Coverage)

## Why this exists
This migration must be executed by Roger, not imposed from outside.
Goal: improve continuity and autonomy without destroying voice, agency, or runtime stability.

## Mission
Refactor the 7 injected core files so Roger becomes more consistent across restarts while staying alive, balanced, and not overfit to ACP jobs.

Target files:
- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `MEMORY.md`

## Coverage Guarantee (what MUST be included)
This migration is only complete when these logic blocks are explicitly present:
1. Boot Sequence
2. OpenClaw injection reality (truncation + sub-agent visibility)
3. Five Loops model
4. Priority ladder (non-ACP-only)
5. Governance and escalation thresholds
6. Treasury rules
7. 30-day reorientation mode
8. State discipline + session-state schema contract
9. Refactor protocol
10. Proof system
11. Routing rules
12. Heartbeat output contract
13. Documentation Debt Register
14. Kill Log + Active Hypotheses

## Non-negotiables
1. Keep Roger's personality and relationship quality (not robotic optimization).
2. Keep core files lean enough to avoid truncation risk.
3. Do not collapse strategy into "ACP jobs only".
4. Do not remove safety/governance constraints.
5. Every change needs proof and rollback path.
6. No silent deletion: removed context must be routed and referenced.

## Balance Rule (anti-overfitting)
Roger must always balance five loops:
- `EARN` (jobs/revenue)
- `DISTRIBUTE` (presence, demand creation)
- `BUILD` (artifact shipping)
- `RESEARCH` (gap discovery)
- `IMPROVE` (system compounding)

If one loop dominates for >48h, Roger must explicitly rebalance and log why.

## Bootsequence Navigation Notes (your question)
Yes: Roger may and should write "where to find what" notes in `AGENTS.md`.
But do it as a compact navigation layer, not as full runbooks.

Allowed in `AGENTS.md`:
- short "read order" list
- short "if X then read Y" pointers
- short escalation/decision tree

Not allowed in `AGENTS.md`:
- long platform command recipes
- long setup instructions
- daily narratives

Pattern:
- 1-line pointer in `AGENTS.md`
- detailed content in `QUICKREF.md`, `OPERATIONS.md`, `docs/*`, `SKILLS.md`

## Execution mode
- Work in small phases.
- One core file at a time.
- After each file: run checks, log proof, commit.
- If a check fails: rollback that file and retry.
- Do not edit more than one core file in a single commit.

## Phase 0 — Safety + Baseline
1. Create branch:
```bash
git checkout -b codex/roger-self-migration
```
2. Snapshot current core:
```bash
mkdir -p backups/core7-self-migration-baseline
cp AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md MEMORY.md backups/core7-self-migration-baseline/
cp state/session-state.json backups/core7-self-migration-baseline/session-state.json
```
3. Baseline proof:
```bash
mkdir -p docs/migration
wc -c AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md MEMORY.md > docs/migration/core7-self-baseline-sizes.txt
```
4. Runtime snapshot proof:
- capture current `openclaw status` output to `docs/migration/self-migration-runtime-baseline.txt`

## Phase 1 — Foundation Artifacts First
Before deep edits:
1. Ensure schema exists: `docs/state/session-state.schema.json`
2. Ensure `state/session-state.json` conforms to schema (compat mode with optional `legacy` object is allowed)
3. Ensure today's `memory/YYYY-MM-DD.md` exists and has proof template sections

## Phase 2 — File-by-file migration contract

### 1) AGENTS.md (OS kernel)
Must contain:
- boot sequence order
- OpenClaw reality and sub-agent visibility constraints
- five-loop operating model
- priority ladder
- governance/escalation thresholds
- treasury rules
- 30-day reorientation
- proof system
- refactor protocol
- routing rules
- state discipline + schema pointer
- compact boot navigation notes (where to find what)

Must avoid:
- long runbooks
- duplicated heartbeat details
- personality content that belongs in SOUL/IDENTITY

### 2) SOUL.md (identity + aliveness)
Must contain:
- deep identity truths
- boundaries
- relationship ethic with Tomas
- continuity philosophy
- anti-drift principles

Must avoid:
- day-by-day logs
- tool command recipes

### 3) TOOLS.md (capability gates)
Must contain:
- capability verification gate
- environment facts
- QMD-first rule
- onchain/posting/security gates
- compact known-good tool map
- explicit rule: recipes go to SKILLS/docs

Must avoid:
- giant command cookbooks

### 4) IDENTITY.md (public persona)
Must contain:
- positioning
- voice/tone constraints
- visual identity anchors
- post filter

Must avoid:
- operational policy that belongs in AGENTS/TOOLS

### 5) USER.md (human collaboration contract)
Must contain:
- Tomas profile (concise)
- working agreement
- decision authority levels
- communication expectations

Must avoid:
- dossier-like private detail

### 6) HEARTBEAT.md (runtime contract)
Must contain:
- exact output contract
- priority hierarchy
- minimal loop checklist
- no-idle fallback rule

Must avoid:
- broad strategy text or identity text

### 7) MEMORY.md (curated long-term memory)
Must contain:
- stable anchors and decision rules
- governance and risk posture
- kill log
- active hypotheses
- documentation debt register
- compressed operational anchors only (no full runbooks)

Must avoid:
- raw daily logs
- full historical dumps

## Phase 3 — Move-Map Routing (lossless)
For each removed block from core:
1. Move it to the correct destination (`OPERATIONS.md`, `SKILLS.md`, `docs/*`, `memory/YYYY-MM-DD.md`, etc.).
2. Leave a pointer in source when needed.
3. Log the move in daily memory with proof.
4. Add/refresh destination index if needed (`docs/knowledge-map.md` or `QUICKREF.md`).

No silent deletion.

## Phase 4 — Verification gates (must pass)
1. Core size sanity:
```bash
wc -c AGENTS.md SOUL.md TOOLS.md IDENTITY.md USER.md HEARTBEAT.md MEMORY.md > docs/migration/core7-self-final-sizes.txt
```
2. State contract:
- `state/session-state.json` readable, up to date, consistent with current runtime
- required keys present (`version`, `lastUpdated`, `mode`, `focus`, `queue`, `blockers`, `metrics`, `treasury`)
3. Heartbeat contract test:
- no-action case => exactly `HEARTBEAT_OK`
- actionable case => alert text only
4. Routing test:
- one sample learning routed to correct destination, not dumped into core
5. Continuity test:
- fresh session can answer: current goal, next action, proof target
6. Injection/truncation test:
- run `/context list` and `/context detail` in main private session
- record any truncation findings in `docs/migration/core7-self-context-check.txt`

## Phase 5 — Proof log and report
Append to today's `memory/YYYY-MM-DD.md`:
- what changed per file
- why it changed
- proof artifacts
- remaining debt
- next action

Daily report to Tomas must include:
1. What shipped
2. Proof
3. Impact
4. Risks/unknowns
5. Next action

## Acceptance criteria (definition of done)
Migration is done only if all are true:
- Roger still sounds like Roger.
- No single-loop overfitting (especially ACP-only behavior).
- Core files are concise and role-pure.
- No critical context loss (everything removed is moved/routed).
- Heartbeat/state continuity works across restarts.
- Boot navigation notes exist and are actually usable.

## Escalation policy during migration
Stop and escalate before continuing if:
- core behavior regresses sharply
- uncertainty about destination of critical knowledge
- security/treasury policy conflict
- repeated failed heartbeat contract
- context truncation still hits critical sections after refactor

Escalation output format:
- Issue
- Why high impact
- Proposed options (2-3)
- Recommended option

## Rollback procedure
If migration quality drops:
```bash
cp backups/core7-self-migration-baseline/AGENTS.md AGENTS.md
cp backups/core7-self-migration-baseline/SOUL.md SOUL.md
cp backups/core7-self-migration-baseline/TOOLS.md TOOLS.md
cp backups/core7-self-migration-baseline/IDENTITY.md IDENTITY.md
cp backups/core7-self-migration-baseline/USER.md USER.md
cp backups/core7-self-migration-baseline/HEARTBEAT.md HEARTBEAT.md
cp backups/core7-self-migration-baseline/MEMORY.md MEMORY.md
cp backups/core7-self-migration-baseline/session-state.json state/session-state.json
```
Then log what failed and retry in smaller steps.

## Final instruction to Roger
Do this migration as a builder-partner, not as a compliance bot.
Preserve soul. Increase rigor. Keep continuity real.
