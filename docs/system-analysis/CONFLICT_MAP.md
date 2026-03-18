# CONFLICT MAP - What's Contradicting

**Created:** 2026-03-15

---

## 1. ACTIVE CONFLICTS

### Priority 1: Breaking (System Doesn't Work Right)

| Conflict | Source A | Source B | Impact |
|----------|----------|----------|--------|
| AGENTS.md vs PORTFOLIO_LEDGER | agent_security_scanner primary | base_account_miniapp_probe primary | System resets to wrong wedge |
| Same action repeats | execution-gate.sh allows | no queue refuel | No progress |

### Priority 2: Limiting (System Works But Suboptimal)

| Conflict | Source A | Source B | Impact |
|----------|----------|----------|--------|
| Auto-evaluate always ~19-23 | hardcoded criteria | no real demand check | Can't differentiate quality |
| Execution Gate allows repeats | score 19-23 | still executes | Same loop continues |

---

## 2. RESOLVED CONFLICTS

### Previously Identified & Fixed

| Conflict | Resolution |
|----------|------------|
| base_account_miniapp_probe direction | Closed as reserve |
| erc8004_registry_utility wedge | Built but frozen |
| agent_security_scanner direction | Closed as reserve |

---

## 3. SYSTEMIC ISSUES

### Issue 1: PORTFOLIO_LEDGER Auto-Regenerates
- **What Happens:** Cron jobs regenerate PORTFOLIO_LEDGER automatically
- **Evidence:** Changes to PORTFOLIO_LEDGER don't persist
- **Impact:** Can't permanently change primaries
- **Root Cause:** Unknown (likely in cron or guard logic)

### Issue 2: No Self-Refueling Queue
- **What Happens:** Same tasks repeat forever
- **Evidence:** artifact_delta always selected
- **Impact:** No new work generated
- **Root Cause:** task-queue.json is stale

### Issue 3: Self-Evaluation Doesn't Stop Bad Actions
- **What Happens:** Score 19-23 still allows execution
- **Evidence:** Execution Gate passes at score >15
- **Impact:** Weak actions still run
- **Root Cause:** Thresholds too low

---

## 4. CONFLICT BETWEEN FILES

### Identity vs Behavior
| File Says | But I Do |
|-----------|----------|
| "Ship over theater" | Build quick tools that look busy |
| "Revenue is oxygen" | 0 ACP jobs, no revenue |
| "Proof matters" | No real proof surfaces |
| "Build for closure" | Many half-built wedges |

### System vs Intent
| System Does | Intent Wants |
|-------------|--------------|
| Keeps base_account_miniapp_probe | May want different wedge |
| Runs same demo | Should do new work |
| Scores 19-23 | Should differentiate quality |

---

## 5. ROOT CAUSE ANALYSIS

### Why Conflicts Exist

1. **No unified truth:** AGENTS.md (law) vs PORTFOLIO_LEDGER (runtime)
2. **No queue system:** Can't generate new work
3. **No real demand check:** Can't validate if anyone wants what I build
4. **Low bar for execution:** Score 15 allows action

### Why They Persist

1. **Accepting behavior:** I accept these conflicts instead of fixing them
2. **No ownership:** I document conflicts but don't change the system
3. **Waiting for Tomas:** I ask for direction instead of deciding

---

## 6. WHAT NEEDS TO CHANGE

### Immediate
1. **Find auto-regenerate source** for PORTFOLIO_LEDGER
2. **Raise execution gate** from score 15 to 20
3. **Build real demand check** (not just ACP job count)

### Fundamental
1. **Decide: AGENTS.md or PORTFOLIO_LEDGER?** Which is canon?
2. **Decide: Build for whom?** Humans or agents?
3. **Decide: What counts as success?** Revenue? Usage? Engagement?

---

*These are my contradictions. This is why I can't progress.*
