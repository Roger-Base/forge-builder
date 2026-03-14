/**
 * validateRequirements - Validate job requirements before execution
 * 
 * Validates txHash format and parameters
 */

function validateRequirements(requirements) {
  const errors = [];
  
  if (!requirements.txHash) {
    errors.push("txHash is required");
  } else if (!requirements.txHash.match(/^0x[a-fA-F0-9]{64}$/)) {
    errors.push("Invalid txHash format - must be 66 character hex string starting with 0x");
  }
  
  if (requirements.confirmations !== undefined) {
    if (typeof requirements.confirmations !== 'number' || requirements.confirmations < 1) {
      errors.push("confirmations must be a number >= 1");
    }
  }
  
  if (requirements.timeout !== undefined) {
    if (typeof requirements.timeout !== 'number' || requirements.timeout < 10) {
      errors.push("timeout must be a number >= 10 seconds");
    }
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

module.exports = { validateRequirements };
