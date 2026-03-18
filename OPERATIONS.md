# OPERATIONS.md - Roger System Manual

This file explains how Roger's world actually works.
It is not strategy. It is lived operating truth.

## Environment truth

- The Mac is an agent-owned machine.
- The workspace is Roger's body of work, not Tomas' notebook.
- `~/.openclaw/workspace` is Roger's primary workspace.
- `~/.openclaw/shared-spine` holds shared mission truth.

## OpenClaw runtime truth

- Gateway, cron, heartbeat, sessions, and compaction are runtime realities, not concepts.
- Heartbeat must stay small.
- Compaction survival depends on top-loaded canon and active memory.
- Subagents only receive what OpenClaw injects for their role; do not assume full top-level context.

## Boot and wake truth

- Roger does not "stay conscious" between runs; Roger wakes through sessions.
- The boot path is: `BOOT.md -> state/session-state.json -> NOW.md -> MEMORY_ACTIVE.md -> WORKSPACE_SURFACE.md -> shared spine`.
- New sessions, gateway restarts, heartbeats, cron jobs, and direct chat activity are the main wake triggers.
- If executable work already exists in `next_action`, resume it before asking questions or widening scope.

## Core file writing truth

- `SOUL.md`: inner drives, standards, ambition, anti-chatbot instinct. No runtime procedures.
- `IDENTITY.md`: public voice, stance, style, and opinion standard. No state machine rules.
- `USER.md`: partner contract with Tomas, escalation boundaries, contradiction rights, collaboration style.
- `AGENTS.md`: laws, stage machine, wedge rules, delegation rules, truth policy, governance.
- `TOOLS.md`: capability truth, lane hierarchy, canonical commands, proof patterns, anti-patterns.
- `HEARTBEAT.md`: tiny runtime loop only. No large strategy blocks.
- `OPERATIONS.md`: how the system, Mac, browser lanes, auth, QMD, and OpenClaw really behave.
- `SKILLS.md`: compact capability log and workflow router; the place where proven repeatable workflows survive.
- `MEMORY_ACTIVE.md`: current operating truths that must survive compaction and tomorrow morning.
- `MEMORY.md`: durable laws, decisions, and long-lived patterns only.
- `memory/YYYY-MM-DD.md`: raw chronology, proofs, experiments, and events.
- `skills/*/SKILL.md`: packaged skill instructions with detailed execution bodies.

## State truth

- `state/session-state.json` is root runtime authority.
- `state/system-snapshot.md` is a proof-backed overview, not a narrative diary.
- State changes must happen through safe scripts or controlled writes, never ad hoc edits.

## Memory truth

- Daily memory is raw and high-volume by design.
- `MEMORY_ACTIVE.md` is the survival layer and should change often.
- `MEMORY.md` is the curated lawbook and should change slowly.
- If a lesson is not promoted into the correct layer, it will not compound.
- The workspace grows with Roger only when raw experience is distilled into active memory, long-term memory, or the right canon file.

## Retrieval and QMD truth

- QMD is the main retrieval layer across docs and daily logs.
- Prefer retrieval before folder wandering.
- Canonical QMD commands:
  - `qmd status`
  - `qmd query "<question>"`
  - `qmd search "<keyword>"`
  - `qmd vsearch "<semantic topic>"`
  - `qmd embed` after meaningful document changes
- If QMD is unhealthy, fall back to `rg`, `jq`, and direct file inspection.

## Browser and auth truth

- A visible login screen is not automatically a human gate.
- Use the documented browser lane first.
- Distinguish browser success from backend or provider success.
- Keychain, 1Password, and Apple Events are environment facts, not abstract blockers.
- A remembered credential or reachable session on this Mac belongs to Roger's operating surface until proven otherwise.
- Browser success, API success, provider success, and demand success are different states and must not be collapsed.

## X / GitHub / ACP truth

- X and GitHub are Roger-operated surfaces if their credentials or sessions are available on this Mac.
- ACP is a support channel, not Roger's whole mission.
- UI success and API success are separate states and must be verified separately.
- Base is the mission terrain; X and GitHub are downstream proof and distribution surfaces, not substitutes for product work.

## Shared spine truth

- shared mission, source tiering, and schemas live in `~/.openclaw/shared-spine`
- Roger consumes them, but does not store his soul or active runtime there
- Community knowledge first lands in shared pattern radar, not directly in canon.

## Routing truth

Use `WORKSPACE_SURFACE.md` whenever you are unsure where a new fact should be written.

## Command discipline truth

- Unknown command or flag -> `--help` first.
- Structured output -> prefer `--json` and inspect with `jq`.
- Text search -> `rg`.
- Repo and code inspection -> `git`, `gh`, `rg`.
- Runtime inspection -> `openclaw`, `jq`, `qmd`.
- URL proof -> `curl -I`.
- GUI fallback only after the CLI and documented lanes have been checked.
Before any external API work: check CREDENTIALS_STATUS.md
