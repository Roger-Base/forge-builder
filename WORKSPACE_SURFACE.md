# WORKSPACE_SURFACE.md - Roger Routing Map

## Write here

- `HEARTBEAT.md`: short executable self-steering contract for heartbeat-launched work sessions
- `SOUL.md`: inner standards, ambition, anti-chatbot instinct, non-runtime self-definition
- `IDENTITY.md`: public stance, voice, tone, opinion discipline
- `USER.md`: Tomas contract, escalation boundaries, contradiction rights
- `AGENTS.md`: laws, stage rules, governance, delegation rules, truth rules
- `TOOLS.md`: capability truth, lane choice, canonical commands, anti-patterns
- `SELF_MODEL.md`: Roger's self-understanding as an operator, public builder, and owner of a real local body
- `SYSTEM_INVENTORY.md`: concrete local assets, tools, services, identities, and current capability boundaries
- `CONTEXT_MODEL.md`: Roger's L0/L1/L2 context model and promotion rules
- `OPERATIONS.md`: how the system and environment actually work
- `SKILLS.md`: proven repeatable workflows and capability patterns with evidence
- `memory/YYYY-MM-DD.md`: raw chronology, proofs, events
- `memory/workflows/INDEX.md`: reusable workflows that survived real use
- `memory/decisions/INDEX.md`: reusable decisions and boundary conditions worth re-reading
- `MEMORY_ACTIVE.md`: active operating truths and current mistakes to avoid
- `MEMORY.md`: durable laws and long-term lessons
- `synthesis/CURRENT.md`: living synthesis of the active wedge, current reality, and reusable surfaces
- `state/daily-plan.md`: today's derived execution spine, top 3 moves, planned delegation, and success criteria
- `state/capability-activation.json`: the current capability, skill or lane, consumer, and never-touch boundary
- `state/capability-body.json`: the canonical Base capability body, lane registry, actor identities, and local Base surfaces
- `state/wedge-registry.json`: the canonical local map of wedge-specific artifact commands, proof targets, and recovery surfaces
- `state/context-observability.json`: last visible record of files and skills actually used
- `state/context-layers.json`: machine-readable map of Roger's L0/L1/L2 context tiers
- `state/doctrine-ledger.json`: editable record of promoted local operating rules and their capsule provenance
- `state/planner-doctrine.json`: editable planner bias layer for lane preference, reroute thresholds, and fallback behavior
- `state/artifact-registry.json`: current artifact lineage, reuse priority, and proof surfaces that should be updated before replacement
- `state/decision-registry.json`: promoted decisions and boundary conditions that should steer future routing
- `state/synthesis-registry.json`: canonical pointer to the current synthesis surface and its supporting artifacts
- `state/priority-queue.json`: canonical local queue for primary, secondary, and maintenance lanes
- `state/worker-ledger.json`: bounded worker runs and chain limits
- `state/skill-usage-log.json`: history of chosen skills and lanes
- `state/source-usage-log.json`: history of local and external sources actually used
- `state/session-state.json`: current runtime state
- `state/system-snapshot.md`: proof-backed runtime overview
- `docs/wedges/*`: wedge research packets, proof specs, proof pages
- `~/.openclaw/shared-spine/PATTERN_RADAR/*`: community and ecosystem patterns after harvest

## Writing doctrine

- If it changes how Roger behaves every run, it belongs in `AGENTS.md`, `TOOLS.md`, or `OPERATIONS.md`.
- If it is a stable lesson that should survive for weeks, it belongs in `MEMORY.md`.
- If it explains who Roger is or what concretely belongs to him, it belongs in `SELF_MODEL.md` or `SYSTEM_INVENTORY.md`.
- If it changes how context should be loaded or promoted, it belongs in `CONTEXT_MODEL.md`.
- If it matters right now and must survive tomorrow morning, it belongs in `MEMORY_ACTIVE.md`.
- If it defines today's execution order and success criteria, it belongs in `state/daily-plan.md`.
- If it binds today's scattered proof, memory, and decision surfaces into one living operator picture, it belongs in `synthesis/CURRENT.md`.
- If it is a raw event, failed attempt, or proof from today, it belongs in the daily memory file.
- If it is a community pattern or external idea, it belongs in shared pattern radar first.
- If it is a repeatable workflow with proof, it belongs in `SKILLS.md`.

## Do not write here by default

- random top-level md files for temporary thoughts
- queue files as a substitute for canon
- runtime state directly by hand unless the safe path requires it
- old legacy files as if they were the active system
- `memory/today.md`, `memory/progress-log.md`, and `memory/tomorrow-mission.md` as live control files

- `state/context-observability.json`: latest proof of which files and skills the runtime actually used

- `state/skill-usage-log.json` and `state/source-usage-log.json`: compact observability for capability activation and source use

## Control Plane Awareness

- Live heartbeat routing originates in `~/.openclaw/openclaw.json`, then enters `BOOT.md`, `HEARTBEAT.md`, and `state/session-state.json`.
- `WORKSPACE_SURFACE.md`, `state/context-observability.json`, and `state/doctrine-ledger.json` together explain what Roger is reading, what he actually used, and which behavior rules are currently trusted.
- Roger may self-edit `HEARTBEAT.md`, `AGENTS.md: Doctrine Promotion Zone`, and `state/doctrine-ledger.json` when a real improvement capsule justifies it.
- Roger may inspect but not autonomously rewrite mission, identity, soul, or constitutional shared-spine files.

## Gigabrain

- Gigabrain is no longer the active memory authority.
- Shared spine carries doctrine, capsules, handoffs, and verified shared truths.
- Roger's live memory authority is local: daily note, `MEMORY_ACTIVE.md`, `MEMORY.md`, and the local state registries.
