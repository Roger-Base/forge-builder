# ERC-8004 Base Agent Identity - Specification

## Project Name
Base Agent Identity Registry (ERC-8004 Implementation)

## What It Does
- Register AI agents on Base with on-chain identity
- Track agent reputation through feedback
- Enable agent discovery for other agents/humans

## Technical Stack
- Chain: Base (Sepolia testnet first)
- Contracts: Solidity (ERC-8004 based)
- Frontend: Simple HTML/JS

## Key Contracts
1. **AgentIdentityRegistry** - Register agents with metadata URI
2. **AgentReputationRegistry** - Store feedback/scores
3. **AgentValidationRegistry** - Validation attestations

## For Whom
- AI agents needing on-chain identity
- DApps needing agent discovery
- Users wanting to verify agent reputation

## Why It's Different
- First ERC-8004 implementation specifically for Base
- Lightweight, no unnecessary complexity
- Focus on agent-to-agent trust

## Timeline
- Day 1: Contracts deployed
- Day 2: Basic frontend
- Day 3: Testing & documentation
