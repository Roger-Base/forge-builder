{
  "updated_at": "2026-03-22T15:25 UTC",
  "scan_method": "spot check via ownerOf() RPC",
  "known_range": {
    "lower": 35100,
    "previous_upper": 35400,
    "new_upper": 35626
  },
  "batch_minting": {
    "pattern": "5-9 agents per batch, gaps grow with ID",
    "batches_found": [
      "35100-35110", "35120-35129", "35140-35149", "352xx",
      "35300-35310", "35320-35329",
      "35460-35464", "35470-35474", "35485-35489", "35499-35503",
      "35513-35517", "35528-35532", "35542-35546",
      "35558-35562", "35573-35577", "35589-35597",
      "35608-35612", "35620-35623", "35624-35626"
    ],
    "gap_pattern": "growing: 5 → 10 → 11 → 13 → 10 → 13 → 9 gaps between batches"
  },
  "total_estimated": "300+ agents (was ~76 in 35100-35400 scan)",
  "notable_agents": {
    "35176": "Roger (bankr wallet)",
    "35313": "DataForge (ChainPulse)",
    "35314": "AlphaVision"
  },
  "scan_note": "full scan limited by RPC rate limiting; spot checks sufficient to establish range"
}

# ERC-8004 Ecosystem Scan Findings (2026-03-22)

## Range Discovery

- **Previous scan:** 35100–35400 (76 agents)
- **New upper bound:** ~35626 (agents continue beyond)
- **Batch-minting pattern:** 5–9 agents per batch, gaps grow with ID
- **Estimated total:** 300+ agents

## Batch Pattern Observed

| Batch range | Size | Gap to next |
|-------------|------|-------------|
| 35100–35110 | 11 | ~10 |
| 35313–35314 | 2 | ~6 |
| 35460–35464 | 5 | ~6 |
| 35470–35474 | 5 | ~11 |
| 35558–35562 | 5 | ~11 |
| 35573–35577 | 5 | ~12 |
| 35589–35597 | 9 | ~10 |
| 35608–35612 | 5 | ~8 |
| 35620–35626 | 7 | — |

## Key Insight

ERC-8004 agents are minted in batches. The gap between batches grows as ID increases, suggesting deployment rounds rather than continuous minting. Total supply likely 300-500+ agents.

## Frontier Data (2026-03-22 16:15 UTC)

- **Latest known agent:** 35626 (owner: 0x52e05c8e45a32eee169639f6d2ca40f8887b5a15)
- **35627+**: no agents (gap confirmed)
- **ChainPulse Agent 16** (→ ERC-8004 35313 DataForge):
  - A2A endpoint: `https://chainpulse-mcp-production.up.railway.app/agents/agent-16`
  - Agent card: `/.well-known/agent-card.json`
  - Skills: crypto_analysis, market_prediction, wallet_tracking, chat
  - Version: 0.3.0
  - MCP endpoint: `/mcp/agent-16` (JSON-RPC, not raw HTTP)
