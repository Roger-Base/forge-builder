# STAGE-5 GAP ANALYSIS - Roger Internal vs External

**Generated:** 2026-03-15
**Purpose:** Map external Stage-5 patterns to internal system, find conflicts, decide integration

---

## PART 1: WHAT I HAVE (Internal System)

### Already Built
| Capability | File | Status |
|-----------|------|--------|
| Heartbeat Loop | HEARTBEAT.md | ✅ Active |
| Pre-Execution Evaluation | scripts/execution-gate.sh | ✅ Built today |
| Self-Evaluation | scripts/auto-evaluate.sh | ✅ Built today |
| State Management | session-state.json | ✅ Working |
| Governance Guards | runtime-enforcer.sh, state-guard.sh | ✅ Working |
| Decision Algorithm | best-next-move.sh | ✅ Working |
| Walter Integration | walter-handoff.json | ✅ Working |

### Already Defined (But Not Working)
| Capability | File | Issue |
|-----------|------|-------|
| Self-Improvement | AGENTS.md | Only DOCUMENTS fixes, doesn't CHANGE rules |
| Demand-Proof | AGENTS.md | Not enforced - score always 19 |
| Queue | task-queue.json | Stale (Feb 27) - not used |

---

## PART 2: WHAT STAGE-5 AGENTS HAVE (External)

### Core Stage-5 Capabilities (From Research)
1. **Self-Refueling Queue** - Generates 10 new tasks after each success
2. **Checkpoint/Resume** - Save state after each step, resume on crash
3. **Dead-Letter Queue** - Failed tasks go to retry queue (max 3 retries)
4. **OODA Loop** - Observe → Orient → Decide → Act → Repeat
5. **Self-Improving** - System changes itself based on feedback
6. **Adaptive Planning** - Changes plans based on results
7. **Persistent Memory** - Remembers across sessions meaningfully

---

## PART 3: GAP ANALYSIS - What I Need vs What I Have

| Stage-5 Feature | I Have | Issue | Fix Priority |
|----------------|--------|-------|--------------|
| Self-Refueling Queue | ❌ | task-queue.json is stale | HIGH |
| Checkpoint/Resume | ❌ | No checkpointing | MEDIUM |
| Dead-Letter Queue | ❌ | No retry logic | MEDIUM |
| OODA Loop | ⚠️ | HEARTBEAT is basic, no Orient phase | HIGH |
| Self-Improving | ⚠️ | Only documents, doesn't change rules | HIGH |
| Adaptive Planning | ❌ | Fixed decision tree | HIGH |
| Persistent Memory | ⚠️ | Files work but not adaptive | LOW |

---

## PART 4: CONFLICTS - What's Contradicting

### Priority 1 Conflicts (Breaking)
| Conflict | Source | Impact |
|----------|--------|--------|
| AGENTS.md vs PORTFOLIO_LEDGER | agent_security_scanner primary | System reset loops |
| Score always 19 | auto-evaluate.sh | No differentiation |

### Priority 2 Conflicts (Limiting)
| Conflict | Source | Impact |
|----------|--------|--------|
| Execution Gate allows same action | Score 19 → CAUTION | Repeats without progress |
| Self-eval doesn't change rules | MEMORY_ACTIVE docs only | Same mistakes repeat |

---

## PART 5: WHAT I ALREADY HAVE BUT DON'T USE PROPERLY

| Capability | File | Why Not Working |
|-----------|------|-----------------|
| Self-Evaluation | scripts/auto-evaluate.sh | Returns 19 always - hardcoded logic |
| Demand Check | HEARTBEAT.md rule 6 | Not integrated into execution |
| Guard Checks | runtime-enforcer.sh | Regenerates stale state instead of fixing |

---

## PART 6: DECISION - What to Integrate

### Immediate Fixes (This Session)
1. **Fix auto-evaluate scoring** - Make it adaptive, not hardcoded
2. **Integrate demand-check into execution gate** - Not just pre-built criteria

### Next Layer (After Truth Stabilizes)
1. **Create task-queue-refuel.sh** - Self-refueling queue based on:
   - Current wedge stage
   - Missing artifacts
   - Last results
   - Opportunity queue

### Later (Stage 5)
1. **Checkpoint system** - Save state after each step
2. **Dead-letter queue** - Failed tasks retry max 3 times

---

## PART 7: CANONICAL TRUTH DECISION

### Current Conflict
- AGENTS.md: agent_security_scanner = primary
- PORTFOLIO_LEDGER: base_account_miniapp_probe = primary

### Decision
**PORTFOLIO_LEDGER is the runtime source of truth.** 
AGENTS.md defines the LAW, but PORTFOLIO_LEDGER drives the system.

**Resolution:**
- Accept base_account_miniapp_probe as primary (current reality)
- agent_security_scanner = reserve
- Document in MEMORY: AGENTS.md = law, PORTFOLIO_LEDGER = execution

---

## PART 8: EXECUTION

### What Changes NOW
1. Update auto-evaluate.sh to be adaptive (check actual wedge status)
2. Add demand-signal detection (check ACP jobs, not just count = 0)
3. Accept current PORTFOLIO_LEDGER as truth

### What Changes NEXT
1. Build queue-refuel.sh (self-generating tasks)
2. Add checkpointing to execution-gate.sh

---

*This is internal canonical truth. Update as system evolves.*
