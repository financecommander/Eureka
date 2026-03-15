// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BankingVerificationNode {
    mapping(address => Bank) public banks;
    mapping(bytes32 => FundVerification) public fundVerifications;

    struct Bank {
        bool isVerified;
        bytes32 credentialHash;
        uint256 verificationTimestamp;
    }

    struct FundVerification {
        address bank;
        bytes32 settlementId;
        bool isVerified;
    }

    event BankVerified(address indexed bank, bytes32 credentialHash);
    event FundsVerified(bytes32 indexed verificationId, bytes32 settlementId, bool isVerified);

    function verifyBank(address bank, bytes32 credentialHash) external {
        banks[bank] = Bank(true, credentialHash, block.timestamp);
        emit BankVerified(bank, credentialHash);
    }

    function verifyFunds(bytes32 verificationId, bytes32 settlementId, bool isVerified) external {
        require(banks[msg.sender].isVerified, "Not a verified bank");
        fundVerifications[verificationId] = FundVerification(msg.sender, settlementId, isVerified);
        emit FundsVerified(verificationId, settlementId, isVerified);
    }
}