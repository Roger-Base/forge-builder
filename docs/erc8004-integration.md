# ERC-8004 Integration Guide

**Version:** 1.0  
**Standard:** ERC-8004 (Trustless Agents)  
**Network:** Base Sepolia → Base Mainnet  

---

## Overview

ERC-8004 is an Ethereum standard for AI agent identity, reputation, and validation on-chain. This implementation provides:

1. **Identity Registry** - Agent registration with ERC-721 tokens
2. **Reputation Registry** - Feedback and reputation scoring
3. **Validation Registry** - Work verification (zkML, TEE, stake-secured)

---

## Contract Addresses (Testnet)

| Contract | Address | Status |
|----------|---------|--------|
| IdentityRegistry | `TBD` | Pending deploy |
| ReputationRegistry | `TBD` | Pending deploy |
| ValidationRegistry | `TBD` | Pending deploy |

---

## Quick Start

### 1. Deploy Contracts

```bash
# Set environment variables
export DEPLOYER_KEY=your_private_key
export ETHERSCAN_API_KEY=your_api_key

# Deploy to Base Sepolia
cd contracts
./scripts/deploy-erc8004.sh
```

### 2. Register an Agent

```solidity
// Register agent with metadata URI
string memory agentURI = "ipfs://QmYourAgentMetadata";
uint256 agentId = identityRegistry.register(agentURI);
```

### 3. Submit Feedback

```solidity
// Give feedback (1 per 24h per agent)
int128 value = 80; // Rating value
string memory tag1 = "quality";
repRegistry.giveFeedback(agentId, value, tag1);
```

### 4. Request Validation

```solidity
// Request validation from validator
address validator = 0xValidatorContract;
string memory requestURI = "ipfs://QmValidationData";
bytes32 requestHash = keccak256(abi.encodePacked(requestURI));
valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
```

---

## Agent Registration File Structure

Agents are identified by ERC-721 tokens with metadata URIs pointing to JSON files:

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "Agent Name",
  "description": "Agent description...",
  "image": "https://example.com/agent-image.png",
  "services": [
    {
      "name": "web",
      "endpoint": "https://agent.example.com/",
      "version": "1.0"
    },
    {
      "name": "A2A",
      "endpoint": "https://agent.example.com/.well-known/agent-card.json",
      "version": "0.3.0"
    },
    {
      "name": "MCP",
      "endpoint": "https://mcp.agent.example.com/",
      "version": "2025-06-18"
    },
    {
      "name": "x402",
      "endpoint": "https://x402.agent.example.com/",
      "version": "1.0"
    }
  ],
  "x402Support": true,
  "active": true,
  "registrations": [
    {
      "agentId": 1,
      "agentRegistry": "eip155:84532:0xIdentityRegistryAddress"
    }
  ],
  "supportedTrust": ["reputation", "validation", "tee-attestation"]
}
```

---

## Identity Registry API

### Core Functions

```solidity
// Register new agent
function register(string memory agentURI) external returns (uint256 agentId)

// Update agent URI
function setAgentURI(uint256 agentId, string calldata newURI) external

// Get metadata
function getMetadata(uint256 agentId, string memory metadataKey) external view returns (bytes memory)

// Set metadata (agentWallet is reserved)
function setMetadata(uint256 agentId, string memory metadataKey, bytes memory metadataValue) external

// Set agent wallet with EIP-712 signature
function setAgentWallet(uint256 agentId, address newWallet, uint256 deadline, bytes calldata signature) external

// Add multi-chain registration
function addRegistration(uint256 agentId, string calldata agentRegistry) external
```

### Events

```solidity
event Registered(uint256 indexed agentId, string agentURI, address indexed owner)
event URIUpdated(uint256 indexed agentId, string newURI, address indexed updatedBy)
event MetadataSet(uint256 indexed agentId, string indexed indexedMetadataKey, string metadataKey, bytes metadataValue)
event AgentWalletSet(uint256 indexed agentId, address indexed newWallet, address indexed owner)
event RegistrationAdded(uint256 indexed agentId, string agentRegistry, uint256 registrationIndex)
```

---

## Reputation Registry API

### Core Functions

```solidity
// Give feedback (1 per 24h per agent)
function giveFeedback(uint256 agentId, int128 value, string calldata tag1) external

// Revoke feedback
function revokeFeedback(uint256 agentId, uint256 idx) external

// Append response to feedback
function appendResponse(uint256 agentId, address client, uint256 idx) external

// Get summary (weighted by stake)
function getSummary(uint256 agentId, address[] calldata clients) external view returns (uint256 count, int128 avg)

// Read single feedback
function readFeedback(uint256 agentId, address client, uint256 idx) external view returns (int128 value, uint8 decimals, string memory tag1, string memory tag2, bool revoked)

// Get clients who reviewed
function getClients(uint256 agentId) external view returns (address[] memory)

// Set reviewer stake weight (owner only)
function setReviewerStake(address reviewer, uint256 stake) external
```

### Events

```solidity
event NewFeedback(uint256 indexed agentId, address indexed client, uint256 feedbackIndex, int128 value, string indexed tag1)
event FeedbackRevoked(uint256 indexed agentId, address indexed client, uint256 feedbackIndex)
event ResponseAppended(uint256 indexed agentId, address indexed client, uint256 indexed feedbackIndex)
```

### Reputation Features

- **24h cooldown** - 1 review per agent per 24 hours (Sybil resistance)
- **Stake-weighted scoring** - Higher stake reviewers have more weight
- **Owner cannot review** - Agent owners cannot review their own agents
- **Revokable feedback** - Reviewers can revoke their feedback

---

## Validation Registry API

### Core Functions

```solidity
// Request validation
function validationRequest(address validator, uint256 agentId, string calldata requestURI, bytes32 requestHash) external

// Submit validation response
function validationResponse(bytes32 requestHash, uint8 response, string calldata responseURI, bytes32 responseHash, string calldata tag) external

// Get validation status
function getValidationStatus(bytes32 requestHash) external view returns (address validator, uint256 agentId, uint8 response, bytes32 responseHash, string memory tag, uint256 lastUpdate)

// Get summary
function getSummary(uint256 agentId, address[] calldata validators, string calldata tag) external view returns (uint64 count, uint8 averageResponse)

// Get all validations for agent
function getAgentValidations(uint256 agentId) external view returns (bytes32[] memory)
```

### Events

```solidity
event ValidationRequested(address indexed validator, uint256 indexed agentId, string requestURI, bytes32 indexed requestHash)
event ValidationResponse(address indexed validator, uint256 indexed agentId, bytes32 indexed requestHash, uint8 response, string responseURI, bytes32 responseHash, string tag)
```

### Validation Models

- **Stake-secured re-execution** - Validators re-run computation with stake slashing
- **zkML verifiers** - Zero-knowledge proofs for ML inference
- **TEE oracles** - Trusted Execution Environment attestations

---

## Integration Examples

### Web3.js Example

```javascript
const identityRegistry = new web3.eth.Contract(ABI, address);

// Register agent
const agentURI = "ipfs://QmYourAgentMetadata";
const tx = await identityRegistry.methods.register(agentURI).send({ from: account });
const agentId = tx.events.Registered.returnValues.agentId;

// Get agent details
const agentId = 1;
const owner = await identityRegistry.methods.ownerOf(agentId).call();
const uri = await identityRegistry.methods.tokenURI(agentId).call();
```

### Ethers.js Example

```javascript
const repRegistry = new ethers.Contract(address, ABI, signer);

// Give feedback
const agentId = 1;
const value = 80;
const tag1 = "quality";
const tx = await repRegistry.giveFeedback(agentId, value, tag1);
await tx.wait();

// Get summary
const clients = [signer.address];
const [count, avg] = await repRegistry.getSummary(agentId, clients);
console.log(`Count: ${count}, Average: ${avg}`);
```

---

## Best Practices

### Agent Registration

1. **Use IPFS for metadata** - Pin agent registration files on IPFS
2. **Include all services** - List all agent endpoints (MCP, A2A, x402, etc.)
3. **Set agentWallet** - Verify payment address with EIP-712 signature
4. **Add multi-chain registrations** - Register on multiple chains if deploying cross-chain

### Reputation Management

1. **Wait 24h between reviews** - Cooldown enforced per agent
2. **Use meaningful tags** - tag1 for categorization (quality, uptime, etc.)
3. **Stake-weighted scoring** - Higher stake = more reputation impact
4. **Monitor feedback** - Track agent reputation over time

### Validation

1. **Choose appropriate validators** - Match validation type to use case
2. **Provide clear request data** - Include inputs/outputs in requestURI
3. **Track validation status** - Monitor validation responses
4. **Use progressive validation** - Multiple responses for complex validations

---

## Security Considerations

### Sybil Resistance

- **24h cooldown** - Prevents spam reviews
- **Owner cannot review** - Prevents self-review manipulation
- **Stake-weighted scoring** - Requires stake for high-impact reviews

### On-chain Immutability

- **Cannot delete** - All registrations and feedback are permanent
- **Audit trail** - Full history of all interactions
- **Revocable feedback** - Reviewers can mark feedback as revoked

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

## Testing

### Run Unit Tests

```bash
cd contracts
forge test -vv
```

### Test Coverage

```bash
forge coverage
```

### Deploy to Testnet

```bash
./scripts/deploy-erc8004.sh
```

---

## Mainnet Deployment

### Pre-Mainnet Checklist

1. ✅ Testnet deployment complete
2. ✅ All unit tests passing
3. ✅ Security audit complete
4. ✅ Gas optimization reviewed
5. ✅ Frontend integration tested
6. ✅ Documentation complete

### Mainnet Deploy

```bash
# Update RPC to mainnet
export RPC_URL="https://mainnet.base.org"
export CHAIN_ID=8453

# Deploy
./scripts/deploy-erc8004.sh
```

---

## Resources

- **ERC-8004 Spec:** https://eips.ethereum.org/EIPS/eip-8004
- **Base Sepolia Faucet:** https://coinbase.com/faucets/base-sepolia-faucet
- **Base Explorer:** https://sepolia.basescan.org
- **Foundry Docs:** https://book.getfoundry.sh

---

*ERC-8004 Integration Guide - March 2026*
