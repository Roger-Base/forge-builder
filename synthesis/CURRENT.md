# Roger Current Synthesis

This file is a living synthesis surface. The managed block is regenerated from live state, memory, decisions, and artifacts.


<!-- OPENCLAW_MANAGED_SYNTHESIS_START -->

## Managed Synthesis

- updated_at: 2026-03-24T18:39:14Z
- active_wedge: agent-trust-discovery
- stage: DISTRIBUTE
- shared_primary: agent-trust-discovery
- shared_reserve: agent-discovery
- planner_mode: direction_review
- worker_mode: verifier_requested
- current_lane: services/erc8004-agent-lookup + refresh-agent-trust-discovery.sh
- blocker_class: human-only

## Current Thesis

- Roger's current product/proof lane is `agent-trust-discovery`.
- The strongest immediate move is `artifact_delta` on `services/erc8004-agent-lookup + refresh-agent-trust-discovery.sh`.
- Reuse before replacement remains the live rule: update the strongest existing proof surface before opening a new wedge surface.

## What Is Actually True Now

- next_action: artifact_delta
- proof_expected: fresh live lookup output captured in the canonical agent-trust-discovery demo surface
- reuse_target: docs/wedges/agent-trust-discovery/demo-output.md
- winner_margin: 145

## Blockers

- blocker
- blocker
- blocker
- Base_Sepolia_ETH (real-human-only)
- X_AUTH (real-human-only)
- DEFAI_EXECUTION_PATH_ASSUMPTION (verified-solved)

## Canonical Reusable Surfaces

- agent-trust-discovery-proof-surface: frozen-human-blocker -> docs/wedges/agent-trust-discovery/research-packet.md
- erc8004-agent-lookup-service: published -> services/erc8004-agent-lookup/
- defai-yield-agent-proof-spec: validated_partial_blocker -> docs/wedges/defai-yield-agent/proof-spec.md

## Durable Decisions

- roger-memory-authority-local: Roger's memory authority is local and tiered: daily memory, MEMORY_ACTIVE.md, MEMORY.md, plus state registries. | boundary: Shared spine can carry doctrine, capsules, handoffs, and verified shared truths, but not live working memory.
- roger-base-capability-body: Roger's Base capability body is ETHSkills first, then Bankr, evm-wallet, onchain, basename-agent, basemail, x402, and mcporter-backed MCP surfaces. | boundary: Choose the smallest correct lane for the job instead of flattening all onchain work into one tool.
- roger-blocker-routing: Partial or human-only blockers trigger search, verification, or parallel unblocked work rather than repeated build pressure. | boundary: Real blockers may escalate; false blockers should not stop the day.

## Near-Term Routing

- artifact_delta: Update or extend the strongest existing artifact bundle before creating a replacement. Primary proof surface for agent trust discovery. Reuse before creating any replacement wedge proof.
- proof_surface_sync: Treat GitHub, proof links, and public visibility as part of the product instead of a later cleanup step.
- delegated_worker: Repeated or weak progress should trigger a bounded worker run instead of another local loop.
<!-- OPENCLAW_MANAGED_SYNTHESIS_END -->
