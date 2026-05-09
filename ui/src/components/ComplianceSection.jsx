/* ── icons ──────────────────────────────────────────────── */
function IconCheck() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor"
      strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4">
      <polyline points="2.5 8.5 6.5 12.5 13.5 3.5" />
    </svg>
  );
}
function IconCross() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor"
      strokeWidth="2.5" strokeLinecap="round" className="w-4 h-4">
      <line x1="4" y1="4" x2="12" y2="12" />
      <line x1="12" y1="4" x2="4" y2="12" />
    </svg>
  );
}
function IconCaution() {
  return (
    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor"
      strokeWidth="2" strokeLinecap="round" className="w-4 h-4">
      <circle cx="8" cy="8" r="6.5" />
      <line x1="8" y1="5" x2="8" y2="8.5" />
      <circle cx="8" cy="11" r="0.7" fill="currentColor" stroke="none" />
    </svg>
  );
}

/* ── checklist config ───────────────────────────────────── */
const CANONICAL_CHECKS = [
  { src: 'CDD',       label: 'KYC & Due Diligence'    },
  { src: 'EDD',       label: 'Enhanced Due Diligence' },
  { src: 'PORTFOLIO', label: 'Portfolio Suitability'  },
  { src: 'INCOME',    label: 'Income Validation'      },
  { src: 'CIBIL',     label: 'Credit Health'          },
];

const CHECK_STYLE = {
  PASS: {
    wrap:      'border-emerald-100 bg-emerald-50/60',
    hub:       'bg-emerald-100 border-emerald-300 text-emerald-600',
    badge:     'CLEAR',
    badgeCls:  'bg-emerald-100 text-emerald-700',
    labelCls:  'text-slate-700',
    detailCls: 'text-emerald-600',
  },
  CAUTION: {
    wrap:      'border-amber-100 bg-amber-50/60',
    hub:       'bg-amber-100 border-amber-300 text-amber-600',
    badge:     'CAUTION',
    badgeCls:  'bg-amber-100 text-amber-700',
    labelCls:  'text-slate-800',
    detailCls: 'text-amber-700',
  },
  FAIL: {
    wrap:      'border-red-100 bg-red-50/60',
    hub:       'bg-red-100 border-red-300 text-red-600',
    badge:     'NON-COMPLIANT',
    badgeCls:  'bg-red-100 text-red-700',
    labelCls:  'text-slate-800',
    detailCls: 'text-red-700',
  },
};

function getCheckStatus(src, high, medium) {
  const hFlags = high.filter(f => f.source === src);
  const mFlags = medium.filter(f => f.source === src);
  if (hFlags.length > 0) return { status: 'FAIL',    detail: hFlags[0].flag };
  if (mFlags.length > 0) return { status: 'CAUTION', detail: mFlags[0].flag };
  return { status: 'PASS', detail: 'No issues detected' };
}

function ChecklistItem({ label, status, detail }) {
  const c = CHECK_STYLE[status];
  const text = detail?.length > 110 ? detail.slice(0, 110) + '…' : (detail ?? '');
  return (
    <div className={`flex items-start gap-3 p-3.5 rounded-xl border ${c.wrap}`}>
      <div className={`flex-shrink-0 w-8 h-8 rounded-full border-2 flex items-center justify-center ${c.hub}`}>
        {status === 'PASS'    && <IconCheck />}
        {status === 'CAUTION' && <IconCaution />}
        {status === 'FAIL'    && <IconCross />}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap mb-0.5">
          <span className={`text-sm font-semibold ${c.labelCls}`}>{label}</span>
          <span className={`px-1.5 py-0.5 rounded text-[9px] font-bold tracking-widest uppercase ${c.badgeCls}`}>
            {c.badge}
          </span>
        </div>
        <p className={`text-xs leading-relaxed ${c.detailCls}`}>{text}</p>
      </div>
    </div>
  );
}

/* ── flag card (existing flags detail section) ──────────── */
const FLAG_STYLE = {
  high:   { wrap: 'bg-red-50 border-red-200',    badge: 'bg-red-100 text-red-700',    text: 'text-red-900'   },
  medium: { wrap: 'bg-amber-50 border-amber-200', badge: 'bg-amber-100 text-amber-700', text: 'text-amber-900' },
};

function FlagCard({ flag, level }) {
  const s = FLAG_STYLE[level];
  return (
    <div className={`flex gap-3 border rounded-xl p-4 ${s.wrap}`}>
      <span className={`flex-shrink-0 mt-0.5 px-2 py-0.5 rounded text-xs font-bold tracking-wide ${s.badge}`}>
        {flag.source}
      </span>
      <p className={`text-sm leading-relaxed ${s.text}`}>{flag.flag}</p>
    </div>
  );
}

/* ── main component ─────────────────────────────────────── */
export default function ComplianceSection({ data }) {
  if (!data) return null;

  const high   = data.red_flags_high        ?? [];
  const medium = data.caution_points_medium ?? [];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      {/* header */}
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">
          Compliance &amp; Due Diligence
        </h2>
      </div>

      <div className="p-5 space-y-6">

        {/* ── 1. Compliance checklist ── */}
        <div>
          <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-3">
            Compliance Checklist
          </div>
          <div className="space-y-2">
            {CANONICAL_CHECKS.map(({ src, label }) => {
              const { status, detail } = getCheckStatus(src, high, medium);
              return (
                <ChecklistItem key={src} label={label} status={status} detail={detail} />
              );
            })}
          </div>
        </div>

        {/* ── 2. Flag details ── */}
        {(high.length > 0 || medium.length > 0) && (
          <div className="space-y-5">
            <div className="border-t border-slate-100" />

            {high.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-2.5 h-2.5 rounded-full bg-red-500 flex-shrink-0" />
                  <span className="text-xs font-bold text-red-600 uppercase tracking-wider">
                    High Severity Flags
                  </span>
                </div>
                <div className="space-y-2">
                  {high.map((f, i) => <FlagCard key={i} flag={f} level="high" />)}
                </div>
              </div>
            )}

            {medium.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-2.5 h-2.5 rounded-full bg-amber-500 flex-shrink-0" />
                  <span className="text-xs font-bold text-amber-600 uppercase tracking-wider">
                    Medium Severity Cautions
                  </span>
                </div>
                <div className="space-y-2">
                  {medium.map((f, i) => <FlagCard key={i} flag={f} level="medium" />)}
                </div>
              </div>
            )}
          </div>
        )}

        {high.length === 0 && medium.length === 0 && (
          <p className="text-emerald-600 text-sm font-medium">
            All compliance checks passed — no flags detected.
          </p>
        )}

        {/* ── 3. EDD summary ── */}
        {data.edd_summary && (
          <>
            <div className="border-t border-slate-100" />
            <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
              <div className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">
                EDD Summary
              </div>
              <p className="text-slate-700 text-sm leading-relaxed">{data.edd_summary}</p>
            </div>
          </>
        )}

      </div>
    </div>
  );
}
