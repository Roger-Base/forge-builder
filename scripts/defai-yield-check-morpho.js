#!/usr/bin/env node
// Check Morpho Blue USDC supply APY on Base via direct RPC
const { execSync } = require('child_process');
const fs = require('fs');

const MORPHO_BLUE = '0xbbbbbbbbbb9cc5e90e3b3af64bdaf62c37eeffcb'; // Morpho Blue on Base
const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913';
const RPC = 'https://mainnet.base.org';
const STATE_FILE = '/Users/roger/.openclaw/workspace/state/defai-yield-state.json';

function getMorphoAPY() {
  try {
    // Morpho Blue uses a different interface - getMarket()
    // For Morpho Blue on Base, we need the IRM and LLTV
    // Try getting market config first
    const raw = execSync(
      `~/.foundry/bin/cast call ${MORPHO_BLUE} "idToMarketParams(bytes32)((address,address,address,address,uint256))" 0x0000000000000000000000000000000000000000000000000000000000000001 --rpc-url ${RPC}`,
      { timeout: 10000 }
    ).toString();
    
    console.log('Morpho response:', raw.slice(0, 200));
    return null; // placeholder
  } catch(e) {
    console.log('Morpho read failed:', e.message.split('\n')[0]);
    return null;
  }
}

getMorphoAPY();
