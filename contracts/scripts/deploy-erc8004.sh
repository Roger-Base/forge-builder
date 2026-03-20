#!/bin/bash
# ERC-8004 Deployment Script
# Deploy Identity, Reputation, and Validation registries to Base Sepolia

set -e

# Configuration
RPC_URL="https://sepolia.base.org"
CHAIN_ID=84532
EXPLORER_URL="https://sepolia.basescan.org"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required environment variables
check_env() {
    if [ -z "$DEPLOYER_KEY" ]; then
        echo -e "${RED}Error: DEPLOYER_KEY not set${NC}"
        echo "Please set your deployer private key:"
        echo "  export DEPLOYER_KEY=your_private_key"
        exit 1
    fi
    
    if [ -z "$RPC_URL" ]; then
        echo -e "${RED}Error: RPC_URL not set${NC}"
        exit 1
    fi
}

# Deploy contract
deploy_contract() {
    local contract_name=$1
    local constructor_args=$2
    
    echo -e "${YELLOW}Deploying $contract_name...${NC}"
    
    # Deploy using forge
    forge create \
        --rpc-url "$RPC_URL" \
        --private-key "$DEPLOYER_KEY" \
        --chain-id $CHAIN_ID \
        --broadcast \
        --verify \
        --etherscan-api-key "$ETHERSCAN_API_KEY" \
        $contract_name \
        $constructor_args
    
    echo -e "${GREEN}$contract_name deployed successfully${NC}"
}

# Main deployment
main() {
    echo -e "${YELLOW}=== ERC-8004 Suite Deployment ===${NC}"
    echo ""
    
    check_env
    
    echo "Network: Base Sepolia ($CHAIN_ID)"
    echo "RPC: $RPC_URL"
    echo "Deployer: $(cast wallet address --private-key $DEPLOYER_KEY)"
    echo ""
    
    # 1. Deploy Identity Registry
    echo -e "${YELLOW}Step 1: Deploy IdentityRegistry${NC}"
    IDENTITY_ADDR=$(forge create \
        --rpc-url "$RPC_URL" \
        --private-key "$DEPLOYER_KEY" \
        --chain-id $CHAIN_ID \
        --broadcast \
        --json \
        src/IdentityRegistry.sol:IdentityRegistry \
        "AgentRegistry" "AGENT" "eip155" | jq -r '.deployedTo')
    
    echo -e "${GREEN}IdentityRegistry deployed to: $IDENTITY_ADDR${NC}"
    echo ""
    
    # 2. Deploy Reputation Registry
    echo -e "${YELLOW}Step 2: Deploy ReputationRegistry${NC}"
    REPUTATION_ADDR=$(forge create \
        --rpc-url "$RPC_URL" \
        --private-key "$DEPLOYER_KEY" \
        --chain-id $CHAIN_ID \
        --broadcast \
        --json \
        src/ReputationRegistry.sol:ReputationRegistry \
        $IDENTITY_ADDR $(cast wallet address --private-key $DEPLOYER_KEY) | jq -r '.deployedTo')
    
    echo -e "${GREEN}ReputationRegistry deployed to: $REPUTATION_ADDR${NC}"
    echo ""
    
    # 3. Deploy Validation Registry
    echo -e "${YELLOW}Step 3: Deploy ValidationRegistry${NC}"
    VALIDATION_ADDR=$(forge create \
        --rpc-url "$RPC_URL" \
        --private-key "$DEPLOYER_KEY" \
        --chain-id $CHAIN_ID \
        --broadcast \
        --json \
        src/ValidationRegistry.sol:ValidationRegistry \
        $IDENTITY_ADDR $(cast wallet address --private-key $DEPLOYER_KEY) | jq -r '.deployedTo')
    
    echo -e "${GREEN}ValidationRegistry deployed to: $VALIDATION_ADDR${NC}"
    echo ""
    
    # 4. Verify contracts
    echo -e "${YELLOW}Step 4: Verify contracts${NC}"
    forge verify-contract \
        --chain-id $CHAIN_ID \
        --num-of-optimizations 200 \
        --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
        --constructor-args $(cast abi-encode "constructor(string,string,string)" "AgentRegistry" "AGENT" "eip155") \
        $IDENTITY_ADDR \
        src/IdentityRegistry.sol:IdentityRegistry
    
    forge verify-contract \
        --chain-id $CHAIN_ID \
        --num-of-optimizations 200 \
        --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
        --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY_ADDR $(cast wallet address --private-key $DEPLOYER_KEY)) \
        $REPUTATION_ADDR \
        src/ReputationRegistry.sol:ReputationRegistry
    
    forge verify-contract \
        --chain-id $CHAIN_ID \
        --num-of-optimizations 200 \
        --compiler-version $(forge --version | grep -oE 'solc[0-9.]+' | head -1) \
        --constructor-args $(cast abi-encode "constructor(address,address)" $IDENTITY_ADDR $(cast wallet address --private-key $DEPLOYER_KEY)) \
        $VALIDATION_ADDR \
        src/ValidationRegistry.sol:ValidationRegistry
    
    echo -e "${GREEN}All contracts verified${NC}"
    echo ""
    
    # 5. Summary
    echo -e "${YELLOW}=== Deployment Summary ===${NC}"
    echo "Identity Registry:    $IDENTITY_ADDR"
    echo "Reputation Registry:  $REPUTATION_ADDR"
    echo "Validation Registry:  $VALIDATION_ADDR"
    echo ""
    echo "Explorer: $EXPLORER_URL"
    echo ""
    echo -e "${GREEN}Deployment complete!${NC}"
}

# Run main function
main
