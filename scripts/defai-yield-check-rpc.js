#!/usr/bin/env node
// Direct RPC yield check — uses foundry's cast for reliable on-chain reads
const { execSync } = require('child_process');
const fs = require('fs');

const AAVE_POOL = '0xA238Dd80C259a72e81d7e4664a9801593F98d1c5';
const USDC = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913';
const RPC = 'https://mainnet.base.org';
const STATE_FILE = '/Users/roger/.openclaw/workspace/state/defai-yield-state.json';

function getAPY() {
  try {
    const raw = execSync(
      `~/.foundry/bin/cast call ${AAVE_POOL} "getReserveData(address)((uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool,bool,bool,bool,bool))" ${USDC} --rpc-url ${RPC}`,
      { timeout: 15000 }
    ).toString();
    
    // Parse the floating point numbers from foundry output like "[1.128e27],..."
    const nums = raw.match(/\[([0-9.e+]+)\]/g);
    if (!nums || nums.length < 3) throw new Error('Could not parse APY from: ' + raw.slice(0, 100));
    
    const liquidityRate = parseFloat(nums[2].slice(1, -1)); // remove [ and ]
    const apy = liquidityRate / 1e25;
    return parseFloat(apy.toFixed(3));
  } catch(e) {
    console.error('APY read failed:', e.message);
    return null;
  }
}

async function main() {
  const apy = getAPY();
  const now = new Date().toISOString();
  
  if (apy === null) {
    // Fallback: try to read last known from state
    let state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    if (state.rebalanceTriggered) {
      state.rebalanceTriggered = null;
      fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
      console.log('[!] No fresh APY — cleared stale rebalanceTriggered');
    }
    return;
  }
  
  console.log(`[${now}] Aave V3 USDC APY: ${apy}%`);
  
  let state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  
  // Record reading
  state.readings.push({ apy, ts: now, source: 'rpc-foundry', protocol: 'aave-v3' });
  if (state.readings.length > 100) state.readings = state.readings.slice(-50);
  
  // Update check time
  state.lastCheck = { aave: apy, ts: now };
  state.lastUpdated = now;
  
  // Clear stale rebalanceTriggered if gap is old
  if (state.rebalanceTriggered) {
    const gapMs = Date.now() - new Date(state.lastCheck?.ts || 0).getTime();
    if (gapMs > 3600000) { // > 1 hour
      state.rebalanceTriggered = null;
      console.log('[!] Gap data > 1h old — cleared stale rebalanceTriggered');
    }
  }
  
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
  console.log(`[+] State updated. Readings: ${state.readings.length}, Rebalance: ${state.rebalanceTriggered ? 'YES' : 'NO'}`);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });
