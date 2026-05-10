import { useState } from 'react';

const TIERS = [
  {
    key:      'NO_RISK',
    label:    'No Risk',
    subtitle: 'Capital protection first',
    products: ['Fixed Deposit', 'PPF', 'Post Office Savings', 'Provident Fund'],
    returns:  '6.5 – 7.5% p.a.',
    dot:      'bg-emerald-500',
    border:   'border-emerald-300',
    bg:       'bg-emerald-50',
    badge:    'bg-emerald-100 text-emerald-700',
    divider:  'border-emerald-200',
    check:    'text-emerald-600',
  },
  {
    key:      'LOW',
    label:    'Low Risk',
    subtitle: 'Stable income with liquidity',
    products: ['Liquid Funds', 'Government Bonds', 'Corporate Bonds'],
    returns:  '7.5 – 9% p.a.',
    dot:      'bg-blue-500',
    border:   'border-blue-300',
    bg:       'bg-blue-50',
    badge:    'bg-blue-100 text-blue-700',
    divider:  'border-blue-200',
    check:    'text-blue-600',
  },
  {
    key:      'MEDIUM',
    label:    'Medium Risk',
    subtitle: 'Balanced growth and safety',
    products: ['Balanced / Hybrid Funds', 'Index Funds'],
    returns:  '10 – 13% p.a.',
    dot:      'bg-amber-500',
    border:   'border-amber-300',
    bg:       'bg-amber-50',
    badge:    'bg-amber-100 text-amber-700',
    divider:  'border-amber-200',
    check:    'text-amber-600',
  },
  {
    key:      'HIGH',
    label:    'High Risk',
    subtitle: 'Aggressive growth potential',
    products: ['Direct Equity', 'Sectoral Funds', 'Small Cap Funds'],
    returns:  '14 – 18%+ p.a.',
    dot:      'bg-red-500',
    border:   'border-red-300',
    bg:       'bg-red-50',
    badge:    'bg-red-100 text-red-700',
    divider:  'border-red-200',
    check:    'text-red-600',
  },
];

export default function RiskPreferenceSelector({ onSelect, onSkip }) {
  const [selected, setSelected] = useState(null);
  const tier = TIERS.find(t => t.key === selected);

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-3xl">

        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-amber-100 rounded-full mb-4">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
            <span className="text-xs font-semibold text-amber-700 uppercase tracking-widest">Step 2 of 2</span>
          </div>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Customer Risk Preference</h1>
          <p className="text-sm text-slate-500 max-w-md mx-auto">
            Select the profile that matches what the customer is seeking. This is used to benchmark
            portfolio returns against the appropriate peer group.
          </p>
        </div>

        {/* Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
          {TIERS.map(t => {
            const active = selected === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setSelected(t.key)}
                className={`text-left rounded-2xl border-2 p-5 transition-all ${
                  active
                    ? `${t.border} ${t.bg} shadow-md`
                    : 'border-slate-200 bg-white hover:border-slate-300 hover:shadow-sm'
                }`}
              >
                {/* Title row */}
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className={`w-2 h-2 rounded-full flex-shrink-0 ${t.dot}`} />
                      <span className="font-bold text-slate-900 text-base">{t.label}</span>
                    </div>
                    <p className="text-xs text-slate-500 ml-4">{t.subtitle}</p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold whitespace-nowrap ${t.badge}`}>
                    {t.returns}
                  </span>
                </div>

                {/* Products */}
                <div className="ml-4 space-y-1">
                  {t.products.map(p => (
                    <div key={p} className="flex items-center gap-2 text-xs text-slate-600">
                      <span className="w-1 h-1 rounded-full bg-slate-400 flex-shrink-0" />
                      {p}
                    </div>
                  ))}
                </div>

                {/* Selected indicator */}
                {active && (
                  <div className={`mt-3 pt-3 border-t ${t.divider} flex items-center gap-1.5`}>
                    <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2.5"
                      strokeLinecap="round" strokeLinejoin="round"
                      className={`w-3.5 h-3.5 ${t.check}`}>
                      <polyline points="2.5 8.5 6.5 12.5 13.5 3.5" />
                    </svg>
                    <span className="text-xs font-semibold text-slate-700">Selected</span>
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Actions */}
        <div className="flex gap-3">
          <button
            onClick={onSkip}
            className="flex-1 py-3 bg-white border border-slate-200 text-slate-600 font-semibold rounded-xl text-sm hover:bg-slate-50 transition-colors"
          >
            Skip — Use Default (Medium)
          </button>
          <button
            disabled={!selected}
            onClick={() => selected && onSelect(selected)}
            className="flex-1 py-3 bg-amber-500 hover:bg-amber-400 disabled:bg-slate-200 disabled:text-slate-400 text-slate-900 font-bold rounded-xl text-sm transition-colors"
          >
            {selected ? `Continue with ${tier?.label}` : 'Select a profile to continue'}
          </button>
        </div>

      </div>
    </div>
  );
}
