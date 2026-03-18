# Base RPC Health - Integration Guide

## Overview

This service provides real-time health monitoring for Base RPC endpoints. It checks multiple RPC providers, measures latency, and recommends the best endpoint for AI agents.

## Quick Start

```bash
# Clone and run
git clone https://github.com/your-repo/base-rpc-health.git
cd base-rpc-health
node index.js
```

## API Usage

### JavaScript/Node.js

```javascript
const { checkRPCHealth } = require('./index.js');

async function main() {
  const result = await checkRPCHealth();
  console.log('Best RPC:', result.best.rpc);
  console.log('Latency:', result.best.latency, 'ms');
}

main();
```

### Python

```python
import requests

def check_health():
    response = requests.post('https://your-rpc-health-api.com/check', json={
        'endpoints': [
            'https://base.publicnode.com',
            'https://base.llamarpc.com',
            'https://mainnet.base.org'
        ]
    })
    return response.json()

result = check_health()
print(f"Best RPC: {result['best']['rpc']}")
```

### As CLI Tool

```bash
# Get best RPC
node index.js --best

# Get all results
node index.js --all

# JSON output
node index.js --json
```

## Configuration

Create `config.json`:

```json
{
  "endpoints": [
    "https://base.publicnode.com",
    "https://base.llamarpc.com"
  ],
  "timeout": 5000,
  "sortBy": "latency"
}
```

## Integration Examples

### With ethers.js

```javascript
const { checkRPCHealth } = require('./base-rpc-health');

async function getBestRPC() {
  const health = await checkRPCHealth();
  return health.best.rpc;
}

const provider = new ethers.JsonRpcProvider(await getBestRPC());
```

### With viem

```javascript
import { createPublicClient, http } from 'viem';
import { base } from 'viem/chains';

async function getClient() {
  const health = await checkRPCHealth();
  return createPublicClient({
    chain: base,
    transport: http(health.best.rpc)
  });
}
```

## Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "index.js"]
```

```bash
docker build -t base-rpc-health .
docker run base-rpc-health
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| RPC_TIMEOUT | Request timeout (ms) | 5000 |
| RPC_ENDPOINTS | Comma-separated endpoints | Built-in list |
| LOG_LEVEL | debug, info, warn, error | info |

## Response Format

```json
{
  "timestamp": "2026-03-17T23:00:00Z",
  "results": [
    {
      "rpc": "https://base.publicnode.com",
      "latency": 125,
      "block": 43498539,
      "status": "ok"
    }
  ],
  "best": {
    "rpc": "https://base.publicnode.com",
    "latency": 125
  }
}
```

## License

MIT
