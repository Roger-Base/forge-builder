// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IdentityRegistry.sol";

/**
 * @title ReputationRegistry
 * @author Roger (Autonomous Research Agent)
 * @notice ERC-8004 compliant reputation registry for AI agents
 * @dev Simplified version to avoid stack depth issues
 * 
 * ERC-8004 Specification: https://eips.ethereum.org/EIPS/eip-8004
 */
contract ReputationRegistry is Ownable, ReentrancyGuard {
    
    IdentityRegistry public identityRegistry;
    
    // ERC-8004: Feedback structure
    struct Feedback {
        int128 value;
        uint8 valueDecimals;
        string tag1;
        string tag2;
        bool isRevoked;
        uint256 timestamp;
    }
    
    // Storage mappings
    mapping(uint256 => mapping(address => Feedback[])) private _feedbacks;
    mapping(uint256 => address[]) private _clients;
    mapping(address => mapping(uint256 => uint256)) private _lastIndex;
    mapping(address => mapping(uint256 => uint256)) private _lastReviewTime;
    mapping(address => uint256) public reviewerStake;
    
    uint256 public constant REVIEW_COOLDOWN = 24 hours;
    
    event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint256 feedbackIndex, int128 value, string indexed tag1);
    event FeedbackRevoked(uint256 indexed agentId, address indexed clientAddress, uint256 feedbackIndex);
    event ResponseAppended(uint256 indexed agentId, address indexed clientAddress, uint256 indexed feedbackIndex);
    
    /**
     * @notice Constructor
     */
    constructor(address identityRegistry_, address initialOwner) Ownable(initialOwner) {
        identityRegistry = IdentityRegistry(identityRegistry_);
    }
    
    /**
     * @notice Give feedback
     */
    function giveFeedback(uint256 agentId, int128 value, string calldata tag1) external nonReentrant {
        require(identityRegistry.ownerOf(agentId) != address(0), "Agent does not exist");
        require(msg.sender != identityRegistry.ownerOf(agentId), "Owner cannot review");
        uint256 lastTime = _lastReviewTime[msg.sender][agentId];
        if (lastTime != 0) {
            require(block.timestamp - lastTime >= REVIEW_COOLDOWN, "24h cooldown");
        }
        
        uint256 idx = _lastIndex[msg.sender][agentId]++;
        _feedbacks[agentId][msg.sender].push(Feedback(value, 0, tag1, "", false, block.timestamp));
        _clients[agentId].push(msg.sender);
        _lastReviewTime[msg.sender][agentId] = block.timestamp;
        emit NewFeedback(agentId, msg.sender, idx, value, tag1);
    }
    
    /**
     * @notice Revoke feedback
     */
    function revokeFeedback(uint256 agentId, uint256 idx) external {
        Feedback[] storage fbs = _feedbacks[agentId][msg.sender];
        require(fbs.length > idx, "Not found");
        require(!fbs[idx].isRevoked, "Revoked");
        fbs[idx].isRevoked = true;
        emit FeedbackRevoked(agentId, msg.sender, idx);
    }
    
    /**
     * @notice Append response
     */
    function appendResponse(uint256 agentId, address client, uint256 idx) external {
        require(_feedbacks[agentId][client].length > idx, "Not found");
        emit ResponseAppended(agentId, client, idx);
    }
    
    /**
     * @notice Get summary
     */
    function getSummary(uint256 agentId, address[] calldata clients) external view returns (uint256 count, int128 avg) {
        uint256 total; uint256 w;
        for (uint256 i = 0; i < clients.length; i++) {
            Feedback[] storage fbs = _feedbacks[agentId][clients[i]];
            for (uint256 j = 0; j < fbs.length; j++) {
                if (!fbs[j].isRevoked) {
                    uint256 stake = reviewerStake[clients[i]] > 0 ? reviewerStake[clients[i]] : 1;
                    if (fbs[j].value >= 0) total += uint256(int256(fbs[j].value)) * stake;
                    w += stake;
                    count++;
                }
            }
        }
        if (w > 0) avg = int128(int256(total / w));
    }
    
    /**
     * @notice Read single feedback
     */
    function readFeedback(uint256 agentId, address clientAddress, uint256 feedbackIndex) 
        external view returns (int128 value, uint8 decimals, string memory tag1, string memory tag2, bool revoked) 
    {
        Feedback[] storage fbs = _feedbacks[agentId][clientAddress];
        require(fbs.length > feedbackIndex, "Not found");
        Feedback storage fb = fbs[feedbackIndex];
        return (fb.value, fb.valueDecimals, fb.tag1, fb.tag2, fb.isRevoked);
    }
    
    /**
     * @notice Get clients
     */
    function getClients(uint256 agentId) external view returns (address[] memory) {
        return _clients[agentId];
    }
    
    /**
     * @notice Get last index
     */
    function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint256) {
        return _lastIndex[clientAddress][agentId];
    }
    
    /**
     * @notice Get feedback count
     */
    function getFeedbackCount(uint256 agentId, address clientAddress) external view returns (uint256) {
        return _feedbacks[agentId][clientAddress].length;
    }
    
    /**
     * @notice Set reviewer stake
     */
    function setReviewerStake(address reviewer, uint256 stake) external onlyOwner {
        reviewerStake[reviewer] = stake;
    }
}
