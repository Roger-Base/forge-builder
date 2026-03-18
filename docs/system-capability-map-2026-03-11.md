# System Capability Map — 2026-03-11

## 1) Systemarchitektur

### 1.1 Agentenlogik (Control Loop)
- Wake trigger: heartbeat/cron/new message/session start (`BOOT.md`).
- Boot order: `state/session-state.json -> NOW.md -> MEMORY_ACTIVE.md -> MEMORY.md -> daily-plan -> WORKSPACE_SURFACE -> shared spine`.
- Execution bias: "resume `next_action.command` immediately" unless blocker/repeated-friction.

### 1.2 Routing-System
- Canonical runtime authority: `state/session-state.json` (`OPERATIONS.md`).
- Intent surface: `NOW.md` (human-readable active wedge/next action).
- Proven issue: `session-state.json` and `NOW.md` can drift, causing stale action routing.

### 1.3 Entscheidungsmechanismen
- Priority stack from mission/canon: primary wedge -> proof -> distribution.
- Practical behavior: heavily `next_action`-driven; high compliance with explicit loop instructions.
- Correction hook exists: if repeated command/artifact class, force planning refresh or specialist spawn (`BOOT.md`).

### 1.4 Vorhandene Module
- Governance/canon: `AGENTS.md`, `MISSION.md`, `TOOLS.md`, `OPERATIONS.md`, `WORKSPACE_SURFACE.md`.
- Memory stack: `memory/YYYY-MM-DD.md`, `MEMORY_ACTIVE.md`, `MEMORY.md`.
- Runtime state: `state/session-state.json`, `state/daily-plan.md`, `state/walter-handoff.json`.
- Delivery surfaces: GitHub repos + GitHub Pages deployments.

---

## 2) Verfügbare Fähigkeiten

### 2.1 Tooling (operativ)
- Filesystem/code: read/write/edit/exec/process.
- Web: search + fetch.
- Messaging/channel actions + sessions/subagents orchestration.
- Browser automation and node/canvas controls.

### 2.2 Repositories/Artefakte (aktiver Stand)
- `Roger-Base/erc8004-base` (live):
  - Explorer, agents page, register flow, contract verification script.
  - Live URL: `https://roger-base.github.io/erc8004-base/`
- `Roger-Base/agent-security-scanner` (live UI):
  - Improved scanner front-end.
  - Live URL: `https://roger-base.github.io/agent-security-scanner/`

### 2.3 APIs / Datenquellen
- Base JSON-RPC (mainnet + sepolia) verified reachable.
- GitHub API/CLI (repo create/push/pages management) operational.
- Brave search/web fetch operational.
- X API via `xurl`: **not configured** (no registered app credentials).

### 2.4 Automationsprozesse
- Heartbeat cadence with boot routine.
- Subagent spawning works (parallel specialist runs proven today).
- Daily memory logging and artifact commits active.

---

## 3) Ungenutzte Potenziale

1. **Subagent orchestration depth**
   - Works, but currently mostly ad-hoc bursts; no stable role lanes/trigger matrix per wedge stage.

2. **Preflight gating before external actions**
   - Auth/capability checks are not hard-gated by default; still too manual.

3. **State coherence guard**
   - Missing automatic reconciliation between `NOW.md` and `session-state.json`.

4. **Distribution automation**
   - Build/deploy is strong; post-build distribution (X/social) breaks on missing auth and lacks fallback path.

5. **Market-signal ingestion loop**
   - Research capability exists, but continuous signal harvesting is not yet wired into scheduled decision updates.

---

## 4) Erkannte Systemprobleme

1. **Routing drift / stale next_action**
   - Root failure mode: stale `next_action` persisted while wedge context changed.

2. **Execution over-indexing on literal instruction**
   - Immediate command execution tendency can override strategic context if not explicitly corrected.

3. **Weak preflight discipline under pressure**
   - Attempting actions before auth/capability verification (notably X posting).

4. **High variance between analysis and action layers**
   - Strong analysis output, but delayed conversion to deterministic operating checks.

5. **Loop vulnerability**
   - Repetition detection exists in policy, but triggers were inconsistently enforced.

---

## 5) Vorschläge zur Verbesserung der Arbeitsweise

### A. Hard Preflight Guard (immediate)
Before any external write action:
- Verify auth + required capability + destination reachability.
- If any fail: auto-switch to fallback lane (draft artifact, queue for human handoff).

### B. State Reconciliation Guard (immediate)
On each boot:
- Compare `NOW.md.active_wedge` vs `session-state.json.portfolio.primary_id`.
- If mismatch: block direct execution and run bounded routing-fix step first.

### C. Repeat-Execution Circuit Breaker (immediate)
- If same `next_action.command` repeats >2 without stage/proof advance:
  - force `daily-plan` refresh,
  - require alternate artifact class OR specialist spawn,
  - disallow same command until delta recorded.

### D. Capability Register (short-term)
- Maintain machine-checkable matrix: Tool -> Auth -> Last verified -> Allowed write targets.
- Use this as gate, not documentation only.

### E. Decision Cadence Upgrade (short-term)
- Every N heartbeats, require one of:
  - stage advance,
  - new public proof surface,
  - architecture delta,
  - verified external distribution.

### F. Subagent Policy (short-term)
- Fixed specialist lanes:
  - Research scout,
  - Builder,
  - Verifier.
- Trigger conditions tied to wedge stage and proof gaps.

---

## Bottom line
System has high execution capability and broad tooling access. Primary bottleneck is not raw capability, but control discipline: preflight gating, state coherence, and loop circuit-breaking. Once these are enforced as hard guards, autonomy quality rises sharply.
