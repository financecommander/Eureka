// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAttorneyVerificationNode.sol";
import "./interfaces/ISettlementVerificationRegistry.sol";

contract AttorneyVerificationNode is IAttorneyVerificationNode {
    ISettlementVerificationRegistry public registry;
    mapping(address => Attorney) public attorneys;
    mapping(bytes32 => bytes) public settlementSignatures;
    
    event AttorneyRegistered(address indexed attorney, bytes credentialHash);
    event SettlementSigned(bytes32 indexed settlementId, address indexed attorney);
    
    constructor(address _registry) {
        registry = ISettlementVerificationRegistry(_registry);
    }
    
    modifier onlyRegisteredAttorney() {
        require(registry.registeredAttorneys(msg.sender), "Not registered attorney");
        _;
    }
    
    function registerAttorney(bytes calldata credentialHash) external {
        require(!attorneys[msg.sender].isRegistered, "Attorney already registered");
        attorneys[msg.sender] = Attorney({
            isRegistered: true,
            credentialHash: credentialHash,
            registrationTimestamp: block.timestamp
        });
        emit AttorneyRegistered(msg.sender, credentialHash);
    }
    
    function signSettlement(bytes32 settlementId, bytes calldata signature) external onlyRegisteredAttorney {
        require(registry.settlements(settlementId).status != VerificationStatus.NONE, "Settlement not found");
        settlementSignatures[settlementId] = signature;
        emit SettlementSigned(settlementId, msg.sender);
    }
    
    function verifySignature(bytes32 settlementId, address attorney) external view returns (bool) {
        return attorneys[attorney].isRegistered && settlementSignatures[settlementId].length > 0;
    }
}
