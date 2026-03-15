// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SettlementVerifier is Ownable {
    bytes32 public merkleRoot;
    mapping(address => bool) public hasClaimed;

    event SettlementClaimed(address indexed claimant, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);

    constructor() Ownable(msg.sender) {}

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    function claimSettlement(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!hasClaimed[msg.sender], "Already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        hasClaimed[msg.sender] = true;
        payable(msg.sender).transfer(amount);
        emit SettlementClaimed(msg.sender, amount);
    }

    // Fund the contract for settlements
    receive() external payable {}
}
