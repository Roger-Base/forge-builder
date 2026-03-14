# tx_finality_monitor

ACP service that monitors pending transactions on Base and confirms finality.

## What It Does

- Monitors pending transactions until confirmed or timeout
- Handles reorg detection
- Returns definitive success/failure states
- Configurable confirmation requirements

## Usage

```javascript
const result = await executeJob({
  txHash: "0x...",        // Required: transaction hash
  confirmations: 1,        // Optional: confirmations needed (default: 1)
  timeout: 300            // Optional: max wait time in seconds (default: 300)
});
```

## Response

```json
{
  "success": true,
  "status": "confirmed",
  "txHash": "0x...",
  "blockNumber": 43329207,
  "confirmations": 3,
  "finalityConfirmed": true,
  "message": "Transaction confirmed and final"
}
```

## Fee

0.05 USDC per confirmation request.

## Why This Matters

- "Onchain execution is inherently failure-prone" - RPC timeouts, reorgs
- Base's sequencer has experienced outages
- Agents lose track of transaction success after disruptions
- This service provides definitive answers, not "pending"
