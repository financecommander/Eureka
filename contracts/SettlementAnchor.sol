// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './interfaces/ISettlementAnchor.sol';

contract SettlementAnchor is ISettlementAnchor {
    mapping(bytes32 => AssetAnchor) public anchors;
    address public registry;
    
    modifier onlyRegistry() {
        require(msg.sender == registry, 'Unauthorized');
        _;
    }
    
    constructor(address _registry) {
        registry = _registry;
    }
    
    function anchorSettlement(
        bytes32 settlementId,
        address[] calldata assets,
        uint256[] calldata amounts
    ) external override onlyRegistry {
        require(assets.length == amounts.length, 'Invalid input lengths');
        anchors[settlementId] = AssetAnchor({
            settlementId: settlementId,
            assets: assets,
            amounts: amounts,
            locked: true
        });
        emit SettlementAnchored(settlementId, assets, amounts);
    }
    
    function releaseAnchor(bytes32 settlementId) external override onlyRegistry {
        AssetAnchor storage anchor = anchors[settlementId];
        require(anchor.locked, 'Not locked');
        anchor.locked = false;
        emit AnchorReleased(settlementId);
    }
}