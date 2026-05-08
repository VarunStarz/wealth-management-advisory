const ALLOC_COLORS = {
  equity_pct: { label: 'Equity', color: '#3b82f6' },
  hybrid_pct: { label: 'Hybrid', color: '#8b5cf6' },
  debt_pct:   { label: 'Debt',   color: '#10b981' },
  gold_pct:   { label: 'Gold',   color: '#f59e0b' },
  cash_pct:   { label: 'Cash',   color: '#94a3b8' },
  other_pct:  { label: 'Other',  color: '#64748b' },
};

function DonutChart({ allocation }) {
  const r    = 44;
  const cx   = 60;
  const cy   = 60;
  const circ = 2 * Math.PI * r;

  const segments = Object.entries(ALLOC_COLORS)
    .map(([key, meta]) => ({ ...meta, value: allocation[key] ?? 0 }))
    .filter(s => s.value > 0);

  let cumulative = 0;

  return (
    <div className="flex flex-col sm:flex-row items-center gap-8">
      <div className="flex-shrink-0">
        <svg
          viewBox="0 0 120 120"
          className="w-36 h-36"
          style={{ transform: 'rotate(-90deg)' }}
        >
          <circle cx={cx} cy={cy} r={r} fill="none" stroke="#f1f5f9" strokeWidth="14" />
          {segments.map((seg, i) => {
            const len = (seg.value / 100) * circ;
            const off = circ * (1 - cumulative / 100);
            cumulative += seg.value;
            return (
              <circle
                key={i}
                cx={cx} cy={cy} r={r}
                fill="none"
                stroke={seg.color}
                strokeWidth="14"
                strokeDasharray={`${len} ${circ}`}
                strokeDashoffset={off}
              />
            );
          })}
        </svg>
      </div>

      <div className="flex-1 space-y-2.5 min-w-0">
        {segments.map(s => (
          <div key={s.label} className="flex items-center gap-3 text-sm">
            <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: s.color }} />
            <span className="text-slate-600 flex-1">{s.label}</span>
            <div className="w-28 bg-slate-100 rounded-full h-1.5 overflow-hidden">
              <div
                className="h-full rounded-full"
                style={{ width: `${s.value}%`, backgroundColor: s.color }}
              />
            </div>
            <span className="font-bold text-slate-800 w-10 text-right">{s.value}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

const STATUS_STYLES = {
  PERFORMING:      'bg-emerald-100 text-emerald-700',
  UNDERPERFORMING: 'bg-red-100 text-red-700',
  NEUTRAL:         'bg-slate-100 text-slate-600',
};

export default function PortfolioSummary({ data }) {
  if (!data) return null;

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">Portfolio Summary</h2>
        <span className="ml-auto text-amber-400 font-bold text-sm">{data.total_aum_inr}</span>
      </div>

      <div className="p-5 space-y-7">
        {/* Asset allocation donut */}
        <div>
          <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4">
            Asset Allocation
          </div>
          <DonutChart allocation={data.asset_allocation} />
        </div>

        {/* Portfolios table */}
        <div>
          <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">
            Portfolios ({data.portfolio_count})
          </div>
          <div className="overflow-x-auto rounded-xl border border-slate-100">
            <table className="w-full text-sm">
              <thead className="bg-slate-50 border-b border-slate-100">
                <tr>
                  {['Portfolio', 'Strategy', 'AUM', 'Alpha', 'Sharpe', 'Status'].map(h => (
                    <th
                      key={h}
                      className="text-left px-4 py-2.5 text-xs font-bold text-slate-500 uppercase tracking-wider whitespace-nowrap"
                    >
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {data.portfolios.map((p, i) => {
                  const alphaVal = parseFloat(p.alpha) || 0;
                  return (
                    <tr key={i} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 font-semibold text-slate-800 whitespace-nowrap">{p.name}</td>
                      <td className="px-4 py-3">
                        <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-700 text-xs font-semibold">
                          {p.strategy}
                        </span>
                      </td>
                      <td className="px-4 py-3 font-semibold text-slate-700 whitespace-nowrap">{p.aum_inr}</td>
                      <td className="px-4 py-3">
                        <span className={`font-bold text-sm ${alphaVal >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                          {alphaVal >= 0 ? '+' : ''}{p.alpha}
                        </span>
                      </td>
                      <td className="px-4 py-3 font-medium text-slate-700">{p.sharpe}</td>
                      <td className="px-4 py-3">
                        <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${STATUS_STYLES[p.status] ?? 'bg-slate-100 text-slate-600'}`}>
                          {p.status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>

        {/* Concentration alerts */}
        {data.concentration_alerts?.length > 0 && (
          <div>
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
              Concentration Alerts
            </div>
            <div className="space-y-2">
              {data.concentration_alerts.map((a, i) => (
                <div key={i} className="flex gap-3 bg-red-50 border border-red-200 rounded-xl p-4">
                  <div className="w-2 h-2 rounded-full bg-red-500 flex-shrink-0 mt-1.5" />
                  <p className="text-red-800 text-sm leading-relaxed">{a}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Suitability notes */}
        {data.suitability_notes && (
          <div>
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
              Suitability Notes
            </div>
            <p className="text-slate-700 text-sm leading-relaxed bg-slate-50 border border-slate-100 rounded-xl p-4">
              {data.suitability_notes}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
