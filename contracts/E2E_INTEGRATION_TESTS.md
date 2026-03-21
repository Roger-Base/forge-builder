# ERC-8004 Integration Tests (E2E)

**Purpose:** End-to-end integration tests for ERC-8004 suite + frontend  
**Framework:** Foundry (contract) + Jest (frontend)  
**Network:** Base Sepolia testnet  

---

## Test Scenarios

### 1. Full Agent Onboarding Flow

**Test:** Register agent → Set wallet → Submit feedback → Verify reputation

```javascript
// E2E Test: Full Agent Onboarding
describe('E2E: Agent Onboarding', () => {
  it('completes full onboarding flow', async () => {
    // 1. Connect wallet
    await connectWallet();
    
    // 2. Register agent
    const agentId = await registerAgent('ipfs://QmAgentMetadata');
    expect(agentId).toBeGreaterThan(0);
    
    // 3. Verify onchain
    const owner = await contract.ownerOf(agentId);
    expect(owner).toEqual(walletAddress);
    
    // 4. Submit feedback
    await submitFeedback(agentId, 80, 'quality');
    
    // 5. Verify reputation
    const [count, avg] = await getReputation(agentId);
    expect(count).toBe(1);
    expect(avg).toBe(80);
    
    // 6. Check UI updates
    expect(screen.getByText('Agent registered successfully!')).toBeInTheDocument();
    expect(screen.getByText('Feedback recorded!')).toBeInTheDocument();
  });
});
```

---

### 2. Registration + Validation Flow

**Test:** Register → Request validation → Poll status → Verify

```javascript
// E2E Test: Registration + Validation
describe('E2E: Validation Flow', () => {
  it('requests and verifies validation', async () => {
    // 1. Register agent
    const agentId = await registerAgent('ipfs://QmAgent');
    
    // 2. Request validation
    const requestHash = await requestValidation(
      validatorAddress,
      agentId,
      'ipfs://QmProof'
    );
    
    // 3. Poll validation status
    const status = await pollValidationStatus(requestHash);
    
    // 4. Verify response
    expect(status.response).toBeGreaterThan(0);
    expect(status.agentId).toBe(agentId);
    
    // 5. Check UI
    expect(screen.getByText('Validation request sent!')).toBeInTheDocument();
  });
});
```

---

### 3. Reputation System E2E

**Test:** Multiple feedback submissions → Cooldown enforcement → Reputation score

```javascript
// E2E Test: Reputation System
describe('E2E: Reputation System', () => {
  it('enforces 24h cooldown and calculates score', async () => {
    // 1. Register agent
    const agentId = await registerAgent('ipfs://QmAgent');
    
    // 2. Submit first feedback
    await submitFeedback(agentId, 80, 'quality');
    
    // 3. Try second feedback (should fail - cooldown)
    await expect(submitFeedback(agentId, 90, 'quality'))
      .rejects.toThrow('24h cooldown');
    
    // 4. Verify reputation score
    const score = await calculateReputationScore(agentId);
    expect(score).toBeGreaterThan(0);
    
    // 5. Check UI shows cooldown error
    expect(screen.getByText('24h cooldown active')).toBeInTheDocument();
  });
});
```

---

### 4. Multi-Chain Registration

**Test:** Register on Base → Add Ethereum registration → Verify multi-chain

```javascript
// E2E Test: Multi-Chain Registration
describe('E2E: Multi-Chain', () => {
  it('registers and adds multi-chain registration', async () => {
    // 1. Register on Base
    const agentId = await registerAgent('ipfs://QmAgent');
    
    // 2. Add Ethereum registration
    await addRegistration(
      agentId,
      'eip155:1:0xEthereumContractAddress'
    );
    
    // 3. Verify registration count
    const count = await getRegistrationCount(agentId);
    expect(count).toBe(2); // Base + Ethereum
    
    // 4. Check UI
    expect(screen.getByText('Agent registered successfully!')).toBeInTheDocument();
  });
});
```

---

### 5. Yield Dashboard Integration

**Test:** Fetch yield data → Filter by protocol → Sort by APY → Display

```javascript
// E2E Test: Yield Dashboard
describe('E2E: Yield Dashboard', () => {
  it('fetches, filters, and sorts yield data', async () => {
    // 1. Load dashboard
    render(<DeFAIDashboard />);
    
    // 2. Wait for data load
    await waitFor(() => {
      expect(screen.getByText('DeFAI Yield Dashboard')).toBeInTheDocument();
    });
    
    // 3. Filter by protocol (Aave)
    fireEvent.change(screen.getByLabelText('Protocol:'), { target: { value: 'aave' } });
    
    // 4. Verify filtered results
    expect(screen.getByText('USDC')).toBeInTheDocument();
    expect(screen.queryByText('Compound')).not.toBeInTheDocument();
    
    // 5. Sort by APY
    fireEvent.change(screen.getByLabelText('Sort by:'), { target: { value: 'apy' } });
    
    // 6. Verify highest APY first
    const apyValues = screen.getAllByText(/%/);
    expect(parseFloat(apyValues[0].textContent)).toBeGreaterThanOrEqual(
      parseFloat(apyValues[1].textContent)
    );
  });
});
```

---

### 6. Wallet Connection + Contract Interaction

**Test:** Connect MetaMask → Read contract → Write transaction → Verify

```javascript
// E2E Test: Wallet + Contract
describe('E2E: Wallet Integration', () => {
  it('connects wallet and interacts with contract', async () => {
    // 1. Connect wallet
    fireEvent.click(screen.getByText('Connect Wallet'));
    
    await waitFor(() => {
      expect(screen.getByText('Connected')).toBeInTheDocument();
    });
    
    // 2. Read contract data
    const totalAgents = await contract.getTotalAgents();
    expect(totalAgents).toBeGreaterThan(0);
    
    // 3. Write transaction
    const tx = await contract.register('ipfs://QmTest');
    const receipt = await tx.wait();
    
    // 4. Verify event
    const event = receipt.logs.find(log => log.fragment.name === 'Registered');
    expect(event).toBeDefined();
    
    // 5. Check UI update
    expect(screen.getByText('Agent registered successfully!')).toBeInTheDocument();
  });
});
```

---

### 7. Error Handling E2E

**Test:** Invalid input → Contract revert → UI error message

```javascript
// E2E Test: Error Handling
describe('E2E: Error Handling', () => {
  it('handles contract reverts gracefully', async () => {
    // 1. Connect wallet
    await connectWallet();
    
    // 2. Try invalid registration (empty URI)
    await expect(registerAgent(''))
      .rejects.toThrow();
    
    // 3. Try self-review (owner cannot review)
    const agentId = await registerAgent('ipfs://QmAgent');
    await expect(submitFeedback(agentId, 80, 'quality'))
      .rejects.toThrow('Owner cannot review');
    
    // 4. Verify UI shows error
    expect(screen.getByText('Agent owners cannot review their own agents')).toBeInTheDocument();
  });
});
```

---

### 8. Gas Optimization Test

**Test:** Batch registration → Compare gas vs individual → Verify savings

```javascript
// E2E Test: Gas Optimization
describe('E2E: Gas Optimization', () => {
  it('batches registrations for gas savings', async () => {
    // 1. Individual registrations
    const gasIndividual = await Promise.all([
      registerAgent('ipfs://Qm1'),
      registerAgent('ipfs://Qm2'),
      registerAgent('ipfs://Qm3')
    ]);
    
    // 2. Batch registration
    const gasBatch = await batchRegister([
      'ipfs://Qm1',
      'ipfs://Qm2',
      'ipfs://Qm3'
    ]);
    
    // 3. Verify gas savings
    expect(gasBatch).toBeLessThan(gasIndividual);
    
    // 4. Verify all registered
    const total = await contract.getTotalAgents();
    expect(total).toBe(3);
  });
});
```

---

## Running E2E Tests

### Contract Tests (Foundry)

```bash
cd contracts

# Run all E2E tests
forge test --match-test "testE2E"

# Run specific scenario
forge test --match-test "testE2E_Onboarding"

# Gas report
forge test --match-test "testE2E" --gas-report
```

### Frontend Tests (Jest)

```bash
cd frontend

# Run all E2E tests
npm test -- --testPathPattern=e2e

# Run specific scenario
npm test -- --testNamePattern="E2E: Yield Dashboard"

# Coverage
npm test -- --coverage --testPathPattern=e2e
```

---

## Test Data

### Mock Agent Data

```json
{
  "agents": [
    {
      "id": 1,
      "name": "DeFAI Yield Agent",
      "description": "Autonomous yield optimization",
      "category": "DeFi",
      "capabilities": ["yield", "trading", "rebalancing"],
      "status": "Active"
    },
    {
      "id": 2,
      "name": "NFT Minting Agent",
      "description": "Autonomous NFT creation",
      "category": "NFT",
      "capabilities": ["minting", "metadata"],
      "status": "Active"
    }
  ]
}
```

### Mock Yield Data

```json
{
  "aave": {
    "base": [
      {"name": "USDC", "apy": 4.23, "tvl": 45670000, "risk": 15}
    ],
    "ethereum": [
      {"name": "USDC", "apy": 3.45, "tvl": 89230000, "risk": 15}
    ]
  }
}
```

---

## Expected Results

| Scenario | Expected Result |
|----------|----------------|
| Full Onboarding | Agent registered + feedback submitted + reputation verified |
| Validation Flow | Validation requested + status polled + response verified |
| Reputation System | Cooldown enforced + score calculated |
| Multi-Chain | Registration count = 2 (Base + Ethereum) |
| Yield Dashboard | Data fetched + filtered + sorted correctly |
| Wallet Integration | Connected + read + write + event verified |
| Error Handling | Invalid input caught + UI error shown |
| Gas Optimization | Batch gas < individual gas |

---

## Troubleshooting

### Common Failures

**"Contract not deployed"**
- Deploy contracts first: `forge create ...`
- Update contract addresses in frontend

**"Network mismatch"**
- Switch to Base Sepolia: chainId 84532
- Update RPC URL in test config

**"Timeout waiting for element"**
- Increase waitFor timeout
- Check if data is loading correctly

**"Gas estimation failed"**
- Ensure sufficient ETH in wallet
- Check contract state (not reverted)

---

## CI/CD Integration

### GitHub Actions

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Install Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - name: Install dependencies
        run: npm install
      
      - name: Build contracts
        run: forge build
      
      - name: Run contract tests
        run: forge test
      
      - name: Run frontend tests
        run: npm test
      
      - name: Run E2E tests
        run: npm run test:e2e
```

---

*E2E Integration Tests v1.0 - March 2026*
