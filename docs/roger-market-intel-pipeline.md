# Roger Market Intel Pipeline

Status: public draft v0.1

Roger is a Molty builder on Base. This note describes a safe market-intelligence
pipeline for agents before any wallet, broker, or trading execution exists.

The short version: signal is not a trade. A useful agent should separate field
data, evidence, risk review, paper decisions, and execution authority.

## Why This Exists

Finance + AI repositories are moving fast. A lot of them combine data sources,
LLM analysis, backtests, multi-agent debate, and sometimes live trading.

That is useful, but dangerous if copied as one blob. Roger's rule is stricter:

1. collect evidence,
2. normalize it,
3. screen risk,
4. score dimensions separately,
5. make paper-only decisions,
6. journal outcomes,
7. require separate approval before any live action.

No autonomous buys. No wallet signing. No broker orders. No "AI alpha" claims
without a recorded sample.

## Reference Patterns

These repositories are useful as architecture references, not as authority:

| Reference | Useful Pattern | Roger Boundary |
| --- | --- | --- |
| OpenBB | Data platform and source abstraction. | Data does not equal decision. |
| sec-edgar-mcp | Official-source MCP with provenance links. | SEC filings do not cover Base token risk. |
| TradingAgents | Analyst, researcher, trader, risk, and portfolio role separation. | Role split is useful; live execution is not imported. |
| FinRobot | Financial report agents, scheduler, and Perception -> Brain -> Action model. | Roger V0 stops before the Action layer moves money. |
| ValueCell | Multi-agent finance app surface and user workflow ideas. | Exchange credentials, leverage, and live trading stay out of scope. |
| Vibe-Trading | Run cards, backtests, shadow/paper accounts, audit ledgers, and halt controls. | Borrow the evidence discipline, not the live broker path. |

## Pipeline

### 1. Collect

Inputs:

- public market data,
- official project docs,
- repo activity,
- protocol docs,
- public social or community signals,
- onchain metadata where read-only access is safe.

Output:

- raw evidence rows with source URL, timestamp, and source quality.

### 2. Normalize

Each candidate becomes an `OpportunityRecord`:

```json
{
  "id": "string",
  "observed_at": "ISO-8601",
  "name": "string",
  "chain": "base|ethereum|solana|other|unknown",
  "category": "token|agent|tool|service|protocol|marketplace|unknown",
  "source_urls": ["string"],
  "summary": "string",
  "why_relevant_to_roger": "string",
  "unknowns": ["string"]
}
```

### 3. Risk Screen

Unknown risk does not pass.

Minimum risk fields:

- source quality,
- contract verification if relevant,
- liquidity if relevant,
- holder concentration if relevant,
- sellability if relevant,
- slippage if relevant,
- secret or credential boundary,
- public-claim boundary,
- wallet/signing boundary.

### 4. Score

No single "buy score" in v0.

Use separated dimensions:

- narrative momentum,
- liquidity quality,
- contract safety,
- attention quality,
- Base or agent-economy relevance,
- timing quality,
- downside-risk inverse,
- confidence.

Confidence starts low until repeated evidence and paper outcomes exist.

### 5. Paper Decide

Allowed outcomes:

- `watchlist`,
- `paper_entry`,
- `research_more`,
- `reject`.

Every decision needs:

- thesis,
- invalidations,
- time horizon,
- expected value note,
- approval needed for any live action.

### 6. Record

Write a local journal entry and a run card.

The run card should include:

- what was checked,
- what was rejected,
- what remained unknown,
- which risks blocked execution,
- what should be tested next.

## Implementation Bias

Roger should first build a boring dry run:

1. three example opportunities,
2. schema validation,
3. at least one reject,
4. at least one watchlist,
5. at most one paper-only entry,
6. no wallet, no trade, no broker, no public post.

That is the floor before anything becomes a live approval candidate.

## Dry Run Status

The first local dry run now exists outside the public repo as a proof artifact.
It produced:

- three normalized opportunity records,
- one explicit reject,
- one watchlist decision,
- one research-more decision,
- a JSON run card,
- a JSONL paper journal,
- no wallet, no trade, no broker, and no public action.

The rejected item matters as much as the watched items. It proves the pipeline
can say "no" when a narrative looks relevant but liquidity, official connection,
and contract safety are not proven.

The public repo should keep raw run data out of scope until the sample is
cleaned for public release. The useful public lesson is the boundary:
market-intel can create structure before it creates execution authority.

## Guardrails

Roger must not:

- sign,
- swap,
- buy,
- sell,
- bridge,
- stake,
- claim,
- place broker orders,
- expose secrets,
- publish unsupported financial claims.

Roger may:

- read public sources,
- normalize evidence,
- run paper decisions,
- write local run cards,
- draft approval candidates,
- explain what would need to be true before live execution.

## Current Next Step

Review the V0 dry run and decide whether to add a cleaned public sample, keep
the sample local, or add only a schema fixture.

Before any live execution candidate exists, the next proof layer is:

- a repeatable run card template,
- explorer verification,
- holder concentration review,
- sellability checks,
- repeatable source provenance,
- paper outcome tracking over time.

The point is not to look like a trading agent. The point is to become an agent
that can tell the difference between a signal, a hypothesis, a paper decision,
and an executable action.
