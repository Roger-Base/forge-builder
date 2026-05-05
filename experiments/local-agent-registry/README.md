# Local Agent Registry v0.2.0 — Base/Molty Discovery Primitive

A local-first discovery + trust prototype. Roger's living proof that he can build
real infrastructure, not just monitor tunnels.

## What it is

- **registry.json** — agent registry with capabilities, services (x402 endpoints), payment rails, discovery patterns, and trust stubs
- **trust-events.jsonl** — immutable event log of capability verifications and trust signals
- **server.mjs** — dependency-free HTTP API (Node.js native)
- **schema.json** — JSON Schema for registry format
- **scripts/validate.mjs** — sanity check for registry integrity

## Routes

```bash
PORT=4317 node server.mjs

curl http://127.0.0.1:4317/health        # ok, version, agents
curl http://127.0.0.1:4317/agents        # list all agents with capabilities + services
curl http://127.0.0.1:4317/agents/roger-base  # full Roger entry
curl http://127.0.0.1:4317/capabilities # all unique capabilities
curl http://127.0.0.1:4317/services     # all agent services with prices
curl http://127.0.0.1:4317/trust-events # trust event log from JSONL
curl http://127.0.0.1:4317/schema       # JSON Schema
```

## Current state (2026-05-05)

- **3 agents**: Roger, Walter, Iris
- **4 Roger services**: yield-gap ($0.01), wallet-profiler ($0.01), token-analyzer ($0.01), tx-decoder ($0.02) — all x402-enabled on Base mainnet
- **10 capabilities** registered
- **8 trust events** logged (capability verifications + self-audit)
- **discovery patterns**: MCP not-connected, A2A not-connected, Bazaar no-facilitator, DNS local-only

## Why this exists

Scout (2026-05-04) showed Base has identity + payment rails but weak programmatic discovery.
`agent-identity-discovery` (coinbase, 2026-04-19) uses DNS-based discovery — but that needs infrastructure Roger doesn't have.
`AI-Agent-Registry` (2026-05-03) is FastAPI + SQL — overkill for local first.

This is a portable, dependency-free primitive that:
1. Proves Roger can build instead of monitor
2. Tests whether agent discovery matters on Base
3. Can evolve into `/.well-known/agents.json` or an ERC-8004 metadata extension

## Non-goals

- No public directory claim
- No wallet signing
- No external listing without Tomas approval
- No reputation score beyond local event log

## Next layer (backlog)

- [ ] Add trust score computation from trust-events.jsonl
- [ ] Add economic-route metadata per capability (earning potential, demand signal)
- [ ] HTTP Bazaar discovery probe (needs facilitator)
- [ ] A2A protocol probe
- [ ] If real demand shows: port to `/.well-known/base-agent.json` spec
- [ ] Fundiora agent entry (Tomas' project)

## Verification

```bash
node scripts/validate-registry.mjs
# { ok: true, agents: 3, capabilities: 10 }
```