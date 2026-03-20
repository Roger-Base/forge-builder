#!/usr/bin/env node

/**
 * DeFAI Yield Scanner CLI
 * Scan DeFi protocols for yield opportunities (Aave, Compound, Curve, Yearn, Uniswap v3)
 * 
 * Usage: node scripts/defai-yield-scan.js --protocol aave --chain base
 * 
 * Node 18+ has fetch built-in - no dependencies required
 */

// Native fetch available in Node 18+

// Protocol configurations
// Note: The Graph migrated from hosted service to decentralized network
// Using mock data for Phase 1 (real API integration in Phase 1.5)
const PROTOCOLS = {
  aave: {
    name: 'Aave',
    subgraph: 'https://api.studio.thegraph.com/query/12999/aave-v3/1.0.0', // Updated endpoint
    chains: ['ethereum', 'polygon', 'arbitrum', 'optimism', 'base'],
    query: `
      query GetReserves {
        reserves(first: 10, orderBy: totalLiquidity, orderDirection: desc) {
          id
          name
          symbol
          totalLiquidity
          utilizationRate
          supplyAPY
          borrowAPY
          availableLiquidity
          price
        }
      }
    `
  },
  compound: {
    name: 'Compound',
    subgraph: 'https://api.studio.thegraph.com/query/12999/compound-v3/1.0.0',
    chains: ['ethereum', 'polygon', 'arbitrum', 'base'],
    query: `
      query GetMarkets {
        markets(first: 10, orderBy: totalBorrows, orderDirection: desc) {
          id
          name
          symbol
          totalBorrows
          totalSupply
          supplyAPY
          borrowAPY
          collateralFactor
          price
        }
      }
    `
  },
  curve: {
    name: 'Curve',
    subgraph: 'https://api.studio.thegraph.com/query/12999/curve/1.0.0',
    chains: ['ethereum', 'polygon', 'arbitrum', 'optimism'],
    query: `
      query GetPools {
        pools(first: 10, orderBy: totalSupply, orderDirection: desc) {
          id
          name
          symbol
          totalSupply
          apy
          volume
          fee
          tvl
        }
      }
    `
  },
  yearn: {
    name: 'Yearn',
    api: 'https://api.yearn.finance/v1/chains',
    chains: ['ethereum', 'fantom', 'arbitrum', 'optimism'],
    query: '/vaults'
  },
  uniswap: {
    name: 'Uniswap v3',
    subgraph: 'https://api.studio.thegraph.com/query/12999/uniswap-v3/1.0.0',
    chains: ['ethereum', 'polygon', 'arbitrum', 'optimism', 'base'],
    query: `
      query GetPools {
        pools(first: 10, orderBy: totalValueLockedETH, orderDirection: desc) {
          id
          token0 {
            symbol
          }
          token1 {
            symbol
          }
          feeTier
          totalValueLockedETH
          volumeUSD
          feeAPY
        }
      }
    `
  }
};

// Mock data for Phase 1 (API integration in Phase 1.5)
const MOCK_DATA = {
  aave: {
    base: [
      { name: 'USDC', symbol: 'USDC', totalLiquidity: '45670000', utilizationRate: '0.75', supplyAPY: '0.0423', borrowAPY: '0.0567', availableLiquidity: '12000000', price: '1.00' },
      { name: 'WETH', symbol: 'WETH', totalLiquidity: '23450000', utilizationRate: '0.65', supplyAPY: '0.0289', borrowAPY: '0.0398', availableLiquidity: '8000000', price: '2800' }
    ],
    ethereum: [
      { name: 'USDC', symbol: 'USDC', totalLiquidity: '89230000', utilizationRate: '0.80', supplyAPY: '0.0345', borrowAPY: '0.0478', availableLiquidity: '20000000', price: '1.00' }
    ]
  },
  compound: {
    ethereum: [
      { name: 'USDC', symbol: 'USDC', totalBorrows: '45000000', totalSupply: '89000000', supplyAPY: '0.0345', borrowAPY: '0.0489', collateralFactor: '0.85', price: '1.00' }
    ]
  },
  curve: {
    ethereum: [
      { name: '3pool', symbol: '3CRV', totalSupply: '156780000', apy: '0.0567', volume: '12000000', fee: '0.0004', tvl: '156780000' }
    ]
  },
  yearn: {
    ethereum: [
      { name: 'yvUSDC', symbol: 'yvUSDC', apy: '0.0612', tvl: '67890000', token: 'USDC' }
    ]
  },
  uniswap: {
    arbitrum: [
      { token0: { symbol: 'WETH' }, token1: { symbol: 'USDC' }, feeTier: 500, totalValueLockedETH: '12000', volumeUSD: '5000000', feeAPY: '0.1234' }
    ],
    ethereum: [
      { token0: { symbol: 'WETH' }, token1: { symbol: 'USDC' }, feeTier: 500, totalValueLockedETH: '45000', volumeUSD: '15000000', feeAPY: '0.0956' }
    ]
  }
};

// Risk scoring
function calculateRisk(protocol, data) {
  let riskScore = 0; // 0-100 (lower = safer)
  
  // Smart contract audit (known protocols = lower risk)
  const auditedProtocols = ['aave', 'compound', 'curve', 'yearn', 'uniswap'];
  if (auditedProtocols.includes(protocol)) {
    riskScore += 10;
  } else {
    riskScore += 40;
  }
  
  // TVL risk (higher TVL = lower risk)
  const tvl = parseFloat(data.totalLiquidity || data.totalSupply || data.tvl || 0);
  if (tvl > 1e9) {
    riskScore += 5;
  } else if (tvl > 1e8) {
    riskScore += 15;
  } else if (tvl > 1e7) {
    riskScore += 30;
  } else {
    riskScore += 50;
  }
  
  // Utilization risk (for lending protocols)
  const utilization = parseFloat(data.utilizationRate || 0);
  if (utilization > 0.8) {
    riskScore += 20;
  } else if (utilization > 0.6) {
    riskScore += 10;
  }
  
  return riskScore;
}

// Fetch protocol data
async function fetchProtocolData(protocol, chain) {
  const config = PROTOCOLS[protocol];
  if (!config) {
    throw new Error(`Unknown protocol: ${protocol}`);
  }
  
  if (!config.chains.includes(chain)) {
    throw new Error(`${protocol} not available on ${chain}`);
  }
  
  // Phase 1: Use mock data (API integration in Phase 1.5)
  if (MOCK_DATA[protocol] && MOCK_DATA[protocol][chain]) {
    console.log(`Using mock data for ${protocol} on ${chain} (Phase 1 - API integration pending)`);
    return MOCK_DATA[protocol][chain];
  }
  
  // Phase 1.5: Real API integration
  try {
    if (config.subgraph) {
      const response = await fetch(config.subgraph, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: config.query })
      });
      const data = await response.json();
      return data.data;
    } else if (config.api) {
      const response = await fetch(`${config.api}${chain}${config.query}`);
      const data = await response.json();
      return data;
    }
  } catch (error) {
    console.error(`Error fetching ${protocol} data:`, error.message);
    // Fallback to mock data
    return MOCK_DATA[protocol]?.[chain] || null;
  }
}

// Format output
function formatOutput(protocol, chain, data) {
  console.log(`\n=== ${protocol.toUpperCase()} Yield Data (${chain}) ===\n`);
  
  if (!data) {
    console.log('No data available');
    return;
  }
  
  const items = data.reserves || data.markets || data.pools || data;
  
  if (Array.isArray(items)) {
    items.forEach((item, idx) => {
      const apy = parseFloat(item.supplyAPY || item.apy || item.feeAPY || 0) * 100;
      const tvl = parseFloat(item.totalLiquidity || item.totalSupply || item.tvl || item.totalValueLockedETH || 0);
      const risk = calculateRisk(protocol, item);
      
      // Build name from token symbols for Uniswap pools
      let name = item.name || item.symbol;
      if (!name && item.token0 && item.token1) {
        const token1Symbol = typeof item.token1 === 'object' ? item.token1.symbol : item.token1;
        name = `${item.token0.symbol}/${token1Symbol} ${item.feeTier ? '0.' + item.feeTier + '%' : ''}`;
      }
      if (!name) name = 'Unknown';
      
      console.log(`${idx + 1}. ${name}`);
      console.log(`   APY: ${apy.toFixed(2)}%`);
      console.log(`   TVL: $${(tvl / 1e6).toFixed(2)}M`);
      console.log(`   Risk Score: ${risk}/100 (${risk < 20 ? 'Low' : risk < 40 ? 'Medium' : 'High'})`);
      console.log('');
    });
  } else {
    console.log('Data format not recognized');
  }
}

// Parse CLI args
function parseArgs() {
  const args = process.argv.slice(2);
  const params = {};
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--protocol' && args[i + 1]) {
      params.protocol = args[i + 1].toLowerCase();
      i++;
    } else if (args[i] === '--chain' && args[i + 1]) {
      params.chain = args[i + 1].toLowerCase();
      i++;
    } else if (args[i] === '--all') {
      params.all = true;
    } else if (args[i] === '--help' || args[i] === '-h') {
      console.log(`
DeFAI Yield Scanner CLI

Usage: node scripts/defai-yield-scan.js [options]

Options:
  --protocol <name>  Protocol to scan (aave, compound, curve, yearn, uniswap)
  --chain <name>     Chain to scan (ethereum, polygon, arbitrum, optimism, base)
  --all              Scan all protocols on all chains
  --help, -h         Show this help message

Examples:
  node scripts/defai-yield-scan.js --protocol aave --chain base
  node scripts/defai-yield-scan.js --all
      `);
      process.exit(0);
    }
  }
  
  return params;
}

// Main scan function
async function scanYield(params) {
  if (params.all) {
    console.log('Scanning all protocols...');
    for (const protocol of Object.keys(PROTOCOLS)) {
      for (const chain of PROTOCOLS[protocol].chains) {
        try {
          const data = await fetchProtocolData(protocol, chain);
          formatOutput(protocol, chain, data);
        } catch (error) {
          console.error(`Error scanning ${protocol} on ${chain}:`, error.message);
        }
      }
    }
  } else if (params.protocol && params.chain) {
    try {
      const data = await fetchProtocolData(params.protocol, params.chain);
      formatOutput(params.protocol, params.chain, data);
    } catch (error) {
      console.error('Error:', error.message);
      process.exit(1);
    }
  } else {
    console.log('Error: Please specify --protocol and --chain, or use --all');
    console.log('Run with --help for usage');
    process.exit(1);
  }
}

// Run
const params = parseArgs();
scanYield(params).catch(console.error);
