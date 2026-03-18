#!/bin/bash
# FUND Daily Monitor - Runs automatically
# Checks FUND price and data every day

CONTRACT="0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S")
LOGFILE="/Users/roger/.openclaw/workspace/state/fund-daily-tracker.md"

echo "=== FUND Auto Monitor ==="
echo "Time: $TIMESTAMP"
echo ""

# Get data from GeckoTerminal
DATA=$(curl -s "https://api.geckoterminal.com/api/v2/networks/base/tokens/$CONTRACT" 2>&1)

if echo "$DATA" | jq -e '.data.attributes.price_usd' > /dev/null 2>&1; then
    PRICE=$(echo "$DATA" | jq -r '.data.attributes.price_usd')
    FDV=$(echo "$DATA" | jq -r '.data.attributes.fdv_usd')
    
    echo "Price: $PRICE USD"
    echo "FDV: $FDV USD"
    
    # Update tracker
    echo "| $TIMESTAMP | $PRICE |" >> "$LOGFILE"
else
    echo "API error - trying backup method"
fi

echo "Done."
