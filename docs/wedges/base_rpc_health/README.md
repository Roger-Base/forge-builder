# base_rpc_health

Base RPC Health Monitor Service

## Overview

A lightweight service that checks multiple Base RPC endpoints for latency, status, and block number. Useful for agent operations that need reliable RPC failover.

## Usage

```bash
cd services/base_rpc_health
node index.js
```

## Output

- Latency for each RPC endpoint
- Current block number
- Best RPC recommendation (fastest)
- Error reporting for failed endpoints

## Tested RPCs

| RPC | Status | Latency (2026-03-17) |
|-----|--------|----------------------|
| base.publicnode.com | ✅ | 125ms |
| base.llamarpc.com | ✅ | 203ms |
| mainnet.base.org | ✅ | 206ms |
| 1rpc.io/base | ✅ | 328ms |
| rpc.ankr.com/base | ❌ | Requires API key |

## Latest Test Run

```
Best RPC: https://base.publicnode.com (125ms)
Working: 4/5 RPCs
Block: 43470720
```

## Created

2026-03-17

## Stage

DISTRIBUTE
