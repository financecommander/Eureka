// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title SettlementVerificationRegistry
 * @author Calculus Holdings LLC — Eureka Settlement Services
 * @notice On-chain verification registry for multi-asset settlement attestations.
 *         Records cryptographically signed attestations from attorneys, custodians,
 *         banks, title agents, and underwriters participating in Eureka settlements.
 * @dev This contract is a NOTARIZATION LAYER, not an execution layer.
 *      It does NOT hold funds, execute transfers, or make decisions.
 *      Eureka's off-chain state machine remains the execution engine.
 *      The chain provides immutable proof of every verification decision.
 */
contract SettlementVerificationRegistry is AccessControl, ReentrancyGuard, Pausable {

    // ═══════════════════════════════════════════════════════════════
    // ROLES
    // ═══════════════════════════════════════════════════════════════

    bytes32 public constant REGISTRY_ADMIN = keccak256("REGISTRY_ADMIN");
    bytes32 public constant NODE_REGISTRAR = keccak256("NODE_REGISTRAR");

    // ═══════════════════════════════════════════════════════════════
    // ENUMS
    // ═══════════════════════════════════════════════════════════════

    enum NodeType {
        ATTORNEY,           // Licensed attorney — title examination, deed review
        CUSTODIAN,          // Asset custodian — Brinks, Loomis, Anchorage
        BANK,               // Banking institution — fiat movement confirmations
        TITLE_AGENT,        // Licensed title insurance agent — closing certification
        UNDERWRITER,        // Title insurance underwriter — policy approval
        COMPLIANCE,         // Compliance officer/system — AML/KYC/OFAC attestation
        SETTLEMENT_ENGINE   // Eureka system — settlement state transitions
    }

    enum AttestationType {
        TITLE_EXAMINATION,      // Attorney certified title search
        DEED_REVIEW,            // Attorney reviewed/approved deed
        LEGAL_OPINION,          // Attorney issued legal opinion
        ASSET_VERIFICATION,     // Custodian confirmed asset exists and is unencumbered
        ASSET_LOCK,             // Custodian confirmed encumbrance placed
        ASSET_TRANSFER,         // Custodian confirmed title/ownership transfer
        ASSET_RELEASE,          // Custodian confirmed lock released
        FUNDS_RECEIVED,         // Bank confirmed funds receipt
        FUNDS_HELD,             // Bank confirmed funds hold
        FUNDS_DISBURSED,        // Bank confirmed disbursement
        COMPLIANCE_CLEARED,     // AML/KYC/OFAC screening passed
        CLOSING_CERTIFIED,      // Title agent certified closing conducted properly
        POLICY_APPROVED,        // Underwriter approved title insurance policy
        SETTLEMENT_INITIATED,   // Eureka settlement file opened
        SETTLEMENT_COMPLETED,   // Eureka settlement completed (all legs)
        SETTLEMENT_FAILED,      // Eureka settlement failed
        SETTLEMENT_ROLLED_BACK  // Eureka settlement rolled back
    }

    enum Decision {
        APPROVED,                   // Verification passed
        APPROVED_WITH_CONDITIONS,   // Passed with noted conditions
        REJECTED,                   // Verification failed
        INFORMATIONAL               // Status update (no approval/rejection)
    }

    // ═══════════════════════════════════════════════════════════════
    // STRUCTS
    // ═══════════════════════════════════════════════════════════════

    struct VerificationNode {
        address wallet;             // Node's signing wallet
        NodeType nodeType;
        string credential;          // Bar number, license number, custodian ID
        string jurisdiction;        // State/jurisdiction (e.g., "RI", "FL", "US")
        string name;                // Human-readable name
        bool active;
        uint256 registeredAt;
        uint256 deactivatedAt;
        uint256 totalAttestations;
    }

    struct Attestation {
        uint256 id;
        bytes32 settlementId;       // Eureka settlement file ID (sfx_xxx hashed)
        bytes32 documentHash;       // SHA-256 of the work product reviewed
        address verifier;           // Node wallet that signed
        NodeType nodeType;
        AttestationType attestationType;
        Decision decision;
        bytes32 conditionsHash;     // Hash of conditions/modifications (bytes32(0) if none)
        string credential;          // Verifier's credential at time of attestation
        string jurisdiction;        // Jurisdiction of attestation
        bytes metadata;             // ABI-encoded additional data
        uint256 timestamp;
        uint256 blockNumber;
    }

    struct SettlementRecord {
        bytes32 settlementId;
        uint256 attestationCount;
        uint256 firstAttestationAt;
        uint256 lastAttestationAt;
        bool finalized;             // True when SETTLEMENT_COMPLETED or SETTLEMENT_ROLLED_BACK recorded
    }

    // ═══════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════

    /// @notice Sequential attestation counter
    uint256 public attestationCount;

    /// @notice All registered verification nodes
    mapping(address => VerificationNode) public nodes;

    /// @notice All attestations by ID
    mapping(uint256 => Attestation) public attestations;

    /// @notice Settlement ID → settlement record
    mapping(bytes32 => SettlementRecord) public settlements;

    /// @notice Settlement ID → array of attestation IDs
    mapping(bytes32 => uint256[]) public settlementAttestations;

    /// @notice Verifier address → array of attestation IDs
    mapping(address => uint256[]) public verifierAttestations;

    /// @notice Settlement ID + Attestation Type + Verifier → bool (prevents duplicate attestations)
    mapping(bytes32 => mapping(AttestationType => mapping(address => bool))) public hasAttested;

    /// @notice Registry of all registered node addresses
    address[] public registeredNodes;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event NodeRegistered(
        address indexed wallet,
        NodeType nodeType,
        string credential,
        string jurisdiction,
        string name,
        uint256 timestamp
    );

    event NodeDeactivated(
        address indexed wallet,
        uint256 timestamp
    );

    event NodeReactivated(
        address indexed wallet,
        uint256 timestamp
    );

    event AttestationRecorded(
        uint256 indexed attestationId,
        bytes32 indexed settlementId,
        address indexed verifier,
        NodeType nodeType,
        AttestationType attestationType,
        Decision decision,
        bytes32 documentHash,
        uint256 timestamp
    );

    event SettlementFinalized(
        bytes32 indexed settlementId,
        uint256 attestationCount,
        uint256 timestamp
    );

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════

    error NodeNotRegistered(address wallet);
    error NodeNotActive(address wallet);
    error NodeAlreadyRegistered(address wallet);
    error DuplicateAttestation(bytes32 settlementId, AttestationType attestationType, address verifier);
    error SettlementAlreadyFinalized(bytes32 settlementId);
    error InvalidDocumentHash();
    error InvalidSettlementId();
    error UnauthorizedNodeType(NodeType expected, NodeType actual);

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRY_ADMIN, admin);
        _grantRole(NODE_REGISTRAR, admin);
    }

    // ═══════════════════════════════════════════════════════════════
    // NODE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Register a new verification node
     * @param wallet The signing wallet address for this node
     * @param nodeType The type of verification node
     * @param credential Professional credential (bar number, license, etc.)
     * @param jurisdiction Operating jurisdiction
     * @param name Human-readable name
     */
    function registerNode(
        address wallet,
        NodeType nodeType,
        string calldata credential,
        string calldata jurisdiction,
        string calldata name
    ) external onlyRole(NODE_REGISTRAR) {
        if (nodes[wallet].wallet != address(0)) revert NodeAlreadyRegistered(wallet);

        nodes[wallet] = VerificationNode({
            wallet: wallet,
            nodeType: nodeType,
            credential: credential,
            jurisdiction: jurisdiction,
            name: name,
            active: true,
            registeredAt: block.timestamp,
            deactivatedAt: 0,
            totalAttestations: 0
        });

        registeredNodes.push(wallet);

        emit NodeRegistered(wallet, nodeType, credential, jurisdiction, name, block.timestamp);
    }

    /**
     * @notice Deactivate a verification node (cannot create new attestations)
     * @param wallet The node wallet to deactivate
     */
    function deactivateNode(address wallet) external onlyRole(REGISTRY_ADMIN) {
        if (nodes[wallet].wallet == address(0)) revert NodeNotRegistered(wallet);
        nodes[wallet].active = false;
        nodes[wallet].deactivatedAt = block.timestamp;
        emit NodeDeactivated(wallet, block.timestamp);
    }

    /**
     * @notice Reactivate a previously deactivated node
     * @param wallet The node wallet to reactivate
     */
    function reactivateNode(address wallet) external onlyRole(REGISTRY_ADMIN) {
        if (nodes[wallet].wallet == address(0)) revert NodeNotRegistered(wallet);
        nodes[wallet].active = true;
        nodes[wallet].deactivatedAt = 0;
        emit NodeReactivated(wallet, block.timestamp);
    }

    // ═══════════════════════════════════════════════════════════════
    // ATTESTATION RECORDING
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Record a verification attestation
     * @dev Called by the verification node's wallet directly (msg.sender must be registered node)
     * @param settlementId Eureka settlement file ID (keccak256 hash of sfx_xxx)
     * @param documentHash SHA-256 hash of the work product reviewed
     * @param attestationType Type of verification being attested
     * @param decision Approval decision
     * @param conditionsHash Hash of any conditions (bytes32(0) if none)
     * @param metadata ABI-encoded additional context
     */
    function recordAttestation(
        bytes32 settlementId,
        bytes32 documentHash,
        AttestationType attestationType,
        Decision decision,
        bytes32 conditionsHash,
        bytes metadata
    ) external whenNotPaused nonReentrant returns (uint256) {
        // Validate caller is registered and active
        if (nodes[msg.sender].wallet == address(0)) revert NodeNotRegistered(msg.sender);
        if (!nodes[msg.sender].active) revert NodeNotActive(msg.sender);
        if (settlementId == bytes32(0)) revert InvalidSettlementId();
        if (documentHash == bytes32(0)) revert InvalidDocumentHash();

        // Check for duplicate attestation (same settlement + type + verifier)
        if (hasAttested[settlementId][attestationType][msg.sender]) {
            revert DuplicateAttestation(settlementId, attestationType, msg.sender);
        }

        // Check settlement not already finalized
        if (settlements[settlementId].finalized) {
            revert SettlementAlreadyFinalized(settlementId);
        }

        // Enforce node type restrictions for attorney-specific attestations
        if (
            attestationType == AttestationType.TITLE_EXAMINATION ||
            attestationType == AttestationType.DEED_REVIEW ||
            attestationType == AttestationType.LEGAL_OPINION
        ) {
            if (nodes[msg.sender].nodeType != NodeType.ATTORNEY) {
                revert UnauthorizedNodeType(NodeType.ATTORNEY, nodes[msg.sender].nodeType);
            }
        }

        // Create attestation
        uint256 attestationId = attestationCount++;
        VerificationNode storage node = nodes[msg.sender];

        attestations[attestationId] = Attestation({
            id: attestationId,
            settlementId: settlementId,
            documentHash: documentHash,
            verifier: msg.sender,
            nodeType: node.nodeType,
            attestationType: attestationType,
            decision: decision,
            conditionsHash: conditionsHash,
            credential: node.credential,
            jurisdiction: node.jurisdiction,
            metadata: metadata,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        // Update indexes
        settlementAttestations[settlementId].push(attestationId);
        verifierAttestations[msg.sender].push(attestationId);
        hasAttested[settlementId][attestationType][msg.sender] = true;
        node.totalAttestations++;

        // Update settlement record
        SettlementRecord storage settlement = settlements[settlementId];
        if (settlement.settlementId == bytes32(0)) {
            settlement.settlementId = settlementId;
            settlement.firstAttestationAt = block.timestamp;
        }
        settlement.attestationCount++;
        settlement.lastAttestationAt = block.timestamp;

        // Check if this is a finalizing attestation
        if (
            attestationType == AttestationType.SETTLEMENT_COMPLETED ||
            attestationType == AttestationType.SETTLEMENT_ROLLED_BACK
        ) {
            settlement.finalized = true;
            emit SettlementFinalized(settlementId, settlement.attestationCount, block.timestamp);
        }

        emit AttestationRecorded(
            attestationId,
            settlementId,
            msg.sender,
            node.nodeType,
            attestationType,
            decision,
            documentHash,
            block.timestamp
        );

        return attestationId;
    }

    // ═══════════════════════════════════════════════════════════════
    // QUERY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get all attestation IDs for a settlement
     * @param settlementId The settlement to query
     * @return Array of attestation IDs
     */
    function getSettlementAttestations(bytes32 settlementId)
        external view returns (uint256[] memory)
    {
        return settlementAttestations[settlementId];
    }

    /**
     * @notice Get all attestation IDs by a specific verifier
     * @param verifier The verifier address
     * @return Array of attestation IDs
     */
    function getVerifierAttestations(address verifier)
        external view returns (uint256[] memory)
    {
        return verifierAttestations[verifier];
    }

    /**
     * @notice Check if a specific attestation type exists for a settlement
     * @param settlementId Settlement to check
     * @param attestationType Type to check
     * @param verifier Verifier to check
     * @return True if attestation exists
     */
    function verifyAttestation(
        bytes32 settlementId,
        AttestationType attestationType,
        address verifier
    ) external view returns (bool) {
        return hasAttested[settlementId][attestationType][verifier];
    }

    /**
     * @notice Get total number of registered nodes
     * @return Count of registered nodes
     */
    function getRegisteredNodeCount() external view returns (uint256) {
        return registeredNodes.length;
    }

    /**
     * @notice Verify a document hash matches what was attested
     * @param attestationId The attestation to verify
     * @param documentHash The hash to verify against
     * @return True if hashes match
     */
    function verifyDocumentHash(uint256 attestationId, bytes32 documentHash)
        external view returns (bool)
    {
        return attestations[attestationId].documentHash == documentHash;
    }

    // ═══════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    function pause() external onlyRole(REGISTRY_ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(REGISTRY_ADMIN) {
        _unpause();
    }
}
