# base_rpc_health - Proof Page

## Service Overview

A lightweight Base RPC health monitoring service that checks multiple RPC endpoints for latency, status, and block number. Designed for agent operations that need reliable RPC failover.

## Live Test Results (2026-03-18 18:58 UTC)

```
=== Base RPC Health + Gas Service ===

Results (sorted by latency):
✅ https://base.publicnode.com
   Latency: 128ms | Block: 43535468

✅ https://1rpc.io/base
   Latency: 191ms | Block: 43535471

✅ https://mainnet.base.org
   Latency: 238ms | Block: 43535472

✅ https://base.llamarpc.com
   Latency: 7996ms | Block: 43535469

❌ https://rpc.ankr.com/base
   Error: Failed (API key required)

Best RPC: https://base.publicnode.com (128ms)
Working: 4/5
Gas Price: 0.01 Gwei
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
