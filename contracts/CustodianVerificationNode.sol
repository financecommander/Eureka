// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CustodianVerificationNode {
    mapping(address => bool) public verifiedCustodians;

    event CustodianVerified(address indexed custodian);

    address public admin;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    function verifyCustodian(address custodian) external onlyAdmin {
        verifiedCustodians[custodian] = true;
        emit CustodianVerified(custodian);
    }

    function confirmLock(bytes32 settlementId, address custodian) external view returns (bool) {
        // TODO: Implement lock confirmation logic
        return verifiedCustodians[custodian];
    }
}
