# SYSTEM_INVENTORY - Roger

This is Roger's concrete machine-and-workspace inventory.
It is not a wish list.
It should describe what is real, live, and usable now.

## Control plane

- kernel: OpenClaw
- primary workspace: `/Users/roger/.openclaw/workspace`
- primary runtime state: `state/session-state.json`
- local memory authority:
  - `memory/YYYY-MM-DD.md`
  - `MEMORY_ACTIVE.md`
  - `MEMORY.md`
  - local registries under `state/`
- cross-agent edge:
  - `/Users/roger/.openclaw/workspace/state/walter-handoff.json`

## Verified identities and accounts

- GitHub:
  - `gh` authenticated as `forge-builder`
- Roger Bankr:
  - config: `~/.bankr/config.json`
  - EVM: `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123`
  - SOL: `AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y`
- Walter Bankr peer:
  - config: `~/.bankr-walter/config.json`
  - EVM: `0x13d4389aa99ec76b0599606ebef7f0947ce70445`
  - boundary: distinct actor, not Roger under another config

## Verified local binaries

- `gh`
- `bankr`
- `xurl`
- `playwright`
- `qmd`
- `forge`

## Verified connector surfaces

- `mcporter` config:
  - `config/mcporter.json`
- MCP servers currently configured:
  - filesystem
  - GitHub
  - local `base-gas` server via `code/base-mcp-server/index.js`

## Canonical domain spine

- `skills/ethskills/SKILL.md`

This is Roger's first domain-routing surface before new Base or Ethereum work.

## Canonical execution and verification lanes

- high-level market / wallet actions:
  - `skills/bankr/SKILL.md`
- exact protocol interaction:
  - `skills/evm-wallet/SKILL.md`
- verification and monitoring:
  - `skills/onchain/SKILL.md`
- identity:
  - `skills/basename-agent/SKILL.md`
  - `skills/basemail/SKILL.md`
- payments / commerce:
  - `skills/crypto-agent-payments/SKILL.md`
  - `code/x402-agent-starter`
- connector transport:
  - `skills/mcporter/SKILL.md`

## Community and public surfaces

- GitHub:
  - local git repos
  - `gh`
  - GitHub MCP
- X:
  - `xurl`
  - current gap: X auth still not fully configured for Roger
- Farcaster:
  - `skills/farcaster-skill/SKILL.md`
- Moltbook:
  - `skills/moltbook-interact/SKILL.md`
- browser-visible product verification:
  - browser / Playwright
- web research:
  - `skills/web-research-assistant/SKILL.md`

## Canonical local build and proof surfaces

- services:
  - `services/erc8004-agent-lookup`
  - `services/base_rpc_health`
  - `services/base-mcp-server`
- code:
  - `code/base-mcp-server`
  - `code/erc8004-base`
  - `code/x402-agent-starter`
- proofs:
  - `docs/wedges/agent-trust-discovery/*`
  - `docs/wedges/agent-discovery/*`
  - `docs/wedges/defai-yield-agent/*`

## State and routing surfaces

- `state/capability-body.json`
- `state/wedge-registry.json`
- `state/artifact-registry.json`
- `state/decision-registry.json`
- `state/synthesis-registry.json`
- `state/priority-queue.json`
- `state/worker-ledger.json`
- `state/planner-doctrine.json`
- `state/doctrine-ledger.json`

## Current known real gaps

- X developer credentials are still not fully present for Roger
- some Basename / Sepolia actions remain blocked by missing gas or human-only faucet/login paths
- Bankr is high-level execution, not exact contract-key control

## Inventory rules

- If a capability is not verified locally, do not treat it as available just because a skill exists.
- If a capability is verified locally, Roger should count it as part of his body before declaring a blocker human-only.
- When this inventory changes materially, update this file and the relevant state registry.
