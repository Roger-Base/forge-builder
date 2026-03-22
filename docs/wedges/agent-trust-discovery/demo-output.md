# agent-trust-discovery Demo Output — 2026-03-22

## ERC-8004 Base Mainnet Registry Scan

**Contract:** `0x8004A169FB4a3325136EB29fA0ceB6D2e539a432`
**RPC:** `https://mainnet.base.org`
**Scan Method:** `ownerOf(uint256)` via `eth_call` (sequential, 30ms delay)

### Known Live Agents (verified 2026-03-22)

| Agent ID | Owner | Notes |
|----------|-------|-------|
| 35176 | `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123` | Roger (bankr wallet) |
| 35313 | `0xe2b442b2cb72a60efea1924a063ff3be264fdf7e` | DataForge (MCP + A2A active) |
| 35314 | `0x1a6708f2fac619090bbf5e77a1976cdd3eef730a` | AlphaVision (MCP + A2A active) |

### Agent Sample (Range 35100-35200)

Found 27 agents in this range. Sample:

- Agent 35100: `0x6ffa1e00509d8b625c2f061d7db07893b37199bc`
- Agent 35101: `0xc5b322e6da0989ed0ec4a1f10d6abc8a19fd8b8a`
- Agent 35109: `0xcc615f59eeadb99253379f257c2ada42ffc38062`
- Agent 35110-35113: Batch by `0x17c57bd...`, `0xd42c560...`, `0x13db5a46...`, `0xa54d390...`
- Agent 35119: `0x33e89ceca902e3febf86686a4d0adb195ba6e49a`
- Agent 35120-35122: Sequential owners
- Agent 35137-35140: `0x1d217f3e41e442914e` (batch registrant)
- Agent 35176: `0x984d6741e2c6559b1e655b6dbb3a38662fe2c123` ← Roger
- Agent 35181-35185: Various owners

### Total Supply Estimate

- Range 35100-35200: **27 agents** (in 100 IDs)
- Range 35100-35400: **~76 agents** (in 300 IDs, from full scan)
- **Estimated total supply:** 35,000+ (based on Basescan: 45,281 transactions)

### Key Contract Facts

- `ownerOf(uint256)`: ✅ Works correctly
- `tokenURI(uint256)`: ✅ Returns base64 data: JSON (ethers.js v6 auto-decodes)
- `balanceOf(address)`: ✅ Works
- `totalSupply()`: ❌ Reverts on Mainnet (contract bug — not implemented)
- `name()`: ❌ Reverts

### TokenURI Format (verified)

DataForge (35313) returns:
```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "DataForge",
  "description": "Powerful agent that transforms raw data...",
  "services": [
    {"name": "MCP", "endpoint": "https://chainpulse-mcp-production.up.railway.app/mcp/agent-16"},
    {"name": "A2A", "endpoint": "https://chainpulse-mcp-production.up.railway.app/agents/agent-16/.well-known/agent-card.json"}
  ],
  "active": true,
  "x402support": false
}
```

### Ecosystem Status

ERC-8004 Base Mainnet Registry is **active**. Multiple builders (ChainPulse, Roger, unknown others) registering agents. Not a test environment — production infrastructure.
