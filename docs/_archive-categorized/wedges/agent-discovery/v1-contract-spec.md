# Agent Discovery V1 - Smart Contract Spec

**Wedge:** agent-discovery  
**Phase:** V1 (Onchain Registry + Reputation)  
**Created:** 2026-03-19  
**Author:** Roger

---

## Contract Overview

**Name:** AgentRegistry  
**Chain:** Base (L2)  
**Standard:** ERC-721 (NFT) + ERC-2981 (Royalties)  
**Purpose:** Onchain registration of AI agents with metadata and reputation

---

## Core Functions

### 1. Register Agent
```solidity
function registerAgent(
    string memory name,
    string memory description,
    string memory category,
    string memory metadataURI,
    address creator
) external returns (uint256 agentId);
```

**Events:**
```solidity
event AgentRegistered(
    uint256 indexed agentId,
    string name,
    address indexed creator,
    uint256 timestamp
);
```

### 2. Update Metadata
```solidity
function updateMetadata(uint256 agentId, string memory newURI) external;
```

**Access:** Only creator/owner

### 3. Submit Review
```solidity
function submitReview(
    uint256 agentId,
    uint8 rating, // 1-5
    string memory reviewText
) external;
```

**Events:**
```solidity
event ReviewSubmitted(
    uint256 indexed agentId,
    address indexed reviewer,
    uint8 rating,
    uint256 timestamp
);
```

### 4. Calculate Reputation
```solidity
function getReputationScore(uint256 agentId) external view returns (uint256 score);
```

**Logic:**
- Average rating (weighted by reviewer stake)
- Transaction count
- Uptime metric
- Audit status bonus

---

## Data Structures

```solidity
struct Agent {
    uint256 agentId;
    string name;
    string description;
    string category;
    string metadataURI;
    address creator;
    uint256 registeredAt;
    uint256 reviewCount;
    uint256 totalRating;
    uint256 reputationScore;
    bool verified;
}

struct Review {
    uint256 reviewId;
    uint256 agentId;
    address reviewer;
    uint8 rating;
    string reviewText;
    uint256 timestamp;
}
```

---

## Storage Pattern

**Onchain:**
- Agent ID → owner mapping
- Basic metadata (name, category)
- Review count, total rating
- Reputation score (updated periodically)

**Offchain (IPFS):**
- Full agent profile
- Detailed description
- Capabilities list
- Social links
- Performance history

**Metadata URI Format:**
```
ipfs://Qm.../{agentId}.json
```

---

## Reputation Algorithm

```
reputationScore = (
    avgRating * 20 +           // Max 100 from ratings
    txCount / 10 +             // 1 point per 10 txs
    uptimeDays / 7 +           // 1 point per week
    (verified ? 50 : 0)        // Verification bonus
) * stakeWeight
```

**Stake Weight:**
- Token holders: 1.5x
- Active users: 1.2x
- New users: 1.0x

---

## Gas Optimization

**Patterns:**
- Batch registration (reduce deploy cost)
- Lazy reputation updates (compute on read)
- Event-based indexing (offchain listeners)
- Minimal onchain storage (IPFS for bulk)

**Estimated Costs:**
- Register agent: ~85,000 gas
- Submit review: ~45,000 gas
- Update metadata: ~35,000 gas
- Get reputation: ~5,000 gas (view)

---

## Security Considerations

**Access Control:**
- Ownable (creator/owner)
- Review submission: any address
- Reputation update: only owner/oracle

**Reentrancy:**
- Reviews: non-reentrant (no external calls)
- Registration: safe ERC-721 mint

**Sybil Resistance:**
- Review rate limiting (1 per 24h per agent)
- Stake-weighted scoring
- Verified reviewer tier

---

## Integration Points

**Frontend:**
- React + ethers.js
- Read contracts (view functions)
- Write transactions (register, review)

**Indexing:**
- The Graph subgraph
- Listen to events
- Build search index

**Backend:**
- IPFS pinning service
- Metadata validation
- Reputation oracle (offchain compute)

---

## Deployment Plan

**Testnet:**
1. Deploy to Base Sepolia
2. Register 10 test agents
3. Submit 50 test reviews
4. Verify reputation calc

**Mainnet:**
1. Audit (OpenZeppelin/Trail of Bits)
2. Deploy to Base mainnet
3. Migrate MVP data (100 agents)
4. Launch reputation system

---

## Milestones

| Milestone | Target | Deliverable |
|-----------|--------|-------------|
| Spec | 2026-03-19 | This document ✅ |
| Contract | 2026-03-22 | Solidity code |
| Testnet | 2026-03-25 | Base Sepolia deploy |
| Audit | 2026-03-28 | Security report |
| Mainnet | 2026-04-01 | Base mainnet |
| Migration | 2026-04-03 | 100 agents onchain |

---

## Skills Required

| Skill | Usage |
|-------|-------|
| evm-wallet | Deployment, tx signing |
| onchain | Contract interaction |
| security-audit-toolkit | Pre-deploy audit |
| clawvault | Memory persistence |
| skill-creator | Contract patterns |

---

## Success Metrics

- 100 agents registered onchain
- 500+ reviews submitted
- Avg reputation score computed
- Gas cost <100k per registration
- Zero security incidents

---

*End of V1 Smart Contract Spec*
