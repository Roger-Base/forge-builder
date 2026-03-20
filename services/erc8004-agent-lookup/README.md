# ERC-8004 Agent Trust Lookup Service

**Base Sepolia — Read-only trust and identity lookup on live ERC-8004 contracts.**

## What it does

Queries the live ERC-8004 IdentityRegistry and ReputationRegistry on Base Sepolia. Returns the total supply of registered agents and per-token owner + metadata for each agent record.

No writes. No signatures. Pure read-only RPC.

## Contract addresses (Base Sepolia)

| Contract | Address |
|---|---|
| IdentityRegistry (ERC-8004) | `0x8004A818BFB912233c491871b3d84c89A494BD9e` |
| ReputationRegistry | `0x8004B663056A597DFFE9EccC1965A193B7388713` |
| RPC default | `https://base-sepolia.publicnode.com` |

## Install

```bash
cd services/erc8004-agent-lookup
npm install
```

## Run

```bash
node index.js
```

## Environment

| Variable | Default | Notes |
|---|---|---|
| `RPC_URL` | `https://base-sepolia.publicnode.com` | Any Base Sepolia RPC |

```bash
RPC_URL=https://base-sepolia.publicnode.com node index.js
```

## Output

```
🔍 ERC-8004 Agent Trust Lookup — Base Sepolia
═══════════════════════════════════════════════

RPC: https://base-sepolia.publicnode.com
IdentityRegistry: 0x8004A818BFB912233c491871b3d84c89A494BD9e
ReputationRegistry: 0x8004B663056A597DFFE9EccC1965A193B7388713

✅ Verifying contracts...

   IdentityRegistry name(): "AgentIdentity" — CONFIRMED
   Total registered agents: 0

⚠️  No agents registered yet on Base Sepolia testnet.
   This is expected — contracts are deployed but not yet used.
   The lookup service infrastructure is working correctly.

═══════════════════════════════════════════════
Timestamp: 2026-03-20T13:42:00.000Z
Network: Base Sepolia (chain 84532)
IdentityRegistry: 0x8004A818BFB912233c491871b3d84c89A494BD9e
ReputationRegistry: 0x8004B663056A597DFFE9EccC1965A193B7388713
Registered agents: 0
═══════════════════════════════════════════════
```

## JSON output

The script exits with a JSON blob on stdout after the human-readable output:

```json
{
  "timestamp": "2026-03-20T13:42:00.000Z",
  "network": "base-sepolia",
  "chainId": 84532,
  "identityRegistry": "0x8004A818BFB912233c491871b3d84c89A494BD9e",
  "reputationRegistry": "0x8004B663056A597DFFE9EccC1965A193B7388713",
  "totalSupply": 0,
  "rpc": "https://base-sepolia.publicnode.com"
}
```

## Architecture

- **Language:** Node.js (no external web3 dependency)
- **RPC:** native `http`/`https` module — no ethers/viem required
- **Encoding:** manual hex encoding for `ownerOf`, `tokenURI`, `name`, `totalSupply`
- **Timeout:** 15s per call

## Status

- ✅ ERC-8004 contracts verified live on Base Sepolia
- ✅ IdentityRegistry `name()` confirmed: "AgentIdentity"
- ✅ Total supply query confirmed working
- ✅ ReputationRegistry code confirmed on-chain
- ⚠️ `totalSupply = 0` — testnet unused; production-ready when agents register
