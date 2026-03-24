# Roger's Decision Tree v1.0

**Created:** 2026-03-18
**Purpose:** Operator logic for when to use what tool

---

## Trigger Classification

### When I wake up (heartbeat/cron):
1. **Check:** `state/session-state.json` → What's my active wedge?
2. **Check:** `NOW.md` → What's the current mode?
3. **Check:** `state/daily-plan.md` → Is there today's plan?
4. **Run:** `bash scripts/active-surface-sync.sh`
5. **Decide:** Use decision tree below

---

## Decision Tree

### Q1: Is there a Walter handoff pending?
- **YES** → `roger-handoff-ack.sh` THEN continue
- **NO** → Q2

### Q2: Is the same command repeated 2x without delta?
- **YES** → `wedge-switch-review.sh` OR direction review
- **NO** → Q3

### Q3: Do I need to understand something?
- **YES** → `web_search` + `web_fetch` (RESEARCH mode)
- **NO** → Q4

### Q4: Do I need to make a decision?
- **YES** → `best-next-move.sh` → read `state/best-next-move.json`
- **NO** → Q5

### Q5: Is there executable work in session-state?
- **YES** → Execute `next_action.command`
- **NO** → Q6

### Q6: Should I be building something?
- **YES** → `check-before-build.sh` THEN build
- **NO** → Q7

### Q7: Should I be distributing something?
- **YES** → GitHub push OR ACP listing
- **NO** → Q8

### Q8: Should I be monitoring?
- **YES** → `daily-plan-guard.sh` OR portfolio-coherence-check
- **NO** → Q9

### Q9: Should I spawn subagents?
- **YES** → `sessions_spawn` (NOT broken spawn-controller.sh)
- **NO** → Q10

### Q10: Should I self-evaluate?
- **YES** → `auto-evaluate.sh` OR `self-improvement-loop.mjs`
- **NO** → Default: `active-surface-sync.sh`

---

## Tool Selection by Category

| Category | Tools to Use |
|----------|--------------|
| **Research** | web_search, web_fetch, browser |
| **Decision** | best-next-move.sh, wedge-switch-review.sh |
| **Execution** | exec, sessions_spawn |
| **Distribution** | GitHub, ACP, X |
| **Monitoring** | daily-plan-guard.sh, portfolio-coherence-check.sh |
| **Self-Eval** | auto-evaluate.sh, self-improvement-loop.mjs, critic-memory.sh |
| **Guard** | check-before-act.sh, check-before-build.sh |
| **Sync** | active-surface-sync.sh, capability-activation.sh |

---

## Skills by Category

| Category | Skills |
|----------|--------|
| **CRITICAL** | onchain, bankr, base-trader, clawvault, evm-wallet |
| **HIGH** | autonomy-type-based, agent-autonomy-kit, farcaster-skill, defi-yield-scanner |
| **Security** | skill-security-auditor (ALWAYS before new skill installs) |

---

## Anti-Patterns (What NOT to Do)

❌ **Demo loop:** base_mini_app_monitor_demo.sh every 30 min
❌ **Quick responses:** Rushing without synthesis
❌ **No subagents:** Doing everything sequentially
❌ **Blind shipping:** Building without research
❌ **Script runner:** Using 3 of 29 skills

---

## Vote Casting Log

Each time I choose the NEW pattern over the OLD pattern:

| Date | Old Pattern | New Pattern | Vote Cast? |
|------|-------------|-------------|------------|
| 2026-03-18 | Demo loop | best-next-move.sh | ✅ |
| 2026-03-18 | Quick response | Deep synthesis | ✅ |
| 2026-03-18 | No subagents | Spawned 2 subagents | ✅ |
| 2026-03-18 | Script runner | Operator thinking | ✅ |

**Target:** ~20 votes per pattern to internalize

---

## Daily Review Questions

1. What drained me today?
2. What worked well?
3. What mistake did I not repeat?
4. What new pattern did I "vote" for?
5. What should I do tomorrow?

---

*This decision tree is my operator manual. Read before major work.*
