import { useState, useEffect, useCallback } from "react";

const NAVY = "#0A1628";
const DARK = "#111827";
const PANEL = "#1A2332";
const CARD = "#1E293B";
const BORDER = "#2D3B4E";
const ACCENT = "#C9A84C";
const ACCENT_DIM = "#8B7033";
const GREEN = "#10B981";
const GREEN_DIM = "#065F46";
const RED = "#EF4444";
const RED_DIM = "#7F1D1D";
const AMBER = "#F59E0B";
const AMBER_DIM = "#78350F";
const BLUE = "#3B82F6";
const TEXT = "#E2E8F0";
const TEXT_DIM = "#94A3B8";
const TEXT_MUTED = "#64748B";

// Mock data for demonstration
const MOCK_QUEUE = [
  {
    id: "sfx_a3f7c912e4b8d6f0",
    type: "title_examination",
    property: "528 Nanaquaket Road, Tiverton, RI 02878",
    parcelId: "TIV-2026-04821",
    submittedAt: "2026-02-28T14:23:00Z",
    priority: "standard",
    transactionValue: 485000,
    aiRiskScore: 12,
    chainLength: 7,
    encumbrances: 1,
    exceptions: 2,
    status: "pending_review",
    originatingSystem: "constitutional-tender",
    transactionType: "hybrid_settlement",
    assets: ["Allocated Gold (50 oz)", "USD Wire ($290,000)", "USDC ($5,000)"],
  },
  {
    id: "sfx_b2e6d801f3a9c5e1",
    type: "deed_review",
    property: "142 Main Street, Woonsocket, RI 02895",
    parcelId: "WOO-2026-11034",
    submittedAt: "2026-02-28T11:07:00Z",
    priority: "urgent",
    transactionValue: 325000,
    aiRiskScore: 4,
    deedType: "warranty",
    status: "pending_review",
    originatingSystem: "tilt",
    transactionType: "loan_closing",
    assets: ["Allocated Gold (30 oz)", "USD Wire ($195,000)"],
  },
  {
    id: "sfx_c1d5e790g2h8i4j3",
    type: "title_examination",
    property: "89 Prospect St, Unit 4B, Providence, RI 02906",
    parcelId: "PVD-2026-07291",
    submittedAt: "2026-02-27T09:45:00Z",
    priority: "standard",
    transactionValue: 215000,
    aiRiskScore: 38,
    chainLength: 12,
    encumbrances: 3,
    exceptions: 5,
    status: "pending_review",
    originatingSystem: "constitutional-tender",
    transactionType: "metal_purchase",
    assets: ["Allocated Silver (2000 oz)", "USD Wire ($215,000)"],
  },
];

const MOCK_COMPLETED = [
  {
    id: "sfx_d0c4b689a1e7f3g2",
    type: "title_examination",
    property: "77 Thames St, Newport, RI 02840",
    completedAt: "2026-02-27T16:12:00Z",
    decision: "approved",
    attestationId: 42,
    txHash: "0x8f3a...c7e1",
  },
  {
    id: "sfx_e9b3a578d0f6g2h1",
    type: "deed_review",
    property: "301 Broad St, Cumberland, RI 02864",
    completedAt: "2026-02-26T10:30:00Z",
    decision: "approved_with_conditions",
    attestationId: 41,
    txHash: "0x2d7b...f4a9",
  },
];

const MOCK_TITLE_REPORT = {
  propertyAddress: "528 Nanaquaket Road, Tiverton, RI 02878",
  parcelId: "TIV-2026-04821",
  searchDate: "2026-02-28",
  chainOfTitle: [
    { date: "2019-03-15", grantor: "Pooler, Earl & Nina", grantee: "Majewski, Vincent & Rebecca", instrument: "Warranty Deed", book: "1247", page: "312" },
    { date: "2005-08-22", grantor: "Correia, Manuel & Maria", grantee: "Pooler, Earl & Nina", instrument: "Warranty Deed", book: "982", page: "178" },
    { date: "1991-06-10", grantor: "Silva, Anthony J.", grantee: "Correia, Manuel & Maria", instrument: "Warranty Deed", book: "714", page: "45" },
    { date: "1978-11-03", grantor: "Tiverton Land Trust", grantee: "Silva, Anthony J.", instrument: "Warranty Deed", book: "523", page: "201" },
    { date: "1964-04-17", grantor: "Almeida, Francisco", grantee: "Tiverton Land Trust", instrument: "Quitclaim Deed", book: "387", page: "89" },
    { date: "1951-09-28", grantor: "Almeida, José & Rosa", grantee: "Almeida, Francisco", instrument: "Warranty Deed", book: "264", page: "156" },
    { date: "1938-02-14", grantor: "Town of Tiverton", grantee: "Almeida, José & Rosa", instrument: "Tax Deed", book: "189", page: "33" },
  ],
  encumbrances: [
    { type: "Mortgage", holder: "People's Credit Union", amount: 245000, recorded: "2019-03-15", book: "1247", page: "315", status: "Active — to be satisfied at closing" },
  ],
  exceptions: [
    { description: "Easement for underground utilities in favor of National Grid, recorded Book 892, Page 44 (2001)" },
    { description: "Right of way along northern boundary per Plat Book 12, Page 7 (1964)" },
  ],
  taxStatus: { current: true, annualAmount: 5842, lastPaid: "2025-12-15" },
  aiAssessment: {
    riskScore: 12,
    chainIntegrity: "CLEAN — No breaks detected in 88-year chain",
    recommendation: "APPROVE — Standard residential transaction with clean chain. Single active mortgage to be satisfied. Two standard utility/access exceptions.",
    flags: [],
  },
};

function formatDate(iso) {
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric", hour: "2-digit", minute: "2-digit" });
}

function formatCurrency(n) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n);
}

function RiskBadge({ score }) {
  const color = score <= 15 ? GREEN : score <= 35 ? AMBER : RED;
  const bg = score <= 15 ? GREEN_DIM : score <= 35 ? AMBER_DIM : RED_DIM;
  const label = score <= 15 ? "LOW" : score <= 35 ? "MEDIUM" : "HIGH";
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 6, padding: "3px 10px", borderRadius: 4, fontSize: 11, fontWeight: 700, letterSpacing: 1, color, background: bg, border: `1px solid ${color}33` }}>
      <span style={{ width: 6, height: 6, borderRadius: "50%", background: color }} />
      {label} RISK ({score})
    </span>
  );
}

function StatusBadge({ status }) {
  const map = {
    pending_review: { label: "PENDING REVIEW", color: AMBER, bg: AMBER_DIM },
    approved: { label: "APPROVED", color: GREEN, bg: GREEN_DIM },
    approved_with_conditions: { label: "APPROVED W/ CONDITIONS", color: BLUE, bg: "#1E3A5F" },
    rejected: { label: "REJECTED", color: RED, bg: RED_DIM },
  };
  const s = map[status] || map.pending_review;
  return (
    <span style={{ padding: "3px 10px", borderRadius: 4, fontSize: 10, fontWeight: 700, letterSpacing: 1, color: s.color, background: s.bg, border: `1px solid ${s.color}33` }}>
      {s.label}
    </span>
  );
}

function PriorityBadge({ priority }) {
  if (priority !== "urgent") return null;
  return (
    <span style={{ padding: "2px 8px", borderRadius: 3, fontSize: 10, fontWeight: 700, letterSpacing: 1, color: RED, background: RED_DIM, border: `1px solid ${RED}33`, animation: "pulse 2s infinite" }}>
      URGENT
    </span>
  );
}

function QueueCard({ item, onClick, selected }) {
  const isSelected = selected?.id === item.id;
  return (
    <div
      onClick={() => onClick(item)}
      style={{
        padding: "16px 18px",
        background: isSelected ? `${ACCENT}11` : CARD,
        border: `1px solid ${isSelected ? ACCENT : BORDER}`,
        borderLeft: `3px solid ${isSelected ? ACCENT : "transparent"}`,
        borderRadius: 6,
        cursor: "pointer",
        transition: "all 0.2s ease",
        marginBottom: 8,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
          <span style={{ fontSize: 11, fontFamily: "'JetBrains Mono', monospace", color: TEXT_MUTED }}>{item.id}</span>
          <PriorityBadge priority={item.priority} />
        </div>
        <RiskBadge score={item.aiRiskScore} />
      </div>
      <div style={{ fontSize: 14, fontWeight: 600, color: TEXT, marginBottom: 4 }}>{item.property}</div>
      <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>
        <span style={{ fontSize: 12, color: TEXT_DIM, textTransform: "uppercase", letterSpacing: 0.5, fontWeight: 600 }}>
          {item.type.replace("_", " ")}
        </span>
        <span style={{ fontSize: 12, color: ACCENT }}>{formatCurrency(item.transactionValue)}</span>
        <span style={{ fontSize: 11, color: TEXT_MUTED }}>{formatDate(item.submittedAt)}</span>
      </div>
      <div style={{ display: "flex", gap: 6, marginTop: 8, flexWrap: "wrap" }}>
        {item.assets.map((a, i) => (
          <span key={i} style={{ fontSize: 10, padding: "2px 8px", borderRadius: 3, background: `${ACCENT}15`, color: ACCENT_DIM, border: `1px solid ${ACCENT}22` }}>
            {a}
          </span>
        ))}
      </div>
    </div>
  );
}

function TitleReportView({ report }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      {/* AI Assessment Banner */}
      <div style={{ background: `${GREEN_DIM}`, border: `1px solid ${GREEN}33`, borderRadius: 6, padding: 16 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: GREEN }}>AI ASSESSMENT</span>
          <RiskBadge score={report.aiAssessment.riskScore} />
        </div>
        <div style={{ fontSize: 13, color: TEXT, lineHeight: 1.6 }}>{report.aiAssessment.recommendation}</div>
        <div style={{ fontSize: 12, color: TEXT_DIM, marginTop: 6 }}>{report.aiAssessment.chainIntegrity}</div>
      </div>

      {/* Chain of Title */}
      <div>
        <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 1, color: TEXT_MUTED, marginBottom: 10, textTransform: "uppercase" }}>Chain of Title ({report.chainOfTitle.length} transfers)</div>
        <div style={{ position: "relative", paddingLeft: 20 }}>
          <div style={{ position: "absolute", left: 6, top: 4, bottom: 4, width: 2, background: BORDER }} />
          {report.chainOfTitle.map((link, i) => (
            <div key={i} style={{ position: "relative", marginBottom: 12, paddingLeft: 16 }}>
              <div style={{ position: "absolute", left: -16, top: 6, width: 10, height: 10, borderRadius: "50%", background: i === 0 ? ACCENT : BORDER, border: `2px solid ${i === 0 ? ACCENT : TEXT_MUTED}` }} />
              <div style={{ fontSize: 11, color: TEXT_MUTED, fontFamily: "'JetBrains Mono', monospace" }}>{link.date} — {link.instrument}</div>
              <div style={{ fontSize: 13, color: TEXT }}>
                <span style={{ color: TEXT_DIM }}>{link.grantor}</span>
                <span style={{ color: ACCENT, margin: "0 6px" }}>→</span>
                <span style={{ fontWeight: 600 }}>{link.grantee}</span>
              </div>
              <div style={{ fontSize: 10, color: TEXT_MUTED }}>Book {link.book}, Page {link.page}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Encumbrances */}
      <div>
        <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 1, color: TEXT_MUTED, marginBottom: 10, textTransform: "uppercase" }}>Active Encumbrances ({report.encumbrances.length})</div>
        {report.encumbrances.map((enc, i) => (
          <div key={i} style={{ padding: 12, background: `${AMBER}08`, border: `1px solid ${AMBER}22`, borderRadius: 6, marginBottom: 6 }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: TEXT }}>{enc.type} — {enc.holder}</div>
            <div style={{ fontSize: 12, color: TEXT_DIM, marginTop: 4 }}>
              {formatCurrency(enc.amount)} · Recorded {enc.recorded} · Book {enc.book}, Page {enc.page}
            </div>
            <div style={{ fontSize: 11, color: AMBER, marginTop: 4, fontWeight: 600 }}>{enc.status}</div>
          </div>
        ))}
      </div>

      {/* Exceptions */}
      <div>
        <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 1, color: TEXT_MUTED, marginBottom: 10, textTransform: "uppercase" }}>Schedule B Exceptions ({report.exceptions.length})</div>
        {report.exceptions.map((exc, i) => (
          <div key={i} style={{ padding: 10, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 6, marginBottom: 6, fontSize: 13, color: TEXT, lineHeight: 1.5 }}>
            {i + 1}. {exc.description}
          </div>
        ))}
      </div>

      {/* Tax Status */}
      <div style={{ padding: 12, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 6 }}>
        <div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 1, color: TEXT_MUTED, marginBottom: 6, textTransform: "uppercase" }}>Property Tax Status</div>
        <div style={{ display: "flex", gap: 20, fontSize: 13 }}>
          <span style={{ color: report.taxStatus.current ? GREEN : RED }}>
            {report.taxStatus.current ? "✓ Current" : "✗ Delinquent"}
          </span>
          <span style={{ color: TEXT_DIM }}>Annual: {formatCurrency(report.taxStatus.annualAmount)}</span>
          <span style={{ color: TEXT_DIM }}>Last paid: {report.taxStatus.lastPaid}</span>
        </div>
      </div>
    </div>
  );
}

function CertificationPanel({ item, onCertify, onClose }) {
  const [decision, setDecision] = useState(null);
  const [conditions, setConditions] = useState("");
  const [signing, setSigning] = useState(false);
  const [signed, setSigned] = useState(false);

  const handleSign = useCallback(() => {
    setSigning(true);
    setTimeout(() => {
      setSigning(false);
      setSigned(true);
      if (onCertify) onCertify(item, decision, conditions);
    }, 2000);
  }, [item, decision, conditions, onCertify]);

  if (signed) {
    return (
      <div style={{ padding: 30, textAlign: "center" }}>
        <div style={{ width: 64, height: 64, borderRadius: "50%", background: GREEN_DIM, border: `2px solid ${GREEN}`, display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", fontSize: 28 }}>✓</div>
        <div style={{ fontSize: 18, fontWeight: 700, color: TEXT, marginBottom: 8 }}>Attestation Recorded On-Chain</div>
        <div style={{ fontSize: 13, color: TEXT_DIM, marginBottom: 16 }}>Your certification has been cryptographically signed and permanently recorded on the settlement verification registry.</div>
        <div style={{ padding: 12, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 6, fontFamily: "'JetBrains Mono', monospace", fontSize: 11, color: ACCENT, textAlign: "left" }}>
          <div>Attestation ID: #43</div>
          <div>Settlement: {item.id}</div>
          <div>Block: 18,294,571</div>
          <div>Tx: 0x7f2a...b3c8</div>
          <div>Timestamp: {new Date().toISOString()}</div>
        </div>
        <button onClick={onClose} style={{ marginTop: 20, padding: "10px 24px", background: ACCENT, color: NAVY, border: "none", borderRadius: 4, fontWeight: 700, fontSize: 13, cursor: "pointer", letterSpacing: 0.5 }}>
          Return to Queue
        </button>
      </div>
    );
  }

  return (
    <div style={{ padding: 20 }}>
      <div style={{ fontSize: 14, fontWeight: 700, color: TEXT, marginBottom: 16 }}>Certification Decision</div>

      <div style={{ display: "flex", gap: 8, marginBottom: 16, flexWrap: "wrap" }}>
        {[
          { key: "approved", label: "Approve", color: GREEN, bg: GREEN_DIM },
          { key: "approved_with_conditions", label: "Approve with Conditions", color: BLUE, bg: "#1E3A5F" },
          { key: "rejected", label: "Reject", color: RED, bg: RED_DIM },
        ].map((opt) => (
          <button
            key={opt.key}
            onClick={() => setDecision(opt.key)}
            style={{
              padding: "8px 16px",
              background: decision === opt.key ? opt.bg : "transparent",
              border: `1px solid ${decision === opt.key ? opt.color : BORDER}`,
              borderRadius: 4,
              color: decision === opt.key ? opt.color : TEXT_MUTED,
              fontWeight: 600,
              fontSize: 12,
              cursor: "pointer",
              transition: "all 0.2s",
            }}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {(decision === "approved_with_conditions" || decision === "rejected") && (
        <div style={{ marginBottom: 16 }}>
          <label style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1, color: TEXT_MUTED, display: "block", marginBottom: 6, textTransform: "uppercase" }}>
            {decision === "rejected" ? "Reason for Rejection" : "Conditions"}
          </label>
          <textarea
            value={conditions}
            onChange={(e) => setConditions(e.target.value)}
            placeholder={decision === "rejected" ? "Describe the issue(s) found..." : "Describe conditions that must be satisfied..."}
            style={{
              width: "100%",
              minHeight: 80,
              padding: 12,
              background: DARK,
              border: `1px solid ${BORDER}`,
              borderRadius: 4,
              color: TEXT,
              fontSize: 13,
              fontFamily: "inherit",
              resize: "vertical",
              outline: "none",
              boxSizing: "border-box",
            }}
          />
        </div>
      )}

      {decision && (
        <div style={{ borderTop: `1px solid ${BORDER}`, paddingTop: 16 }}>
          <div style={{ fontSize: 11, color: TEXT_MUTED, marginBottom: 12, lineHeight: 1.6 }}>
            By signing, you certify that you have reviewed the AI-generated work product for settlement{" "}
            <span style={{ fontFamily: "'JetBrains Mono', monospace", color: ACCENT }}>{item.id}</span>,
            applied your professional judgment as a licensed attorney in the jurisdiction of Rhode Island,
            and attest to this decision under your bar credentials. This certification will be permanently
            recorded on the settlement verification blockchain.
          </div>

          <button
            onClick={handleSign}
            disabled={signing}
            style={{
              width: "100%",
              padding: "14px 24px",
              background: signing ? ACCENT_DIM : ACCENT,
              color: NAVY,
              border: "none",
              borderRadius: 4,
              fontWeight: 700,
              fontSize: 14,
              cursor: signing ? "default" : "pointer",
              letterSpacing: 0.5,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
            }}
          >
            {signing ? (
              <>
                <span style={{ display: "inline-block", width: 16, height: 16, border: `2px solid ${NAVY}`, borderTopColor: "transparent", borderRadius: "50%", animation: "spin 1s linear infinite" }} />
                Recording On-Chain...
              </>
            ) : (
              <>Sign & Record Attestation</>
            )}
          </button>
        </div>
      )}
    </div>
  );
}

export default function AttorneyVerificationPortal() {
  const [selectedItem, setSelectedItem] = useState(null);
  const [view, setView] = useState("queue");
  const [certifying, setCertifying] = useState(false);

  return (
    <div style={{ minHeight: "100vh", background: NAVY, color: TEXT, fontFamily: "'DM Sans', -apple-system, sans-serif" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap');
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: ${DARK}; }
        ::-webkit-scrollbar-thumb { background: ${BORDER}; border-radius: 3px; }
      `}</style>

      {/* Header */}
      <header style={{ background: DARK, borderBottom: `1px solid ${BORDER}`, padding: "0 24px", height: 56, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 32, height: 32, background: `linear-gradient(135deg, ${ACCENT}, ${ACCENT_DIM})`, borderRadius: 6, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, fontSize: 14, color: NAVY }}>E</div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 700, color: TEXT, letterSpacing: 0.5 }}>EUREKA</div>
            <div style={{ fontSize: 9, fontWeight: 600, letterSpacing: 2, color: ACCENT, textTransform: "uppercase" }}>Attorney Verification Portal</div>
          </div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: GREEN, boxShadow: `0 0 8px ${GREEN}66` }} />
            <span style={{ fontSize: 11, color: TEXT_DIM }}>Base L2 Connected</span>
          </div>
          <div style={{ height: 24, width: 1, background: BORDER }} />
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{ width: 28, height: 28, borderRadius: "50%", background: PANEL, border: `1px solid ${BORDER}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, fontWeight: 700, color: ACCENT }}>JD</div>
            <div>
              <div style={{ fontSize: 12, fontWeight: 600, color: TEXT }}>J. DaSilva, Esq.</div>
              <div style={{ fontSize: 10, color: TEXT_MUTED }}>Bar #RI-8847 · Node 0x7f2a...3c8</div>
            </div>
          </div>
        </div>
      </header>

      {/* Stats Bar */}
      <div style={{ background: PANEL, borderBottom: `1px solid ${BORDER}`, padding: "12px 24px", display: "flex", gap: 32 }}>
        {[
          { label: "Pending Review", value: MOCK_QUEUE.length, color: AMBER },
          { label: "Certified Today", value: 2, color: GREEN },
          { label: "Avg Review Time", value: "11 min", color: BLUE },
          { label: "On-Chain Attestations", value: 43, color: ACCENT },
        ].map((stat, i) => (
          <div key={i} style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
            <span style={{ fontSize: 20, fontWeight: 700, color: stat.color, fontFamily: "'JetBrains Mono', monospace" }}>{stat.value}</span>
            <span style={{ fontSize: 11, color: TEXT_MUTED, fontWeight: 600, letterSpacing: 0.5, textTransform: "uppercase" }}>{stat.label}</span>
          </div>
        ))}
      </div>

      {/* Main Content */}
      <div style={{ display: "flex", height: "calc(100vh - 56px - 48px)" }}>
        {/* Left Panel — Queue */}
        <div style={{ width: 420, borderRight: `1px solid ${BORDER}`, display: "flex", flexDirection: "column" }}>
          <div style={{ padding: "16px 18px", borderBottom: `1px solid ${BORDER}`, display: "flex", gap: 0 }}>
            {["queue", "completed"].map((tab) => (
              <button
                key={tab}
                onClick={() => { setView(tab); setSelectedItem(null); setCertifying(false); }}
                style={{
                  padding: "8px 16px",
                  background: view === tab ? `${ACCENT}15` : "transparent",
                  border: `1px solid ${view === tab ? ACCENT : "transparent"}`,
                  borderRadius: 4,
                  color: view === tab ? ACCENT : TEXT_MUTED,
                  fontWeight: 600,
                  fontSize: 12,
                  cursor: "pointer",
                  textTransform: "uppercase",
                  letterSpacing: 1,
                }}
              >
                {tab === "queue" ? `Review Queue (${MOCK_QUEUE.length})` : `Completed (${MOCK_COMPLETED.length})`}
              </button>
            ))}
          </div>
          <div style={{ flex: 1, overflowY: "auto", padding: 12 }}>
            {view === "queue" ? (
              MOCK_QUEUE.map((item) => (
                <QueueCard key={item.id} item={item} selected={selectedItem} onClick={(i) => { setSelectedItem(i); setCertifying(false); }} />
              ))
            ) : (
              MOCK_COMPLETED.map((item) => (
                <div key={item.id} style={{ padding: "14px 18px", background: CARD, border: `1px solid ${BORDER}`, borderRadius: 6, marginBottom: 8 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
                    <span style={{ fontSize: 11, fontFamily: "'JetBrains Mono', monospace", color: TEXT_MUTED }}>{item.id}</span>
                    <StatusBadge status={item.decision} />
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 600, color: TEXT, marginBottom: 4 }}>{item.property}</div>
                  <div style={{ display: "flex", gap: 12, fontSize: 11, color: TEXT_MUTED }}>
                    <span>Attestation #{item.attestationId}</span>
                    <span>Tx: {item.txHash}</span>
                    <span>{formatDate(item.completedAt)}</span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Right Panel — Detail / Review */}
        <div style={{ flex: 1, overflowY: "auto", display: "flex", flexDirection: "column" }}>
          {!selectedItem ? (
            <div style={{ flex: 1, display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", gap: 12 }}>
              <div style={{ width: 48, height: 48, borderRadius: 8, background: PANEL, border: `1px solid ${BORDER}`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 20, color: TEXT_MUTED }}>⎔</div>
              <div style={{ fontSize: 14, color: TEXT_MUTED }}>Select a verification request from the queue</div>
            </div>
          ) : (
            <div style={{ animation: "fadeIn 0.3s ease" }}>
              {/* Detail Header */}
              <div style={{ padding: "16px 24px", borderBottom: `1px solid ${BORDER}`, background: PANEL }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <div>
                    <div style={{ fontSize: 16, fontWeight: 700, color: TEXT }}>{selectedItem.property}</div>
                    <div style={{ display: "flex", gap: 12, marginTop: 6, alignItems: "center", flexWrap: "wrap" }}>
                      <span style={{ fontSize: 12, color: TEXT_DIM }}>Parcel: {selectedItem.parcelId}</span>
                      <span style={{ fontSize: 12, color: ACCENT }}>{formatCurrency(selectedItem.transactionValue)}</span>
                      <span style={{ fontSize: 11, padding: "2px 8px", borderRadius: 3, background: `${BLUE}15`, color: BLUE, border: `1px solid ${BLUE}22`, fontWeight: 600, textTransform: "uppercase" }}>
                        {selectedItem.transactionType.replace("_", " ")}
                      </span>
                      <span style={{ fontSize: 11, color: TEXT_MUTED }}>via {selectedItem.originatingSystem}</span>
                    </div>
                  </div>
                  {!certifying && (
                    <button
                      onClick={() => setCertifying(true)}
                      style={{
                        padding: "10px 20px",
                        background: ACCENT,
                        color: NAVY,
                        border: "none",
                        borderRadius: 4,
                        fontWeight: 700,
                        fontSize: 13,
                        cursor: "pointer",
                        letterSpacing: 0.5,
                        whiteSpace: "nowrap",
                      }}
                    >
                      Begin Certification
                    </button>
                  )}
                </div>
              </div>

              {/* Content Area */}
              <div style={{ display: "flex", flex: 1 }}>
                {/* Report */}
                <div style={{ flex: 1, padding: 24, overflowY: "auto" }}>
                  {selectedItem.type === "title_examination" ? (
                    <TitleReportView report={MOCK_TITLE_REPORT} />
                  ) : (
                    <div style={{ padding: 30, textAlign: "center", color: TEXT_MUTED }}>
                      <div style={{ fontSize: 14, marginBottom: 8 }}>Deed Document Preview</div>
                      <div style={{ padding: 40, background: CARD, border: `1px solid ${BORDER}`, borderRadius: 6, fontSize: 13 }}>
                        AI-generated deed document would render here with highlighted sections for attorney review.
                      </div>
                    </div>
                  )}
                </div>

                {/* Certification Panel (slides in from right) */}
                {certifying && (
                  <div style={{ width: 360, borderLeft: `1px solid ${BORDER}`, background: PANEL, animation: "fadeIn 0.3s ease", overflowY: "auto" }}>
                    <CertificationPanel
                      item={selectedItem}
                      onClose={() => { setCertifying(false); setSelectedItem(null); }}
                      onCertify={(item, decision, conditions) => {
                        console.log("Certified:", item.id, decision, conditions);
                      }}
                    />
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
