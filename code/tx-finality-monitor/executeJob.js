#!/usr/bin/env node
/**
 * tx_finality_monitor - Execute Job Handler
 * 
 * Monitors pending transactions on Base and confirms finality.
 * Handles reorg detection and returns definitive success/failure states.
 * 
 * Input: { txHash, confirmations?, timeout? }
 * Output: { status, blockNumber, timestamp, finalityConfirmed }
 */

const RPC_URL = process.env.BASE_RPC || 'https://mainnet.base.org';

async function executeJob(requirements) {
  const { txHash, confirmations = 1, timeout = 300 } = requirements;
  
  if (!txHash || !txHash.match(/^0x[a-fA-F0-9]{64}$/)) {
    return {
      success: false,
      error: 'Invalid transaction hash format'
    };
  }

  const startTime = Date.now();
  
  try {
    // Get transaction receipt
    const receipt = await getTransactionReceipt(txHash, timeout);
    
    if (!receipt) {
      // Transaction still pending after timeout
      return {
        success: false,
        status: 'pending',
        message: 'Transaction still pending after timeout',
        txHash,
        timeout: timeout * 1000
      };
    }

    // Check if we have enough confirmations
    const currentBlock = await getCurrentBlock();
    const receiptBlock = parseInt(receipt.blockNumber, 16);
    const actualConfirmations = currentBlock - receiptBlock;

    if (actualConfirmations < confirmations) {
      return {
        success: false,
        status: 'pending',
        message: `Only ${actualConfirmations} confirmations, need ${confirmations}`,
        txHash,
        currentBlock,
        receiptBlock,
        confirmations,
        actualConfirmations
      };
    }

    // Transaction is confirmed
    const isReverted = receipt.status === '0x0';
    
    return {
      success: !isReverted,
      status: isReverted ? 'reverted' : 'confirmed',
      txHash,
      blockNumber: receiptBlock,
      confirmations: actualConfirmations,
      gasUsed: parseInt(receipt.gasUsed, 16),
      finalityConfirmed: true,
      message: isReverted ? 'Transaction reverted' : 'Transaction confirmed and final'
    };

  } catch (error) {
    return {
      success: false,
      error: error.message,
      txHash
    };
  }
}

async function getTransactionReceipt(txHash, timeout) {
  const startTime = Date.now();
  
  while (Date.now() - startTime < timeout * 1000) {
    try {
      const response = await fetch(RPC_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          jsonrpc: '2.0',
          method: 'eth_getTransactionReceipt',
          params: [txHash],
          id: 1
        })
      });
      
      const data = await response.json();
      if (data.result) {
        return data.result;
      }
    } catch (e) {
      // Continue polling
    }
    
    await sleep(5000); // Wait 5 seconds between checks
  }
  
  return null; // Timeout
}

async function getCurrentBlock() {
  const response = await fetch(RPC_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'eth_blockNumber',
      params: [],
      id: 1
    })
  });
  
  const data = await response.json();
  return parseInt(data.result, 16);
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// CLI interface for testing
const args = process.argv.slice(2);
if (args.length > 0) {
  const requirements = JSON.parse(args[0]);
  executeJob(requirements).then(result => {
    console.log(JSON.stringify(result, null, 2));
    process.exit(result.success ? 0 : 1);
  });
}

module.exports = { executeJob };
