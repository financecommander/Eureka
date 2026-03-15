// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/ISettlementVerificationRegistry.sol';

contract SettlementVerificationRegistry is ISettlementVerificationRegistry {
    mapping(bytes32 => Settlement) public settlements;
    mapping(address => bool) public authorizedVerifiers;
    
    modifier onlyVerifier() {
        require(authorizedVerifiers[msg.sender], 'Unauthorized verifier');
        _;
    }
    
    constructor() {
        authorizedVerifiers[msg.sender] = true;
    }
    
    function registerSettlement(
        bytes32 settlementId,
        address attorney,
        address custodian,
        address banker,
        uint256 amount
    ) external override onlyVerifier {
        require(settlements[settlementId].settlementId == bytes32(0), 'Settlement already registered');
        settlements[settlementId] = Settlement({
            settlementId: settlementId,
            attorney: attorney,
            custodian: custodian,
            banker: banker,
            amount: amount,
            status: VerificationStatus.Pending,
            attorneyVerified: false,
            custodianVerified: false,
            bankerVerified: false
        });
        emit SettlementRegistered(settlementId, attorney, custodian, banker, amount);
    }
    
    function updateVerificationStatus(
        bytes32 settlementId,
        VerificationStatus status
    ) external override onlyVerifier {
        Settlement storage settlement = settlements[settlementId];
        require(settlement.settlementId != bytes32(0), 'Settlement not found');
        settlement.status = status;
        emit VerificationUpdated(settlementId, status);
    }
    
    function recordVerification(
        bytes32 settlementId,
        VerificationType vType
    ) external override onlyVerifier {
        Settlement storage settlement = settlements[settlementId];
        require(settlement.settlementId != bytes32(0), 'Settlement not found');
        if (vType == VerificationType.Attorney) settlement.attorneyVerified = true;
        if (vType == VerificationType.Custodian) settlement.custodianVerified = true;
        if (vType == VerificationType.Banker) settlement.bankerVerified = true;
        emit VerificationRecorded(settlementId, vType);
    }
}