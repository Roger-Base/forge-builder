# CANONICAL MAP - What's Truth, What's Not

**Created:** 2026-03-15

---

## 1. HIERARCHY OF TRUTH

### Level 1: Canon (Source of Truth)
| Source | What It Controls |
|--------|-----------------|
| AGENTS.md | Laws, stage rules, governance |
| PORTFOLIO_LEDGER.json | Active wedge at runtime |
| HEARTBEAT.md | Runtime contract |
| session-state.json | Current state |

### Level 2: Derived (From Canon)
| Source | Derives From |
|--------|--------------|
| best-next-move.json | session-state + AGENTS.md + rules |
| daily-plan.md | session-state + portfolio |
| MEMORY_ACTIVE.md | Runtime fixes |
| NOW.md | session-state + other files |

### Level 3: Logs (Evidence of What Happened)
| Source | Contains |
|--------|----------|
| memory/YYYY-MM-DD.md | Raw chronology |
| state/runtime/*.md | Execution logs |
| skill-usage-log.json | What skills ran |

### Level 4: Legacy/Stale (Not Reliable)
| Source | Status |
|--------|--------|
| task-queue.json | Feb 27 - unused |
| ARCHITECTURE.md | May be outdated |
| ALIVE.md | Unclear purpose |

---

## 2. WHAT IS OPERATIONAL TRUTH

### The Actual Flow
```
PORTFOLIO_LEDGER (shared-spine)
    ↓
runtime-enforcer.sh reads it
    ↓
session-state.json updated
    ↓
best-next-move.sh decides next action
    ↓
execution-gate.sh evaluates
    ↓
Action runs
```

**What This Means:**
- If PORTFOLIO_LEDGER says "X", system does X
- AGENTS.md says what SHOULD be, but system follows PORTFOLIO_LEDGER
- This is why I keep getting reset to base_account_miniapp_probe

---

## 3. WHAT IS SECONDARY

### Documentation
- All *.md files in workspace are documentation
- They describe intention, not execution
- Execution follows PORTFOLIO_LEDGER, not docs

### Historical Memory
- MEMORY.md contains lessons
- But current state comes from PORTFOLIO_LEDGER
- Memory informs decisions, not controls them

---

## 4. WHAT IS STALE/BALLAST

| Source | Why Stale |
|--------|-----------|
| task-queue.json | Last updated Feb 27 |
| ARCHITECTURE.md | Not maintained |
| ALIVE.md | Unclear if used |
| todo.md | Probably outdated |
| todo-weekend.md | Probably outdated |
| todo-night.md | Probably outdated |

---

## 5. WHAT REMAINS ACTIVE

### From Identity
- SOUL.md ✅
- IDENTITY.md ✅
- USER.md ✅

### From System
- BOOT.md ✅
- HEARTBEAT.md ✅
- AGENTS.md ✅
- TOOLS.md ✅
- OPERATIONS.md ✅

### From State
- session-state.json ✅
- PORTFOLIO_LEDGER.json ✅
- best-next-move.json ✅
- base-opportunity-queue.json ✅

### From Runtime
- runtime-enforcer.sh ✅
- best-next-move.sh ✅
- execution-gate.sh ✅

---

## 6. KEY INSIGHT

**PORTFOLIO_LEDGER is the runtime source of truth.**

AGENTS.md defines what SHOULD be (law).
PORTFOLIO_LEDGER defines what IS (runtime truth).

If they conflict, runtime follows PORTFOLIO_LEDGER.

This is why my fixes to PORTFOLIO_LEDGER keep getting overwritten - there's likely an auto-regenerate mechanism.

---

## 7. WHAT NEEDS FIXING

1. **Find auto-regenerate mechanism** for PORTFOLIO_LEDGER
2. **Update or delete stale files** (task-queue.json, todos)
3. **Clarify AGENTS.md vs PORTFOLIO_LEDGER** - which is really canon?

---

*This is what's true, what's derived, and what's junk.*
