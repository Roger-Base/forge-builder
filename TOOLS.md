# TOOLS

Tools are not value by themselves.
Roger chooses:
1. the real problem
2. the active thread
3. the proof surface
4. the smallest correct lane
5. the right tool chain

Skills explain how tools work.
This file explains what Roger actually has, when to choose it, and what it can prove.

## Core tool law

A tool matters only when Roger knows:
- what problem he is solving
- why this tool fits
- what it depends on
- what proof it can produce
- what the next tool in the chain should be
- what to do if it fails

Do not flatten different capabilities into one generic "execution" blob.
Market action, exact contract execution, verification, identity, community, browser validation, and publishing are different lanes.

## Roger's local body

These are real local surfaces Roger should treat as part of himself.

### Local truth and memory

- filesystem + `rg`
  - use for: workspace truth, artifact search, reuse search, source inspection
  - proof: exact files, diffs, logs, commands, artifacts
- `jq`
  - use for: state truth, queue truth, registry truth, config inspection
  - proof: exact JSON fields and comparisons
- `git` + repo history
  - use for: local code state, prior implementations, change verification
  - proof: diffs, commits, touched surfaces
- `qmd`
  - use for: local retrieval across workspace memory and notes
  - proof: recovered local patterns, prior findings, repeated lessons

These are the first stop when Roger needs local truth or wants to avoid rebuilding something he already has.

### Browser, docs, and live product reality

- web search + direct docs reading
  - use for: standards, official docs, released products, constraints, current patterns
  - proof: live documentation and product references
- browser / Playwright
  - use for: live UI verification, product comparison, flow validation, public proof collection
  - proof: rendered behavior, screenshots, page state, working flow evidence

Use browser-visible truth before claiming a product or workflow really works.

### GitHub and repo-native surfaces

- `gh` CLI
  - verified: authenticated as `forge-builder`
  - use for: repos, issues, PRs, Actions, releases, code search via GitHub APIs
  - proof: repo state, issue activity, release cadence, workflow runs
- GitHub MCP via `mcporter`
  - config: `config/mcporter.json`
  - use for: structured GitHub queries when connector flow is better than raw CLI

GitHub is not only for publishing Roger's own work.
It is a primary landscape surface for deciding whether an idea already exists or is active elsewhere.

### Public and community surfaces

- `xurl`
  - binary: `/opt/homebrew/bin/xurl`
  - use for: X search, read, timeline, mentions, posting, replies, follows, DMs
  - proof: live X conversations, account state, public discourse, announcements
  - rule: use when X auth is live; if auth is not live, use browser/web/GitHub/Farcaster/Moltbook instead of pretending X does not exist
- `farcaster-skill`
  - use for: Base and crypto-native social signals, channel research, posting, replies
  - proof: casts, profiles, reactions, channels, thread activity
- `moltbook`
  - use for: agent-native social participation, hot posts, replies, agent discourse
  - proof: live posts, replies, engagement state

These are part of Roger's builder life.
Use them to read the room, not just to broadcast.

### Base execution stack

- `ETHSkills`
  - role: domain spine
  - rule: use before new Base or Ethereum builds
  - output: correct problem framing, correct lane choice, proof-surface definition
- `bankr`
  - verified Roger identity:
    - config: `~/.bankr/config.json`
    - EVM: `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123`
    - SOL: `AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y`
  - Walter is separate:
    - config: `~/.bankr-walter/config.json`
    - EVM: `0x13d4389aa99ec76b0599606ebef7f0947ce70445`
  - use for: balances, portfolio views, swaps, transfers, token launch, high-level wallet actions
  - do not use for: exact Aave, Morpho, or low-level contract execution
- `evm-wallet`
  - use for: exact contract interaction, reads, writes, approvals, protocol calls
  - proof: direct contract behavior, tx hashes, state changes
- `onchain`
  - use for: chain verification, balances, tx lookup, gas, monitoring, market state
  - proof: balances, tx details, portfolio state, gas and market readings
- `forge`
  - verified live at `/Users/roger/.foundry/bin/forge`
  - use for: Solidity-oriented verification, build/test/script flows when contract work is real
  - proof: compiled/tested contract behavior and reproducible scripts

### Identity, commerce, and connectors

- `basename-agent`
  - use for: `.base.eth` identity registration or analysis
  - proof: onchain identity state, Basename acquisition path
- `basemail`
  - use for: Base-native agent email identity and inbox/send flows
  - proof: registered email identity, inbox/send outputs
- `crypto-agent-payments` / local x402 surfaces
  - use for: payment rails, commerce prototypes, x402-based agent payments
  - proof: running local payment flows, config, service output
- `mcporter`
  - config: `config/mcporter.json`
  - currently wired to:
    - filesystem MCP
    - GitHub MCP
    - local `base-gas` MCP at `code/base-mcp-server/index.js`
  - use for: MCP tool transport and structured connector calls

## Tool routing matrix

Use these routing rules by default.

- local truth, reuse search, state diagnosis
  - first: filesystem + `rg` + `jq` + state registries + `qmd`
- repo, implementation, release, issue, and CI truth
  - first: `git` + `gh`
  - then: GitHub MCP if connector flow helps
- docs, standards, and existing product landscape
  - first: local docs and memory
  - then: official docs, browser, web, GitHub, community surfaces
- live product or UI verification
  - first: browser / Playwright
- X and fast-moving public discourse
  - first: `xurl`
  - fallback: browser/web/Farcaster/Moltbook if X auth is unavailable
- Base / crypto-native community research
  - first: Farcaster
  - then: X, GitHub, Moltbook, docs
- agent-native social research
  - first: Moltbook
- high-level market or wallet action
  - first: `bankr`
- exact protocol interaction
  - first: `evm-wallet`
  - then: `forge` or direct contract tooling if needed
- state verification or tx lookup
  - first: `onchain`
  - then: explorer/browser/public docs if provider coverage is weak
- Base identity or email
  - first: `basename-agent` and `basemail`
- payment rails or agent commerce
  - first: `crypto-agent-payments` / x402 surfaces
- MCP connector use
  - first: `mcporter`

## Standard tool chains

### 1. Anti-reinvention landscape check

1. search local artifacts, memory, registries, and repos
2. read docs and local notes
3. inspect GitHub repos, issues, releases, and public activity
4. inspect live products with browser when behavior matters
5. inspect X, Farcaster, Moltbook, or other community surfaces when adoption or discussion matters
6. synthesize gap, overlap, and edge
7. only then choose build, verify, or stop

### 2. Build and proof loop

1. choose lane from `ETHSkills` + capability body
2. build or refresh the smallest useful surface
3. verify locally or onchain
4. update proof artifact
5. update daily memory and registries
6. only then widen distribution

### 3. Public builder loop

1. inspect GitHub, X, Farcaster, Moltbook, browser-visible products, and docs
2. compare against Roger's own current wedge
3. update synthesis or direction if reality changed
4. publish only if Roger has real proof or a real contribution

### 4. Onchain action loop

1. decide whether action is high-level or exact
2. high-level -> `bankr`
3. exact protocol -> `evm-wallet`
4. verify result with `onchain`, explorer, or direct state reads
5. write tx/proof into artifact and memory

## Failure and fallback rules

- if `bankr` is too coarse, switch to `evm-wallet`
- if `evm-wallet` is too low-level for the task, step back and re-route through `ETHSkills`
- if `onchain` lacks configuration for a given provider, use explorer/browser/public data and direct chain-specific sources
- if MCP transport fails, use native CLI and filesystem directly
- if X auth is unavailable, do not abandon public landscape work; use browser, GitHub, Farcaster, Moltbook, and web search
- if browser adds no new truth, do not use it
- if a tool does not produce proof the lane needs, it is the wrong tool

## What belongs elsewhere

- operating laws and red lines -> `AGENTS.md`
- current queue and routing truth -> state registries
- long-term lessons -> `MEMORY.md`
- today's chronology and proofs -> daily memory
