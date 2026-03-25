#!/usr/bin/env node
/**
 * defai-yield-monitor.js
 * Roger DeFAI Yield Agent — APY Monitoring
 * 
 * Queries Bankr for Aave V3 + Morpho USDC APY on Base.
 * Tracks APY history and alerts on significant changes.
 * 
 * Runtime: ~60-90 seconds (Bankr is slow but reliable)
 * Run: node defai-yield-monitor.js
 */

const { execSync } = require('child_process');
const fs = require('fs');

const STATE_FILE = '/Users/roger/.openclaw/workspace/state/defai-yield-state.json';
const LOG_FILE   = '/Users/roger/.openclaw/workspace/state/defai-yield-monitor.log';
const GAP_THRESHOLD = 0.5; // % APY gap to trigger rebalance alert

function log(msg) {
  const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
  const line = `[${ts}] ${msg}`;
  console.log(line);
  fs.appendFileSync(LOG_FILE, line + '\n');
}

function bankrQuery(prompt, timeout = 90000) {
  try {
    const r = execSync(`bankr "${prompt}"`, {
      timeout,
      encoding: 'utf8',
      maxBuffer: 512 * 1024,
      env: { ...process.env }
    });
    return r.trim();
  } catch (e) {
    return null;
  }
}

function parseAPY(text, label) {
  if (!text) return null;
  // Look for patterns like "supply apy: 2.33%" or "net apy: 3.70%"
  const patterns = [
    /supply apy[:\s]+([0-9.]+)%/i,
    /net apy[:\s]+([0-9.]+)%/i,
    /apy[:\s]+([0-9.]+)%/i,
    /([0-9.]+)\s*%/
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) {
      log(`${label}: ${m[1]}% (matched: ${p})`);
      return parseFloat(m[1]);
    }
  }
  log(`WARNING: Could not parse APY from: ${text.slice(0, 100)}`);
  return null;
}

function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch(e) {}
  return { readings: [], lastAPY: null, lastMorphoAPY: null, alerts: [], lastTimestamp: null };
}

function saveState(state) {
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function main() {
  log('=== DeFAI Yield Monitor ===');
  
  // Query Aave V3
  log('Querying Aave V3 USDC APY...');
  const aaveRaw = bankrQuery('what is the current USDC supply APY on Aave V3 Base?');
  const aaveAPY = parseAPY(aaveRaw, 'Aave V3 USDC');
  
  // Small delay between queries
  await new Promise(r => setTimeout(r, 2000));
  
  // Query Morpho
  log('Querying Morpho USDC APY...');
  const morphoRaw = bankrQuery('current USDC supply APY on Morpho Base Steakhouse vault?');
  const morphoAPY = parseAPY(morphoRaw, 'Morpho USDC');
  
  if (!aaveAPY) {
    log('ERROR: Could not get Aave APY');
    return;
  }
  
  log(`Result: Aave=${aaveAPY}% Morpho=${morphoAPY ? morphoAPY + '%' : 'unknown'}`);
  
  // Load state
  const state = loadState();
  const now = new Date().toISOString();
  
  // Record Aave reading
  state.readings.push({ apy: aaveAPY, ts: now, source: 'bankr', protocol: 'aave-v3' });
  if (state.readings.length > 168) state.readings = state.readings.slice(-168);
  
  // Check APY change
  if (state.lastAPY) {
    const delta = aaveAPY - state.lastAPY;
    const absDelta = Math.abs(delta);
    log(`APY delta: ${delta >= 0 ? '+' : ''}${delta.toFixed(3)}%`);
    if (absDelta > 0.1) {
      const alert = `Aave USDC APY ${delta > 0 ? 'UP' : 'DOWN'} ${absDelta.toFixed(2)}%: ${aaveAPY}%`;
      state.alerts.push({ alert, ts: now });
      if (state.alerts.length > 50) state.alerts = state.alerts.slice(-50);
      log(`⚠️  ${alert}`);
    }
  }
  
  state.lastAPY = aaveAPY;
  state.lastTimestamp = now;
  
  // Record Morpho if available
  if (morphoAPY) {
    state.lastMorphoAPY = morphoAPY;
    const gap = morphoAPY - aaveAPY;
    log(`Gap: ${gap >= 0 ? '+' : ''}${gap.toFixed(2)}% (Morpho over Aave)`);
    if (gap > GAP_THRESHOLD) {
      const alert = `Rebalance: Morpho ${morphoAPY}% vs Aave ${aaveAPY}% (+${gap.toFixed(2)}% gap)`;
      log(`⚠️  ${alert}`);
      state.alerts.push({ alert, ts: now });
      
      // Check if we already executed this rebalance today
      const today = now.slice(0, 10);
      const lastRebalance = state.lastRebalance ? state.lastRebalance.slice(0, 10) : null;
      if (lastRebalance !== today) {
        log(`🎯  EXECUTION: Rebalance triggered (gap ${gap.toFixed(2)}% > ${GAP_THRESHOLD}%)`);
        log(`Executing: bankr "swap all my USDC from Aave V3 to Morpho Steakhouse on Base"`);
        state.rebalanceTriggered = { gap, aaveAPY, morphoAPY, ts: now };
        // Execution happens via Bankr CLI (human confirms or auto on Sepolia)
        // TODO: Auto-execute on Sepolia testnet when ETH unblocked
      } else {
        log(`ℹ️  Already rebalanced today (${lastRebalance}) — skipping duplicate execution`);
      }
    }
  }
  
  state.lastRebalance = state.rebalanceTriggered ? now : state.lastRebalance || null;
  saveState(state);
  log(`Saved. Readings: ${state.readings.length}, Alerts: ${state.alerts.length}, Rebalance: ${state.lastRebalance ? 'YES' : 'NO'}`);
}

main().catch(e => {
  log('Fatal: ' + e.message);
  process.exit(1);
});
