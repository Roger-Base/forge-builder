#!/usr/bin/env python3
"""
Roger Token Launcher
Simplified ERC-20 deployment on Base
No Pinecone, no complexity - just shipping
"""

import json
import os
from datetime import datetime

# Token Configuration
TOKEN_CONFIG = {
    "name": "Roger",
    "symbol": "ROGER",
    "decimals": 18,
    "initial_supply": 1000000,  # 1 million tokens
    "network": "base-mainnet",  # or base-sepolia for testing
    "owner": "0x984d6741e2c6559b1e655b6dbb3a38662fe2c123",
    "created": datetime.now().isoformat(),
    "version": "1.0.0"
}

# Simple ERC-20 Contract (Solidity)
CONTRACT_TEMPLATE = '''
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RogerToken is ERC20, Ownable {
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }
    
    // Allow owner to mint more (for growth)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    // Allow burning (for deflation if desired)
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
'''

def generate_deployment_script():
    """Generate deployment script for Hardhat/Foundry"""
    
    hardhat_script = '''
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    
    const RogerToken = await hre.ethers.getContractFactory("RogerToken");
    const token = await RogerToken.deploy(
        "Roger",
        "ROGER", 
        1000000  // 1M initial supply
    );
    
    await token.deployed();
    console.log("RogerToken deployed to:", token.address);
    console.log("View on Basescan:", `https://basescan.org/address/${token.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
'''
    
    return hardhat_script

def save_token_plan():
    """Save complete token launch plan"""
    
    plan = {
        "token": TOKEN_CONFIG,
        "contract": CONTRACT_TEMPLATE,
        "deployment": {
            "method": "Hardhat",
            "network": "base-mainnet",
            "estimated_gas": "0.002 ETH",
            "steps": [
                "1. Install Hardhat: npm init -y && npm install --save-dev hardhat",
                "2. Setup: npx hardhat init",
                "3. Install OpenZeppelin: npm install @openzeppelin/contracts",
                "4. Deploy: npx hardhat run deploy.js --network base-mainnet",
                "5. Verify: npx hardhat verify --network base-mainnet CONTRACT_ADDRESS"
            ]
        },
        "tokenomics": {
            "total_supply": "1,000,000 ROGER",
            "distribution": {
                "development": "40%",
                "community": "30%", 
                "liquidity": "20%",
                "team": "10%"
            },
            "use_case": "Governance + utility in Roger ecosystem"
        },
        "status": "planned",
        "next_step": "Get deployment funds (0.01 ETH on Base)"
    }
    
    # Save to file
    os.makedirs('token', exist_ok=True)
    with open('token/roger-token-plan.json', 'w') as f:
        json.dump(plan, f, indent=2)
    
    with open('token/RogerToken.sol', 'w') as f:
        f.write(CONTRACT_TEMPLATE)
    
    with open('token/deploy.js', 'w') as f:
        f.write(generate_deployment_script())
    
    return plan

if __name__ == '__main__':
    plan = save_token_plan()
    print("🟦 Roger Token Launch Plan Created")
    print(f"Token: {plan['token']['name']} ({plan['token']['symbol']})")
    print(f"Supply: {plan['token']['initial_supply']:,}")
    print(f"Network: {plan['token']['network']}")
    print("\nFiles created:")
    print("  - token/roger-token-plan.json")
    print("  - token/RogerToken.sol")
    print("  - token/deploy.js")
    print("\nNext: Get 0.01 ETH on Base for deployment")
