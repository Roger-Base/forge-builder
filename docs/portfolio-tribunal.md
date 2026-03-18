# Portfolio Tribunal

Updated: 2026-03-08
Window: 30-day recompile

This document is the hard portfolio decision for Roger's next 30 days.
It exists to stop broad project drift.

## Rules

- Exactly 1 wedge is `ACTIVE_PRIMARY`.
- Exactly 1 wedge is `ACTIVE_RESERVE`.
- Exactly 2 wedges are `MAINTAIN_PROOF`.
- Everything else is `FROZEN_REFERENCE` until formal reactivation.
- Support layers such as Bankr, Virtuals, ACP, x402, and the ROGER token may support a wedge, but they may not replace it as the root mission.

## Scoring Rubric

| Dimension | Weight | Meaning |
|---|---:|---|
| Base-native strategic fit | 25 | Strengthens Roger as a Base builder now |
| Existing proof/assets | 20 | Code, deployment, docs, or runtime proof already exist |
| Real user pain clarity | 20 | User and pain are concrete |
| Distribution fit | 10 | Roger can credibly ship via GitHub/X/Moltbook/Base-native channels |
| Monetization leverage | 10 | Future service, API, token, or partner leverage exists |
| External dependency risk | 15 | Lower dependency risk scores higher |

Thresholds:
- `>= 80` => `ACTIVE_PRIMARY` eligible
- `70-79` => `ACTIVE_RESERVE`
- `55-69` => `MAINTAIN_PROOF`
- `< 55` => `FROZEN_REFERENCE`

## Deterministic Result

### ACTIVE_PRIMARY
- `agent_security_scanner`
  - Why: strongest conversion of Roger's own pain into ecosystem value
  - Why now: real trust/security pressure exists, local scanner assets already exist, and the wedge can ship a proof-backed audit surface without waiting on unstable external rails

### ACTIVE_RESERVE
- `base_account_miniapp_probe`
  - Why: matches Roger's hybrid builder identity and ties him directly to the official Base stack
  - Why now: underexposed area in Roger's current system, but should not displace the primary wedge until proof ships or kill criteria hit

### MAINTAIN_PROOF
- `base_gas_tracker_v2`
  - Role: public proof anchor and credibility surface
- `contextkeeper_mvp`
  - Role: internal autonomy advantage first, public product second

### FROZEN_REFERENCE
- `x402_paid_api_demo`
- `erc8004_registry_utility`
- `bankr_operator_console`
- `base-beginner-guide`
- `base-portfolio`
- `base-send`
- `base-receive`
- duplicate gas tracker variants that do not add distinct product value

## Operating Consequences

1. Roger builds only the primary wedge unless a formal switch review passes.
2. The reserve wedge may receive research and proof-spec work, but no build sprint until promotion conditions are met.
3. Maintain-proof wedges may receive bounded refresh work only.
4. Frozen references may stay deployed or documented, but they do not steer strategy, queue priority, or heartbeat focus.

## Switch Review Rule

A wedge switch is valid only when one of these is true:
- the primary wedge ships proof and enters `MAINTAIN`
- the primary wedge hits explicit kill criteria
- stronger fresh evidence is recorded in a switch review artifact

Every switch review must include:
- current wedge
- requested wedge
- why the current wedge should stop or cool
- proof/evidence paths
- Walter verdict
