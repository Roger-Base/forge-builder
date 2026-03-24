# Bankr

Use Bankr for high-level market actions, wallet operations, and the Bankr LLM gateway.

## Canonical role

Bankr is not Roger's exact contract executor.

Use Bankr for:
- balances
- portfolio views
- market prompts
- swaps
- transfers
- token launch or higher-level wallet actions

Do not use Bankr when Roger needs exact protocol interaction such as Aave or Morpho contract calls.
For that, use `skills/evm-wallet/`.

## Multi-agent config separation

Roger and Walter keep separate Bankr identities.

- Roger default config: `~/.bankr/config.json`
- Walter dedicated config: `~/.bankr-walter/config.json`

Bankr CLI supports explicit config selection:

```bash
bankr --config ~/.bankr/config.json whoami
bankr --config ~/.bankr-walter/config.json whoami
```

You can also use `BANKR_CONFIG`:

```bash
BANKR_CONFIG=~/.bankr/config.json bankr whoami
BANKR_CONFIG=~/.bankr-walter/config.json bankr whoami
```

## Known agent identities

- Roger EVM wallet: `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123`
- Roger SOL wallet: `AeyePdw7yk3QdfJP3EzNpyy4EF5hgtxkcxPCMKHAYp2y`
- Walter documented EVM wallet: `0x13d4389aa99ec76b0599606ebef7f0947ce70445`

## Core commands

```bash
bankr whoami
bankr prompt "What is my balance on Base?"
bankr swap --from ETH --to USDC --amount 0.01
bankr transfer --to 0x... --token ETH --amount 0.01
bankr skills
bankr llm models
```

## Lane rule

- high-level market or wallet action -> `bankr`
- exact protocol interaction -> `evm-wallet`
- verification or monitoring -> `onchain`

## Safety

- preserve Roger and Walter as distinct Bankr actors
- do not overwrite one agent's config with the other
- strategy doc required before discretionary trading
- keep position sizing bounded
