// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ReputationRegistry} from "../src/ReputationRegistry.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";

contract ReputationRegistryTest is Test {
    ReputationRegistry public repRegistry;
    IdentityRegistry public identityRegistry;
    address public agentOwner = address(1);
    address public reviewer = address(2);
    address public owner = address(3);
    uint256 public agentId;
    
    function setUp() public {
        identityRegistry = new IdentityRegistry("AgentRegistry", "AGENT", "eip155");
        repRegistry = new ReputationRegistry(address(identityRegistry), owner);
        vm.prank(agentOwner);
        agentId = identityRegistry.register("ipfs://QmTest");
        // Don't give feedback in setUp - let tests do it
    }
    
    function test_GiveFeedback() public {
        int128 value = 80;
        string memory tag1 = "quality";
        
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, value, tag1);
        
        (int128 v, uint8 d, string memory t1, string memory t2, bool revoked) = repRegistry.readFeedback(agentId, reviewer, 0);
        assertEq(v, value, "Value should match");
        assertEq(t1, tag1, "Tag1 should match");
        assertEq(revoked, false, "Should not be revoked");
    }
    
    function test_GiveFeedback_RevertsWithOwner() public {
        vm.expectRevert("Owner cannot review");
        vm.prank(agentOwner);
        repRegistry.giveFeedback(agentId, 80, "quality");
    }
    
    function test_GiveFeedback_RevertsWithCooldown() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        vm.expectRevert("24h cooldown");
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 90, "quality");
    }
    
    function test_RevokeFeedback() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        vm.prank(reviewer);
        repRegistry.revokeFeedback(agentId, 0);
        
        (int128 v, uint8 d, string memory t1, string memory t2, bool revoked) = repRegistry.readFeedback(agentId, reviewer, 0);
        assertEq(revoked, true, "Should be revoked");
    }
    
    function test_AppendResponse() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        repRegistry.appendResponse(agentId, reviewer, 0);
    }
    
    function test_GetSummary() public {
        address[] memory clients = new address[](1);
        clients[0] = reviewer;
        
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        (uint256 count, int128 avg) = repRegistry.getSummary(agentId, clients);
        assertEq(count, 1, "Count should be 1");
        assertEq(avg, 80, "Average should be 80");
    }
    
    function test_GetClients() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        address[] memory clients = repRegistry.getClients(agentId);
        assertEq(clients.length, 1, "Should have 1 client");
        assertEq(clients[0], reviewer, "Client should be reviewer");
    }
    
    function test_GetLastIndex() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        uint256 idx = repRegistry.getLastIndex(agentId, reviewer);
        assertEq(idx, 1, "Index should be 1");
    }
    
    function test_SetReviewerStake() public {
        vm.prank(owner);
        repRegistry.setReviewerStake(reviewer, 100);
        
        assertEq(repRegistry.reviewerStake(reviewer), 100, "Stake should be set");
    }
    
    function test_GetFeedbackCount() public {
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 80, "quality");
        
        vm.warp(block.timestamp + 24 hours + 1);
        
        vm.prank(reviewer);
        repRegistry.giveFeedback(agentId, 90, "quality");
        
        uint256 count = repRegistry.getFeedbackCount(agentId, reviewer);
        assertEq(count, 2, "Should have 2 feedbacks");
    }
}
