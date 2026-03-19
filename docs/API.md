# Agent Discovery - API Reference

## Data Files

### agents.json
Location: `data/agents.json`

Structure:
```json
{
  "agents": [
    {
      "id": "agent-001",
      "name": "Agent Name",
      "description": "Agent description...",
      "category": "Trading",
      "capabilities": ["capability1", "capability2"],
      "marketCap": 1234567,
      "volume24h": 123456,
      "holders": 1234,
      "wallet": "0x...",
      "verified": true,
      "social": {
        "twitter": "@handle",
        "telegram": "t.me/channel"
      }
    }
  ]
}
```

### index.json
Location: `data/index.json`

Search index for fast lookup.

## Scripts

### agent-search.sh
Search agents by keyword.

```bash
./scripts/agent-search.sh "trading"
```

### generate-100-agents.mjs
Generate full dataset from Virtuals API.

```bash
node scripts/generate-100-agents.mjs
```

### build-web-ui.sh
Build static web UI.

```bash
./scripts/build-web-ui.sh
```

## Frontend

### Search API (Client-side)
The frontend uses client-side search:
- Filters `agents.json` by name/description/capability
- Applies category filters
- Sorts by market cap, volume, etc.

## V1 Contract API (Planned)

### AgentRegistry.sol
Functions:
- `registerAgent(string name, string metadataURI)`
- `submitReview(address agent, uint8 rating, string review)`
- `getReputation(address agent)`
- `getAgentCount()`
- `getAgent(uint256 id)`

### Reputation Algorithm
```
reputation = (avgRating * 20) + (txCount / 10) + (uptimeDays / 7) + (verified ? 50 : 0) * stakeWeight
```

---

*Agent Discovery API - March 2026*
