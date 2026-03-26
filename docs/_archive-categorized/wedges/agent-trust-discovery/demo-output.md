# agent-trust-discovery — Demo Output

**Last run:** 2026-03-25T16:30:20Z
**Service:** `services/erc8004-agent-lookup/index.js`
**Status:** OK
**Exit code:** 0

## Live run output

```

🔍 ERC-8004 Agent Trust Lookup — Base Mainnet
═══════════════════════════════════════════════

RPC: https://mainnet.base.org
IdentityRegistry: 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432
ReputationRegistry: 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63

✅ Verifying contracts...

   IdentityRegistry: Contract exists (name() check inconclusive)
   Scanning 35100–35400 via ownerOf()...


   Total agents found: 0

📊 ReputationRegistry status:
   ReputationRegistry: Contract code confirmed (no name() or different interface)

═══════════════════════════════════════════════
Timestamp: 2026-03-25T16:30:27.631Z
Network: Base Mainnet (chain 8453)
IdentityRegistry: 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432
ReputationRegistry: 0x8004BAa17C55a88189AE136b182e5fdA19dE9b63
Registered agents: 0
═══════════════════════════════════════════════


--- JSON OUTPUT ---
{
  "timestamp": "2026-03-25T16:30:27.632Z",
  "network": "base-mainnet",
  "chainId": 84532,
  "identityRegistry": "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432",
  "reputationRegistry": "0x8004BAa17C55a88189AE136b182e5fdA19dE9b63",
  "totalAgents": 0,
  "rpc": "https://mainnet.base.org"
}
```

## Reuse note

- This file is the canonical live demo surface for the agent-trust-discovery wedge.
- Refresh this file before creating a new proof fragment for the same lookup flow.
