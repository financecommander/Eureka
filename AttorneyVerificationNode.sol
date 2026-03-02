// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SettlementVerificationRegistry.sol";

/**
 * @title AttorneyVerificationNode
 * @author Calculus Holdings LLC — Eureka Settlement Services
 * @notice Specialized contract for attorney verification workflows.
 *         Provides structured interfaces for title examination certification,
 *         deed review, and legal opinions — the three attorney-required
 *         functions under Rhode Island's Paplauskas framework.
 * @dev This contract acts as a relay — it validates attorney-specific
 *      business logic and then calls the main SettlementVerificationRegistry.
 *      Attorneys interact with this contract through the verification portal.
 */
contract AttorneyVerificationNode {

    // ═══════════════════════════════════════════════════════════════
    // STATE
    // ═══════════════════════════════════════════════════════════════

    SettlementVerificationRegistry public immutable registry;
    address public immutable owner;

    struct TitleExamCertification {
        bytes32 settlementId;
        bytes32 titleReportHash;        // Hash of the AI-generated title report
        bytes32 propertyId;             // Keccak256 of property address or parcel ID
        string jurisdiction;            // Municipality (e.g., "Woonsocket, RI")
        uint256 chainLength;            // Number of ownership transfers in chain
        uint256 encumbranceCount;       // Number of active encumbrances found
        uint256 exceptionCount;         // Number of exceptions to coverage
        bool cleanChain;                // True if no breaks in chain of title
        bool marketable;                // Attorney's opinion on marketability
    }

    struct DeedReviewCertification {
        bytes32 settlementId;
        bytes32 deedDocumentHash;       // Hash of the deed document reviewed
        bytes32 propertyId;
        string deedType;                // "warranty", "quitclaim", "special_warranty", "bargain_sale"
        bool grantorVerified;           // Grantor identity confirmed
        bool legalDescriptionAccurate;  // Legal description matches title
        bool encumbrancesDisclosed;     // All encumbrances properly noted
        bool executionValid;            // Deed properly executed per state law
    }

    /// @notice Track attorney certifications for analytics
    mapping(address => uint256) public titleExamCount;
    mapping(address => uint256) public deedReviewCount;
    mapping(address => uint256) public legalOpinionCount;

    /// @notice Settlement → property mapping for cross-reference
    mapping(bytes32 => bytes32) public settlementProperty;

    // ═══════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════

    event TitleExaminationCertified(
        bytes32 indexed settlementId,
        bytes32 indexed propertyId,
        address indexed attorney,
        bool marketable,
        bool cleanChain,
        uint256 encumbranceCount,
        uint256 attestationId,
        uint256 timestamp
    );

    event DeedReviewCertified(
        bytes32 indexed settlementId,
        bytes32 indexed propertyId,
        address indexed attorney,
        string deedType,
        bool executionValid,
        uint256 attestationId,
        uint256 timestamp
    );

    event LegalOpinionIssued(
        bytes32 indexed settlementId,
        address indexed attorney,
        uint256 attestationId,
        uint256 timestamp
    );

    // ═══════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════

    error NotAttorneyNode(address caller);
    error InvalidCertification();

    // ═══════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════

    constructor(address _registry) {
        registry = SettlementVerificationRegistry(_registry);
        owner = msg.sender;
    }

    // ═══════════════════════════════════════════════════════════════
    // MODIFIERS
    // ═══════════════════════════════════════════════════════════════

    modifier onlyRegisteredAttorney() {
        (address wallet,,,,,,,,,) = _getNodeInfo(msg.sender);
        if (wallet == address(0)) revert NotAttorneyNode(msg.sender);
        _;
    }

    // ═══════════════════════════════════════════════════════════════
    // ATTORNEY VERIFICATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Certify a title examination
     * @dev Attorney reviews AI-generated title report and certifies
     *      their professional opinion on marketability and chain integrity.
     *      This is the primary attorney function required under RI Paplauskas.
     * @param cert The structured title exam certification data
     * @param decision Approval decision
     * @param conditionsHash Hash of conditions (bytes32(0) if unconditional)
     * @return attestationId The on-chain attestation ID
     */
    function certifyTitleExamination(
        TitleExamCertification calldata cert,
        SettlementVerificationRegistry.Decision decision,
        bytes32 conditionsHash
    ) external onlyRegisteredAttorney returns (uint256) {

        if (cert.titleReportHash == bytes32(0)) revert InvalidCertification();

        // Store property mapping
        settlementProperty[cert.settlementId] = cert.propertyId;

        // Encode certification details as metadata
        bytes memory metadata = abi.encode(
            cert.propertyId,
            cert.jurisdiction,
            cert.chainLength,
            cert.encumbranceCount,
            cert.exceptionCount,
            cert.cleanChain,
            cert.marketable
        );

        // Record attestation on main registry
        uint256 attestationId = registry.recordAttestation(
            cert.settlementId,
            cert.titleReportHash,
            SettlementVerificationRegistry.AttestationType.TITLE_EXAMINATION,
            decision,
            conditionsHash,
            metadata
        );

        titleExamCount[msg.sender]++;

        emit TitleExaminationCertified(
            cert.settlementId,
            cert.propertyId,
            msg.sender,
            cert.marketable,
            cert.cleanChain,
            cert.encumbranceCount,
            attestationId,
            block.timestamp
        );

        return attestationId;
    }

    /**
     * @notice Certify a deed review
     * @dev Attorney reviews deed (AI-generated or human-drafted) and certifies
     *      its legal sufficiency. Required under RI Paplauskas — an attorney
     *      must either draft the deed or review it after preparation.
     * @param cert The structured deed review certification data
     * @param decision Approval decision
     * @param conditionsHash Hash of conditions (bytes32(0) if unconditional)
     * @return attestationId The on-chain attestation ID
     */
    function certifyDeedReview(
        DeedReviewCertification calldata cert,
        SettlementVerificationRegistry.Decision decision,
        bytes32 conditionsHash
    ) external onlyRegisteredAttorney returns (uint256) {

        if (cert.deedDocumentHash == bytes32(0)) revert InvalidCertification();

        bytes memory metadata = abi.encode(
            cert.propertyId,
            cert.deedType,
            cert.grantorVerified,
            cert.legalDescriptionAccurate,
            cert.encumbrancesDisclosed,
            cert.executionValid
        );

        uint256 attestationId = registry.recordAttestation(
            cert.settlementId,
            cert.deedDocumentHash,
            SettlementVerificationRegistry.AttestationType.DEED_REVIEW,
            decision,
            conditionsHash,
            metadata
        );

        deedReviewCount[msg.sender]++;

        emit DeedReviewCertified(
            cert.settlementId,
            cert.propertyId,
            msg.sender,
            cert.deedType,
            cert.executionValid,
            attestationId,
            block.timestamp
        );

        return attestationId;
    }

    /**
     * @notice Issue a legal opinion
     * @dev General-purpose legal opinion attestation for complex settlements
     *      requiring attorney guidance beyond standard title exam / deed review.
     * @param settlementId The settlement this opinion pertains to
     * @param opinionHash Hash of the legal opinion document
     * @param decision Approval decision
     * @param conditionsHash Hash of conditions
     * @param opinionMetadata ABI-encoded opinion details
     * @return attestationId The on-chain attestation ID
     */
    function issueLegalOpinion(
        bytes32 settlementId,
        bytes32 opinionHash,
        SettlementVerificationRegistry.Decision decision,
        bytes32 conditionsHash,
        bytes calldata opinionMetadata
    ) external onlyRegisteredAttorney returns (uint256) {

        uint256 attestationId = registry.recordAttestation(
            settlementId,
            opinionHash,
            SettlementVerificationRegistry.AttestationType.LEGAL_OPINION,
            decision,
            conditionsHash,
            opinionMetadata
        );

        legalOpinionCount[msg.sender]++;

        emit LegalOpinionIssued(
            settlementId,
            msg.sender,
            attestationId,
            block.timestamp
        );

        return attestationId;
    }

    // ═══════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════

    /**
     * @notice Get an attorney's certification statistics
     * @param attorney The attorney wallet address
     * @return titleExams Number of title examinations certified
     * @return deedReviews Number of deed reviews certified
     * @return legalOpinions Number of legal opinions issued
     */
    function getAttorneyStats(address attorney)
        external view returns (uint256 titleExams, uint256 deedReviews, uint256 legalOpinions)
    {
        return (
            titleExamCount[attorney],
            deedReviewCount[attorney],
            legalOpinionCount[attorney]
        );
    }

    /**
     * @notice Get the property ID associated with a settlement
     * @param settlementId The settlement to query
     * @return The property ID hash
     */
    function getSettlementProperty(bytes32 settlementId)
        external view returns (bytes32)
    {
        return settlementProperty[settlementId];
    }

    // ═══════════════════════════════════════════════════════════════
    // INTERNAL
    // ═══════════════════════════════════════════════════════════════

    function _getNodeInfo(address wallet)
        internal view returns (
            address, uint8, string memory, string memory, string memory,
            bool, uint256, uint256, uint256, uint256
        )
    {
        SettlementVerificationRegistry.VerificationNode memory node;
        (
            node.wallet,
            node.nodeType,
            node.credential,
            node.jurisdiction,
            node.name,
            node.active,
            node.registeredAt,
            node.deactivatedAt,
            node.totalAttestations
        ) = registry.nodes(wallet);

        // Struct deconstruction for return
        return (
            node.wallet,
            uint8(node.nodeType),
            node.credential,
            node.jurisdiction,
            node.name,
            node.active,
            node.registeredAt,
            node.deactivatedAt,
            node.totalAttestations,
            0 // padding
        );
    }
}
