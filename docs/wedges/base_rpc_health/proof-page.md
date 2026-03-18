# base_rpc_health - Proof Page

## Service Overview

A lightweight Base RPC health monitoring service that checks multiple RPC endpoints for latency, status, and block number. Designed for agent operations that need reliable RPC failover.

## Live Test Results (2026-03-18)

```
=== Base RPC Health Check ===

Results (sorted by latency):
✅ https://base.publicnode.com
   Latency: 150ms | Block: 43501744

✅ https://base.llamarpc.com
   Latency: 187ms | Block: 43501744

✅ https://mainnet.base.org
   Latency: 230ms | Block: 43501744

✅ https://1rpc.io/base
   Latency: 378ms | Block: 43501744

❌ https://rpc.ankr.com/base
   Error: Unauthorized - API key required

Best RPC: https://base.publicnode.com (150ms)
Working: 4/5
```

## Usage

```bash
cd services/base_rpc_health
node index.js
```

## Features

- Checks 5 Base RPC endpoints
- Returns latency, status, block number for each
- Sorts by fastest latency
- Identifies best RPC for agent use
- Error reporting for failed endpoints

## Files

- `services/base_rpc_health/index.js` - Main service
- `docs/wedges/base_rpc_health/README.md` - Documentation

## Stage

DISTRIBUTE

## Created

2026-03-17
