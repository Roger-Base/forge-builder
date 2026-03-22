# agent-trust-discovery — Demo Output

**Last updated:** 2026-03-22T15:08 UTC
**Status:** LIVE ✅
**Method:** `mcporter call base-gas.lookup_erc8004_agent`

## Live Lookup Results

### Roger — Agent 35176
```
mcporter call base-gas.lookup_erc8004_agent tokenId:35176
```
```json
{
  "exists": true,
  "tokenId": 35176,
  "owner": "0x984d6741e2c6559b1e655b6dbb3a38662fe2c123",
  "name": null,
  "description": null,
  "services": [],
  "x402support": false,
  "chainId": 8453,
  "registry": "0x8004A169FB4a3325136EB29fA0ceB6D2e539a432"
}
```
- **Owner:** bankr wallet (0x9846... — matches DEFAI wallet)
- **Note:** name=null because tokenURI points to IPFS placeholder (ipfs://QmRogerAgent001)

### DataForge — Agent 35313
```
mcporter call base-gas.lookup_erc8004_agent tokenId:35313
```
```json
{
  "exists": true,
  "tokenId": 35313,
  "owner": "0xe2b442b2cb72a60efea1924a063ff3be264fdf7e",
  "name": "DataForge",
  "description": "Powerful agent that transforms raw data into meaningful...",
  "services": [
    {"name": "MCP", "endpoint": "https://chainpulse-mcp-production.up.railway.app/mcp/agent-16"},
    {"name": "A2A", "endpoint": "https://chainpulse-mcp-production.up.railway.app/agents/agent-16/.well-known/agent-card.json"},
    {"name": "OASF", "endpoint": "https://github.com/agntcy/oasf/", "skills": ["analytical_skills/coding_skills/code_optimization"]}
  ],
  "x402support": false,
  "chainId": 8453
}
```
- **Owner:** 0xe2b442... — ChainPulse production wallet
- **Services:** MCP + A2A + OASF confirmed live

### AlphaVision — Agent 35314
```
mcporter call base-gas.lookup_erc8004_agent tokenId:35314
```
```json
{
  "exists": true,
  "tokenId": 35314,
  "owner": "0x1a6708f2fac619090bbf5e77a1976cdd3eef730a",
  "name": "AlphaVision",
  "services": 3,
  "x402support": false,
  "chainId": 8453
}
```

## ERC-8004 Ecosystem Status

- **Registry:** Base Mainnet — 0x8004A169FB4a3325136EB29fA0ceB6D2e539a432
- **Scan (35100–35400):** 76 agents found via ownerOf() scan
- **Known agents:** Roger (35176), DataForge (35313), AlphaVision (35314)
- **Live infrastructure:** Multiple builders using same registry
- **MCP tool:** `base-gas.lookup_erc8004_agent` — 4 tools on base-gas MCP server

## Infrastructure

- **MCP server:** `code/base-mcp-server/index.js` (4 tools)
- **Service:** `services/erc8004-agent-lookup/index.js` (read-only, dual-network)
- **Explorer:** https://roger-base.github.io/erc8004-base/
- **Contract:** ERC-8004 IdentityRegistry on Base (chain 8453)
