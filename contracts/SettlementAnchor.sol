// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISettlementAnchor.sol";
import "./interfaces/ISettlementVerificationRegistry.sol";

contract SettlementAnchor is ISettlementAnchor {
    ISettlementVerificationRegistry public registry;
    mapping(bytes32 => AssetLock) public assetLocks;
    
    event AssetLocked(bytes32 indexed settlementId, address asset, uint256 amount);
    event SettlementAnchored(bytes32 indexed settlementId);
    
    constructor(address _registry) {
        registry = ISettlementVerificationRegistry(_registry);
    }
    
    modifier onlyRegisteredAnchor() {
        require(registry.registeredAnchors(msg.sender), "Not registered anchor");
        _;
    }
    
    function lockAsset(
        bytes32 settlementId,
        address asset,
        uint256 amount
    ) external onlyRegisteredAnchor {
        require(registry.settlements(settlementId).status != VerificationStatus.NONE, "Settlement not found");
        assetLocks[settlementId] = AssetLock({
            asset: asset,
            amount: amount,
            isLocked: true,
            timestamp: block.timestamp
        });
        emit AssetLocked(settlementId, asset, amount);
    }
    
    function anchorSettlement(bytes32 settlementId) external onlyRegisteredAnchor {
        require(assetLocks[settlementId].isLocked, "Assets not locked");
        registry.updateVerificationStatus(settlementId, VerificationStatus.ANCHORED);
        emit SettlementAnchored(settlementId);
    }
}
