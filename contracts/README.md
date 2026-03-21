# ERC-8004 Agent Registry Suite

**Standard:** ERC-8004 (Trustless Agents)  
**Network:** Base (Sepolia testnet → Mainnet)  
**Version:** 1.0.0  
**License:** MIT  

---

## Overview

ERC-8004 is an Ethereum standard for AI agent identity, reputation, and validation on-chain. This implementation provides a complete modular suite:

1. **IdentityRegistry** - Agent registration with ERC-721 tokens
2. **ReputationRegistry** - Feedback and reputation scoring
3. **ValidationRegistry** - Work verification (zkML, TEE, stake-secured)

---

## Architecture

```
┌─────────────────────────────────────────┐
│   Agent Identity (ERC-721 + ERC-8004)   │
│   IdentityRegistry.sol                  │
│   - register()                          │
│   - setAgentWallet()                    │
│   - multi-chain registrations           │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────────────┐       ┌───────────────┐
│  Reputation   │       │  Validation   │
│  Registry     │       │  Registry     │
│  - feedback   │       │  - zkML       │
│  - 24h cooldown│       │  - TEE        │
│  - stake-weight│       │  - stake      │
└───────────────┘       └───────────────┘
```

---

## Smart Contracts

### IdentityRegistry.sol

**Size:** 13,612 bytes  
**Functions:** 15  
**Events:** 6  

**Core Features:**
- ERC-721 + ERC721URIStorage for agent NFTs
- EIP-712 signature verification for agent wallet setting
- Multi-chain registration support
- Metadata storage (custom key-value pairs)
- ERC-8004 compliant agentRegistry format

**Key Functions:**
```solidity
function register(string memory agentURI) external returns (uint256 agentId)
function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external
function addRegistration(uint256 agentId, string calldata agentRegistry) external
function setMetadata(uint256 agentId, string memory metadataKey, bytes memory metadataValue) external
function buildAgentRegistry() external view returns (string memory)
```

### ReputationRegistry.sol

**Size:** 6,824 bytes  
**Functions:** 12  
**Events:** 3  

**Core Features:**
- Feedback submission (int128 fixed-point value)
- 24h cooldown per agent (Sybil resistance)
- Owner cannot review own agent
- Stake-weighted reputation scoring
- Feedback revocation
- Response appending

**Key Functions:**
```solidity
function giveFeedback(uint256 agentId, int128 value, string calldata tag1) external
function revokeFeedback(uint256 agentId, uint256 idx) external
function getSummary(uint256 agentId, address[] calldata clients) external view returns (uint256, int128)
function setReviewerStake(address reviewer, uint256 stake) external
```

### ValidationRegistry.sol

**Size:** 9,493 bytes  
**Functions:** 10  
**Events:** 2  

**Core Features:**
- Validation requests from validators
- Validation responses (0-100 scale)
- zkML, TEE, stake-secured verification support
- Validation status tracking
- Agent validation history

**Key Functions:**
```solidity
function validationRequest(address validator, uint256 agentId, string calldata requestURI, bytes32 requestHash) external
function validationResponse(bytes32 requestHash, uint8 response, string calldata responseURI, bytes32 responseHash, string calldata tag) external
function getValidationStatus(bytes32 requestHash) external view returns (address, uint256, uint8, bytes32, string memory, uint256)
```

---

## Installation

### Prerequisites

- Node.js 18+
- Foundry (forge, cast)
- MetaMask (for deployment)

### Setup

```bash
# Clone repository
git clone https://github.com/Roger-Base/forge-builder.git
cd forge-builder/contracts

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Build contracts
forge build

# Run tests
forge test
```

---

## Deployment

### Base Sepolia Testnet

```bash
# Set environment variables
export DEPLOYER_KEY=<your_private_key>
export ETHERSCAN_API_KEY=<your_api_key>
export RPC_URL=https://sepolia.base.org

# Deploy IdentityRegistry
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY src/IdentityRegistry.sol:IdentityRegistry \
  --constructor-args "AgentRegistry" "AGENT" "eip155"

# Deploy ReputationRegistry (requires IdentityRegistry address)
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY src/ReputationRegistry.sol:ReputationRegistry \
  --constructor-args <IdentityRegistry_Address> <deployer_address>

# Deploy ValidationRegistry (requires IdentityRegistry address)
forge create --rpc-url $RPC_URL --private-key $DEPLOYER_KEY src/ValidationRegistry.sol:ValidationRegistry \
  --constructor-args <IdentityRegistry_Address> <deployer_address>

# Verify contracts
forge verify-contract --chain-id 84532 <contract_address> src/IdentityRegistry.sol:IdentityRegistry
```

### Mainnet (After Testnet Validation)

```bash
# Update RPC to mainnet
export RPC_URL=https://mainnet.base.org
export CHAIN_ID=8453

# Deploy (same commands as testnet)
```

---

## Usage

### Register an Agent

```solidity
// Register agent with metadata URI
string memory agentURI = "ipfs://QmYourAgentMetadata";
uint256 agentId = identityRegistry.register(agentURI);
```

### Submit Feedback

```solidity
// Give feedback (1 per 24h per agent)
int128 value = 80; // Rating value
string memory tag1 = "quality";
repRegistry.giveFeedback(agentId, value, tag1);
```

### Request Validation

```solidity
// Request validation from validator
address validator = 0xValidatorContract;
string memory requestURI = "ipfs://QmValidationData";
bytes32 requestHash = keccak256(abi.encodePacked(requestURI));
valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
```

---

## Testing

### Run All Tests

```bash
forge test
```

### Run Specific Test Suite

```bash
# IdentityRegistry tests
forge test --match-path test/IdentityRegistry.t.sol

# ReputationRegistry tests
forge test --match-path test/ReputationRegistry.t.sol

# ValidationRegistry tests
forge test --match-path test/ValidationRegistry.t.sol
```

### Test Coverage

```bash
forge coverage
```

### Gas Reports

```bash
forge test --gas-report
```

---

## Security Considerations

### Sybil Resistance

- **24h cooldown** - 1 review per agent per 24 hours
- **Owner cannot review** - Agent owners cannot review their own agents
- **Stake-weighted scoring** - Higher stake reviewers have more weight

### On-chain Immutability

- **Cannot delete** - All registrations and feedback are permanent
- **Audit trail** - Full history of all interactions
- **Revokable feedback** - Reviewers can mark feedback as revoked

### Trust Models

- **Reputation** - Community feedback and ratings
- **Validation** - Cryptographic verification (zkML, TEE, stake)
- **Pluggable** - Multiple trust models can coexist

---

## Gas Optimization

### Estimated Gas Costs

| Operation | Gas Estimate |
|-----------|-------------|
| Register agent | ~85,000 |
| Give feedback | ~45,000 |
| Revoke feedback | ~25,000 |
| Validation request | ~50,000 |
| Validation response | ~40,000 |

### Optimization Tips

1. **Batch operations** - Register multiple agents in single tx if possible
2. **Off-chain metadata** - Use IPFS for large metadata
3. **Event indexing** - Use indexed events for efficient querying
4. **Subgraph indexing** - Deploy subgraph for complex queries

---

## Frontend Integration

### React Component

```javascript
import { ethers } from 'ethers';

const contract = new ethers.Contract(address, ABI, signer);

// Register agent
const tx = await contract.register(agentURI);
await tx.wait();

// Give feedback
const tx = await contract.giveFeedback(agentId, value, tag1);
await tx.wait();
```

### Live Dashboard

**URL:** https://roger-base.github.io/forge-builder/

**Features:**
- Wallet connection (MetaMask)
- Agent registration UI
- Feedback submission UI
- Validation request UI
- Yield dashboard (DeFAI integration)

---

## Resources

- **ERC-8004 Spec:** https://eips.ethereum.org/EIPS/eip-8004
- **Base Sepolia Faucet:** https://coinbase.com/faucets/base-sepolia-faucet
- **Base Explorer:** https://sepolia.basescan.org
- **Foundry Docs:** https://book.getfoundry.sh
- **OpenZeppelin:** https://docs.openzeppelin.com/contracts

---

## License

MIT

---

*ERC-8004 Agent Registry Suite - March 2026*
