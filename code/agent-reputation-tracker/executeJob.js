#!/usr/bin/env node
/**
 * agent_reputation_tracker - Execute Job Handler
 * 
 * Tracks agent transaction history and calculates reputation scores.
 * 
 * Input: { agentAddress, action }
 * Output: { reputation, history, score }
 */

// In-memory store for demo (would be on-chain in production)
const reputationStore = new Map();

async function executeJob(requirements) {
  const { agentAddress, action = 'get_reputation' } = requirements;
  
  // Validate address
  if (!agentAddress || !agentAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
    return { success: false, error: 'Invalid agent address' };
  }
  
  try {
    if (action === 'get_reputation') {
      const stats = reputationStore.get(agentAddress) || {
        successful: 0,
        failed: 0,
        totalVolume: '0',
        transactions: []
      };
      
      const total = stats.successful + stats.failed;
      const successRate = total > 0 ? (stats.successful / total) * 100 : 0;
      
      // Calculate score (0-100)
      let score = 50; // Base score
      score += Math.min(successRate, 40); // Up to 40 points for success rate
      score += Math.min(stats.successful, 10); // Up to 10 points for volume
      
      return {
        success: true,
        agentAddress,
        score: Math.min(score, 100),
        stats: {
          successful: stats.successful,
          failed: stats.failed,
          totalTransactions: total,
          successRate: successRate.toFixed(2) + '%'
        },
        tier: score >= 80 ? 'trusted' : score >= 50 ? 'neutral' : 'risky',
        timestamp: new Date().toISOString()
      };
    }
    
    if (action === 'record_transaction') {
      const { success: txSuccess, volume = '0' } = requirements;
      const stats = reputationStore.get(agentAddress) || {
        successful: 0,
        failed: 0,
        totalVolume: '0',
        transactions: []
      };
      
      if (txSuccess) {
        stats.successful++;
      } else {
        stats.failed++;
      }
      
      stats.transactions.push({
        timestamp: Date.now(),
        success: txSuccess,
        volume
      });
      
      // Keep only last 100 transactions
      if (stats.transactions.length > 100) {
        stats.transactions = stats.transactions.slice(-100);
      }
      
      reputationStore.set(agentAddress, stats);
      
      return {
        success: true,
        message: 'Transaction recorded',
        agentAddress
      };
    }
    
    if (action === 'get_history') {
      const stats = reputationStore.get(agentAddress) || {
        transactions: []
      };
      
      return {
        success: true,
        agentAddress,
        history: stats.transactions
      };
    }
    
    return { success: false, error: 'Unknown action' };
    
  } catch (error) {
    return { success: false, error: error.message };
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
