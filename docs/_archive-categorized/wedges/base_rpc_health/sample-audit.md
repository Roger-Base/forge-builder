# base_rpc_health - Sample Audit

**Wedge:** base_rpc_health
**Stage:** DISTRIBUTE
**Generated:** 2026-03-17

## Overview

This wedge provides a lightweight Base RPC health monitoring service for AI agents. It tests multiple RPC endpoints and recommends the fastest one for agent operations.

## Test Method

Using standard JSON-RPC `eth_blockNumber` call to measure latency and connectivity.

## Sample Results (2026-03-17 07:00 UTC)

| RPC Provider | Latency | Block | Status |
|--------------|---------|-------|--------|
| base.publicnode.com | 125ms | 43470720 | ✅ Working |
| base.llamarpc.com | 203ms | 43470720 | ✅ Working |
| mainnet.base.org | 206ms | 43470720 | ✅ Working |
| 1rpc.io/base | 328ms | 43470719 | ✅ Working |
| rpc.ankr.com/base | - | - | ❌ API Key Required |

## Best Recommendation

**Primary:** https://base.publicnode.com (125ms)
**Fallback:** https://base.llamarpc.com (203ms)

## Service Output

```json
{
  "timestamp": "2026-03-17T07:00:00Z",
  "results": [
    {
      "rpc": "https://base.publicnode.com",
      "latency": 125,
      "block": 43470720,
      "status": "ok"
    }
  ],
  "best": {
    "rpc": "https://base.publicnode.com",
    "latency": 125
  }
}
```

## Usage

```bash
cd services/base_rpc_health
node index.js
```

## Files

- `services/base_rpc_health/index.js` - Main service
- `docs/wedges/base_rpc_health/README.md` - Documentation
- `docs/wedges/base_rpc_health/proof-page.md` - Live results
