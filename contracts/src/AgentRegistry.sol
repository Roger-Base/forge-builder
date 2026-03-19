// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AgentRegistry
 * @author Roger (Autonomous Research Agent)
 * @notice Onchain registry for AI agents with reputation system
 * @dev ERC-721 based agent registration on Base
 */
contract AgentRegistry is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    
    uint256 private _nextAgentId;
    
    struct Agent {
        uint256 agentId;
        string name;
        string description;
        string category;
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
    
    mapping(uint256 => Agent) private _agents;
    mapping(uint256 => Review[]) private _agentReviews;
    mapping(address => mapping(uint256 => bool)) private _hasReviewed;
    mapping(address => uint256) private _reviewerStake;
    
    event AgentRegistered(
        uint256 indexed agentId,
        string name,
        address indexed creator,
        uint256 timestamp
    );
    
    event MetadataUpdated(
        uint256 indexed agentId,
        string newURI,
        uint256 timestamp
    );
    
    event ReviewSubmitted(
        uint256 indexed reviewId,
        uint256 indexed agentId,
        address indexed reviewer,
        uint8 rating,
        uint256 timestamp
    );
    
    event ReputationUpdated(
        uint256 indexed agentId,
        uint256 newScore,
        uint256 timestamp
    );
    
    event AgentVerified(
        uint256 indexed agentId,
        bool verified,
        uint256 timestamp
    );
    
    constructor() ERC721("AgentRegistry", "AGENT") Ownable(msg.sender) {
        _nextAgentId = 1;
    }
    
    /**
     * @notice Register a new AI agent
     * @param name Agent name
     * @param description Agent description
     * @param category Agent category (analysis, trading, defi, etc.)
     * @param metadataURI IPFS URI for full metadata
     * @return agentId New agent ID
     */
    function registerAgent(
        string memory name,
        string memory description,
        string memory category,
        string memory metadataURI
    ) external nonReentrant returns (uint256) {
        uint256 agentId = _nextAgentId++;
        
        _agents[agentId] = Agent({
            agentId: agentId,
            name: name,
            description: description,
            category: category,
            creator: msg.sender,
            registeredAt: block.timestamp,
            reviewCount: 0,
            totalRating: 0,
            reputationScore: 0,
            verified: false
        });
        
        _safeMint(msg.sender, agentId);
        _setTokenURI(agentId, metadataURI);
        
        emit AgentRegistered(agentId, name, msg.sender, block.timestamp);
        
        return agentId;
    }
    
    /**
     * @notice Update agent metadata URI
     * @param agentId Agent ID
     * @param newURI New IPFS URI
     */
    function updateMetadata(uint256 agentId, string memory newURI) external {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        
        _setTokenURI(agentId, newURI);
        
        emit MetadataUpdated(agentId, newURI, block.timestamp);
    }
    
    /**
     * @notice Submit a review for an agent
     * @param agentId Agent ID to review
     * @param rating Rating 1-5
     * @param reviewText Review text
     */
    function submitReview(
        uint256 agentId,
        uint8 rating,
        string memory reviewText
    ) external nonReentrant {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(rating >= 1 && rating <= 5, "Rating must be 1-5");
        require(!_hasReviewed[msg.sender][agentId], "Already reviewed");
        
        uint256 reviewId = _agentReviews[agentId].length;
        
        _agentReviews[agentId].push(Review({
            reviewId: reviewId,
            agentId: agentId,
            reviewer: msg.sender,
            rating: rating,
            reviewText: reviewText,
            timestamp: block.timestamp
        }));
        
        _hasReviewed[msg.sender][agentId] = true;
        
        _agents[agentId].reviewCount++;
        _agents[agentId].totalRating += rating;
        
        _updateReputationScore(agentId);
        
        emit ReviewSubmitted(reviewId, agentId, msg.sender, rating, block.timestamp);
    }
    
    /**
     * @notice Get agent details
     * @param agentId Agent ID
     * @return Agent struct
     */
    function getAgent(uint256 agentId) external view returns (Agent memory) {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        return _agents[agentId];
    }
    
    /**
     * @notice Get reputation score for an agent
     * @param agentId Agent ID
     * @return Reputation score
     */
    function getReputationScore(uint256 agentId) external view returns (uint256) {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        return _agents[agentId].reputationScore;
    }
    
    /**
     * @notice Get all reviews for an agent
     * @param agentId Agent ID
     * @return Array of reviews
     */
    function getReviews(uint256 agentId) external view returns (Review[] memory) {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        return _agentReviews[agentId];
    }
    
    /**
     * @notice Get review count for an agent
     * @param agentId Agent ID
     * @return Review count
     */
    function getReviewCount(uint256 agentId) external view returns (uint256) {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        return _agents[agentId].reviewCount;
    }
    
    /**
     * @notice Check if address has reviewed an agent
     * @param reviewer Address
     * @param agentId Agent ID
     * @return Has reviewed
     */
    function hasReviewed(address reviewer, uint256 agentId) external view returns (bool) {
        return _hasReviewed[reviewer][agentId];
    }
    
    /**
     * @notice Get total agents registered
     * @return Total count
     */
    function getTotalAgents() external view returns (uint256) {
        return _nextAgentId;
    }
    
    /**
     * @notice Verify an agent (owner only)
     * @param agentId Agent ID
     * @param verified Verification status
     */
    function verifyAgent(uint256 agentId, bool verified) external onlyOwner {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        _agents[agentId].verified = verified;
        _updateReputationScore(agentId);
        
        emit AgentVerified(agentId, verified, block.timestamp);
    }
    
    /**
     * @notice Set reviewer stake weight (owner only)
     * @param reviewer Address
     * @param stake Stake amount
     */
    function setReviewerStake(address reviewer, uint256 stake) external onlyOwner {
        _reviewerStake[reviewer] = stake;
    }
    
    /**
     * @notice Internal function to update reputation score
     * @param agentId Agent ID
     */
    function _updateReputationScore(uint256 agentId) internal {
        Agent storage agent = _agents[agentId];
        
        uint256 avgRating = agent.reviewCount > 0 
            ? (agent.totalRating * 100) / agent.reviewCount 
            : 0;
        
        uint256 ratingScore = avgRating / 5; // Max 20
        
        uint256 verificationBonus = agent.verified ? 50 : 0;
        
        agent.reputationScore = ratingScore + verificationBonus;
        
        emit ReputationUpdated(agentId, agent.reputationScore, block.timestamp);
    }
    
    /**
     * @notice Override supportsInterface
     */
    function supportsInterface(bytes4 interfaceId) 
        public view override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @notice Override tokenURI
     */
    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @notice Override burn
     */
    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Not owner");
        
        _burn(tokenId);
    }
}
