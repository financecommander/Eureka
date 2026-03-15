// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISettlementVerificationRegistry.sol";
import "./interfaces/IAttorneyVerificationNode.sol";
import "./interfaces/ISettlementAnchor.sol";

contract SettlementVerificationRegistry is ISettlementVerificationRegistry {
    mapping(bytes32 => Settlement) public settlements;
    mapping(address => bool) public registeredAnchors;
    mapping(address => bool) public registeredAttorneys;
    
    address public owner;
    
    event SettlementRegistered(bytes32 indexed settlementId, address anchor);
    event VerificationUpdated(bytes32 indexed settlementId, VerificationStatus status);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyRegisteredAnchor() {
        require(registeredAnchors[msg.sender], "Not registered anchor");
        _;
    }
    
    function registerAnchor(address anchor) external onlyOwner {
        registeredAnchors[anchor] = true;
    }
    
    function registerAttorney(address attorney) external onlyOwner {
        registeredAttorneys[attorney] = true;
    }
    
    function registerSettlement(
        bytes32 settlementId,
        address anchor,
        bytes calldata metadata
    ) external onlyRegisteredAnchor {
        require(settlements[settlementId].status == VerificationStatus.NONE, "Settlement already exists");
        settlements[settlementId] = Settlement({
            anchor: anchor,
            status: VerificationStatus.REGISTERED,
            metadata: metadata,
            timestamp: block.timestamp
        });
        emit SettlementRegistered(settlementId, anchor);
    }
    
    function updateVerificationStatus(
        bytes32 settlementId,
        VerificationStatus status
    ) external onlyRegisteredAnchor {
        require(settlements[settlementId].status != VerificationStatus.NONE, "Settlement not found");
        settlements[settlementId].status = status;
        settlements[settlementId].timestamp = block.timestamp;
        emit VerificationUpdated(settlementId, status);
    }
}
