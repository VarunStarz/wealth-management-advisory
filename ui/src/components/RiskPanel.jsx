const TIER = {
  LOW:       { ring: '#10b981', bg: 'bg-emerald-50', border: 'border-emerald-200', text: 'text-emerald-700' },
  MEDIUM:    { ring: '#f59e0b', bg: 'bg-amber-50',   border: 'border-amber-200',   text: 'text-amber-700' },
  HIGH:      { ring: '#ef4444', bg: 'bg-red-50',     border: 'border-red-200',     text: 'text-red-700' },
  VERY_HIGH: { ring: '#991b1b', bg: 'bg-red-100',    border: 'border-red-300',     text: 'text-red-900' },
};

const CDD = {
  PASS:         { bg: 'bg-emerald-100', text: 'text-emerald-700' },
  REFER_TO_EDD: { bg: 'bg-amber-100',  text: 'text-amber-700' },
  FAIL:         { bg: 'bg-red-100',    text: 'text-red-700' },
};

const ACTION = {
  STANDARD_REVIEW:       { bg: 'bg-blue-50',   text: 'text-blue-700' },
  ENHANCED_MONITORING:   { bg: 'bg-amber-50',  text: 'text-amber-700' },
  COMPLIANCE_ESCALATION: { bg: 'bg-red-50',    text: 'text-red-700' },
};

function SemiGauge({ score }) {
  const r = 38;
  const cx = 60;
  const cy = 58;
  const semiCirc = Math.PI * r;
  const filled = Math.min(score / 100, 1) * semiCirc;

  let color = '#10b981';
  if (score >= 40) color = '#f59e0b';
  if (score >= 60) color = '#ef4444';
  if (score >= 80) color = '#991b1b';

  return (
    <svg viewBox="0 0 120 76" className="w-full">
      {/* track */}
      <path
        d={`M ${cx - r} ${cy} A ${r} ${r} 0 0 0 ${cx + r} ${cy}`}
        fill="none" stroke="#e2e8f0" strokeWidth="11" strokeLinecap="round"
      />
      {/* filled */}
      <path
        d={`M ${cx - r} ${cy} A ${r} ${r} 0 0 0 ${cx + r} ${cy}`}
        fill="none" stroke={color} strokeWidth="11" strokeLinecap="round"
        strokeDasharray={`${filled} ${semiCirc}`}
      />
      {/* score */}
      <text x={cx} y={cy - 6} textAnchor="middle" fill={color}
        fontSize="22" fontWeight="800" fontFamily="Inter, system-ui, sans-serif">
        {score}
      </text>
      <text x={cx} y={cy + 10} textAnchor="middle" fill="#94a3b8"
        fontSize="9" fontFamily="Inter, system-ui, sans-serif">
        out of 100
      </text>
    </svg>
  );
}

export default function RiskPanel({ data }) {
  if (!data) return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden h-full">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">Risk Profile</h2>
      </div>
      <div className="p-5 text-center text-slate-400 text-sm">
        CDD not run for this pipeline.
      </div>
    </div>
  );

  const t  = TIER[data.risk_tier]   ?? TIER.LOW;
  const c  = CDD[data.cdd_status]   ?? CDD.PASS;
  const a  = ACTION[data.recommended_compliance_action] ?? ACTION.STANDARD_REVIEW;

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden h-full">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">Risk Profile</h2>
      </div>
      <div className="p-5 flex flex-col items-center gap-4">
        <SemiGauge score={data.risk_score} />

        <div className={`w-full text-center py-2.5 rounded-xl border ${t.bg} ${t.border}`}>
          <div className={`text-base font-bold ${t.text}`}>
            {data.risk_tier?.replace('_', ' ')}
          </div>
          <div className="text-slate-400 text-xs mt-0.5">Risk Tier</div>
        </div>

        <div className="w-full space-y-1.5">
          <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider">CDD Status</div>
          <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold ${c.bg} ${c.text}`}>
            {data.cdd_status?.replace(/_/g, ' ')}
          </span>
        </div>

        <div className="w-full space-y-1.5">
          <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Compliance Action</div>
          <span className={`inline-block px-3 py-1.5 rounded-lg text-xs font-semibold ${a.bg} ${a.text}`}>
            {data.recommended_compliance_action?.replace(/_/g, ' ')}
          </span>
        </div>
      </div>
    </div>
  );
}
