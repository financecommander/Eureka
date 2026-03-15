// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SettlementAnchor {
    mapping(bytes32 => AssetLock) public assetLocks;

    struct AssetLock {
        address assetContract;
        uint256 amount;
        address owner;
        bool isLocked;
        bool isReleased;
    }

    event AssetLocked(bytes32 indexed settlementId, address assetContract, uint256 amount);
    event AssetReleased(bytes32 indexed settlementId, address to);

    function lockAsset(bytes32 settlementId, address assetContract, uint256 amount) external {
        require(assetLocks[settlementId].isLocked == false, "Asset already locked");
        // TODO: Implement ERC20/ETH transfer logic
        assetLocks[settlementId] = AssetLock(assetContract, amount, msg.sender, true, false);
        emit AssetLocked(settlementId, assetContract, amount);
    }

    function releaseAsset(bytes32 settlementId, address to) external {
        AssetLock storage lock = assetLocks[settlementId];
        require(lock.isLocked, "No asset locked");
        require(lock.owner == msg.sender, "Not owner");
        lock.isReleased = true;
        // TODO: Implement asset transfer to 'to' address
        emit AssetReleased(settlementId, to);
    }
}
