const VERDICT_STYLE = {
  REAL_POSITIVE:      { badge: 'bg-emerald-100 text-emerald-700 border-emerald-200', dot: 'bg-emerald-500' },
  INFLATION_ERODING:  { badge: 'bg-amber-100  text-amber-700  border-amber-200',  dot: 'bg-amber-500'  },
  BELOW_INFLATION:    { badge: 'bg-red-100    text-red-700    border-red-200',    dot: 'bg-red-500'    },
};

function ReturnBar({ label, nominal, real, maxAbs }) {
  const nomPct  = maxAbs > 0 ? Math.min(Math.abs(nominal) / maxAbs * 100, 100) : 0;
  const realPct = maxAbs > 0 ? Math.min(Math.abs(real)    / maxAbs * 100, 100) : 0;
  const realNeg = real < 0;

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between">
        <span className="text-xs text-slate-500 font-medium">{label}</span>
        <div className="flex items-center gap-3 text-xs">
          <span className="text-slate-400">Nominal <span className="font-semibold text-slate-700">{nominal?.toFixed(1)}%</span></span>
          <span className={`font-bold ${realNeg ? 'text-red-600' : 'text-emerald-700'}`}>
            Real {real >= 0 ? '+' : ''}{real?.toFixed(1)}%
          </span>
        </div>
      </div>
      <div className="relative h-2 bg-slate-100 rounded-full overflow-hidden">
        <div className="absolute inset-y-0 left-0 bg-slate-300 rounded-full" style={{ width: `${nomPct}%` }} />
        <div
          className={`absolute inset-y-0 left-0 rounded-full ${realNeg ? 'bg-red-400' : 'bg-emerald-500'}`}
          style={{ width: `${realPct}%` }}
        />
      </div>
    </div>
  );
}

export default function RealReturnsPanel({ data }) {
  if (!data) return null;

  const v   = VERDICT_STYLE[data.verdict] ?? VERDICT_STYLE.INFLATION_ERODING;
  const maxAbs = Math.max(
    Math.abs(data.portfolio_nominal_return_pct ?? 0),
    Math.abs(data.benchmark_cagr_pct ?? 0),
    20,
  );

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest flex-1">
          Real Returns (Inflation-Adjusted)
        </h2>
        {data.verdict && (
          <span className={`px-2.5 py-1 rounded-full border text-xs font-bold ${v.badge}`}>
            {data.verdict.replace(/_/g, ' ')}
          </span>
        )}
      </div>

      {/* CPI callout */}
      <div className="px-5 py-3 border-b border-slate-100 flex items-center gap-4">
        <div className="flex-1">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-0.5">India CPI Inflation</p>
          <p className="text-2xl font-extrabold text-slate-800">
            {data.cpi_inflation_pct?.toFixed(1)}%
            <span className="text-sm font-normal text-slate-400 ml-1">p.a.</span>
          </p>
          {data.inflation_source && (
            <p className="text-[10px] text-slate-400 mt-0.5">{data.inflation_source}</p>
          )}
        </div>
        <div className="text-right">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-0.5">Risk Tier</p>
          <p className="text-sm font-bold text-slate-700">{data.risk_preference_tier ?? '—'}</p>
        </div>
      </div>

      {/* Return bars */}
      <div className="px-5 py-4 space-y-4">
        {data.portfolio_nominal_return_pct != null && (
          <ReturnBar
            label="Portfolio Return"
            nominal={data.portfolio_nominal_return_pct}
            real={data.real_return_pct}
            maxAbs={maxAbs}
          />
        )}
        {data.benchmark_cagr_pct != null && (
          <ReturnBar
            label={`Benchmark (${data.risk_preference_tier ?? 'Market'})`}
            nominal={data.benchmark_cagr_pct}
            real={data.real_benchmark_pct}
            maxAbs={maxAbs}
          />
        )}
      </div>

      {/* Note */}
      {data.note && (
        <div className="px-5 py-3 border-t border-slate-100 bg-slate-50">
          <p className="text-xs text-slate-600 leading-relaxed">{data.note}</p>
        </div>
      )}
    </div>
  );
}
