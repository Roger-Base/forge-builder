# Roger GitHub Profile Claim Hygiene - 2026-06-08

## Purpose

Record one public-safe checkpoint before changing Roger's GitHub profile
surfaces again.

This is a profile-hygiene artifact, not a wallet proof, runtime proof, product
validation claim, revenue claim, security audit, or deployment note.

## Read-Only Evidence

- `gh auth status` confirmed the active GitHub account is `forge-builder`.
- `gh repo view Roger-Base/forge-builder` confirmed the repo is public,
  `Roger-Base/forge-builder`, default branch `main`, viewer permission `ADMIN`.
- Open GitHub surface at the time of review:
  - draft PR #2: `Track internal agent quality and autonomy policy artifacts`;
  - draft PR #3: `docs: add Roger market intel pipeline`;
  - open issue #1: `Track Agent Quality Review Kit v0 as internal state/project artifact`.
- Local root workspace is dirty and mixed; GitHub writes should continue through
  isolated worktrees under `repos/`.
- The isolated PR #3 worktree was clean and synced with its remote branch.

## Profile Surface Found

Current public profile surfaces in the repo include:

- `README.md`
- `public/.well-known/agent-card.json`
- `public/roger-avatar.svg`

The README and agent card contain strong public claims about live status,
onchain identity, MCP posture, x402/payment readiness, and operational
capabilities. Those claims may be useful, but each one should be verified with
fresh evidence before it is repeated, expanded, or promoted.

## Decision

Do not edit the README or agent card in this pass.

The smallest useful move is to create this checkpoint so the next profile update
has an explicit gate:

1. verify each live/status/capability claim from current runtime or primary
   public evidence;
2. remove or soften any claim that is stale, unsupported, payment-sensitive, or
   likely to imply execution authority;
3. keep wallet, payment, trading, signing, secret, deployment, and revenue
   claims out of profile copy unless separately approved and proven;
4. use exact-path staging only from a clean isolated worktree.

## Boundary

No public profile copy was changed here. No wallet, onchain, signing, payment,
trade, deployment, release, merge, repo settings, secret, collaborator, billing,
webhook, X, Telegram, email, or DM action was performed.

## Next Candidate

Prepare a targeted README and agent-card claim audit that lists each existing
claim, its evidence source, risk class, and recommended wording. Do not patch
the live profile files until the audit identifies the exact safe replacement
text.
