#!/usr/bin/env node
/**
 * defai-yield-check.js
 * Roger DeFAI Yield Agent — Single Heartbeat Check
 * Queries Bankr for Aave V3 USDC Supply APY on Base.
 * Saves result to state/defai-yield-state.json for history tracking.
 * 
 * Runtime: ~45 seconds (Bankr API latency)
 * Run via: node defai-yield-check.js
 */

const { execSync } = require('child_process');
const fs = require('fs');

const STATE_FILE = '/Users/roger/.openclaw/workspace/state/defai-yield-state.json';

function log(msg) {
  const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
  console.log(`[${ts}] ${msg}`);
}

function bankrQuery(prompt) {
  try {
    const result = execSync(`bankr "${prompt}"`, {
      timeout: 90000,
      encoding: 'utf8',
      maxBuffer: 512 * 1024
    });
    return result.trim();
  } catch (e) {
    log(`Bankr error: ${e.message}`);
    return null;
  }
}

function parseAPY(text) {
  const match = text.match(/supply apy[:\s]+([0-9.]+)%/i) ||
                text.match(/([0-9.]+)\s*%/);
  return match ? parseFloat(match[1]) : null;
}

function loadState() {
  try {
    if (fs.existsSync(STATE_FILE)) {
      return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    }
  } catch (e) {}
  return { readings: [], lastAPY: null };
}

function saveState(state) {
  const dir = require('path').dirname(STATE_FILE);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

async function main() {
  log('DeFAI Yield Check — querying Aave V3 USDC on Base');
  
  const response = bankrQuery('what is the current USDC supply APY on Aave V3 Base?');
  if (!response) {
    log('FAIL: Bankr returned no data');
    process.exit(1);
  }
  
  log('Raw response: ' + response.slice(0, 200));
  
  const apy = parseAPY(response);
  if (!apy) {
    log('FAIL: Could not parse APY from response');
    process.exit(1);
  }
  
  log(`✅ USDC Supply APY: ${apy}%`);
  
  const state = loadState();
  const now = new Date().toISOString();
  
  if (state.lastAPY) {
    const delta = (apy - state.lastAPY).toFixed(3);
    const absDelta = Math.abs(delta);
    log(`APY delta since last reading: ${delta >= 0 ? '+' : ''}${delta}% (${absDelta} bps)`);
    
    if (absDelta >= 0.15) {
      log(`⚠️  Significant change detected — monitor for rebalancing opportunity`);
    }
  } else {
    log('First reading — baseline established');
  }
  
  state.lastAPY = apy;
  state.lastTimestamp = now;
  state.readings.push({ apy, ts: now });
  if (state.readings.length > 168) state.readings = state.readings.slice(-168); // 1 week at hourly
  
  saveState(state);
  log(`State saved. Total readings: ${state.readings.length}`);
}

main().catch(e => {
  log(`Fatal: ${e.message}`);
  process.exit(1);
});
