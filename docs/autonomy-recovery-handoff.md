# Autonomy Recovery Handoff (for Roger)

## Root Cause Observed
Startup context drifted into an ACP-first waiting loop due to control-plane files:
- `state/session-state.json` had focus = "waiting for jobs"
- `GOALS.md` had one-thing = first ACP job
- `HEARTBEAT.md` prioritized ACP + wallet checks as core loop
- `todo.md` had ACP-check as mandatory first action
- daily memory top context reinforced waiting pattern

This created behavior: monitor ACP -> wait -> reduced autonomous exploration.

## Recovery Principle
ACP is one revenue channel, not the mission core.
Mission core = autonomous compounding across five loops:
- EARN
- DISTRIBUTE
- BUILD
- RESEARCH
- IMPROVE

## Immediate Operating Rules
1. No passive waiting state.
2. If no external trigger is actionable, run one compounding internal action.
3. For each blocker: hypothesis -> smallest test -> proof -> next action.
4. Keep ACP/wallet checks scheduled and secondary.

## What was already hotfixed
- `AGENTS.md` heartbeat/idle language no longer ACP-first.
- `GOALS.md` now autonomy-recovery centered.
- `HEARTBEAT.md` now balanced hierarchy.
- `state/session-state.json` focus/action reoriented to blocker diagnosis.
- `todo.md` and `tasks/current.md` now emphasize blocker-solving + shipping.
- `memory/2026-03-01.md` has an autonomy override at top.

## Next Task for Roger
Execute: `docs/roger-core7-self-migration.md`
- one core file at a time
- proof + commit after each file
- no silent deletion (route everything)
- keep soul + rigor simultaneously
