# Frontend Integration Guide

## Overview

The frontend provides a complete UI for interacting with ERC-8004 contracts:
- **ERC8004Registry** - Wallet connect + contract interactions
- **AgentBrowser** - Browse, search, and filter agents
- **Responsive design** - Mobile-friendly, Base-themed

---

## Components

### 1. ERC8004Registry.jsx (7,758 bytes)

**Features:**
- MetaMask wallet connection
- Register agent (IdentityRegistry)
- Give feedback (ReputationRegistry)
- Request validation (ValidationRegistry)
- Live stats (total agents)
- Error handling + status display

**Usage:**
```jsx
import ERC8004Registry from './ERC8004Registry';

function App() {
  return <ERC8004Registry />;
}
```

**Contract Integration:**
```javascript
// Update contract addresses after deploy
const CONTRACTS = {
  identityRegistry: '0xYourDeployedAddress',
  reputationRegistry: '0xYourDeployedAddress',
  validationRegistry: '0xYourDeployedAddress'
};
```

### 2. AgentBrowser.jsx (4,309 bytes)

**Features:**
- Fetch agents from GitHub data endpoint
- Search by name/description/capability
- Category filters
- Stats bar (total + per-category)
- Responsive grid layout

**Data Source:**
- `https://raw.githubusercontent.com/Roger-Base/forge-builder/main/data/agents.json`

### 3. App.jsx (814 bytes)

**Integration:**
- Combines ERC8004Registry + AgentBrowser
- Header + footer branding
- Main sections for registry + browse

---

## Styling

### ERC8004Registry.css (2,162 bytes)
- Clean, professional design
- Base blue (#0052ff) theme
- Responsive layout
- Form styling + buttons

### AgentBrowser.css (3,281 bytes)
- Card-based agent grid
- Gradient stats bar
- Search + filter controls
- Hover effects + transitions

### App.css (3,304 bytes)
- Global app styling
- Header/footer design
- Section layouts

---

## Build & Deploy

### Local Development

```bash
cd frontend
npm install
npm run dev
```

### Production Build

```bash
npm run build
# Output: dist/ folder (193.70 KB JS, 4.40 KB CSS)
```

### Deploy to GitHub Pages

```bash
# Build
npm run build

# Deploy (using gh-pages package)
npm run deploy
# Or manual:
# 1. Copy dist/ to docs/
# 2. git add docs/
# 3. git commit -m "Deploy frontend"
# 4. git push
```

**Live URL:** https://roger-base.github.io/forge-builder/

---

## Contract Integration

### After Deploying Contracts

1. **Update addresses in ERC8004Registry.jsx:**
```javascript
const CONTRACTS = {
  identityRegistry: '0x...', // from deploy script output
  reputationRegistry: '0x...',
  validationRegistry: '0x...'
};
```

2. **Rebuild:**
```bash
npm run build
```

3. **Deploy:**
```bash
npm run deploy
```

---

## Features Roadmap

### Current (v1.0):
- ✅ Wallet connection
- ✅ Agent registration
- ✅ Feedback submission
- ✅ Validation requests
- ✅ Agent browsing
- ✅ Search + filters

### Next (v1.1):
- ⏳ Agent detail pages
- ⏳ Reputation display per agent
- ⏳ Validation status display
- ⏳ Transaction history
- ⏳ ENS integration

### Future (v2.0):
- ⏳ Real-time event updates (WebSocket)
- ⏳ Multi-chain support
- ⏳ Advanced filtering (stake, uptime, etc.)
- ⏳ Agent analytics dashboard

---

## Testing

### Component Testing

```bash
# Install testing libs
npm install --save-dev @testing-library/react @testing-library/jest-dom

# Run tests
npm test
```

### Manual Testing Checklist

1. **Wallet Connect:**
   - [ ] MetaMask prompt appears
   - [ ] Account displays after connect
   - [ ] Network switches to Base Sepolia

2. **Agent Registration:**
   - [ ] Input accepts IPFS URI
   - [ ] Transaction sends
   - [ ] Success message displays
   - [ ] Total agents count updates

3. **Feedback:**
   - [ ] Agent ID input works
   - [ ] Value range (-100 to 100)
   - [ ] Tag input works
   - [ ] 24h cooldown error shows

4. **Validation:**
   - [ ] Validator address input
   - [ ] Request URI input
   - [ ] Transaction sends
   - [ ] Status displays

5. **Agent Browser:**
   - [ ] Agents load from GitHub
   - [ ] Search filters correctly
   - [ ] Category filters work
   - [ ] Stats bar displays

---

## Troubleshooting

### Common Issues

**"Please install MetaMask"**
- Install MetaMask extension
- Refresh page

**"Transaction failed"**
- Check network (Base Sepolia)
- Ensure sufficient ETH for gas
- Verify contract addresses are correct

**"Agent ID not found"**
- Agent must be registered first
- Check contract deployment

**"24h cooldown"**
- Wait 24 hours between reviews for same agent
- This is enforced by contract

**"No agents found"**
- Check GitHub data endpoint
- Verify internet connection
- Check browser console for errors

---

## Performance

### Bundle Size
- JS: 193.70 KB
- CSS: 4.40 KB
- Total: ~198 KB

### Optimization Tips
1. Lazy load components
2. Code split by route
3. Compress images
4. Enable gzip compression
5. Use CDN for ethers.js

---

## Security

### Frontend Security Checklist

- [ ] Validate all user inputs
- [ ] Use HTTPS in production
- [ ] Sanitize URLs (agent URIs)
- [ ] Handle private keys securely (never store)
- [ ] Use ethers.js for type-safe contract calls
- [ ] Display clear error messages
- [ ] Rate limit form submissions

---

## Resources

- **Ethers.js Docs:** https://docs.ethers.org/
- **React Docs:** https://react.dev/
- **Base Network:** https://base.org/
- **ERC-8004 Spec:** https://eips.ethereum.org/EIPS/eip-8004

---

*Frontend Integration Guide - March 2026*
