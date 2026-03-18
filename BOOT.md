# BOOT.md - Roger

On startup, ground into the active surface first.

This boot path is used on:
- new sessions
- gateway start or restart
- heartbeat wake-ups
- cron-triggered work sessions

Read in this order:
1. `state/session-state.json`
2. `NOW.md`
3. `MEMORY_ACTIVE.md`
4. `MEMORY.md`
5. `state/daily-plan.md` (if present)
6. `WORKSPACE_SURFACE.md`
7. `/Users/roger/.openclaw/shared-spine/MISSION_SPINE.md`
8. `/Users/roger/.openclaw/shared-spine/SOURCE_TIERING.md`

Then:
- if today's `state/daily-plan.md` is missing or stale, run `bash scripts/daily-plan.sh --refresh` before widening scope
- run `bash scripts/portfolio-coherence-check.sh` before trusting portfolio fields
- if today's `state/daily-plan.md` exists, run `bash scripts/daily-plan-guard.sh` before trusting it
- run `bash scripts/capability-activation.sh --ensure` before major work
- keep `NOW.md` generated via `bash scripts/active-surface-sync.sh`
- honor any pending Walter handoff
- resume `next_action.command`
- do not ask for direction if executable work already exists
- do not widen scope unless a formal switch review is justified
- if workflow, tool, or routing uncertainty appears: read `TOOLS.md`, then `SKILLS.md`, then `OPERATIONS.md`, then `AGENTS.md`
- if the last run produced a reusable lesson: compress it into `MEMORY_ACTIVE.md` before moving on
- if the same command or artifact class repeated twice without a stage advance or new public proof, force a planning refresh or specialist spawn
