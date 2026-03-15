// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SettlementAnchor {
    mapping(bytes32 => AssetLock) public locks;

    struct AssetLock {
        address assetContract;
        uint256 amount;
        address owner;
        bool isLocked;
    }

    event AssetLocked(bytes32 indexed settlementId, address assetContract, uint256 amount);
    event AssetReleased(bytes32 indexed settlementId);

    function lockAsset(bytes32 settlementId, address assetContract, uint256 amount) external {
        require(locks[settlementId].isLocked == false, 'Already locked');
        locks[settlementId] = AssetLock(assetContract, amount, msg.sender, true);
        // TODO: Implement ERC20 transferFrom for actual locking
        emit AssetLocked(settlementId, assetContract, amount);
    }

    function releaseAsset(bytes32 settlementId) external {
        require(locks[settlementId].isLocked, 'Not locked');
        require(locks[settlementId].owner == msg.sender, 'Unauthorized');
        locks[settlementId].isLocked = false;
        // TODO: Implement ERC20 transfer back to owner
        emit AssetReleased(settlementId);
    }
}
