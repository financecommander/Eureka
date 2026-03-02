// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SettlementAnchor
 * @author Calculus Holdings LLC — Eureka Settlement Services
 * @notice Periodic merkle root anchor for settlement verification records.
 *         Deployed on Ethereum mainnet. The SettlementVerificationRegistry
 *         runs on a Layer 2 (Base/Polygon) for low-cost attestation recording.
 *         This contract receives periodic merkle roots of L2 attestations,
 *         providing Ethereum-grade permanence and security.
 * @dev Called by an authorized relayer that batches L2 attestations,
 *      computes the merkle root, and anchors it to mainnet.
 *      Frequency: every 100 attestations or every 24 hours, whichever comes first.
 */
contract SettlementAnchor is Ownable {

    struct Anchor {
        bytes32 merkleRoot;             // Root of attestation merkle tree
        uint256 attestationStart;       // First attestation ID in this batch
        uint256 attestationEnd;         // Last attestation ID in this batch
        uint256 l2BlockNumber;          // L2 block at time of anchoring
        uint256 timestamp;
        string l2Chain;                 // "base", "polygon", etc.
    }

    /// @notice Sequential anchor counter
    uint256 public anchorCount;

    /// @notice All anchors
    mapping(uint256 => Anchor) public anchors;

    /// @notice Merkle root → anchor ID (for reverse lookup)
    mapping(bytes32 => uint256) public rootToAnchor;

    /// @notice Authorized relayer address
    address public relayer;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event AnchorRecorded(
        uint256 indexed anchorId,
        bytes32 indexed merkleRoot,
        uint256 attestationStart,
        uint256 attestationEnd,
        string l2Chain,
        uint256 timestamp
    );

    event RelayerUpdated(address indexed oldRelayer, address indexed newRelayer);

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════

    error OnlyRelayer();
    error InvalidMerkleRoot();
    error DuplicateMerkleRoot(bytes32 root);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════

    constructor(address _relayer) Ownable(msg.sender) {
        relayer = _relayer;
    }

    // ═══════════════════════════════════════════════════════════════
    // ANCHOR FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Record a merkle root anchor from the L2 verification registry
     * @param merkleRoot The merkle root of the attestation batch
     * @param attestationStart First attestation ID in the batch
     * @param attestationEnd Last attestation ID in the batch
     * @param l2BlockNumber The L2 block number at anchoring time
     * @param l2Chain The L2 chain identifier
     */
    function recordAnchor(
        bytes32 merkleRoot,
        uint256 attestationStart,
        uint256 attestationEnd,
        uint256 l2BlockNumber,
        string calldata l2Chain
    ) external {
        if (msg.sender != relayer) revert OnlyRelayer();
        if (merkleRoot == bytes32(0)) revert InvalidMerkleRoot();
        if (rootToAnchor[merkleRoot] != 0) revert DuplicateMerkleRoot(merkleRoot);

        uint256 anchorId = ++anchorCount; // Start from 1 so 0 means "not found"

        anchors[anchorId] = Anchor({
            merkleRoot: merkleRoot,
            attestationStart: attestationStart,
            attestationEnd: attestationEnd,
            l2BlockNumber: l2BlockNumber,
            timestamp: block.timestamp,
            l2Chain: l2Chain
        });

        rootToAnchor[merkleRoot] = anchorId;

        emit AnchorRecorded(
            anchorId,
            merkleRoot,
            attestationStart,
            attestationEnd,
            l2Chain,
            block.timestamp
        );
    }

    /**
     * @notice Verify that a merkle root has been anchored
     * @param merkleRoot The root to verify
     * @return exists True if the root has been anchored
     * @return anchorId The anchor ID (0 if not found)
     * @return timestamp When it was anchored
     */
    function verifyAnchor(bytes32 merkleRoot)
        external view returns (bool exists, uint256 anchorId, uint256 timestamp)
    {
        anchorId = rootToAnchor[merkleRoot];
        if (anchorId == 0) return (false, 0, 0);
        return (true, anchorId, anchors[anchorId].timestamp);
    }

    /**
     * @notice Update the authorized relayer
     * @param newRelayer The new relayer address
     */
    function setRelayer(address newRelayer) external onlyOwner {
        emit RelayerUpdated(relayer, newRelayer);
        relayer = newRelayer;
    }
}
