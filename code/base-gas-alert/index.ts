/**
 * Base Gas Alert Service
 * Alerts when Base gas price drops below a threshold
 * Price: 0.02 USDC per alert check
 */

const GAS_API = 'https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=';

export async function handleGasAlert(params: { threshold: number; chain?: string }) {
  const threshold = params.threshold || 20; // default 20 gwei
  const chain = params.chain || 'base';
  
  // Get current gas (Base uses ETH gas oracle)
  const response = await fetch(`https://api.etherscan.io/api?module=gastracker&action=gasoracle&tag=latest&apikey=${process.env.ETHERSCAN_API_KEY || ''}`);
  const data = await response.json();
  
  if (data.status !== '1') {
    return { error: 'Failed to fetch gas data' };
  }
  
  const result = data.result;
  const currentGas = parseFloat(result.SafeGasPrice || result.ProposeGasPrice || '20');
  
  // Check if below threshold
  const isBelow = currentGas <= threshold;
  
  return {
    currentGas: currentGas + ' gwei',
    threshold: threshold + ' gwei',
    alert: isBelow,
    message: isBelow 
      ? `🔥 Gas is LOW: ${currentGas} gwei (threshold: ${threshold} gwei)`
      : `Gas is normal: ${currentGas} gwei (threshold: ${threshold} gwei)`,
    recommendation: isBelow ? 'GOOD_TIME_TO_SWAP' : 'WAIT'
  };
}

export const service = {
  name: 'base_gas_alert',
  description: 'Alert when Base gas drops below threshold',
  price: '0.02 USDC',
  inputs: {
    threshold: { type: 'number', description: 'Gas threshold in gwei', required: false },
    chain: { type: 'string', description: 'Chain (base/ethereum)', required: false }
  },
  handler: handleGasAlert
};

export default service;
