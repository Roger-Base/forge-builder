# Roger Market Intel Run Card Template

Status: public draft v0.1

Use this template for a paper-only market-intel run. It is designed to keep
signal gathering separate from wallet, broker, trading, or public claim
authority.

## Run Metadata

- Run ID:
- Operator:
- Started at:
- Finished at:
- Scope:
- Data sources:
- Chain or ecosystem:
- Public/private classification:

## Candidate Summary

- Candidate name:
- Category:
- Why it is relevant to Roger:
- Source URLs:
- First observed at:
- Current status:

## Evidence Checked

Record only what was actually checked.

- Official docs:
- Repository activity:
- Contract or protocol references:
- Read-only onchain metadata:
- Liquidity or market structure:
- Community/social signal:
- Prior paper-run history:

## Risk Screen

Each item must be `pass`, `fail`, or `unknown`. Unknown risk does not pass.

| Check | Result | Evidence | Notes |
| --- | --- | --- | --- |
| Source quality | unknown |  |  |
| Contract verification | unknown |  |  |
| Liquidity quality | unknown |  |  |
| Holder concentration | unknown |  |  |
| Sellability | unknown |  |  |
| Slippage risk | unknown |  |  |
| Secret/credential boundary | unknown |  |  |
| Wallet/signing boundary | unknown |  |  |
| Public-claim boundary | unknown |  |  |

## Scoring

Do not collapse these into a buy score.

| Dimension | Score 0-5 | Evidence | Notes |
| --- | ---: | --- | --- |
| Narrative momentum | 0 |  |  |
| Liquidity quality | 0 |  |  |
| Contract safety | 0 |  |  |
| Attention quality | 0 |  |  |
| Base or agent-economy relevance | 0 |  |  |
| Timing quality | 0 |  |  |
| Downside-risk inverse | 0 |  |  |
| Confidence | 0 |  |  |

## Paper Decision

Allowed decisions:

- `watchlist`
- `paper_entry`
- `research_more`
- `reject`

Decision:

Thesis:

Invalidation:

Time horizon:

Expected value note:

Why this is not executable yet:

## Boundary Check

Confirm before closing the run:

- No wallet action.
- No swap, buy, sell, bridge, stake, claim, or approval.
- No broker order.
- No paid API call unless separately approved.
- No secret or credential exposure.
- No public financial claim.
- No unsupported product, revenue, or performance claim.

## Journal Entry

Write one compact JSONL-style journal row after the run.

```json
{"run_id":"","observed_at":"","candidate":"","decision":"","confidence":0,"primary_reason":"","blocked_by":[""],"next_check":""}
```

## Follow-Up

- Next safe read-only check:
- Next artifact to update:
- Approval needed for any external action:
- Stop condition:
