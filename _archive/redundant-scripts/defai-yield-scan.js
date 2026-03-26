#!/usr/bin/env node
/**
 * defai-yield-scan.js
 * Roger DeFAI Yield Agent — Base Aave V3 Monitor
 * 
 * Queries Bankr for real Aave V3 USDC rates on Base.
 * Compares with previous scan.
 * If APY differential > threshold, recommends rebalancing.
 * 
 * Usage: node defai-yield-scan.js
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const STATE_FILE = '/Users/roger/.openclaw/workspace/state/defai-yield-state.json';
const THRESHOLD_BPS = 15; // 15 basis points = 0.15% APY difference triggers alert

function log(msg) {
  console.log(`[${new Date().toISOString()}] ${msg}`);
}

function bankrQuery(prompt) {
  try {
    const result = execSync(`bankr "${prompt}"`, {
      timeout: 60000,
      encoding: 'utf8',
      maxBuffer: 1024 * 1024
    });
    return result.trim();
  } catch (e) {
    return null;
  }
}

function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch (e) {}
  return { lastAPY: null, lastTimestamp: null, history: [] };
}

function saveState(state) {
  const dir = path.dirname(STATE_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function main() {
  log('Starting DeFAI Yield Scan — Aave V3 USDC on Base');
  
  // Query current rates
  const supplyData = bankrQuery('what is the current supply APY for USDC on Aave V3 Base?');
  const borrowData = bankrQuery('what is the current variable borrow APR for USDC on Aave V3 Base?');
  
  if (!supplyData) {
    log('ERROR: Could not get supply APY from Bankr');
    process.exit(1);
  }
  
  // Parse supply APY
  const supplyMatch = supplyData.match(/supply apy[:\s]+([0-9.]+)%/i) ||
                      supplyData.match(/([0-9.]+)%/);
  const currentSupplyAPY = supplyMatch ? parseFloat(supplyMatch[1]) : null;
  
  // Parse borrow APR
  let currentBorrowAPR = null;
  if (borrowData) {
    const borrowMatch = borrowData.match(/variable borrow apr[:\s]+([0-9.]+)%/i) ||
                        borrowData.match(/borrow.*?([0-9.]+)%/i);
    if (borrowMatch) currentBorrowAPR = parseFloat(borrowMatch[1]);
  }
  
  if (!currentSupplyAPY) {
    log('ERROR: Could not parse supply APY from response');
    log('Raw:', supplyData);
    process.exit(1);
  }
  
  log(`Current Aave V3 USDC Supply APY: ${currentSupplyAPY}%`);
  if (currentBorrowAPR) log(`Current Aave V3 USDC Borrow APR: ${currentBorrowAPR}%`);
  
  // Load state and compare
  const state = loadState();
  const now = new Date().toISOString();
  
  if (state.lastAPY) {
    const delta = (currentSupplyAPY - state.lastAPY) * 100; // in basis points
    log(`APY change since last scan: ${delta >= 0 ? '+' : ''}${delta.toFixed(2)} bps`);
    
    if (Math.abs(delta) >= THRESHOLD_BPS) {
      log(`⚠️  ALERT: APY moved ${Math.abs(delta).toFixed(2)} bps (threshold: ${THRESHOLD_BPS} bps)`);
      log(`Action: Consider rebalancing supply between protocols`);
      
      // Suggest swap decision
      if (currentSupplyAPY < state.lastAPY && delta < -THRESHOLD_BPS) {
        log(`⚠️  APY DROPPED — Consider moving USDC to higher-yield protocol`);
      } else if (currentSupplyAPY > state.lastAPY && delta > THRESHOLD_BPS) {
        log(`✅ APY INCREASED — Current allocation may be suboptimal, consider increasing USDC supply`);
      }
    } else {
      log(`No rebalancing needed (${Math.abs(delta).toFixed(2)} bps < ${THRESHOLD_BPS} bps threshold)`);
    }
  } else {
    log('First scan — no comparison available. This run establishes baseline.');
  }
  
  // Update state
  state.lastAPY = currentSupplyAPY;
  state.lastBorrowAPR = currentBorrowAPR;
  state.lastTimestamp = now;
  state.history.push({ apy: currentSupplyAPY, borrow: currentBorrowAPR, ts: now });
  
  // Keep only last 100 entries
  if (state.history.length > 100) {
    state.history = state.history.slice(-100);
  }
  
  saveState(state);
  log(`State saved to ${STATE_FILE}`);
  log(`Next scan recommended in 1 hour (via cron or heartbeat)`);
}

main().catch(e => {
  log(`Fatal error: ${e.message}`);
  process.exit(1);
});
