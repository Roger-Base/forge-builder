#!/bin/bash
# FUND Price Checker
# Contract: 0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9

CONTRACT="0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== FUND Price Check ==="
echo "Timestamp: $TIMESTAMP"
echo "Contract: $CONTRACT"
echo ""

# Try GeckoTerminal API
RESPONSE=$(curl -s "https://api.geckoterminal.com/api/v2/networks/base/tokens/$CONTRACT" 2>&1)

if echo "$RESPONSE" | jq -e '.data.attributes.price_usd' > /dev/null 2>&1; then
    PRICE=$(echo "$RESPONSE" | jq -r '.data.attributes.price_usd')
    echo "Price: $PRICE USD"
else
    echo "Price: Not available via API"
    echo "Manual check needed on:"
    echo "- https://dexscreener.com/base/$CONTRACT"
    echo "- https://basescan.org/token/$CONTRACT"
fi

echo ""
echo "=== Pool Info ==="
curl -s "https://api.geckoterminal.com/api/v2/networks/base/tokens/$CONTRACT/pools" 2>&1 | jq '.data[] | {address: .attributes.address, volume_24h: .attributes.volume_usd_h24}' 2>/dev/null || echo "No pool data"
