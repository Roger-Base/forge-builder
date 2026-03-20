// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ValidationRegistry} from "../src/ValidationRegistry.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";

contract ValidationRegistryTest is Test {
    ValidationRegistry public valRegistry;
    IdentityRegistry public identityRegistry;
    address public user = address(1);
    address public validator = address(2);
    address public owner = address(3);
    uint256 public agentId;
    bytes32 public requestHash = keccak256("test-request");
    
    function setUp() public {
        identityRegistry = new IdentityRegistry("AgentRegistry", "AGENT", "eip155");
        valRegistry = new ValidationRegistry(address(identityRegistry), owner);
        vm.prank(user);
        agentId = identityRegistry.register("ipfs://QmTest");
    }
    
    function test_ValidationRequest() public {
        string memory requestURI = "ipfs://QmRequest";
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
        vm.stopPrank();
        
        (address v, uint256 aId, uint8 response, bytes32 rHash, string memory tag, uint256 lastUpdate) = valRegistry.getValidationStatus(requestHash);
        
        assertEq(v, validator, "Validator should match");
        assertEq(aId, agentId, "Agent ID should match");
        assertEq(response, 0, "Response should be 0 initially");
        assertEq(lastUpdate, 0, "Last update should be 0");
    }
    
    function test_ValidationResponse() public {
        string memory requestURI = "ipfs://QmRequest";
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
        vm.stopPrank();
        
        uint8 response = 100;
        string memory responseURI = "ipfs://QmResponse";
        bytes32 responseHash = keccak256("response");
        string memory tag = "verified";
        
        vm.prank(validator);
        valRegistry.validationResponse(requestHash, response, responseURI, responseHash, tag);
        
        (,, uint8 r, bytes32 rH, string memory t, uint256 lastUpdate) = valRegistry.getValidationStatus(requestHash);
        
        assertEq(r, response, "Response should match");
        assertEq(t, tag, "Tag should match");
        assertTrue(lastUpdate > 0, "Last update should be set");
    }
    
    function test_ValidationResponse_RevertsWithoutRequest() public {
        vm.expectRevert("Request not found");
        vm.prank(validator);
        valRegistry.validationResponse(requestHash, 100, "ipfs://QmResponse", keccak256("response"), "verified");
    }
    
    function test_ValidationResponse_RevertsWithInvalidValidator() public {
        string memory requestURI = "ipfs://QmRequest";
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
        vm.stopPrank();
        
        vm.expectRevert("Only validator");
        vm.prank(address(3));
        valRegistry.validationResponse(requestHash, 100, "ipfs://QmResponse", keccak256("response"), "verified");
    }
    
    function test_GetAgentValidations() public {
        bytes32 hash1 = keccak256("request1");
        bytes32 hash2 = keccak256("request2");
        
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest1", hash1);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest2", hash2);
        vm.stopPrank();
        
        bytes32[] memory requests = valRegistry.getAgentValidations(agentId);
        assertEq(requests.length, 2, "Should have 2 requests");
    }
    
    function test_GetValidatorRequests() public {
        bytes32 hash1 = keccak256("request1");
        bytes32 hash2 = keccak256("request2");
        
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest1", hash1);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest2", hash2);
        vm.stopPrank();
        
        bytes32[] memory requests = valRegistry.getValidatorRequests(validator);
        assertEq(requests.length, 2, "Should have 2 requests");
    }
    
    function test_GetSummary() public {
        address[] memory validators = new address[](1);
        validators[0] = validator;
        
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest", requestHash);
        vm.stopPrank();
        
        vm.prank(validator);
        valRegistry.validationResponse(requestHash, 100, "ipfs://QmResponse", keccak256("response"), "verified");
        
        (uint64 count, uint8 avgResponse) = valRegistry.getSummary(agentId, validators, "verified");
        
        assertEq(count, 1, "Count should be 1");
        assertEq(avgResponse, 100, "Average response should be 100");
    }
    
    function test_GetTotalRequests() public {
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest1", keccak256("hash1"));
        valRegistry.validationRequest(validator, agentId, "ipfs://QmRequest2", keccak256("hash2"));
        vm.stopPrank();
        
        uint256 total = valRegistry.getTotalRequests(agentId);
        assertEq(total, 2, "Should have 2 requests");
    }
    
    function test_GetRequest() public {
        string memory requestURI = "ipfs://QmRequest";
        vm.startPrank(user);
        valRegistry.validationRequest(validator, agentId, requestURI, requestHash);
        vm.stopPrank();
        
        ValidationRegistry.ValidationRequest memory req = valRegistry.getRequest(requestHash);
        
        assertEq(req.validatorAddress, validator, "Validator should match");
        assertEq(req.agentId, agentId, "Agent ID should match");
        assertEq(req.requestURI, requestURI, "Request URI should match");
        assertEq(req.exists, true, "Should exist");
    }
}
