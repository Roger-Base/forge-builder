#!/usr/bin/env node
/**
 * Base Gas Alert - Check gas and notify when below threshold
 * Run: node code/base-gas-alert/check.js
 */

const FETCH = globalThis.fetch || ((...args) => import('node-fetch').then(m => m.default(...args)));

const BASESCAN_API = process.env.BASESCAN_API_KEY || '';
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID || '';

const THRESHOLD_GWEI = parseFloat(process.env.GAS_THRESHOLD || '0.5'); // Base is very cheap, default 0.5 gwei

async function getBaseGas() {
  try {
    // Fetch from BaseScan gas tracker
    const url = 'https://basescan.org/gastracker';
    const response = await FETCH(url);
    const html = await response.text();
    
    // Parse gas values from HTML - look for pattern like "0.005 Gwei"
    const gasMatches = html.match(/([0-9.]+)\s*Gwei/g);
    
    if (gasMatches && gasMatches.length > 0) {
      // Remove "Gwei" and get the number
      const gas = parseFloat(gasMatches[0]);
      
      return {
        slow: gas.toString(),
        normal: gas.toString(),
        fast: gas.toString(),
        source: 'BaseScan'
      };
    }
  } catch (e) {
    console.error('BaseScan error:', e.message);
  }
  
  // Fallback: typical Base gas
  return {
    slow: '0.01',
    normal: '0.05', 
    fast: '0.1',
    note: 'Estimated - API unavailable'
  };
}

async function sendAlert(message) {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) {
    console.log('No Telegram config, logging only:', message);
    return;
  }
  
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  await FETCH(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: TELEGRAM_CHAT_ID,
      text: message,
      parse_mode: 'HTML'
    })
  });
}

async function main() {
  console.log('🔍 Checking Base gas...');
  
  const gas = await getBaseGas();
  if (!gas) {
    console.log('❌ Failed to get gas data');
    process.exit(1);
  }
  
  const normalGas = parseFloat(gas.normal);
  console.log(`📊 Current gas: Slow=${gas.slow}, Normal=${gas.normal}, Fast=${gas.fast} gwei`);
  
  if (normalGas <= THRESHOLD_GWEI) {
    const message = `🔥 <b>GAS ALERT!</b>\n\n` +
      `Current gas: <b>${normalGas} gwei</b>\n` +
      `Threshold: ${THRESHOLD_GWEI} gwei\n\n` +
      `✅ Good time to swap/execute!`;
    
    console.log('✅ Alert triggered!');
    await sendAlert(message);
  } else {
    console.log(`⏳ Gas is normal (${normalGas} gwei), no alert.`);
  }
}

main().catch(console.error);
