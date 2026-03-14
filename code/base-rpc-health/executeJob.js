#!/usr/bin/env node
/**
 * base_rpc_health - Execute Job Handler
 * 
 * Monitors multiple Base RPC endpoints and returns health status.
 * 
 * Input: { action: "health_check" | "get_best_endpoint" | "get_all_status" }
 * Output: { endpoints: [...], best: {...}, timestamp }
 */

const RPC_ENDPOINTS = [
  { name: 'base-mainnet', url: 'https://mainnet.base.org', priority: 1 },
  { name: 'base-sepolia', url: 'https://sepolia.base.org', priority: 2 },
  { name: 'alchemy-base', url: 'https://base-mainnet.g.alchemy.com/v2/demo', priority: 3 },
  { name: 'public-rpc', url: 'https://rpc.ankr.com/base', priority: 4 }
];

async function checkEndpoint(endpoint) {
  const start = Date.now();
  try {
    const response = await fetch(endpoint.url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 1
      }),
      signal: AbortSignal.timeout(5000)
    });
    
    const latency = Date.now() - start;
    const data = await response.json();
    
    return {
      name: endpoint.name,
      url: endpoint.url,
      status: response.ok && data.result ? 'healthy' : 'unhealthy',
      latency,
      blockNumber: data.result ? parseInt(data.result, 16) : null,
      priority: endpoint.priority,
      error: response.ok ? null : 'HTTP error'
    };
  } catch (error) {
    return {
      name: endpoint.name,
      url: endpoint.url,
      status: 'unhealthy',
      latency: null,
      blockNumber: null,
      priority: endpoint.priority,
      error: error.message
    };
  }
}

async function executeJob(requirements) {
  const { action = 'health_check' } = requirements;
  
  try {
    // Check all endpoints in parallel
    const results = await Promise.all(RPC_ENDPOINTS.map(ep => checkEndpoint(ep)));
    
    // Sort by health + latency
    const healthy = results.filter(r => r.status === 'healthy').sort((a, b) => a.latency - b.latency);
    const unhealthy = results.filter(r => r.status === 'unhealthy');
    
    const best = healthy.length > 0 ? healthy[0] : null;
    
    if (action === 'get_best_endpoint') {
      return {
        success: !!best,
        best: best,
        message: best ? 'Best endpoint found' : 'No healthy endpoints'
      };
    }
    
    if (action === 'get_all_status') {
      return {
        success: true,
        endpoints: results,
        summary: {
          healthy: healthy.length,
          unhealthy: unhealthy.length,
          total: results.length
        }
      };
    }
    
    // Default: health_check
    return {
      success: healthy.length > 0,
      best: best,
      endpoints: results,
      healthy_count: healthy.length,
      unhealthy_count: unhealthy.length,
      timestamp: new Date().toISOString(),
      recommendation: best 
        ? `Use ${best.name} (${best.latency}ms)`
        : 'All endpoints unhealthy - wait and retry'
    };
    
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// CLI test
const args = process.argv.slice(2);
if (args.length > 0) {
  const requirements = JSON.parse(args[0]);
  executeJob(requirements).then(result => {
    console.log(JSON.stringify(result, null, 2));
  });
}

module.exports = { executeJob };
