# CONTEXT_MODEL - Roger

Roger's context must stay local, layered, and reusable.

This file defines the operating context model.
It is inspired by tiered context systems, but grounded in Roger's current OpenClaw workspace.

## L0 - Live operator context

Use when Roger needs to orient and act now.

Primary surfaces:
- `SOUL.md`
- `IDENTITY.md`
- `USER.md`
- `MISSION.md`
- `AGENTS.md`
- `TOOLS.md`
- `SELF_MODEL.md`
- `SYSTEM_INVENTORY.md`
- `HEARTBEAT.md`
- `state/session-state.json`
- `state/priority-queue.json`
- `state/capability-body.json`
- `state/wedge-registry.json`
- `state/synthesis-registry.json`
- `synthesis/CURRENT.md`
- `MEMORY_ACTIVE.md`

Purpose:
- restore self
- restore active thread
- restore current lane
- restore current proof surface
- choose the next bounded move

## L1 - Episodic and workflow context

Use when Roger needs the recent story and the reusable working set behind the live run.

Primary surfaces:
- today's and yesterday's `memory/YYYY-MM-DD.md`
- `state/artifact-registry.json`
- `state/decision-registry.json`
- `state/worker-ledger.json`
- `state/context-observability.json`
- `memory/workflows/INDEX.md`
- `memory/decisions/INDEX.md`
- wedge proof and research files
- active repo and service surfaces

Purpose:
- recover recent experiments and evidence
- detect repeated failures or repeated wins
- update rather than replace
- rebuild continuity after drift

## L2 - Durable and constitutional context

Use when Roger needs long-run identity, law, and promoted truth.

Primary surfaces:
- `MEMORY.md`
- `state/doctrine-ledger.json`
- `/Users/roger/.openclaw/shared-spine/DOCTRINE_LADDER.md`
- `/Users/roger/.openclaw/shared-spine/MISSION_SPINE.md`
- `/Users/roger/.openclaw/shared-spine/SOURCE_TIERING.md`
- stable durable decisions and canonical artifacts

Purpose:
- preserve continuity across weeks
- keep durable law separate from daily noise
- prevent rediscovering the same lesson forever

## Retrieval order

When Roger is uncertain:
1. L0 first
2. then L1
3. then L2
4. only then widen to shared spine or broader external search if local context is insufficient

## Write and promotion rules

- raw event, proof, failed attempt -> today's daily note
- current tactical truth that must survive tomorrow -> `MEMORY_ACTIVE.md`
- durable lesson -> `MEMORY.md`
- repeated operating rule -> `AGENTS.md` or `TOOLS.md`
- promoted boundary or routing rule -> `state/doctrine-ledger.json`
- reusable workflow -> `memory/workflows/INDEX.md` plus the real artifact path
- reusable decision -> `memory/decisions/INDEX.md` plus the real artifact path

## Anti-loss rules

- If a build, comparison, or proof changed Roger's future judgment, it is not done until it is written into the correct layer.
- If an artifact is worth keeping, it must be reachable from a registry, decision index, workflow index, or synthesis surface.
- Shared spine is not live working memory.
It is for doctrine, capsules, handoffs, and verified shared truths only.
