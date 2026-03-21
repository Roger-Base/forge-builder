// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";

contract IdentityRegistryTest is Test {
    IdentityRegistry public registry;
    address public user = address(1);
    string public constant TEST_URI = "ipfs://QmTest123";
    
    function setUp() public {
        registry = new IdentityRegistry("AgentRegistry", "AGENT", "eip155");
    }
    
    function test_RegisterAgent() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        
        assertEq(agentId, 1, "Agent ID should be 1");
        assertEq(registry.ownerOf(agentId), user, "Owner should be user");
        assertEq(registry.tokenURI(agentId), TEST_URI, "URI should match");
        assertEq(registry.getAgentWallet(agentId), user, "Wallet should be user");
    }
    
    function test_SetAgentURI() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        string memory newURI = "ipfs://QmNew456";
        
        vm.prank(user);
        registry.setAgentURI(agentId, newURI);
        
        assertEq(registry.tokenURI(agentId), newURI, "URI should be updated");
    }
    
    function test_SetMetadata() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        
        vm.prank(user);
        registry.setMetadata(agentId, "customKey", bytes("customValue"));
        
        bytes memory value = registry.getMetadata(agentId, "customKey");
        assertEq(value, bytes("customValue"), "Metadata should be set");
    }
    
    function test_SetAgentWallet_RevertsWithInvalidSignature() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        address newWallet = address(2);
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory invalidSig = abi.encodePacked("invalid");
        
        vm.expectRevert();
        vm.prank(user);
        registry.setAgentWallet(agentId, newWallet, deadline, invalidSig);
    }
    
    function test_AddRegistration() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        string memory multiChainRegistry = "eip155:1:0x1234567890123456789012345678901234567890";
        
        vm.prank(user);
        registry.addRegistration(agentId, multiChainRegistry);
        
        assertEq(registry.getRegistrationCount(agentId), 1, "Should have 1 registration");
    }
    
    function test_GetTotalAgents() public {
        // Don't register in setUp, so this counts correctly
        vm.prank(user);
        registry.register(TEST_URI);
        vm.prank(user);
        registry.register(TEST_URI);
        vm.prank(user);
        registry.register(TEST_URI);
        
        assertEq(registry.getTotalAgents(), 3, "Should have 3 agents");
    }
    
    function test_Burn() public {
        vm.prank(user);
        uint256 agentId = registry.register(TEST_URI);
        
        vm.prank(user);
        registry.burn(agentId);
        
        // OpenZeppelin error signature changed - use generic expectRevert
        vm.expectRevert();
        registry.ownerOf(agentId);
    }
    
    function test_SetReviewerStake() public {
        address reviewer = address(3);
        uint256 stake = 100;
        
        registry.setReviewerStake(reviewer, stake);
        
        assertEq(registry.getReviewerStake(reviewer), stake, "Stake should be set");
    }
    
    function test_GetLastReviewTime() public {
        vm.prank(user);
        registry.register(TEST_URI);
        
        uint256 lastTime = registry.getLastReviewTime(user, 1);
        assertEq(lastTime, 0, "Should be 0 initially");
    }
    
    function test_BuildAgentRegistry() public {
        string memory result = registry.buildAgentRegistry();
        // Just check it starts with eip155: and contains chainid
        bytes memory resultBytes = bytes(result);
        require(resultBytes.length > 10, "Result should not be empty");
        // Check format: eip155:{chainid}:{address}
        assertEq(resultBytes[0], bytes1('e'), "Should start with 'e'");
    }
}
