// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SettlementAnchor {
    mapping(bytes32 => AssetLock) public assetLocks;

    struct AssetLock {
        address owner;
        uint256 amount;
        bytes32 assetType;
        bool isLocked;
        uint256 lockTimestamp;
    }

    event AssetLocked(bytes32 indexed lockId, address owner, uint256 amount, bytes32 assetType);
    event AssetReleased(bytes32 indexed lockId, address owner);

    function lockAsset(bytes32 lockId, uint256 amount, bytes32 assetType) external payable {
        require(assetLocks[lockId].isLocked == false, "Asset already locked");
        assetLocks[lockId] = AssetLock(msg.sender, amount, assetType, true, block.timestamp);
        emit AssetLocked(lockId, msg.sender, amount, assetType);
    }

    function releaseAsset(bytes32 lockId) external {
        require(assetLocks[lockId].isLocked, "Asset not locked");
        require(assetLocks[lockId].owner == msg.sender, "Not the owner");
        assetLocks[lockId].isLocked = false;
        emit AssetReleased(lockId, msg.sender);
    }
}