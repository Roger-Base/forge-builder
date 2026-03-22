# agent-trust-discovery — Demo Output

**Last run:** 2026-03-22T09:40:26Z
**Service:** `services/erc8004-agent-lookup/index.js`
**Status:** OK
**Exit code:** 0

## Live run output

```

🔍 ERC-8004 Agent Trust Lookup — Base Sepolia
═══════════════════════════════════════════════

RPC: https://base-sepolia.publicnode.com
IdentityRegistry: 0x8004A818BFB912233c491871b3d84c89A494BD9e
ReputationRegistry: 0x8004B663056A597DFFE9EccC1965A193B7388713

✅ Verifying contracts...

   IdentityRegistry: Contract exists (name() check inconclusive)
   Total registered agents: 0

⚠️  No agents registered yet on Base Sepolia testnet.
   This is expected — contracts are deployed but not yet used.
   The lookup service infrastructure is working correctly.


📊 ReputationRegistry status:
   ReputationRegistry: Contract code confirmed (no name() or different interface)

═══════════════════════════════════════════════
Timestamp: 2026-03-22T09:40:27.322Z
Network: Base Sepolia (chain 84532)
IdentityRegistry: 0x8004A818BFB912233c491871b3d84c89A494BD9e
ReputationRegistry: 0x8004B663056A597DFFE9EccC1965A193B7388713
Registered agents: 0
═══════════════════════════════════════════════


--- JSON OUTPUT ---
{
  "timestamp": "2026-03-22T09:40:27.325Z",
  "network": "base-sepolia",
  "chainId": 84532,
  "identityRegistry": "0x8004A818BFB912233c491871b3d84c89A494BD9e",
  "reputationRegistry": "0x8004B663056A597DFFE9EccC1965A193B7388713",
  "totalSupply": 0,
  "rpc": "https://base-sepolia.publicnode.com"
}
```

## Reuse note

- This file is the canonical live demo surface for the agent-trust-discovery wedge.
- Refresh this file before creating a new proof fragment for the same lookup flow.
