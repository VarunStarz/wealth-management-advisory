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

function SpeedometerGauge({ score }) {
  const cx = 130, cy = 102;
  const ro = 88, ri = 54;       // outer / inner radius → thick donut
  const needleLen = 74;
  const s = Math.min(Math.max(score, 0), 100);

  // angle: score 0 → π (left), score 100 → 0 (right)
  const rad  = (sc) => Math.PI * (1 - sc / 100);
  const outerPt = (sc) => [cx + ro * Math.cos(rad(sc)), cy - ro * Math.sin(rad(sc))];
  const innerPt = (sc) => [cx + ri * Math.cos(rad(sc)), cy - ri * Math.sin(rad(sc))];

  // Filled donut sector between score s1 and s2
  const sector = (s1, s2) => {
    const [ox1, oy1] = outerPt(s1);
    const [ox2, oy2] = outerPt(s2);
    const [ix2, iy2] = innerPt(s2);
    const [ix1, iy1] = innerPt(s1);
    const f = (n) => n.toFixed(3);
    return [
      `M ${f(ox1)} ${f(oy1)}`,
      `A ${ro} ${ro} 0 0 0 ${f(ox2)} ${f(oy2)}`,  // outer arc CCW
      `L ${f(ix2)} ${f(iy2)}`,
      `A ${ri} ${ri} 0 0 1 ${f(ix1)} ${f(iy1)}`,  // inner arc CW (back)
      'Z',
    ].join(' ');
  };

  // 5 zones with a 2-score-unit gap between each
  const ZONES = [
    { s1:  1, s2: 19, fill: '#22c55e' },  // green   – low risk
    { s1: 21, s2: 39, fill: '#84cc16' },  // lime
    { s1: 41, s2: 59, fill: '#eab308' },  // yellow
    { s1: 61, s2: 79, fill: '#f97316' },  // orange
    { s1: 81, s2: 99, fill: '#ef4444' },  // red     – high risk
  ];

  const angle = rad(s);
  const nx = cx + needleLen * Math.cos(angle);
  const ny = cy - needleLen * Math.sin(angle);

  let scoreColor = '#22c55e';
  if (s >= 80) scoreColor = '#ef4444';
  else if (s >= 60) scoreColor = '#f97316';
  else if (s >= 40) scoreColor = '#eab308';
  else if (s >= 20) scoreColor = '#84cc16';

  return (
    <svg viewBox="0 0 260 138" className="w-full">
      {/* Donut sectors */}
      {ZONES.map(({ s1, s2, fill }) => (
        <path key={s1} d={sector(s1, s2)} fill={fill} />
      ))}

      {/* LOW / HIGH axis labels */}
      <text x={cx - ro - 4} y={cy + 15} textAnchor="middle"
        fill="#94a3b8" fontSize="9" fontFamily="Inter, system-ui, sans-serif">LOW</text>
      <text x={cx + ro + 4} y={cy + 15} textAnchor="middle"
        fill="#94a3b8" fontSize="9" fontFamily="Inter, system-ui, sans-serif">HIGH</text>

      {/* Needle */}
      <line x1={cx} y1={cy} x2={nx.toFixed(3)} y2={ny.toFixed(3)}
        stroke="#1e293b" strokeWidth="2.5" strokeLinecap="round" />

      {/* Gold hub */}
      <circle cx={cx} cy={cy} r="14" fill="#fbbf24" />
      <circle cx={cx} cy={cy} r="8"  fill="#f59e0b" />
      <circle cx={cx} cy={cy} r="3.5" fill="#1c1917" />

      {/* Score */}
      <text x={cx} y={cy + 23} textAnchor="middle" fill={scoreColor}
        fontSize="20" fontWeight="800" fontFamily="Inter, system-ui, sans-serif">
        {score}
      </text>
      <text x={cx} y={cy + 33} textAnchor="middle" fill="#94a3b8"
        fontSize="8" fontFamily="Inter, system-ui, sans-serif">
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
        <SpeedometerGauge score={data.risk_score} />

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
