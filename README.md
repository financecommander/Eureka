# Eureka Settlement Verification Chain

**On-Chain Verification Infrastructure for Multi-Asset Atomic Settlement**

Eureka Settlement Verification Chain is the blockchain layer of the Eureka Settlement Services ecosystem. It provides an immutable, cryptographically signed audit trail for every verification decision in a multi-asset settlement — from attorney title certifications to custodian lock confirmations to banking fund verifications.

This is a **notarization layer**, not an execution layer. Eureka's off-chain state machine coordinates settlement logic. The chain provides permanent, publicly verifiable proof that every legally mandated verification occurred, when it occurred, and who performed it.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Why On-Chain Verification](#why-on-chain-verification)
- [Smart Contracts](#smart-contracts)
  - [SettlementVerificationRegistry](#settlementverificationregistry)
  - [AttorneyVerificationNode](#attorneyverificationnode)
  - [SettlementAnchor](#settlementanchor)
- [Verification Node Types](#verification-node-types)
- [Attorney Verification Portal](#attorney-verification-portal)
- [Settlement Verification Flow](#settlement-verification-flow)
- [Chain Selection & Deployment](#chain-selection--deployment)
- [Integration with Eureka](#integration-with-eureka)
- [Regulatory Framework](#regulatory-framework)
- [Entity Structure](#entity-structure)
- [Development Setup](#development-setup)
- [API Reference](#api-reference)
- [Security Considerations](#security-considerations)
- [Roadmap](#roadmap)
- [License](#license)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     CALCULUS HOLDINGS LLC                         │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌──────┐  ┌──────────────┐  │
│  │Constitutional│  │   Eureka    │  │ TILT │  │  Calculus     │  │
│  │   Tender    │  │ Settlement  │  │      │  │  Title &     │  │
│  │             │  │  Services   │  │      │  │  Escrow      │  │
│  └──────┬──────┘  └──────┬──────┘  └──┬───┘  └──────┬───────┘  │
│         │                │            │              │           │
│         └────────────────┼────────────┘──────────────┘           │
│                          │                                       │
│                    ┌─────▼──────┐                                │
│                    │  Eureka    │  Off-Chain: State machine,     │
│                    │  Engine    │  orchestration, API gateway    │
│                    └─────┬──────┘                                │
│                          │                                       │
└──────────────────────────┼───────────────────────────────────────┘
                           │
              ┌────────────▼────────────┐
              │  VERIFICATION CHAIN     │
              │  (Base L2 / Polygon)    │
              │                         │
              │  ┌───────────────────┐  │
              │  │ Settlement        │  │
              │  │ Verification      │  │  On-Chain: Immutable
              │  │ Registry          │  │  attestation records
              │  └────────┬──────────┘  │
              │           │             │
              │  ┌────────▼──────────┐  │
              │  │ Attorney          │  │
              │  │ Verification      │  │  Specialized attorney
              │  │ Node              │  │  certification workflows
              │  └──────────────────┘  │
              │                         │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  ETHEREUM MAINNET       │
              │                         │
              │  ┌───────────────────┐  │
              │  │ Settlement        │  │  Periodic merkle root
              │  │ Anchor            │  │  anchoring for maximum
              │  └───────────────────┘  │  permanence
              │                         │
              └─────────────────────────┘
```

The system uses a two-layer blockchain architecture. The **Settlement Verification Registry** and **Attorney Verification Node** contracts deploy to a Layer 2 chain (Base or Polygon) for low-cost, high-throughput attestation recording. The **Settlement Anchor** contract deploys to Ethereum mainnet and receives periodic merkle root anchors from the L2, providing Ethereum-grade permanence for the verification history.

---

## Why On-Chain Verification

Traditional title and settlement companies store verification records in internal databases. When disputes arise years later, proving that an attorney actually reviewed a title search, or that a custodian confirmed an asset lock, depends on document retention policies and human testimony.

On-chain verification solves this permanently:

**Immutability** — Once an attorney certifies a title examination, that certification cannot be altered, backdated, or deleted. It exists on-chain forever.

**Verifiability** — Anyone (a court, a regulator, an insurance underwriter, a counterparty) can independently verify that a specific certification exists, when it was recorded, what document was reviewed, and who signed it. No trust in the title company's internal records required.

**Attorney Protection** — The on-chain record proves exactly what work product the attorney was given to review. If a title defect surfaces later, the chain of responsibility is clear and auditable.

**Regulatory Compliance** — In states like Rhode Island (under the *In re Paplauskas* framework), attorney involvement in title examination and deed review is legally mandated. On-chain attestations provide cryptographic proof that these requirements were met — a level of compliance transparency no traditional title company offers.

**Multi-Party Coordination** — Eureka settlements involve custodians, banks, attorneys, title agents, underwriters, and compliance systems. On-chain verification creates a shared, trustless record that all parties can reference without relying on any single party's database.

---

## Smart Contracts

### SettlementVerificationRegistry

**File:** `contracts/SettlementVerificationRegistry.sol`

The core contract. Manages verification node registration, attestation recording, and settlement tracking.

**Key Features:**

- **Node Registration** — Verification nodes (attorneys, custodians, banks, title agents, underwriters, compliance systems) are registered with their professional credentials, jurisdiction, and signing wallet. Only registered, active nodes can create attestations.

- **Attestation Recording** — Nodes submit signed attestations containing: settlement ID, document hash (SHA-256 of the work product reviewed), attestation type, decision (approved / approved with conditions / rejected / informational), and optional conditions hash.

- **Duplicate Prevention** — A node cannot submit the same attestation type for the same settlement twice. This prevents accidental double-signing.

- **Finalization** — When a `SETTLEMENT_COMPLETED` or `SETTLEMENT_ROLLED_BACK` attestation is recorded, the settlement is marked as finalized. No further attestations can be added.

- **Node Type Enforcement** — Attorney-specific attestation types (title examination, deed review, legal opinion) can only be created by nodes registered as `ATTORNEY` type. A custodian node cannot certify a title examination.

- **Role-Based Access** — Uses OpenZeppelin `AccessControl` for admin and registrar roles. Pausable for emergency stops. Reentrancy-guarded.

**Attestation Types:**

| Type | Node Type | Description |
|------|-----------|-------------|
| `TITLE_EXAMINATION` | Attorney | Title search certified for marketability |
| `DEED_REVIEW` | Attorney | Deed reviewed/approved per state law |
| `LEGAL_OPINION` | Attorney | General legal opinion for complex settlements |
| `ASSET_VERIFICATION` | Custodian | Asset confirmed to exist and be unencumbered |
| `ASSET_LOCK` | Custodian | Encumbrance placed on asset |
| `ASSET_TRANSFER` | Custodian | Ownership/title of asset transferred |
| `ASSET_RELEASE` | Custodian | Lock/encumbrance released |
| `FUNDS_RECEIVED` | Bank | Fiat funds receipt confirmed |
| `FUNDS_HELD` | Bank | Funds hold confirmed |
| `FUNDS_DISBURSED` | Bank | Disbursement confirmed |
| `COMPLIANCE_CLEARED` | Compliance | AML/KYC/OFAC screening passed |
| `CLOSING_CERTIFIED` | Title Agent | Closing conducted properly |
| `POLICY_APPROVED` | Underwriter | Title insurance policy approved |
| `SETTLEMENT_INITIATED` | Settlement Engine | Settlement file opened |
| `SETTLEMENT_COMPLETED` | Settlement Engine | All legs settled (finalizing) |
| `SETTLEMENT_FAILED` | Settlement Engine | Settlement failed (finalizing) |
| `SETTLEMENT_ROLLED_BACK` | Settlement Engine | Rollback complete (finalizing) |

**Query Functions:**

- `getSettlementAttestations(settlementId)` — All attestation IDs for a settlement
- `getVerifierAttestations(verifier)` — All attestation IDs by a specific node
- `verifyAttestation(settlementId, type, verifier)` — Check if a specific attestation exists
- `verifyDocumentHash(attestationId, hash)` — Verify a document matches what was attested

---

### AttorneyVerificationNode

**File:** `contracts/AttorneyVerificationNode.sol`

Specialized wrapper contract for attorney-specific verification workflows. Provides structured interfaces for the three attorney-required functions under Rhode Island's *Paplauskas* framework:

1. **Title Examination Certification** (`certifyTitleExamination`) — Attorney reviews AI-generated title report and certifies professional opinion on marketability and chain integrity. Records: property ID, jurisdiction, chain length, encumbrance count, exception count, clean chain status, and marketability opinion.

2. **Deed Review Certification** (`certifyDeedReview`) — Attorney reviews deed document (AI-generated or human-drafted) and certifies legal sufficiency. Records: deed type, grantor verification, legal description accuracy, encumbrance disclosure, and execution validity.

3. **Legal Opinion** (`issueLegalOpinion`) — General-purpose legal opinion for complex settlements requiring attorney guidance beyond standard title/deed work.

Each function validates the caller is a registered attorney node, encodes the structured certification data as metadata, and calls through to the main `SettlementVerificationRegistry` for attestation recording.

**Attorney Statistics:** The contract tracks per-attorney certification counts (title exams, deed reviews, legal opinions) for analytics and performance monitoring.

---

### SettlementAnchor

**File:** `contracts/SettlementAnchor.sol`

Deployed on Ethereum mainnet. Receives periodic merkle root anchors from the L2 verification registry, providing Ethereum-grade permanence and security for the verification history.

**Anchoring Protocol:**

- An authorized relayer batches L2 attestations, computes the merkle root, and submits it to mainnet.
- Anchoring frequency: every 100 attestations or every 24 hours, whichever comes first.
- Each anchor records: merkle root, attestation ID range, L2 block number, timestamp, and L2 chain identifier.
- Duplicate merkle roots are rejected.

**Verification:** Any party can call `verifyAnchor(merkleRoot)` to confirm that a batch of attestations has been anchored to Ethereum mainnet. Combined with a merkle proof from the L2, this provides end-to-end verification: L2 attestation → L2 merkle tree → Ethereum anchor.

---

## Verification Node Types

Every participant in a Eureka settlement operates as a verification node with a registered signing wallet and professional credentials.

| Node Type | Examples | Attestation Scope |
|-----------|----------|-------------------|
| **Attorney** | Licensed RI/FL/TX attorneys | Title examination, deed review, legal opinions |
| **Custodian** | Brinks, Loomis, Anchorage | Asset verification, lock, transfer, release |
| **Bank** | People's Bank, Pathward | Funds received, held, disbursed |
| **Title Agent** | Calculus Title licensed agents | Closing certification |
| **Underwriter** | WFG National, Agents National | Policy approval |
| **Compliance** | Automated or human systems | AML/KYC/OFAC clearance |
| **Settlement Engine** | Eureka system | Settlement lifecycle events |

Nodes are registered by the `NODE_REGISTRAR` role and can be deactivated/reactivated by the `REGISTRY_ADMIN` role. Deactivated nodes cannot create new attestations but their historical attestations remain on-chain permanently.

---

## Attorney Verification Portal

**File:** `AttorneyVerificationPortal.jsx`

A production-grade React interface for attorneys to review AI-generated work products and issue on-chain certifications. The portal is the attorney's window into the Eureka settlement verification system.

### Portal Features

**Review Queue** — Attorneys see all pending verification requests sorted by priority and submission date. Each queue card shows the settlement ID, property address, transaction value, AI risk score, asset composition (gold, fiat, crypto), and urgency level.

**AI-Generated Title Reports** — For title examination certifications, the portal displays the complete AI-generated title report including chain of ownership (with grantor/grantee history, instrument types, and recording references), active encumbrances with amounts and status, Schedule B exceptions, property tax status, and the AI's risk assessment with recommendation.

**Risk Scoring** — Every title report includes an AI risk score (0-100). Low risk (≤15) items are candidates for streamlined review. Medium risk (16-35) items require standard review. High risk (>35) items are flagged for detailed attorney examination.

**Certification Workflow** — The attorney selects a decision (Approve, Approve with Conditions, Reject), optionally provides conditions or rejection reasons, and signs. The signing triggers a blockchain transaction that records the attestation permanently.

**On-Chain Confirmation** — After signing, the portal displays the attestation ID, block number, transaction hash, and timestamp. The attorney has cryptographic proof of their certification.

**Completed History** — The "Completed" tab shows all previously certified items with their on-chain attestation IDs and transaction hashes for reference.

### Design Language

The portal uses a dark, institutional aesthetic appropriate for legal professionals handling financial instruments. Colors are deliberately muted with gold accents (matching the precious metals settlement context). Typography uses JetBrains Mono for data/identifiers and DM Sans for interface text. The design intentionally avoids consumer-facing patterns — this is a professional verification tool, not a consumer app.

---

## Settlement Verification Flow

A complete Eureka settlement with title verification follows this sequence:

```
1. SETTLEMENT INITIATED
   └─ Eureka records SETTLEMENT_INITIATED attestation on-chain
   
2. COMPLIANCE SCREENING
   └─ Compliance node records COMPLIANCE_CLEARED attestation
   
3. TITLE EXAMINATION (Attorney Required — Paplauskas)
   ├─ AI Title Search Engine produces structured title report
   ├─ Report hash (SHA-256) computed
   ├─ Report submitted to Attorney Verification Portal
   ├─ Attorney reviews AI output (10-15 min typical)
   ├─ Attorney certifies via portal → on-chain TITLE_EXAMINATION attestation
   └─ Eureka state machine receives event, transitions to ASSETS_VERIFIED
   
4. DEED REVIEW (Attorney Required — Paplauskas)
   ├─ AI Document Generator produces deed
   ├─ Deed hash computed
   ├─ Attorney reviews via portal
   ├─ Attorney certifies → on-chain DEED_REVIEW attestation
   └─ Eureka records certification
   
5. ASSET VERIFICATION & LOCK
   ├─ Custodian node (Brinks) records ASSET_VERIFICATION for gold
   ├─ Custodian node records ASSET_LOCK → gold encumbered
   ├─ Bank node records FUNDS_RECEIVED → fiat confirmed
   └─ Eureka transitions to LOCKS_PLACED
   
6. EXECUTION
   ├─ Eureka transitions to EXECUTING
   ├─ Custodian records ASSET_TRANSFER → gold ownership transferred
   ├─ Bank records FUNDS_DISBURSED → fiat disbursed to seller
   ├─ Title agent records CLOSING_CERTIFIED
   └─ Underwriter records POLICY_APPROVED
   
7. SETTLEMENT COMPLETED
   ├─ Eureka records SETTLEMENT_COMPLETED (finalizing attestation)
   ├─ Settlement marked finalized on-chain
   └─ Deed recorded with county + blockchain
   
8. ETHEREUM ANCHORING
   └─ Relayer batches attestations → merkle root → SettlementAnchor on mainnet
```

Every step produces an immutable, cryptographically signed on-chain record. The complete verification history for any settlement can be reconstructed from the chain at any time by any party.

---

## Chain Selection & Deployment

### Primary Chain: Base (Coinbase L2)

Base is the recommended deployment target for the SettlementVerificationRegistry and AttorneyVerificationNode contracts.

**Rationale:**
- Low transaction costs (<$0.01 per attestation)
- Fast finality (~2 seconds)
- Institutional credibility via Coinbase association
- Growing RWA (Real World Assets) ecosystem
- EVM-compatible (standard Solidity tooling)
- Propy has established precedent on Base for real estate recording

### Anchor Chain: Ethereum Mainnet

The SettlementAnchor contract deploys to Ethereum mainnet for maximum permanence and security. Merkle root anchoring keeps mainnet costs manageable (one transaction per batch of ~100 attestations).

### Alternative L2 Options

- **Polygon PoS** — Mature ecosystem, low cost, widely used by RWA projects. Viable alternative to Base.
- **Arbitrum** — Strong DeFi ecosystem. Consider if institutional DeFi integration is prioritized.
- **Private/Consortium** — Hyperledger Besu or similar. Only if institutional partners categorically refuse public chains. Sacrifices public verifiability.

### Deployment Addresses

| Contract | Chain | Address |
|----------|-------|---------|
| SettlementVerificationRegistry | Base | *TBD — Deployment pending* |
| AttorneyVerificationNode | Base | *TBD — Deployment pending* |
| SettlementAnchor | Ethereum Mainnet | *TBD — Deployment pending* |

---

## Integration with Eureka

The on-chain verification layer integrates with Eureka's off-chain settlement engine through a webhook/event listener pattern.

### Eureka → Chain (Writing Attestations)

When Eureka's state machine triggers a verification event:

1. Eureka's blockchain service constructs the attestation payload
2. The service signs and submits the transaction to the appropriate contract
3. The transaction is confirmed on L2
4. Eureka records the attestation ID and transaction hash in its internal database

### Chain → Eureka (Reading Confirmations)

When an external node (attorney, custodian) records an attestation:

1. The contract emits an `AttestationRecorded` event
2. Eureka's event listener (WebSocket subscription to L2 node) receives the event
3. The listener validates the attestation against the expected settlement state
4. If valid, the listener triggers the appropriate state transition in Eureka's state machine

### Eureka Off-Chain Database Fields

The `settlement_files` and `state_transitions` tables in Eureka's PostgreSQL database include fields for on-chain references:

```sql
-- In state_transitions table
attestation_id      INTEGER,        -- On-chain attestation ID
tx_hash             VARCHAR(66),    -- L2 transaction hash
block_number        BIGINT,         -- L2 block number
anchor_id           INTEGER,        -- Ethereum mainnet anchor ID (populated after anchoring)
```

This creates a bidirectional link: from Eureka's database you can look up the on-chain proof, and from the chain you can identify the Eureka settlement.

---

## Regulatory Framework

### Rhode Island — Paplauskas Compliance

The 2020 Rhode Island Supreme Court decision *In re William E. Paplauskas, Jr.* (228 A.3d 43) established that:

1. Non-attorney title agents MAY conduct residential real estate closings in conjunction with title insurance issuance
2. Title examination for marketability MUST be conducted by a licensed attorney
3. Deeds MUST be drafted by an attorney or reviewed by an attorney after preparation

The Attorney Verification Node contract and portal are designed specifically to satisfy requirements (2) and (3). Every title examination and deed review produces a permanent, cryptographically verifiable on-chain attestation that the attorney requirement was met.

### Required Disclosure

Under the Paplauskas ruling, when a non-attorney title agent conducts a closing, a disclosure notice must be provided to all parties. The Eureka system generates and tracks this disclosure as part of the settlement workflow.

### Multi-State Compliance

The verification node architecture is jurisdiction-agnostic. Attorney nodes are registered with their specific jurisdiction (bar state). When Eureka expands to Florida, Texas, or other states, the same contract infrastructure supports each jurisdiction's requirements — only the business logic around which attestation types are required changes.

### RESPA & TILA Compliance

Settlement fee disclosures, closing cost calculations, and good faith estimates are handled by Eureka's off-chain compliance engine. The on-chain layer records that compliance checks passed (via `COMPLIANCE_CLEARED` attestations) but does not store consumer financial data on-chain.

### Data Privacy

**No PII on-chain.** The contracts store only:
- Settlement IDs (opaque identifiers)
- Document hashes (SHA-256 — the document content is off-chain)
- Professional credentials (bar numbers, license numbers — public record)
- Wallet addresses
- Decisions and timestamps

Property addresses, party names, financial details, and all personal information remain in Eureka's encrypted off-chain database. The on-chain layer is a verification registry, not a data store.

---

## Entity Structure

```
Calculus Holdings LLC (Wyoming)
│
├── Constitutional Tender LLC ─── Precious metals trading platform
│
├── Eureka Settlement Services LLC ─── Non-custodial settlement coordination
│   └── Settlement Verification Chain ─── On-chain verification layer (this repo)
│
├── TILT LLC ─── Metals-backed real estate lending
│
├── Calculus Title & Escrow LLC ─── Licensed title/escrow services
│   ├── Licensed in Rhode Island (home state)
│   ├── Licensed in Florida
│   └── Licensed in Texas
│
└── [Other entities]
```

Eureka Settlement Services and Calculus Title & Escrow are **sister companies** under Calculus Holdings — not parent/subsidiary. This preserves Eureka's neutrality as a settlement coordinator. The title company is one of many verification nodes in the settlement network, interfacing with Eureka through the same API contracts as external partners.

---

## Development Setup

### Prerequisites

- Node.js 20+
- npm or yarn
- Hardhat (Solidity development framework)
- An RPC endpoint for Base Sepolia (testnet) and Ethereum Sepolia

### Installation

```bash
git clone https://github.com/calculus-holdings/eureka-chain.git
cd eureka-chain
npm install
```

### Environment

```bash
cp .env.example .env
# Edit .env with your configuration:
# BASE_RPC_URL=https://sepolia.base.org
# ETHEREUM_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
# DEPLOYER_PRIVATE_KEY=0x...
# ETHERSCAN_API_KEY=...
# BASESCAN_API_KEY=...
```

### Compile

```bash
npx hardhat compile
```

### Test

```bash
npx hardhat test
```

### Deploy (Testnet)

```bash
# Deploy SettlementVerificationRegistry to Base Sepolia
npx hardhat run scripts/deploy-registry.ts --network base-sepolia

# Deploy AttorneyVerificationNode to Base Sepolia
npx hardhat run scripts/deploy-attorney-node.ts --network base-sepolia

# Deploy SettlementAnchor to Ethereum Sepolia
npx hardhat run scripts/deploy-anchor.ts --network ethereum-sepolia
```

### Verify Contracts

```bash
npx hardhat verify --network base-sepolia REGISTRY_ADDRESS "ADMIN_ADDRESS"
npx hardhat verify --network base-sepolia ATTORNEY_NODE_ADDRESS "REGISTRY_ADDRESS"
npx hardhat verify --network ethereum-sepolia ANCHOR_ADDRESS "RELAYER_ADDRESS"
```

---

## API Reference

### SettlementVerificationRegistry

#### Write Functions

| Function | Access | Description |
|----------|--------|-------------|
| `registerNode(wallet, nodeType, credential, jurisdiction, name)` | NODE_REGISTRAR | Register a new verification node |
| `deactivateNode(wallet)` | REGISTRY_ADMIN | Deactivate a node |
| `reactivateNode(wallet)` | REGISTRY_ADMIN | Reactivate a deactivated node |
| `recordAttestation(settlementId, documentHash, attestationType, decision, conditionsHash, metadata)` | Registered Node | Record a verification attestation |
| `pause()` / `unpause()` | REGISTRY_ADMIN | Emergency pause/unpause |

#### Read Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `nodes(address)` | VerificationNode | Get node details |
| `attestations(id)` | Attestation | Get attestation by ID |
| `settlements(id)` | SettlementRecord | Get settlement record |
| `getSettlementAttestations(settlementId)` | uint256[] | All attestation IDs for a settlement |
| `getVerifierAttestations(verifier)` | uint256[] | All attestation IDs by a verifier |
| `verifyAttestation(settlementId, type, verifier)` | bool | Check if attestation exists |
| `verifyDocumentHash(attestationId, hash)` | bool | Verify document hash match |
| `attestationCount` | uint256 | Total attestations recorded |
| `getRegisteredNodeCount()` | uint256 | Total registered nodes |

### AttorneyVerificationNode

| Function | Access | Description |
|----------|--------|-------------|
| `certifyTitleExamination(cert, decision, conditionsHash)` | Attorney Node | Certify title examination |
| `certifyDeedReview(cert, decision, conditionsHash)` | Attorney Node | Certify deed review |
| `issueLegalOpinion(settlementId, hash, decision, conditionsHash, metadata)` | Attorney Node | Issue legal opinion |
| `getAttorneyStats(attorney)` | Public | Get certification counts |
| `getSettlementProperty(settlementId)` | Public | Get property ID for settlement |

### SettlementAnchor

| Function | Access | Description |
|----------|--------|-------------|
| `recordAnchor(merkleRoot, start, end, l2Block, l2Chain)` | Relayer | Record merkle root anchor |
| `verifyAnchor(merkleRoot)` | Public | Verify a merkle root exists |
| `setRelayer(newRelayer)` | Owner | Update relayer address |
| `anchorCount` | Public | Total anchors recorded |

---

## Security Considerations

### Smart Contract Security

- **OpenZeppelin Contracts** — Uses battle-tested AccessControl, ReentrancyGuard, and Pausable patterns.
- **No Fund Custody** — Contracts never hold ETH or tokens. Pure verification registry. Zero financial attack surface.
- **Role Separation** — Admin, registrar, and node roles are distinct. No single key controls everything.
- **Emergency Pause** — Registry can be paused by admin in case of compromise. Existing attestations remain permanent; only new attestation recording is blocked.

### Key Management

- Attorney and node signing keys should be managed through hardware wallets or institutional key management (e.g., Fireblocks, Fordefi).
- The portal abstracts key management — attorneys interact with a clean UI, not raw blockchain transactions.
- Deployer/admin keys must be multi-sig (Gnosis Safe recommended) for production.

### Audit Trail Integrity

- Attestations are append-only. The contracts have no `update` or `delete` functions for attestation records.
- Node deactivation prevents future attestations but cannot modify or remove historical records.
- Settlement finalization prevents any further attestations from being added to a completed settlement.

### Privacy

- No personally identifiable information (PII) is stored on-chain.
- Document contents are never on-chain — only SHA-256 hashes.
- Professional credentials (bar numbers) are public record and appropriate for on-chain storage.
- Settlement IDs are opaque hashes that cannot be reverse-engineered to reveal transaction details.

### Pre-Deployment Checklist

- [ ] Formal audit by a reputable smart contract auditing firm
- [ ] Multi-sig deployment for all admin roles
- [ ] Testnet validation with full settlement lifecycle
- [ ] Rate limiting / gas optimization for high-volume scenarios
- [ ] Monitoring and alerting for contract events
- [ ] Incident response plan for key compromise scenarios

---

## Roadmap

### Phase 1 — Foundation (Current)

- [x] Smart contract specification (SettlementVerificationRegistry, AttorneyVerificationNode, SettlementAnchor)
- [x] Attorney Verification Portal UI design
- [ ] Contract unit tests (Hardhat + Chai)
- [ ] Base Sepolia testnet deployment
- [ ] Ethereum Sepolia anchor deployment
- [ ] Portal ↔ contract integration (ethers.js / wagmi)

### Phase 2 — Integration

- [ ] Eureka state machine ↔ on-chain event listener
- [ ] Custodian node registration (Brinks, Loomis integration)
- [ ] Banking node registration (People's Bank, Pathward)
- [ ] Merkle root relayer service (automated anchoring)
- [ ] Attorney onboarding workflow (wallet creation, node registration)

### Phase 3 — Production

- [ ] Formal smart contract audit
- [ ] Base mainnet deployment
- [ ] Ethereum mainnet anchor deployment
- [ ] Multi-sig admin setup (Gnosis Safe)
- [ ] First live settlement with full on-chain verification
- [ ] Calculus Title & Escrow RI license integration

### Phase 4 — Scale

- [ ] Florida and Texas title company acquisition/licensing
- [ ] AI Title Search Engine ↔ portal integration
- [ ] Orchestra DSL workflow for autonomous closing
- [ ] Additional verification node types (appraiser, surveyor, inspector)
- [ ] Cross-chain verification proofs
- [ ] Public verification explorer (settlement audit viewer)

---

## License

Proprietary — Calculus Holdings LLC. All rights reserved.

Smart contract source code is provided for review and audit purposes. Deployment and commercial use require explicit authorization from Calculus Holdings LLC.

---

**Eureka Settlement Verification Chain** — Making every verification decision permanent, provable, and trustless.

*Built by Calculus Holdings LLC · Eureka Settlement Services*
