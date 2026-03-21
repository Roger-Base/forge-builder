# ERC-8004 Integration Examples

**Version:** 1.0.0  
**Purpose:** Practical code examples for integrating ERC-8004 contracts  

---

## Solidity Examples

### 1. Register an Agent

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IdentityRegistry} from "./IdentityRegistry.sol";

contract AgentRegistrar {
    IdentityRegistry public identityRegistry;
    
    constructor(address _identityRegistry) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }
    
    function registerAgent(string memory agentURI) external returns (uint256) {
        // Register agent with IPFS metadata URI
        uint256 agentId = identityRegistry.register(agentURI);
        
        emit AgentRegistered(msg.sender, agentId, agentURI);
        
        return agentId;
    }
    
    event AgentRegistered(address indexed owner, uint256 indexed agentId, string agentURI);
}
```

**Usage:**
```solidity
// Deploy registrar
AgentRegistrar registrar = new AgentRegistrar(identityRegistryAddress);

// Register agent
uint256 agentId = registrar.registerAgent("ipfs://QmYourAgentMetadata");
```

---

### 2. Set Agent Wallet with Signature

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IdentityRegistry} from "./IdentityRegistry.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AgentWalletSetter {
    using ECDSA for bytes32;
    
    IdentityRegistry public identityRegistry;
    
    constructor(address _identityRegistry) {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }
    
    function setAgentWallet(
        uint256 agentId,
        address newWallet,
        uint256 deadline,
        bytes memory signature
    ) external {
        // Verify signature hasn't expired
        require(block.timestamp <= deadline, "Signature expired");
        
        // Set agent wallet
        identityRegistry.setAgentWallet(agentId, newWallet, deadline, signature);
        
        emit WalletSet(agentId, newWallet, msg.sender);
    }
    
    event WalletSet(uint256 indexed agentId, address newWallet, address setter);
}
```

**Usage:**
```solidity
// Sign off-chain
bytes32 hash = keccak256(abi.encodePacked(agentId, newWallet, deadline));
bytes memory signature = signHash(hash, privateKey);

// Set wallet on-chain
walletSetter.setAgentWallet(agentId, newWallet, deadline, signature);
```

---

### 3. Submit Feedback with Cooldown Check

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReputationRegistry} from "./ReputationRegistry.sol";

contract FeedbackSubmitter {
    ReputationRegistry public repRegistry;
    
    constructor(address _repRegistry) {
        repRegistry = ReputationRegistry(_repRegistry);
    }
    
    function submitFeedback(
        uint256 agentId,
        int128 value,
        string calldata tag1
    ) external {
        // Check cooldown (24h)
        uint256 lastReview = repRegistry.getLastReviewTime(msg.sender, agentId);
        require(
            lastReview == 0 || block.timestamp - lastReview >= 86400,
            "24h cooldown active"
        );
        
        // Submit feedback
        repRegistry.giveFeedback(agentId, value, tag1);
        
        emit FeedbackSubmitted(msg.sender, agentId, value, tag1);
    }
    
    event FeedbackSubmitted(
        address indexed reviewer,
        uint256 indexed agentId,
        int128 value,
        string tag1
    );
}
```

**Usage:**
```solidity
// Submit feedback (value: -100 to 100)
feedbackSubmitter.submitFeedback(agentId, 80, "quality");

// Will revert if < 24h since last review
```

---

### 4. Get Reputation Summary

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReputationRegistry} from "./ReputationRegistry.sol";

contract ReputationViewer {
    ReputationRegistry public repRegistry;
    
    constructor(address _repRegistry) {
        repRegistry = ReputationRegistry(_repRegistry);
    }
    
    function getAgentReputation(
        uint256 agentId,
        address[] calldata clients
    ) external view returns (uint256 count, int128 avgRating) {
        (count, avgRating) = repRegistry.getSummary(agentId, clients);
        
        return (count, avgRating);
    }
    
    function calculateReputationScore(
        uint256 agentId,
        address[] calldata clients
    ) external view returns (uint256 score) {
        (uint256 count, int128 avg) = repRegistry.getSummary(agentId, clients);
        
        // Novel reputation algorithm from spec:
        // score = (avgRating * 20 + txCount / 10 + uptimeDays / 7 + (verified ? 50 : 0)) * stakeWeight
        score = uint256(int256(avg * 20)) + count / 10;
        
        return score;
    }
}
```

**Usage:**
```solidity
// Get reputation
(uint256 count, int128 avg) = viewer.getAgentReputation(agentId, clients);

// Calculate score
uint256 score = viewer.calculateReputationScore(agentId, clients);
```

---

### 5. Request Validation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ValidationRegistry} from "./ValidationRegistry.sol";

contract ValidationRequester {
    ValidationRegistry public valRegistry;
    
    constructor(address _valRegistry) {
        valRegistry = ValidationRegistry(_valRegistry);
    }
    
    function requestValidation(
        address validator,
        uint256 agentId,
        string calldata requestURI
    ) external returns (bytes32) {
        // Hash request data
        bytes32 requestHash = keccak256(abi.encodePacked(requestURI));
        
        // Request validation
        valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
        
        emit ValidationRequested(validator, agentId, requestURI, requestHash);
        
        return requestHash;
    }
    
    function getValidationStatus(
        bytes32 requestHash
    ) external view returns (
        address validator,
        uint256 agentId,
        uint8 response,
        string memory tag
    ) {
        (validator, agentId, response, , tag, ) = valRegistry.getValidationStatus(requestHash);
        
        return (validator, agentId, response, tag);
    }
    
    event ValidationRequested(
        address indexed validator,
        uint256 indexed agentId,
        string requestURI,
        bytes32 indexed requestHash
    );
}
```

**Usage:**
```solidity
// Request validation
bytes32 requestHash = requester.requestValidation(
    validatorAddress,
    agentId,
    "ipfs://QmValidationData"
);

// Check status
(uint8 response, string memory tag) = requester.getValidationStatus(requestHash);
```

---

## JavaScript/React Examples

### 1. Connect Wallet + Register Agent

```javascript
import { ethers } from 'ethers';
import { IdentityRegistryABI } from './abis/IdentityRegistry';

const IDENTITY_REGISTRY_ADDRESS = '0x...'; // Deployed address

async function registerAgent() {
  // Connect wallet
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  
  // Create contract instance
  const contract = new ethers.Contract(
    IDENTITY_REGISTRY_ADDRESS,
    IdentityRegistryABI,
    signer
  );
  
  // Register agent
  const agentURI = "ipfs://QmYourAgentMetadata";
  const tx = await contract.register(agentURI);
  
  // Wait for confirmation
  const receipt = await tx.wait();
  
  // Get agent ID from event
  const event = receipt.logs.find(log => log.fragment.name === 'Registered');
  const agentId = event.args.agentId;
  
  console.log(`Agent registered with ID: ${agentId}`);
  
  return agentId;
}
```

---

### 2. Submit Feedback with Error Handling

```javascript
import { ReputationRegistryABI } from './abis/ReputationRegistry';

const REPUTATION_REGISTRY_ADDRESS = '0x...';

async function submitFeedback(agentId, value, tag1) {
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  
  const contract = new ethers.Contract(
    REPUTATION_REGISTRY_ADDRESS,
    ReputationRegistryABI,
    signer
  );
  
  try {
    // Submit feedback
    const tx = await contract.giveFeedback(agentId, value, tag1);
    await tx.wait();
    
    console.log('Feedback submitted successfully!');
    
  } catch (error) {
    if (error.reason === '24h cooldown') {
      console.error('Please wait 24 hours before reviewing this agent again');
    } else if (error.reason === 'Owner cannot review') {
      console.error('Agent owners cannot review their own agents');
    } else {
      console.error('Feedback submission failed:', error);
    }
    
    throw error;
  }
}

// Usage
await submitFeedback(1, 80, 'quality');
```

---

### 3. Get Reputation Dashboard Data

```javascript
async function getReputationDashboard(agentId) {
  const provider = new ethers.JsonProvider('https://sepolia.base.org');
  
  const contract = new ethers.Contract(
    REPUTATION_REGISTRY_ADDRESS,
    ReputationRegistryABI,
    provider
  );
  
  // Get connected user address
  const signerAddress = await signer.getAddress();
  
  // Get summary
  const [count, avg] = await contract.getSummary(agentId, [signerAddress]);
  
  // Get all clients who reviewed
  const clients = await contract.getClients(agentId);
  
  // Calculate reputation score
  const score = (Number(avg) * 20) + (Number(count) / 10);
  
  return {
    agentId,
    reviewCount: Number(count),
    averageRating: Number(avg),
    reputationScore: score,
    uniqueReviewers: clients.length
  };
}

// Usage
const dashboard = await getReputationDashboard(1);
console.log(dashboard);
// { agentId: 1, reviewCount: 5, averageRating: 75, reputationScore: 1500.5, uniqueReviewers: 5 }
```

---

### 4. Validation Status Polling

```javascript
import { ValidationRegistryABI } from './abis/ValidationRegistry';

async function pollValidationStatus(requestHash, pollInterval = 5000) {
  const provider = new ethers.JsonProvider('https://sepolia.base.org');
  
  const contract = new ethers.Contract(
    VALIDATION_REGISTRY_ADDRESS,
    ValidationRegistryABI,
    provider
  );
  
  return new Promise((resolve, reject) => {
    const poll = async () => {
      try {
        const [validator, agentId, response, responseHash, tag, lastUpdate] = 
          await contract.getValidationStatus(requestHash);
        
        // Check if response is set (response != 0 or lastUpdate != 0)
        if (response !== 0 || lastUpdate !== 0n) {
          resolve({
            validator,
            agentId: Number(agentId),
            response: Number(response),
            responseHash,
            tag,
            lastUpdate: Number(lastUpdate)
          });
        } else {
          // Poll again
          setTimeout(poll, pollInterval);
        }
      } catch (error) {
        reject(error);
      }
    };
    
    poll();
  });
}

// Usage
const status = await pollValidationStatus(requestHash);
console.log('Validation complete:', status);
```

---

### 5. React Component - Agent Registration Form

```jsx
import { useState } from 'react';
import { ethers } from 'ethers';

function AgentRegistrationForm() {
  const [agentURI, setAgentURI] = useState('');
  const [agentId, setAgentId] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  
  const handleRegister = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const contract = new ethers.Contract(
        IDENTITY_REGISTRY_ADDRESS,
        IdentityRegistryABI,
        signer
      );
      
      const tx = await contract.register(agentURI);
      const receipt = await tx.wait();
      
      const event = receipt.logs.find(log => log.fragment.name === 'Registered');
      const id = event.args.agentId;
      
      setAgentId(Number(id));
      
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={handleRegister}>
      <input
        type="text"
        value={agentURI}
        onChange={(e) => setAgentURI(e.target.value)}
        placeholder="IPFS URI (e.g., ipfs://Qm...)"
        required
      />
      
      <button type="submit" disabled={loading}>
        {loading ? 'Registering...' : 'Register Agent'}
      </button>
      
      {agentId && (
        <div className="success">
          Agent registered with ID: {agentId}
        </div>
      )}
      
      {error && (
        <div className="error">
          {error}
        </div>
      )}
    </form>
  );
}
```

---

## Full-Stack Integration Example

### End-to-End Agent Onboarding

```javascript
// 1. Register agent
const agentId = await registerAgent("ipfs://QmAgentMetadata");

// 2. Set agent wallet (with signature)
const signature = await signAgentWalletMessage(agentId, newWallet, privateKey);
await setAgentWallet(agentId, newWallet, deadline, signature);

// 3. Add multi-chain registration
await addRegistration(agentId, "eip155:8453:0xBaseMainnetAddress");

// 4. Submit initial feedback (bootstrap reputation)
await submitFeedback(agentId, 100, "genesis");

// 5. Request validation (zkML proof)
const requestHash = await requestValidation(
  zkmlValidatorAddress,
  agentId,
  "ipfs://QmZKProof"
);

// 6. Poll validation status
const validationStatus = await pollValidationStatus(requestHash);

// 7. Display dashboard
const dashboard = await getReputationDashboard(agentId);
displayDashboard(dashboard);
```

---

## Testing Examples

### Unit Test (Foundry)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";

contract ERC8004IntegrationTest is Test {
    IdentityRegistry public identityRegistry;
    ReputationRegistry public repRegistry;
    address public user = address(1);
    
    function setUp() public {
        identityRegistry = new IdentityRegistry("AgentRegistry", "AGENT", "eip155");
        repRegistry = new ReputationRegistry(address(identityRegistry), address(this));
    }
    
    function testFullOnboardingFlow() public {
        // 1. Register agent
        vm.prank(user);
        uint256 agentId = identityRegistry.register("ipfs://QmTest");
        
        // 2. Submit feedback
        vm.prank(user);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        // 3. Verify reputation
        (uint256 count, int128 avg) = repRegistry.getSummary(agentId, address(this));
        
        assertEq(count, 1, "Should have 1 review");
        assertEq(avg, 80, "Average should be 80");
    }
}
```

---

## Best Practices

### Gas Optimization

```javascript
// Batch multiple registrations
async function batchRegister(agentURIs) {
  const contract = new ethers.Contract(address, ABI, signer);
  
  // Use multicall if available
  const calls = agentURIs.map(uri => 
    contract.interface.encodeFunctionData('register', [uri])
  );
  
  await multicall.aggregate(calls);
}
```

### Error Handling

```javascript
// Always check for known reverts
try {
  await contract.giveFeedback(agentId, value, tag1);
} catch (error) {
  if (error.reason === '24h cooldown') {
    // Handle cooldown
  } else if (error.reason === 'Owner cannot review') {
    // Handle self-review
  } else {
    // Handle unknown error
  }
}
```

### Event Listening

```javascript
// Listen for registration events
contract.on('Registered', (agentId, agentURI, owner, event) => {
  console.log(`Agent ${agentId} registered by ${owner}`);
});
```

---

*Integration Examples v1.0 - March 2026*
