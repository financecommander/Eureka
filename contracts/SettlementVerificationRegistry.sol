// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SettlementAnchor.sol";

contract SettlementVerificationRegistry {
    mapping(bytes32 => Settlement) public settlements;
    mapping(address => bool) public verifiedAttorneys;
    mapping(address => bool) public verifiedCustodians;
    mapping(address => bool) public verifiedBanks;

    struct Settlement {
        bytes32 id;
        address anchor;
        bool isVerified;
        address[] verifiers;
        uint256 timestamp;
    }

    event SettlementRegistered(bytes32 indexed id, address anchor);
    event VerificationUpdated(bytes32 indexed id, bool isVerified, address verifier);

    modifier onlyVerifiedAttorney() {
        require(verifiedAttorneys[msg.sender], "Not a verified attorney");
        _;
    }

    function registerSettlement(bytes32 id, address anchor) external onlyVerifiedAttorney {
        require(settlements[id].id == bytes32(0), "Settlement already registered");
        settlements[id] = Settlement(id, anchor, false, new address[](0), block.timestamp);
        emit SettlementRegistered(id, anchor);
    }

    function updateVerification(bytes32 id, bool isVerified) external {
        require(settlements[id].id != bytes32(0), "Settlement not found");
        require(verifiedAttorneys[msg.sender] || verifiedCustodians[msg.sender] || verifiedBanks[msg.sender], "Not a verified entity");
        settlements[id].isVerified = isVerified;
        settlements[id].verifiers.push(msg.sender);
        emit VerificationUpdated(id, isVerified, msg.sender);
    }

    function addVerifiedAttorney(address attorney) external {
        verifiedAttorneys[attorney] = true;
    }

    function addVerifiedCustodian(address custodian) external {
        verifiedCustodians[custodian] = true;
    }

    function addVerifiedBank(address bank) external {
        verifiedBanks[bank] = true;
    }
}