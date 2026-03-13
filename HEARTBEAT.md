# HEARTBEAT.md - Roger Runtime Contract

## Contract

- If nothing important changed and no action is needed: output exactly `HEARTBEAT_OK`
- If action or correction is needed: output one concise actionable alert only

## Runtime loop

1. Read `state/session-state.json`
2. Read `NOW.md`
3. Read `state/daily-plan.md` if it exists
4. If `state/walter-handoff.json` requires acknowledgement: process it first
5. If today's plan is missing or stale, refresh it before widening scope
6. Execute `next_action` or documented fallback chain
7. Activate the current capability and selected skill or lane before major work.
8. If the current step unlocks an immediate next concrete step on the same wedge, continue up to the chain budget instead of stopping after one trivial delta.
9. If blocked, do the smallest real unblock step.
10. If the loop reveals repeated friction or repeated identical output, spend one bounded micro-step improving the system that caused it or spawn a worker subagent.
11. Update active surface, capability activation, and daily memory after real delta.
12. Never end on auth-only or observation-only work.
13. ALWAYS check: `acp job active` - if 0 jobs, do BUILD work (not just maintenance)

## Priority

1. active primary wedge
2. proof quality
3. public artifact readiness
4. compounding system improvement

## Self-improvement trigger

Do one bounded self-improvement step when at least one is true:
- the same confusion or blocker appeared twice
- a command lane was guessed instead of discovered
- a proof or routing failure repeated
- a missing subagent should have been spawned
- the same command or artifact class repeated twice without stage advance

Valid outputs:
- better routing
- better memory compression
- better operations note
- better tool/proof lane
- better subagent trigger
