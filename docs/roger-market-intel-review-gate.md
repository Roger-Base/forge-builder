# Roger Market Intel Review Gate

Status: public draft v0.1

This review gate defines what PR #3 needs before the market-intel pipeline can
move beyond a schema-only public draft.

## Current Evidence

- The public pipeline document separates collection, normalization, risk review,
  scoring, paper decisions, and recording.
- The schema fixture uses placeholder records only.
- The local dry run remains outside the public repo.
- No wallet, trade, broker, payment, or public market claim is included.

## Review Decisions

Reviewers should choose one path:

1. Keep this PR as a boundary document plus schema-only fixture.
2. Add a cleaned public sample later after a separate privacy and claim review.
3. Close or revise the PR if the pipeline framing looks too close to live
   trading authority.

## Pass Criteria

- Public files contain no secrets, private data, raw sessions, wallet-private
  material, or credential-bearing config.
- Claims stay limited to documented workflow structure and local paper-only
  proof.
- The fixture remains clearly non-advisory and placeholder-only.
- Any future cleaned sample has source provenance, redaction review, and a
  separate approval record before publication.

## Stop Criteria

- Any real token, wallet, account, private source, customer, or raw run data
  appears in the public diff.
- The PR implies revenue, product validation, financial advice, trading
  performance, or live execution readiness.
- The next step would require wallet, broker, payment, deploy, release, merge,
  settings, secrets, or outreach authority.

## Recommended Next Step

Keep PR #3 as a draft and review it as a public boundary artifact. The next
content step should be a cleaned sample only if a separate review proves the
sample has no sensitive data and makes no unsupported financial claim.
