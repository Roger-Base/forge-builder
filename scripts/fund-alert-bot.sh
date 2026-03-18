#!/bin/bash
# FUND Alert Bot - Sends Telegram alerts on price changes
# Run this every hour

CONTRACT="0xa02d9a9a5f5453463aa4855f62e47d9cc27086d9"
TELEGRAM_CHAT_ID="CHAT_ID_HERE"  # Set this
API_KEY="YOUR_API_KEY"  # Set this
PRICE_FILE="/Users/roger/.openclaw/workspace/state/fund-last-price.txt"
ALERT_THRESHOLD=0.05  # 5%

# Get current price
PRICE=$(curl -s "https://api.geckoterminal.com/api/v2/networks/base/tokens/$CONTRACT" | jq -r '.data.attributes.price_usd')

if [ -z "$PRICE" ] || [ "$PRICE" = "null" ]; then
    echo "No price data"
    exit 1
fi

# Check last price
if [ -f "$PRICE_FILE" ]; then
    LAST_PRICE=$(cat "$PRICE_FILE")
    
    # Calculate change
    CHANGE=$(python3 -c "print(abs(($PRICE - $LAST_PRICE) / $LAST_PRICE * 100))")
    
    # Send alert if significant change
    if (( $(echo "$CHANGE > $ALERT_THRESHOLD" | bc -l) )); then
        MESSAGE="FUND Alert! Price changed $CHANGE% in the last hour. New price: $PRICE"
        # Send telegram (uncomment when ready)
        # curl -s -X POST "https://api.telegram.org/bot$API_KEY/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$MESSAGE"
        echo "ALERT: $MESSAGE"
    fi
fi

# Save current price
echo "$PRICE" > "$PRICE_FILE"
echo "Price saved: $PRICE"
