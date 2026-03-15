// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SettlementAnchor.sol';

contract SettlementVerificationRegistry {
    mapping(bytes32 => Settlement) public settlements;
    mapping(address => bool) public authorizedNodes;

    struct Settlement {
        bytes32 id;
        address anchor;
        uint256 timestamp;
        bool isVerified;
        mapping(address => bool) nodeVerifications;
    }

    event SettlementRegistered(bytes32 indexed id, address anchor);
    event VerificationUpdated(bytes32 indexed id, address node, bool verified);

    modifier onlyAuthorizedNode() {
        require(authorizedNodes[msg.sender], 'Unauthorized node');
        _;
    }

    constructor() {
        authorizedNodes[msg.sender] = true;
    }

    function registerSettlement(bytes32 id, address anchor) external {
        require(settlements[id].id == bytes32(0), 'Settlement already exists');
        settlements[id].id = id;
        settlements[id].anchor = anchor;
        settlements[id].timestamp = block.timestamp;
        emit SettlementRegistered(id, anchor);
    }

    function verifySettlement(bytes32 id, bool verified) external onlyAuthorizedNode {
        require(settlements[id].id != bytes32(0), 'Settlement not found');
        settlements[id].nodeVerifications[msg.sender] = verified;
        emit VerificationUpdated(id, msg.sender, verified);
    }

    function addAuthorizedNode(address node) external {
        authorizedNodes[node] = true;
    }
}
