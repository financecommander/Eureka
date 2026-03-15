// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustodianVerificationNode {
    mapping(address => Custodian) public custodians;
    mapping(bytes32 => LockConfirmation) public lockConfirmations;

    struct Custodian {
        bool isVerified;
        bytes32 credentialHash;
        uint256 verificationTimestamp;
    }

    struct LockConfirmation {
        address custodian;
        bytes32 lockId;
        bool isConfirmed;
    }

    event CustodianVerified(address indexed custodian, bytes32 credentialHash);
    event LockConfirmed(bytes32 indexed confirmationId, bytes32 lockId, bool isConfirmed);

    function verifyCustodian(address custodian, bytes32 credentialHash) external {
        custodians[custodian] = Custodian(true, credentialHash, block.timestamp);
        emit CustodianVerified(custodian, credentialHash);
    }

    function confirmLock(bytes32 confirmationId, bytes32 lockId, bool isConfirmed) external {
        require(custodians[msg.sender].isVerified, "Not a verified custodian");
        lockConfirmations[confirmationId] = LockConfirmation(msg.sender, lockId, isConfirmed);
        emit LockConfirmed(confirmationId, lockId, isConfirmed);
    }
}