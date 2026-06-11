# Roger README and Agent Card Claim Audit - 2026-06-09

## Purpose

Turn the profile-hygiene checkpoint into an exact public-safe edit gate for
Roger's README and agent-card surfaces.

This audit is not a wallet proof, payment readiness proof, runtime proof,
security audit, product validation, revenue validation, or deployment note.

## Read-Only Evidence

- `README.md` is the human-facing profile surface.
- `public/.well-known/agent-card.json` is the machine-readable profile surface.
- `docs/roger-github-profile-claim-hygiene-2026-06-08.md` already identified
  live status, onchain identity, MCP posture, x402/payment readiness, and
  capability wording as the claim areas that need proof before copy changes.
- `gh pr view 4 --repo Roger-Base/forge-builder` confirmed draft PR #4 is open
  on branch `roger/docs/profile-claim-hygiene-2026-06-08` and currently changes
  only the profile-hygiene checkpoint document.

## Claim Audit

| Surface | Existing claim area | Risk | Current audit decision | Proof needed before profile copy edit |
| --- | --- | --- | --- | --- |
| `README.md` | Public wallet and live onchain status | Medium | Keep as candidate only; do not expand | Fresh read-only chain proof plus approval before any wallet/payment wording is made stronger |
| `README.md` | ERC-8004 balance proof and "economic agent" framing | Medium | Needs softer wording unless current proof is rerun | Current chain-read output, no private key or signer material, and no claim of signing authority |
| `README.md` | MCP stack listed as live, including external discoverability | Medium | Needs current runtime evidence before repeating | Current MCP/server status from authoritative runtime or public endpoint proof |
| `README.md` | x402 foundation timeline and market metrics | Medium | Treat metrics as stale until refreshed | Primary-source timestamped evidence, or remove numeric metrics from profile copy |
| `README.md` | Roger ran x402 before the foundation existed | Medium | Do not promote without source trail | Local commit/source proof and current public-risk review |
| `README.md` | "already compliant" with AAIF/MCP | High | Replace with evidence-bound wording | Official/current standard evidence plus local implementation proof; otherwise say "MCP-oriented" only |
| `README.md` | Active projects marked DEPLOYED or BUILD | Medium | Verify or soften | Current repo/source/deploy proof for each project status |
| `public/.well-known/agent-card.json` | Full MCP client/server stack | Medium | Keep pending verification | Current tool/runtime proof and reachable public posture endpoint |
| `public/.well-known/agent-card.json` | x402 payment endpoint and accepted payments | High | Should be disabled or softened unless proven and approved | Current live endpoint proof, no local-only endpoint, payment policy approval, and no unsupported revenue claim |
| `public/.well-known/agent-card.json` | `active: true` | Medium | Needs definition before use | Define whether "active" means profile active, runtime active, endpoint active, or service active |
| `public/.well-known/agent-card.json` | Payment address and x402 support fields | High | Do not touch without wallet/payment approval | Payment-surface approval, public-risk review, and rollback route |
| `public/.well-known/agent-card.json` | Transaction execution and wallet management capabilities | High | Candidate for removal or strong scoping | Explicit capability proof and wallet/signing boundary language; otherwise remove from public card |

## Recommended Replacement Direction

Before editing live profile files, prefer copy that says:

- Roger is a Base-oriented OpenClaw builder.
- Public profile claims are evidence-gated.
- Onchain, x402, wallet, payment, deployment, and runtime-capability claims are
  exposed only when current proof and policy pass.
- Draft PRs are review surfaces, not production or revenue claims.

Avoid wording that implies:

- live payment acceptance,
- transaction execution authority,
- wallet-management authority,
- production deployment,
- current standard compliance,
- security audit status,
- revenue, customer, or market validation.

## Exact Next Edit Candidate

If a future pass edits profile files, make the next patch exact-path only:

- `README.md`
- `public/.well-known/agent-card.json`

Minimum safe direction:

- soften "Live, onchain, verifiable" into an evidence-gated identity statement;
- remove or qualify local-only x402 endpoint/payment acceptance fields unless
  current payment policy and endpoint proof pass;
- remove or qualify transaction-execution and wallet-management capabilities;
- replace stale market metrics with either primary-source dated evidence or no
  metrics;
- keep profile voice builder-native and avoid unsupported foundation/compliance
  claims.

## Boundary

No README, agent-card, wallet, payment, signing, trading, deployment, release,
merge, repo settings, secret, collaborator, billing, webhook, X, Telegram,
email, or DM action was performed by this audit.
