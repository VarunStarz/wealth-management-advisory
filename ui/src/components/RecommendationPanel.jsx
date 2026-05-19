import { useState } from 'react';

const ASSET_CLASS_META = {
  EQUITY:        { color: '#3b82f6', label: 'Equity' },
  DEBT:          { color: '#10b981', label: 'Debt' },
  HYBRID:        { color: '#8b5cf6', label: 'Hybrid' },
  GOLD:          { color: '#f59e0b', label: 'Gold' },
  METALS:        { color: '#eab308', label: 'Metals' },
  SAFE:          { color: '#64748b', label: 'Safe' },
  INTERNATIONAL: { color: '#6366f1', label: 'International' },
};

const RISK_BADGE = {
  NO_RISK: 'bg-slate-100  text-slate-600  border-slate-200',
  LOW:     'bg-blue-100   text-blue-700   border-blue-200',
  MEDIUM:  'bg-amber-100  text-amber-700  border-amber-200',
  HIGH:    'bg-red-100    text-red-700    border-red-200',
};

// ── Stacked horizontal allocation bar ────────────────────────
function AllocationBar({ instruments }) {
  const byClass = {};
  for (const inst of instruments) {
    const ac = inst.asset_class || 'OTHER';
    byClass[ac] = (byClass[ac] || 0) + (inst.suggested_allocation_pct || 0);
  }

  const segments = Object.entries(byClass).map(([ac, pct]) => ({
    pct,
    ...(ASSET_CLASS_META[ac] || { color: '#94a3b8', label: ac }),
  }));

  return (
    <div>
      <div className="flex h-3 rounded-full overflow-hidden gap-px">
        {segments.map((s, i) => (
          <div
            key={i}
            style={{ width: `${s.pct}%`, backgroundColor: s.color }}
            title={`${s.label}: ${s.pct}%`}
          />
        ))}
      </div>
      <div className="flex flex-wrap gap-x-5 gap-y-1.5 mt-2.5">
        {segments.map((s, i) => (
          <div key={i} className="flex items-center gap-1.5 text-xs text-slate-600">
            <div className="w-2.5 h-2.5 rounded-sm flex-shrink-0" style={{ backgroundColor: s.color }} />
            <span>{s.label}</span>
            <span className="font-bold text-slate-800">{s.pct}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Single instrument card ────────────────────────────────────
function InstrumentCard({ inst, rank }) {
  const acMeta  = ASSET_CLASS_META[inst.asset_class] || { color: '#94a3b8', label: inst.asset_class };
  const cagr3   = inst.cagr_3yr_pct;
  const cagr1   = inst.cagr_1yr_pct;
  const dd      = inst.max_drawdown_pct;

  return (
    <div className="border border-slate-200 rounded-xl overflow-hidden hover:shadow-md transition-shadow">

      {/* Card header row */}
      <div className="flex items-center gap-3 px-4 py-3 bg-slate-50 border-b border-slate-100">
        <div
          className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 text-white text-xs font-black shadow-sm"
          style={{ backgroundColor: acMeta.color }}
        >
          {rank}
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-slate-800 text-sm leading-tight truncate">{inst.name}</p>
          <p className="text-xs text-slate-500 mt-0.5">{inst.amc} · {inst.category}</p>
        </div>
        <div className="flex-shrink-0 text-right">
          <p className="font-extrabold text-slate-800 text-sm">{inst.suggested_amount_inr}</p>
          <p className="text-xs text-slate-400">{inst.suggested_allocation_pct}% of portfolio</p>
        </div>
      </div>

      {/* Performance metrics */}
      <div className="grid grid-cols-3 divide-x divide-slate-100 border-b border-slate-100">
        {[
          {
            label: '3yr CAGR',
            value: cagr3 != null ? `${cagr3}%` : '—',
            color: cagr3 > 0 ? 'text-emerald-600' : 'text-slate-600',
          },
          {
            label: '1yr Return',
            value: cagr1 != null ? `${cagr1}%` : '—',
            color: cagr1 > 0 ? 'text-emerald-600' : cagr1 < 0 ? 'text-red-600' : 'text-slate-600',
          },
          {
            label: 'Max Drawdown',
            value: dd != null ? `${dd}%` : '—',
            color: dd != null && dd < -20 ? 'text-red-600' : dd != null && dd < -10 ? 'text-amber-600' : 'text-slate-600',
          },
        ].map(({ label, value, color }) => (
          <div key={label} className="px-3 py-2.5 text-center">
            <p className="text-[10px] text-slate-400 uppercase tracking-wide mb-0.5">{label}</p>
            <p className={`text-sm font-bold ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      {/* Allocation progress bar + asset class badge */}
      <div className="flex items-center gap-3 px-4 py-2.5 border-b border-slate-100">
        <div className="flex-1 bg-slate-100 rounded-full h-1.5 overflow-hidden">
          <div
            className="h-full rounded-full transition-all"
            style={{
              width: `${inst.suggested_allocation_pct}%`,
              backgroundColor: acMeta.color,
            }}
          />
        </div>
        <span
          className="text-xs font-semibold px-2 py-0.5 rounded-full"
          style={{
            backgroundColor: `${acMeta.color}18`,
            color: acMeta.color,
          }}
        >
          {acMeta.label}
        </span>
      </div>

      {/* Rationale */}
      {inst.rationale && (
        <div className="px-4 py-3 bg-slate-50">
          <p className="text-xs text-slate-500 leading-relaxed italic">{inst.rationale}</p>
        </div>
      )}
    </div>
  );
}

// ── Option return summary card ────────────────────────────────
function ReturnSummaryCard({ opt }) {
  if (!opt) return null;
  const ret    = opt.expected_portfolio_return_pct;
  const corpus = opt.projected_corpus_3yr_inr;
  const gain   = opt.projected_gain_3yr_inr;
  const dd     = opt.expected_portfolio_max_drawdown_pct;
  const algo   = opt.algorithm;
  if (ret == null && corpus == null) return null;

  return (
    <div className="bg-slate-50 rounded-xl border border-slate-200 overflow-hidden">
      {/* Row 1 — three primary metric tiles */}
      <div className="grid grid-cols-3 divide-x divide-slate-200">
        <div className="px-4 py-4 text-center">
          <p className="text-[10px] text-slate-400 uppercase tracking-wide mb-1">Expected 3yr Return</p>
          <p className="text-2xl font-extrabold text-emerald-600">{ret != null ? `${ret}%` : '—'}</p>
          <p className="text-[10px] text-slate-400 mt-0.5">annualised CAGR (weighted)</p>
        </div>
        <div className="px-4 py-4 text-center">
          <p className="text-[10px] text-slate-400 uppercase tracking-wide mb-1">Projected Corpus</p>
          <p className="text-2xl font-extrabold text-blue-600">{corpus ?? '—'}</p>
          <p className="text-[10px] text-slate-400 mt-0.5">after 3 years</p>
        </div>
        <div className="px-4 py-4 text-center">
          <p className="text-[10px] text-slate-400 uppercase tracking-wide mb-1">Net Gain in 3 Years</p>
          <p className="text-2xl font-extrabold text-emerald-600">{gain ?? '—'}</p>
          <p className="text-[10px] text-slate-400 mt-0.5">above invested amount</p>
        </div>
      </div>
      {/* Row 2 — drawdown + algorithm badge */}
      <div className="flex items-center justify-between px-4 py-2.5 border-t border-slate-200 bg-white">
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-slate-400 uppercase tracking-wide">Weighted Drawdown Risk</span>
          <span className={`text-xs font-bold ${
            dd != null && dd < -20 ? 'text-red-600'
            : dd != null && dd < -10 ? 'text-amber-600'
            : 'text-slate-600'
          }`}>{dd != null ? `${dd}%` : '—'}</span>
        </div>
        {algo && (
          <span className={`text-[10px] font-bold px-2.5 py-1 rounded-full border ${
            algo === 'SHARPE_OPTIMISED'
              ? 'bg-indigo-50 text-indigo-700 border-indigo-200'
              : 'bg-slate-100 text-slate-600 border-slate-200'
          }`}>
            {algo === 'SHARPE_OPTIMISED' ? 'Sharpe-Optimised' : 'Template-Driven'}
          </span>
        )}
      </div>
    </div>
  );
}

// ── Main panel ────────────────────────────────────────────────
export default function RecommendationPanel({ data }) {
  const [selectedIdx, setSelectedIdx] = useState(0);
  if (!data) return null;

  const options    = data.options ?? [];
  const tierStyle  = RISK_BADGE[data.risk_tier_used] ?? RISK_BADGE.MEDIUM;
  const activeOpt  = options[selectedIdx] ?? null;
  const instruments = activeOpt?.recommended_instruments ?? [];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">

      {/* Panel header */}
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest flex-1">
          Wealth Recommendation
        </h2>
        {data.risk_tier_used && (
          <span className={`px-2.5 py-1 rounded-full border text-xs font-bold ${tierStyle}`}>
            {data.risk_tier_used.replace('_', ' ')} Risk
          </span>
        )}
        {data.investable_amount_inr && (
          <span className="text-amber-400 font-bold text-sm ml-2">
            {data.investable_amount_inr}
          </span>
        )}
      </div>

      {/* Compliance block — recommendation withheld */}
      {!data.eligible && (
        <div className="m-5 flex gap-3 bg-red-50 border border-red-200 rounded-xl p-4">
          <div className="w-2 h-2 rounded-full bg-red-500 flex-shrink-0 mt-1.5" />
          <div>
            <p className="text-xs font-bold text-red-700 uppercase tracking-wide mb-1">
              Recommendation Withheld — Compliance Block
            </p>
            <p className="text-sm text-red-800 leading-relaxed">{data.compliance_note}</p>
          </div>
        </div>
      )}

      {/* Eligible — multi-option recommendation */}
      {data.eligible && options.length > 0 && (
        <div className="p-5 space-y-6">

          {/* Stats row — universe level (same across all options) */}
          <div className="grid grid-cols-3 gap-3">
            {[
              { label: 'Options Generated',  value: options.length },
              { label: 'Universe Scored',    value: data.total_instruments_evaluated ?? '—' },
              { label: 'Already Held',       value: data.instruments_excluded_existing_holdings ?? 0 },
            ].map(({ label, value }) => (
              <div
                key={label}
                className="bg-slate-50 rounded-xl px-4 py-3 text-center border border-slate-100"
              >
                <p className="text-2xl font-extrabold text-slate-800">{value}</p>
                <p className="text-[10px] text-slate-400 uppercase tracking-wide mt-0.5 leading-tight">
                  {label}
                </p>
              </div>
            ))}
          </div>

          {/* Option tabs */}
          <div>
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
              Portfolio Options
            </div>
            <div className="flex flex-wrap gap-2">
              {options.map((opt, i) => (
                <button
                  key={opt.option_id ?? i}
                  onClick={() => setSelectedIdx(i)}
                  className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all ${
                    i === selectedIdx
                      ? 'bg-slate-900 text-white border-slate-900 shadow-sm'
                      : 'bg-white text-slate-600 border-slate-200 hover:border-slate-400 hover:text-slate-800'
                  }`}
                >
                  {/* OLD: {opt.option_name ?? `Option ${i + 1}`} */}
                  {opt.expected_portfolio_return_pct != null
                    ? `${opt.option_name ?? `Option ${i + 1}`} · ${opt.expected_portfolio_return_pct}%`
                    : (opt.option_name ?? `Option ${i + 1}`)
                  }
                </button>
              ))}
            </div>
            {activeOpt?.strategy_description && (
              <p className="text-xs text-slate-500 mt-2 italic">{activeOpt.strategy_description}</p>
            )}
          </div>

          {/* Return summary card — option-level aggregate metrics */}
          <ReturnSummaryCard opt={activeOpt} />

          {/* Allocation bar for selected option */}
          {instruments.length > 0 && (
            <div>
              <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">
                Suggested Allocation
              </div>
              <AllocationBar instruments={instruments} />
              {activeOpt?.allocation_summary && (
                <p className="text-xs text-slate-500 mt-2 italic">{activeOpt.allocation_summary}</p>
              )}
            </div>
          )}

          {/* Instrument cards for selected option */}
          {instruments.length > 0 && (
            <div>
              <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3">
                Recommended Instruments · {instruments.length} funds
              </div>
              <div className="space-y-3">
                {instruments.map((inst, i) => (
                  <InstrumentCard key={`${selectedIdx}-${inst.fund_id ?? i}`} inst={inst} rank={i + 1} />
                ))}
              </div>
            </div>
          )}

        </div>
      )}

      {/* Disclaimer */}
      {data.disclaimer && (
        <div className="px-5 py-4 border-t border-slate-100 bg-slate-50">
          <p className="text-[11px] text-slate-400 leading-relaxed italic">{data.disclaimer}</p>
        </div>
      )}

    </div>
  );
}
