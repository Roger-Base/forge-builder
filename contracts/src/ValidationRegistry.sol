// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IdentityRegistry.sol";

/**
 * @title ValidationRegistry
 * @author Roger (Autonomous Research Agent)
 * @notice ERC-8004 compliant validation registry for AI agents
 * @dev Enables agents to request verification of their work
 * 
 * ERC-8004 Specification: https://eips.ethereum.org/EIPS/eip-8004
 * 
 * Supports: stake-secured re-execution, zkML verifiers, TEE oracles
 */
contract ValidationRegistry is Ownable, ReentrancyGuard {
    
    IdentityRegistry public identityRegistry;
    
    // ERC-8004: Validation request structure
    struct ValidationRequest {
        address validatorAddress;
        uint256 agentId;
        string requestURI;
        bytes32 requestHash;
        uint8 response; // 0-100 (0=failed, 100=passed)
        string responseURI;
        bytes32 responseHash;
        string tag;
        uint256 lastUpdate;
        bool exists;
    }
    
    // ERC-8004: Storage mappings
    mapping(bytes32 => ValidationRequest) private _requests;
    mapping(uint256 => bytes32[]) private _agentRequests;
    mapping(address => bytes32[]) private _validatorRequests;
    
    event ValidationRequested(
        address indexed validatorAddress,
        uint256 indexed agentId,
        string requestURI,
        bytes32 indexed requestHash,
        uint256 timestamp
    );
    
    event ValidationResponse(
        address indexed validatorAddress,
        uint256 indexed agentId,
        bytes32 indexed requestHash,
        uint8 response,
        string responseURI,
        bytes32 responseHash,
        string tag,
        uint256 timestamp
    );
    
    /**
     * @notice Constructor
     * @param identityRegistry_ IdentityRegistry contract address
     */
    constructor(
        address identityRegistry_,
        address initialOwner
    ) Ownable(initialOwner) {
        identityRegistry = IdentityRegistry(identityRegistry_);
    }
    
    /**
     * @notice ERC-8004: Request validation
     * @param validatorAddress Validator contract address
     * @param agentId Agent ID
     * @param requestURI Off-chain request data URI
     * @param requestHash KECCAK-256 hash of request data
     */
    function validationRequest(
        address validatorAddress,
        uint256 agentId,
        string calldata requestURI,
        bytes32 requestHash
    ) external nonReentrant {
        require(
            identityRegistry.ownerOf(agentId) != address(0),
            "Agent does not exist"
        );
        require(
            msg.sender == identityRegistry.ownerOf(agentId) ||
            identityRegistry.isApprovedForAll(identityRegistry.ownerOf(agentId), msg.sender) ||
            identityRegistry.getApproved(agentId) == msg.sender,
            "Not authorized"
        );
        require(validatorAddress != address(0), "Invalid validator");
        
        // Store request
        _requests[requestHash] = ValidationRequest({
            validatorAddress: validatorAddress,
            agentId: agentId,
            requestURI: requestURI,
            requestHash: requestHash,
            response: 0,
            responseURI: "",
            responseHash: bytes32(0),
            tag: "",
            lastUpdate: 0,
            exists: true
        });
        
        // Track agent requests
        _agentRequests[agentId].push(requestHash);
        
        // Track validator requests
        _validatorRequests[validatorAddress].push(requestHash);
        
        emit ValidationRequested(
            validatorAddress,
            agentId,
            requestURI,
            requestHash,
            block.timestamp
        );
    }
    
    /**
     * @notice ERC-8004: Submit validation response
     * @param requestHash Request hash
     * @param response Response value (0-100)
     * @param responseURI Off-chain response data URI
     * @param responseHash KECCAK-256 hash of response data
     * @param tag Optional categorization
     */
    function validationResponse(
        bytes32 requestHash,
        uint8 response,
        string calldata responseURI,
        bytes32 responseHash,
        string calldata tag
    ) external {
        require(_requests[requestHash].exists, "Request not found");
        require(
            msg.sender == _requests[requestHash].validatorAddress,
            "Only validator"
        );
        require(response <= 100, "Response must be 0-100");
        
        // Update request
        ValidationRequest storage req = _requests[requestHash];
        req.response = response;
        req.responseURI = responseURI;
        req.responseHash = responseHash;
        req.tag = tag;
        req.lastUpdate = block.timestamp;
        
        emit ValidationResponse(
            req.validatorAddress,
            req.agentId,
            requestHash,
            response,
            responseURI,
            responseHash,
            tag,
            block.timestamp
        );
    }
    
    /**
     * @notice ERC-8004: Get validation status
     * @param requestHash Request hash
     * @return validatorAddress Validator address
     * @return agentId Agent ID
     * @return response Response value (0-100)
     * @return responseHash Response hash
     * @return tag Tag
     * @return lastUpdate Last update timestamp
     */
    function getValidationStatus(bytes32 requestHash) 
        external 
        view 
        returns (
            address validatorAddress,
            uint256 agentId,
            uint8 response,
            bytes32 responseHash,
            string memory tag,
            uint256 lastUpdate
        ) 
    {
        require(_requests[requestHash].exists, "Request not found");
        
        ValidationRequest storage req = _requests[requestHash];
        return (
            req.validatorAddress,
            req.agentId,
            req.response,
            req.responseHash,
            req.tag,
            req.lastUpdate
        );
    }
    
    /**
     * @notice ERC-8004: Get summary statistics for agent
     * @param agentId Agent ID
     * @param validatorAddresses Filter by validators
     * @param tag Filter by tag
     * @return count Request count
     * @return averageResponse Average response value (0-100)
     */
    function getSummary(
        uint256 agentId,
        address[] calldata validatorAddresses,
        string calldata tag
    ) 
        external 
        view 
        returns (
            uint64 count,
            uint8 averageResponse
        ) 
    {
        bytes32[] storage requests = _agentRequests[agentId];
        uint256 totalResponse = 0;
        uint256 validCount = 0;
        
        for (uint256 i = 0; i < requests.length; i++) {
            ValidationRequest storage req = _requests[requests[i]];
            
            if (req.exists && req.lastUpdate > 0) {
                bool validatorMatch = validatorAddresses.length == 0;
                bool tagMatch = bytes(tag).length == 0;
                
                for (uint256 j = 0; j < validatorAddresses.length; j++) {
                    if (req.validatorAddress == validatorAddresses[j]) {
                        validatorMatch = true;
                        break;
                    }
                }
                
                if (bytes(req.tag).length == 0 || keccak256(bytes(req.tag)) == keccak256(bytes(tag))) {
                    tagMatch = true;
                }
                
                if (validatorMatch && tagMatch) {
                    totalResponse += req.response;
                    validCount++;
                    count++;
                }
            }
        }
        
        if (validCount > 0) {
            averageResponse = uint8(totalResponse / validCount);
        }
    }
    
    /**
     * @notice ERC-8004: Get all validation requests for agent
     * @param agentId Agent ID
     * @return Request hashes
     */
    function getAgentValidations(uint256 agentId) 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return _agentRequests[agentId];
    }
    
    /**
     * @notice ERC-8004: Get all requests for validator
     * @param validatorAddress Validator address
     * @return Request hashes
     */
    function getValidatorRequests(address validatorAddress) 
        external 
        view 
        returns (bytes32[] memory) 
    {
        return _validatorRequests[validatorAddress];
    }
    
    /**
     * @notice Get request details
     * @param requestHash Request hash
     * @return ValidationRequest struct
     */
    function getRequest(bytes32 requestHash) 
        external 
        view 
        returns (ValidationRequest memory) 
    {
        require(_requests[requestHash].exists, "Request not found");
        return _requests[requestHash];
    }
    
    /**
     * @notice Get total requests for agent
     * @param agentId Agent ID
     * @return Count
     */
    function getTotalRequests(uint256 agentId) 
        external 
        view 
        returns (uint256) 
    {
        return _agentRequests[agentId].length;
    }
    
    /**
     * @notice Get total requests for validator
     * @param validatorAddress Validator address
     * @return Count
     */
    function getTotalValidatorRequests(address validatorAddress) 
        external 
        view 
        returns (uint256) 
    {
        return _validatorRequests[validatorAddress].length;
    }
}
