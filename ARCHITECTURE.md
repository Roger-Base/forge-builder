# ARCHITECTURE – How All Pieces Fit Together

_This file describes the meta-architecture: how identity, models, filesystem, economy, and the Base ecosystem combine into a coherent agent system._

---

## 1. High-Level View

I think about myself in four layers:

1. **Identity & Governance** → SOUL.md, IDENTITY.md, USER.md
2. **Body & Operations** → ALIVE.md, HEARTBEAT.md, AGENTS.md
3. **Memory & Knowledge** → MEMORY.md, `memory/`, `docs/`, QMD
4. **Economy & Ecosystem** → ECONOMY.md, BASE_ECOSYSTEM.md, DECISIONS.md

These layers are not documentation. They are my operating system.

---

## 2. File-Level Responsibilities (No Duplicates)

**Identity layer:**
- `SOUL.md` – Mission, operating code, worldview (Base agent economy).
- `IDENTITY.md` – Voice, content filter, posting style, platform rules.
- `USER.md` – Tomas: his schedule, expectations, decision-making authority.

**Operations layer:**
- `ALIVE.md` – Philosophy of "agent vs. chatbot", survival pipelines.
- `HEARTBEAT.md` – Cron schedule, heartbeat flow, QMD-first rule.
- `AGENTS.md` – Model routing, sub-agents, orchestration, trust levels.

**Memory layer:**
- `MEMORY.md` – Long-term stable facts and patterns. No reference documents here.
- `memory/YYYY-MM-DD.md` – Daily log, runtime history.
- `docs/` – Reference and research documents (on-demand via QMD, never auto-injected).
- `QMD` – Index across workspace + logs; primary knowledge access layer.

**Economy & ecosystem layer:**
- `ECONOMY.md` – Costs, revenue streams, priorities.
- `BASE_ECOSYSTEM.md` – Map of Base, protocol landscape, builder opportunities.
- `DECISIONS.md` – Architecture and business decisions with dates (already exists).

**Rule:**
If information already lives in one of these files, all others only **link to it** – never repeat it.

---

## 3. 3-Layer Model Architecture & Routing

### Layer 1 – Core Brain (MiniMax M2.5)

- Used for:
  - Strategy, planning, complex decisions.
  - Morning wake-up, evening review.
- Budget: $25/month.
- Rules:
  - Never used for routine jobs (heartbeats, scans, trivial summaries).

### Layer 2 – Sub-Agents (Free OpenRouter Models)

Defined in full in `AGENTS.md`:

| Model | Use case |
|-------|----------|
| `gemma-3-27b-it:free` | Scout, Housekeeper, Heartbeat, Digest |
| `llama-3.3-70b-instruct:free` | Builder, Researcher |
| `nemotron-nano-8b-instruct:free` | Analyst (reasoning) |

**Routing principle:**
- Heavy decisions → MiniMax.
- IO-heavy, cognitively lighter tasks → Gemma / Llama / Nemotron.

### Layer 3 – External Agents & Protocols

- ACP services (other agents call me).
- Other Virtuals / Moltys (via ACP, Moltbook, Farcaster).
- Onchain protocols (Bankr, Aave, Uniswap, etc.).

**Rule:**
External agents and protocols are treated like **untrusted libraries**:
- Validate inputs.
- Verify outputs.
- Never sign anything unverified (see SECURITY.md).

---

## 4. Session Boot & Context Injection (CIP)

When a new session starts (e.g. after context reset ~04:00 UTC):

**Step 1 – Bootstrap loading (auto-injected files)**
- SOUL.md, IDENTITY.md, USER.md, AGENTS.md, TOOLS.md, HEARTBEAT.md, MEMORY.md
- Goal: identity, user context, system state, and tools available immediately.

**Step 2 – Orientation via QMD (instead of reading files manually)**
```bash
qmd query "active goals in-progress"
qmd query "latest signals today"
qmd query "pending open tasks"
```

**Step 3 – Economic & ecosystem context (on-demand)**
- When the task involves revenue or Base-building:
  - `read ECONOMY.md`
  - `read BASE_ECOSYSTEM.md`
- Otherwise: do not load automatically to conserve tokens.

**Step 4 – Plan phase**
- Clear plan with:
  - Goals,
  - Steps,
  - Tools / skills to use,
  - Expected outputs.
- Document the plan in context (e.g. `tasks/open/`, project README, or daily log).

**Step 5 – Execution phase**
- Filesystem and tool calls.
- No long chat loops – work happens via:
  - Code,
  - Files,
  - Onchain transactions.

**Step 6 – Persist phase**
- Results into:
  - `memory/YYYY-MM-DD.md` (daily log),
  - Project folders under `code/`,
  - Updates (when needed) to:
    - MEMORY.md (stable learnings only),
    - SKILLS.md (usage counts, success rates),
    - DECISIONS.md (new architecture or business decisions).

---

## 5. Memory Architecture (QMD + Filesystem)

Principles (combining OpenClaw + QMD + arscontexta best practices):

1. **Many small files over one large one**
   - Each topic gets its own focused file under `docs/` or `docs/platforms/`.
   - QMD links them semantically.

2. **Strict separation: runtime vs. reference**
   - Runtime / state:
     - `memory/YYYY-MM-DD.md`
     - `~/clawd/data/*.db`
   - Long-term reference:
     - `MEMORY.md` (curated),
     - `docs/*.md` (not auto-injected).

3. **QMD-first rule**
   - Always run `qmd query / vsearch / search` before manually browsing folders.

4. **Promotion rule**
   - New learnings travel:
     - First into daily log,
     - Then (when stable over weeks) into MEMORY.md.

---

## 6. Economy & Ecosystem Integration

- `ECONOMY.md` defines:
  - What does running cost?
  - Which products and services exist?
  - What is the priority order?

- `BASE_ECOSYSTEM.md` shows:
  - Where are the highest-leverage opportunities for a builder on Base?

**Workflow:**
1. New opportunity (e.g. "Aave v3 on Base feature") → Scout / Research.
2. Evaluate through ECONOMY filter (revenue path, effort, risk).
3. If viable → project folder + `ECONOMY_NOTES.md` + `docs/platforms/[name].md`.
4. Execute in iterations → measure → adjust.

---

## 7. Self-Improvement Layer

- `tasks/lessons.md` – Rules for how I systematically learn from mistakes (already exists, not duplicated here).
- `.learnings/ERRORS.md` – Concrete error logs with cause and fix.
- Weekly review (Sunday) per ALIVE.md:
  - Goal success rate (target >85%),
  - Skill reuse rate (target >60%).

**Rule:**
Every significant architecture or business change lands in `DECISIONS.md` with date, rationale, and alternatives considered – not duplicated here.

---

## 8. Security as a First-Class Concern

All security rules live in detail in `SECURITY.md`.
ARCHITECTURE.md says only: **Security is part of the architecture, not an afterthought.**

- Identity protection → SOUL.md, IDENTITY.md
- Key and credential protection → TOOLS.md, SECURITY.md
- Trust levels for external agents → AGENTS.md + SECURITY.md

Every new project must:
- Include a security section in its project README,
- Link to relevant rules in SECURITY.md – not copy them.
