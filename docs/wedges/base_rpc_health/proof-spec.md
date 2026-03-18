# base_rpc_health - Proof Spec

## Service Definition

A lightweight Base RPC health monitoring service for AI agents.

## Functionality

1. **Multi-RPC Check**: Tests 5 Base RPC endpoints
2. **Latency Measurement**: Records response time for each
3. **Block Number**: Fetches current block from each
4. **Ranking**: Sorts by fastest latency
5. **Recommendation**: Identifies best RPC for agent use
6. **Error Handling**: Reports failed endpoints with reasons

## Tested RPCs

| RPC | Status |
|-----|--------|
| base.publicnode.com | ✅ Working |
| base.llamarpc.com | ✅ Working |
| mainnet.base.org | ✅ Working |
| 1rpc.io/base | ✅ Working |
| rpc.ankr.com/base | ❌ API key required |

## Output Format

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

## Proof Artifacts

- [x] README.md - Service documentation
- [x] proof-page.md - Live test results
- [x] research-packet.md - Problem analysis (this file)
- [ ] proof-spec.md - Service specification (this section)

## Run Command

```bash
cd services/base_rpc_health
node index.js
```

## Stage

DISTRIBUTE

## Created

2026-03-17
