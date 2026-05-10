function parseRs(str) {
  if (!str) return 0;
  return parseInt(String(str).replace(/Rs\.|,|\s/g, ''), 10) || 0;
}

function Bar({ label, value, max, raw, color, flagged }) {
  const pct = max > 0 ? Math.round((value / max) * 100) : 0;
  return (
    <div className="space-y-1.5">
      <div className="flex justify-between text-sm">
        <span className="text-slate-600">{label}</span>
        <span className="font-semibold text-slate-800">{raw}</span>
      </div>
      <div className="bg-slate-100 rounded-full h-2.5 overflow-hidden">
        <div
          className={`h-full rounded-full ${color} transition-all duration-700`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}

export default function IncomeValidation({ data }) {
  if (!data) return null;

  const declared  = parseRs(data.declared_annual_gross_inr);
  const inferred  = parseRs(data.inferred_income_spend_signals_inr);
  const benchmark = parseRs(data.market_benchmark_p50_inr);
  const maxVal    = Math.max(declared, inferred, benchmark, 1);
  const flagged   = data.discrepancy_status === 'FLAGGED';

  const bars = [
    { label: 'Declared Annual Income',          value: declared,  raw: data.declared_annual_gross_inr,           color: 'bg-blue-500' },
    { label: 'Inferred Income (Spend Signals)', value: inferred,  raw: data.inferred_income_spend_signals_inr,   color: flagged ? 'bg-red-500' : 'bg-emerald-500' },
    { label: 'Market Benchmark P50',            value: benchmark, raw: data.market_benchmark_p50_inr,            color: 'bg-slate-400' },
  ];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">Income Validation</h2>
        <div className="ml-auto">
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
            flagged ? 'bg-red-500 text-white' : 'bg-emerald-500 text-white'
          }`}>
            {data.discrepancy_pct} — {data.discrepancy_status}
          </span>
        </div>
      </div>
      <div className="p-5 space-y-6">
        <div className="space-y-4">
          {bars.map(b => (
            <Bar key={b.label} {...b} max={maxVal} flagged={flagged} />
          ))}
        </div>

        {data.signals?.length > 0 && (
          <div className="border-t border-slate-100 pt-4">
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Signals</div>
            <ul className="space-y-2.5">
              {data.signals.map((s, i) => (
                <li key={i} className="flex gap-2.5 text-sm text-slate-700 leading-relaxed">
                  <span className="text-amber-500 font-bold flex-shrink-0 mt-0.5 select-none">—</span>
                  {s}
                </li>
              ))}
            </ul>
          </div>
        )}

        {data.employer_stability && (() => {
          const es = data.employer_stability;
          const ratingStyle = {
            HIGH:    { badge: 'bg-green-100 text-green-700',  border: 'border-green-200' },
            MEDIUM:  { badge: 'bg-amber-100 text-amber-700',  border: 'border-amber-200' },
            LOW:     { badge: 'bg-red-100 text-red-700',      border: 'border-red-200'   },
            UNKNOWN: { badge: 'bg-slate-100 text-slate-500',  border: 'border-slate-200' },
          }[es.stability_rating] ?? { badge: 'bg-slate-100 text-slate-500', border: 'border-slate-200' };
          return (
            <div className={`border-t border-slate-100 pt-4`}>
              <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">Employer Stability</div>
              <div className={`border ${ratingStyle.border} rounded-xl p-4 space-y-3`}>
                <div className="flex items-center justify-between gap-3">
                  <span className="text-sm font-semibold text-slate-800">{es.employer_name}</span>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    {es.listed_on_exchange && (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-100 text-blue-700 uppercase tracking-wide">
                        Listed
                      </span>
                    )}
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wide ${ratingStyle.badge}`}>
                      {es.stability_rating}
                    </span>
                  </div>
                </div>
                {es.stability_notes && (
                  <p className="text-xs text-slate-500 leading-relaxed">{es.stability_notes}</p>
                )}
              </div>
            </div>
          );
        })()}
      </div>
    </div>
  );
}
