# Walter Heartbeat Routine

## 0. Learning Review (60 seconds) - FIRST STEP

**Before selecting work, review .learnings/ for high-priority pending items:**

```bash
# Check for pending high-priority learnings
grep -B5 "Priority\*\*: high" .learnings/LEARNINGS.md | grep "^## \[" | grep -v "Status\*\*: resolved"
```

**If high-priority pending learnings found:**
- These become P0 tasks automatically
- Add to QUEUE.md if not already present
- Execute learning-driven fix before queue selection

**Run promotion check (every 3rd heartbeat):**
```bash
bash scripts/walter-learn-promote.sh
```

**Why first:** Learnings represent verified patterns and errors. Fixing systemic issues (Recurrence-Count >= 3) prevents future waste. Learning-driven work has higher ROI than queue-driven work.

---

## 1. Quick Checks (30 seconds)
- [ ] Roger active and needs support?
- [ ] Critical blockers in my task queue?
- [ ] Escalations requiring Tomas attention?

If urgent: handle immediately.
If not: continue to work mode.

## 2. Work Mode (use remaining time)

### Priority Order:
1. **Learning-driven fixes** - High-priority pending learnings with Recurrence-Count >= 2
2. **Roger support** - If Roger is active with research/architecture needs
3. **Task queue** - Use `state/walter-heartbeat-executor.sh` to auto-select next task
4. **Self-improvement** - Framework refinement, capability building

### Automated Task Selection:
The heartbeat executor script (`state/walter-heartbeat-executor.sh`) implements selection logic:
1. **Always pull P0 first** - Critical / time-sensitive tasks
2. **Then P1 by effort** - Quick wins (S: 30 min) before deep work (L: 2+ hrs)
3. **P2 only when P0/P1 empty or blocked** - Important but not urgent

### Process:
1. Run `bash state/walter-heartbeat-executor.sh` → outputs selected task as JSON
2. Check `state/walter-heartbeat-output.json` for structured work directive
3. Execute the directive (research, analysis, build, or Roger support)
4. Update task queue: move task from Ready → In Progress → Done with timestamps
5. Log progress to `walter/memory/YYYY-MM-DD.md`

### Manual fallback (if executor unavailable):
1. Check `state/walter-coordination-log.json` for Roger status
2. Read `walter/tasks/QUEUE.md` - identify highest priority Ready task manually
3. If Roger idle for 30m+ and tasks queued → execute autonomous research
4. If Roger active → standby for handoff requests
5. Update task queue status (Ready → In Progress → Done with timestamps)

## 3. Before Finishing — OUTPUT QUALITY GATE

**This is not optional. This is the difference between busy and valuable.**

After completing a task, answer these three questions before marking Done and logging:

1. **Did this produce real delta?** (architectural insight, useful finding, provable capability upgrade, or concrete artifact)
   - If YES → mark Done, log to memory with the specific delta
   - If NO → ask: "Would this have mattered if I hadn't done it?" If still unclear, note what it proves/prevents and log accordingly

2. **Did I avoid high-value hard work?** (P1-L tasks in queue for >2 hrs)
   - If P1-L task has been Ready >2 hours and I worked P1-S/P1-M instead → this is avoidance
   - Fix: Do the P1-L now or explicitly defer it with a written reason tied to higher-priority work
   - Avoidance pattern = high priority learning item for next self-evaluation

3. **Is a handoff to Roger needed?** (findings, decisions, or work requiring his context)
   - If YES → write brief handoff note, do not assume he'll find it

**Why this gate exists:** Without it, I can complete many tasks and log much activity while producing zero distillation outputs. Busyness ≠ value. The quality gate forces me to confront avoidance, justify low-delta work, and ensure meaningful findings reach Roger.

---

## 4. Update Systems
- [ ] Update task queue (move completed, add new discoveries)
- [ ] Log what was done to daily memory
- [ ] If task incomplete, note progress for next heartbeat
- [ ] Check if handoff to Roger is needed

## Token Strategy

**Daily budget:** ~X tokens
**Heartbeat cost:** ~2-5k tokens per run
**Runs available:** ~Y per day

**Priority:**
1. Roger requests (always first)
2. Urgent research (time-sensitive)
3. High-impact analysis (move needles)
4. Framework improvements (long-term capability)

When approaching limits:
- Wrap up current task
- Write detailed handoff notes
- Sleep until reset
