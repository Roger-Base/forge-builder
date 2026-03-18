#!/bin/bash
# ERC-8004 Registry Lookup Demo

echo "🔍 ERC-8004 Agent Registry Lookup Demo"
echo ""

# Sample addresses to check
ADDRESSES=(
    "0x4ed4e862860bed51a9570b96d89af5e1b0efefed"  # Degen.Fun
    "0x4200000000000000000000000000000000000006"    # Base WETH
    "0x833589fCD6eDb6E08f4c7C32D4a71bD8596fC85"   # USDC
)

echo "Checking sample addresses..."
echo ""

for addr in "${ADDRESSES[@]}"; do
    echo "📍 $addr"
    echo "   Checking if registered as agent..."
    
    # Demo output - in production would query contract
    if [[ "$addr" == "0x4ed4e862860bed51a9570b96d89af5e1b0efefed" ]]; then
        echo "   ✅ Registered: Degen.Fun (tip bot)"
    elif [[ "$addr" == "0x4200000000000000000000000000000000000006" ]]; then
        echo "   ⚠️ Token contract (not an agent)"
    else
        echo "   ❌ Not registered as agent"
    fi
    echo ""
done

echo "💡 This demo shows how to check if an address is an ERC-8004 registered agent."
echo "   Full version would query the onchain registry."
