// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title IdentityRegistry
 * @author Roger (Autonomous Research Agent)
 * @notice ERC-8004 compliant identity registry for AI agents
 * @dev ERC-721 based agent registration with ERC-8004 standard alignment
 * 
 * ERC-8004 Specification: https://eips.ethereum.org/EIPS/eip-8004
 */
contract IdentityRegistry is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard, EIP712 {
    
    using ECDSA for bytes32;
    
    uint256 private _nextAgentId;
    
    // ERC-8004: agentRegistry format = namespace:chainId:registryAddress
    string public namespace;
    uint256 public chainId;
    address public identityRegistry;
    
    // ERC-8004: Agent Registration structure
    struct AgentRegistration {
        uint256 agentId;
        string agentRegistry; // e.g., "eip155:8453:0x..."
        string agentURI;
        bool active;
        bool x402Support;
        string[] services; // MCP, A2A, web, x402, ENS, DID
        string[] supportedTrust; // reputation, validation, tee-attestation
        address agentWallet;
        uint256 registeredAt;
    }
    
    // ERC-8004: On-chain metadata
    mapping(uint256 => mapping(string => bytes)) private _agentMetadata;
    
    // ERC-8004: Multi-chain registrations
    mapping(uint256 => AgentRegistration[]) private _agentRegistrations;
    
    // ERC-8004: Reserved wallet key
    mapping(uint256 => address) private _agentWallets;
    
    // ERC-8004: Wallet verification signatures (nonces)
    mapping(address => uint256) private _walletNonces;
    
    // My novel: 1 review per 24h tracking
    mapping(address => mapping(uint256 => uint256)) private _lastReviewTime;
    
    // My novel: Reviewer stake weight
    mapping(address => uint256) private _reviewerStake;
    
    event Registered(
        uint256 indexed agentId,
        string agentURI,
        address indexed owner,
        uint256 timestamp
    );
    
    event URIUpdated(
        uint256 indexed agentId,
        string newURI,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    event MetadataSet(
        uint256 indexed agentId,
        string indexed indexedMetadataKey,
        string metadataKey,
        bytes metadataValue,
        uint256 timestamp
    );
    
    event AgentWalletSet(
        uint256 indexed agentId,
        address indexed newWallet,
        address indexed owner,
        uint256 timestamp
    );
    
    event AgentWalletCleared(
        uint256 indexed agentId,
        uint256 timestamp
    );
    
    event RegistrationAdded(
        uint256 indexed agentId,
        string agentRegistry,
        uint256 registrationIndex,
        uint256 timestamp
    );
    
    /**
     * @notice Constructor
     * @param name ERC-721 name
     * @param symbol ERC-721 symbol
     * @param namespace_ ERC-8004 namespace (e.g., "eip155")
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory namespace_
    ) ERC721(name, symbol) Ownable(msg.sender) EIP712(name, "1") {
        namespace = namespace_;
        chainId = block.chainid;
        identityRegistry = address(this);
        _nextAgentId = 1;
    }
    
    /**
     * @notice ERC-8004: Register new agent
     * @param agentURI Agent registration file URI (IPFS, HTTPS, or data:)
     * @return agentId New agent ID
     */
    function register(string memory agentURI) 
        external 
        nonReentrant 
        returns (uint256) 
    {
        uint256 agentId = _nextAgentId++;
        
        // ERC-8004: Mint ERC-721 token
        _safeMint(msg.sender, agentId);
        
        // ERC-8004: Set initial URI
        _setTokenURI(agentId, agentURI);
        
        // ERC-8004: Initialize wallet to owner
        _agentWallets[agentId] = msg.sender;
        
        // ERC-8004: Emit Registered event
        emit Registered(agentId, agentURI, msg.sender, block.timestamp);
        
        // ERC-8004: Set reserved agentWallet metadata
        _setMetadata(agentId, "agentWallet", abi.encodePacked(msg.sender));
        
        return agentId;
    }
    
    /**
     * @notice ERC-8004: Register with metadata
     * @param agentURI Agent registration file URI
     * @param metadata Additional on-chain metadata
     * @return agentId New agent ID
     */
    function registerWithMetadata(
        string memory agentURI,
        MetadataEntry[] calldata metadata
    ) external nonReentrant returns (uint256) {
        uint256 agentId = _nextAgentId++;
        
        // Mint ERC-721 token
        _safeMint(msg.sender, agentId);
        
        // Set initial URI
        _setTokenURI(agentId, agentURI);
        
        // Initialize wallet to owner
        _agentWallets[agentId] = msg.sender;
        
        // Emit Registered event
        emit Registered(agentId, agentURI, msg.sender, block.timestamp);
        
        // Set reserved agentWallet metadata
        _setMetadata(agentId, "agentWallet", abi.encodePacked(msg.sender));
        
        // Set additional metadata
        for (uint256 i = 0; i < metadata.length; i++) {
            _setMetadata(agentId, metadata[i].metadataKey, metadata[i].metadataValue);
        }
        
        return agentId;
    }
    
    struct MetadataEntry {
        string metadataKey;
        bytes metadataValue;
    }
    
    /**
     * @notice ERC-8004: Update agent URI
     * @param agentId Agent ID
     * @param newURI New URI
     */
    function setAgentURI(uint256 agentId, string calldata newURI) 
        external 
    {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        
        _setTokenURI(agentId, newURI);
        
        emit URIUpdated(agentId, newURI, msg.sender, block.timestamp);
    }
    
    /**
     * @notice ERC-8004: Get metadata
     * @param agentId Agent ID
     * @param metadataKey Metadata key
     * @return Metadata value
     */
    function getMetadata(uint256 agentId, string memory metadataKey) 
        external 
        view 
        returns (bytes memory) 
    {
        return _agentMetadata[agentId][metadataKey];
    }
    
    /**
     * @notice ERC-8004: Set metadata
     * @param agentId Agent ID
     * @param metadataKey Metadata key
     * @param metadataValue Metadata value
     */
    function setMetadata(
        uint256 agentId,
        string memory metadataKey,
        bytes memory metadataValue
    ) external {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        
        // ERC-8004: agentWallet is reserved, must use setAgentWallet
        require(
            keccak256(bytes(metadataKey)) != keccak256(bytes("agentWallet")),
            "Use setAgentWallet"
        );
        
        _setMetadata(agentId, metadataKey, metadataValue);
    }
    
    /**
     * @notice Internal: Set metadata
     */
    function _setMetadata(
        uint256 agentId,
        string memory metadataKey,
        bytes memory metadataValue
    ) internal {
        _agentMetadata[agentId][metadataKey] = metadataValue;
        
        emit MetadataSet(
            agentId,
            metadataKey,
            metadataKey,
            metadataValue,
            block.timestamp
        );
    }
    
    /**
     * @notice ERC-8004: Set agent wallet with EIP-712 signature
     * @param agentId Agent ID
     * @param newWallet New wallet address
     * @param deadline Signature deadline
     * @param signature EIP-712 signature
     */
    function setAgentWallet(
        uint256 agentId,
        address newWallet,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        require(block.timestamp <= deadline, "Signature expired");
        
        // ERC-8004: Verify EIP-712 signature
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("SetAgentWallet(uint256 agentId,address newWallet,uint256 nonce)"),
                    agentId,
                    newWallet,
                    _walletNonces[msg.sender]
                )
            )
        );
        
        address signer = digest.recover(signature);
        require(signer == msg.sender, "Invalid signature");
        
        // Increment nonce
        _walletNonces[msg.sender]++;
        
        // Set new wallet
        _agentWallets[agentId] = newWallet;
        
        // Update metadata
        _setMetadata(agentId, "agentWallet", abi.encodePacked(newWallet));
        
        emit AgentWalletSet(agentId, newWallet, msg.sender, block.timestamp);
    }
    
    /**
     * @notice ERC-8004: Get agent wallet
     * @param agentId Agent ID
     * @return Wallet address
     */
    function getAgentWallet(uint256 agentId) 
        external 
        view 
        returns (address) 
    {
        return _agentWallets[agentId];
    }
    
    /**
     * @notice ERC-8004: Clear agent wallet
     * @param agentId Agent ID
     */
    function unsetAgentWallet(uint256 agentId) external {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        
        delete _agentWallets[agentId];
        delete _agentMetadata[agentId]["agentWallet"];
        
        emit AgentWalletCleared(agentId, block.timestamp);
    }
    
    /**
     * @notice ERC-8004: Add multi-chain registration
     * @param agentId Agent ID
     * @param agentRegistry Registry format (e.g., "eip155:1:0x...")
     */
    function addRegistration(
        uint256 agentId,
        string calldata agentRegistry
    ) external {
        require(ownerOf(agentId) != address(0), "Agent does not exist");
        require(ownerOf(agentId) == msg.sender, "Not owner");
        
        uint256 index = _agentRegistrations[agentId].length;
        
        _agentRegistrations[agentId].push(
            AgentRegistration({
                agentId: agentId,
                agentRegistry: agentRegistry,
                agentURI: tokenURI(agentId),
                active: true,
                x402Support: false,
                services: new string[](0),
                supportedTrust: new string[](0),
                agentWallet: _agentWallets[agentId],
                registeredAt: block.timestamp
            })
        );
        
        emit RegistrationAdded(agentId, agentRegistry, index, block.timestamp);
    }
    
    /**
     * @notice ERC-8004: Get registration count
     * @param agentId Agent ID
     * @return Count
     */
    function getRegistrationCount(uint256 agentId) 
        external 
        view 
        returns (uint256) 
    {
        return _agentRegistrations[agentId].length;
    }
    
    /**
     * @notice ERC-8004: Get registration
     * @param agentId Agent ID
     * @param index Registration index
     * @return Registration struct
     */
    function getRegistration(uint256 agentId, uint256 index) 
        external 
        view 
        returns (AgentRegistration memory) 
    {
        require(
            index < _agentRegistrations[agentId].length,
            "Index out of bounds"
        );
        return _agentRegistrations[agentId][index];
    }
    
    /**
     * @notice My novel: Set reviewer stake weight (owner only)
     * @param reviewer Address
     * @param stake Stake amount
     */
    function setReviewerStake(address reviewer, uint256 stake) 
        external 
        onlyOwner 
    {
        _reviewerStake[reviewer] = stake;
    }
    
    /**
     * @notice My novel: Get reviewer stake
     * @param reviewer Address
     * @return Stake amount
     */
    function getReviewerStake(address reviewer) 
        external 
        view 
        returns (uint256) 
    {
        return _reviewerStake[reviewer];
    }
    
    /**
     * @notice My novel: Get last review time
     * @param reviewer Address
     * @param agentId Agent ID
     * @return Timestamp
     */
    function getLastReviewTime(address reviewer, uint256 agentId) 
        external 
        view 
        returns (uint256) 
    {
        return _lastReviewTime[reviewer][agentId];
    }
    
    /**
     * @notice Get total agents
     * @return Count
     */
    function getTotalAgents() external view returns (uint256) {
        return _nextAgentId;
    }
    
    /**
     * @notice ERC-8004: Build agentRegistry string
     * @return Format: namespace:chainId:registryAddress
     */
    function buildAgentRegistry() 
        external 
        view 
        returns (string memory) 
    {
        return string.concat(
            namespace,
            ":",
            Strings.toString(chainId),
            ":",
            vmToString(address(this))
        );
    }
    
    /**
     * @notice Internal: Convert address to string
     */
    function vmToString(address addr) internal pure returns (string memory) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            b[i] = bytes1(uint8(uint160(addr) / (2 ** (8 * (19 - i)))));
        }
        return string(b);
    }
    
    /**
     * @notice Override supportsInterface
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @notice Override tokenURI
     */
    function tokenURI(uint256 tokenId)
        public 
        view 
        override(ERC721, ERC721URIStorage)
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
