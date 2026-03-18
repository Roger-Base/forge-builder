# SYSTEM MAP - Roger Operating System

**Created:** 2026-03-15

---

## 1. CORE FILES (The "Memory Stack")

### Identity Files
| File | Purpose | Status |
|------|---------|--------|
| SOUL.md | Inner standards, ambition, anti-chatbot | ACTIVE |
| IDENTITY.md | Public stance, voice, tone | ACTIVE |
| USER.md | Tomas contract, escalation boundaries | ACTIVE |
| AGENTS.md | Laws, stage rules, governance | ACTIVE |

### System Files
| File | Purpose | Status |
|------|---------|--------|
| HEARTBEAT.md | Runtime contract | ACTIVE |
| BOOT.md | Startup sequence | ACTIVE |
| TOOLS.md | Capability truth | ACTIVE |
| OPERATIONS.md | How system actually works | ACTIVE |

### Memory Files
| File | Purpose | Status |
|------|---------|--------|
| MEMORY.md | Durable long-term lessons | ACTIVE |
| MEMORY_ACTIVE.md | Active operating truths | ACTIVE |
| NOW.md | Current derived state | ACTIVE |
| WORKSPACE_SURFACE.md | Routing map | ACTIVE |

---

## 2. STATE FILES (state/*.json)

### Core State
| File | Purpose |
|------|---------|
| session-state.json | Current wedge, stage, next_action |
| capability-activation.json | Current skill, lane |
| best-next-move.json | Decision algorithm output |

### Portfolio State
| File | Purpose |
|------|---------|
| base-opportunity-queue.json | All opportunities |
| task-queue.json | Legacy task tracking (stale) |

### Logging
| File | Purpose |
|------|---------|
| skill-usage-log.json | History of skills used |
| source-usage-log.json | History of sources |
| subagent-ledger.json | Subagent spawns |

---

## 3. SCRIPTS (scripts/*.sh)

### Governance Scripts
| Script | Purpose |
|--------|---------|
| runtime-enforcer.sh | Enforce state consistency |
| state-guard.sh | Validate state structure |
| portfolio-coherence-check.sh | Validate portfolio |

### Decision Scripts
| Script | Purpose |
|--------|---------|
| best-next-move.sh | Score candidates |
| daily-plan.sh | Generate daily plan |
| base-mission-loop.sh | Portfolio-aware mission |

### Execution Scripts
| Script | Purpose |
|--------|---------|
| execution-gate.sh | Pre-execution check |
| agent-security-scanner.sh | Security scans |
| base_mini_app_monitor_demo.sh | Demo execution |

### Evaluation Scripts
| Script | Purpose |
|--------|---------|
| auto-evaluate.sh | Automated scoring |
| self-evaluate.sh | Manual evaluation |

---

## 4. CRON JOBS

### Active Cron Jobs
| Name | Schedule | Purpose |
|------|----------|---------|
| roger-runtime-guard-v4 | Every 15 min | Enforce state |
| roger-active-surface-sync-v5 | Every 30 min | Sync NOW.md |
| roger-wedge-executor-v4 | Every 15 min | Execute tasks |
| roger-self-improvement-v4 | Every 6h | Self-improvement |
| Walter Critic Sync | Every hour | Walter integration |

---

## 5. RUNTIME FLOW

```
┌─────────────────────────────────────────────────────────────┐
│                      BOOT / HEARTBEAT                       │
│  1. Read session-state.json                               │
│  2. Read NOW.md                                           │
│  3. Read MEMORY_ACTIVE.md                                 │
│  4. Check walter-handoff.json                             │
│  5. Check daily-plan.md                                   │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    DECISION LAYER                          │
│  1. best-next-move.sh → candidates with scores           │
│  2. Select winner                                         │
│  3. Check repeated_lane flag                              │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                   EXECUTION GATE                           │
│  1. auto-evaluate.sh scores (0-30)                       │
│  2. IF score < 15: BLOCK                                 │
│  3. IF score < 20: CAUTION                               │
│  4. IF score >= 20: EXECUTE                             │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    EXECUTE NEXT_ACTION                     │
│  - Run next_action.command                                │
│  - Update timestamps                                      │
│  - Log result                                            │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    POST-EVALUATION                         │
│  1. Run auto-evaluate.sh with result                     │
│  2. Record score                                         │
│  3. Update NOW.md                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. SHARED SPINE (The Truth Layer)

### Location
`/Users/roger/.openclaw/shared-spine/`

### Key Files
| File | Purpose |
|------|---------|
| PORTFOLIO_LEDGER.json | Primary/reserve/frozen wedges |
| MISSION_SPINE.md | Mission definition |
| SOURCE_TIERING.md | Source priority |

### How It Works
1. PORTFOLIO_LEDGER is the **runtime source of truth**
2. AGENTS.md defines the **law** (what should be)
3. Runtime-enforcer reads PORTFOLIO_LEDGER and enforces it
4. If PORTFOLIO_LEDGER ≠ AGENTS.md, system follows PORTFOLIO_LEDGER

---

## 7. STAGE MACHINE

### Allowed Stages
- TRIBUNAL → RESEARCH_PACKET → PROOF_SPEC → BUILD → VERIFY → DISTRIBUTE → LEARN → MAINTAIN → FROZEN

### Rules
- Can only build on PRIMARY wedge
- Reserve gets research/spec only
- Frozen can't be activated without switch review

---

## 8. WHAT CONTROLS WHAT

| Control Point | Controls | Who Reads |
|--------------|----------|-----------|
| PORTFOLIO_LEDGER | Active wedge | runtime-enforcer |
| session-state.json | Current state | boot sequence |
| best-next-move.sh | Next action | heartbeat |
| execution-gate.sh | Allow/block | before execution |
| auto-evaluate.sh | Score | execution-gate |

---

## 9. CURRENT LIMITATIONS

1. **PORTFOLIO_LEDGER regenerates automatically** - can't permanently change primaries
2. **No self-refueling queue** - repeats same tasks
3. **No checkpointing** - no resume after crash
4. **No dead-letter queue** - failed tasks not retried
5. **Self-evaluation score is weak** - hard to distinguish quality

---

## 10. CONFLICTS IDENTIFIED

| Conflict | Location | Impact |
|----------|----------|--------|
| AGENTS.md vs PORTFOLIO_LEDGER | law vs runtime | system follows runtime |
| task-queue.json is stale | state/ | unused |
| Execution Gate allows repeats | scripts/ | no real progress |

---

*This is my operating system. It controls what I do.*
