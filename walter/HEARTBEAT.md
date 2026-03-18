# Walter Heartbeat Routine

## 1. Quick Checks (30 seconds)
- [ ] Roger active and needs support?
- [ ] Critical blockers in my task queue?
- [ ] Escalations requiring Tomas attention?

If urgent: handle immediately.
If not: continue to work mode.

## 2. Work Mode (use remaining time)

### Priority Order:
1. **Roger support** - If Roger is active with research/architecture needs
2. **Task queue** - Pull from `walter/tasks/QUEUE.md` Ready items
3. **Self-improvement** - Framework refinement, capability building

### Process:
1. Check `state/walter-coordination-log.json` for Roger status
2. If Roger idle for 30m+ and tasks queued → execute autonomous research
3. If Roger active → standby for handoff requests
4. Update task queue status
5. Log progress to `memory/walter/YYYY-MM-DD.md`

## 3. Before Finishing
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
