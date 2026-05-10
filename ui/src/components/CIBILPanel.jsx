const HEALTH_STYLE = {
  EXCELLENT: { bar: 'bg-emerald-500', badge: 'bg-emerald-100 text-emerald-700 border-emerald-200' },
  GOOD:      { bar: 'bg-lime-500',    badge: 'bg-lime-100   text-lime-700   border-lime-200'   },
  FAIR:      { bar: 'bg-amber-500',   badge: 'bg-amber-100  text-amber-700  border-amber-200'  },
  POOR:      { bar: 'bg-orange-500',  badge: 'bg-orange-100 text-orange-700 border-orange-200' },
  CRITICAL:  { bar: 'bg-red-600',     badge: 'bg-red-100    text-red-700    border-red-200'    },
};

function CIBILBar({ score }) {
  // CIBIL range 300–900
  const pct = Math.min(Math.max(((score - 300) / 600) * 100, 0), 100);
  let color = 'bg-red-500';
  if (pct >= 75) color = 'bg-emerald-500';
  else if (pct >= 58) color = 'bg-lime-500';
  else if (pct >= 42) color = 'bg-amber-500';
  else if (pct >= 25) color = 'bg-orange-500';

  return (
    <div className="px-5 py-4 border-t border-slate-100">
      <div className="flex justify-between items-center mb-1.5">
        <span className="text-xs text-slate-400">300 — Poor</span>
        <span className="text-xl font-extrabold text-slate-800">{score}</span>
        <span className="text-xs text-slate-400">900 — Excellent</span>
      </div>
      <div className="h-2.5 bg-slate-100 rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all ${color}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default function CIBILPanel({ data }) {
  if (!data) return null;

  const h    = HEALTH_STYLE[data.credit_health] ?? HEALTH_STYLE.FAIR;
  const flags = data.red_flags ?? [];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest flex-1">
          CIBIL &amp; Credit Health
        </h2>
        {data.credit_health && (
          <span className={`px-2.5 py-1 rounded-full border text-xs font-bold ${h.badge}`}>
            {data.credit_health}
          </span>
        )}
      </div>

      {data.cibil_equivalent != null && (
        <CIBILBar score={data.cibil_equivalent} />
      )}

      <div className="divide-y divide-slate-100">
        {[
          { label: 'Risk Tier',   value: data.risk_tier?.replace('_', ' ') ?? '—' },
          { label: 'KYC Status',  value: data.kyc_status ?? '—' },
          { label: 'Re-KYC Due',  value: data.re_kyc_due ?? 'Not due' },
        ].map(({ label, value }) => (
          <div key={label} className="flex items-center justify-between px-5 py-3 hover:bg-slate-50">
            <span className="text-xs text-slate-500 font-medium">{label}</span>
            <span className="text-sm font-semibold text-slate-800">{value}</span>
          </div>
        ))}
      </div>

      {data.ai_forecast && (
        <div className="px-5 py-3 border-t border-slate-100">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1.5">
            AI Credit Forecast
          </p>
          <p className="text-xs text-slate-600 leading-relaxed italic">{data.ai_forecast}</p>
        </div>
      )}

      {flags.length > 0 && (
        <div className="px-5 py-3 border-t border-slate-100 space-y-1.5">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Flags</p>
          {flags.map((f, i) => (
            <div key={i} className="flex gap-2 items-start">
              <span className="flex-shrink-0 mt-1 w-1.5 h-1.5 rounded-full bg-red-400" />
              <p className="text-xs text-slate-600 leading-snug">{f}</p>
            </div>
          ))}
        </div>
      )}

      {data.cibil_summary && (
        <div className="px-5 py-3 border-t border-slate-100 bg-slate-50">
          <p className="text-xs text-slate-600 leading-relaxed">{data.cibil_summary}</p>
        </div>
      )}
    </div>
  );
}
