const TIER_STYLE = {
  AFFLUENT: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  MODERATE: 'bg-blue-100   text-blue-700   border-blue-200',
  STRESSED: 'bg-red-100    text-red-700    border-red-200',
};

export default function ExpenditurePanel({ data }) {
  if (!data) return null;

  const tierCls = TIER_STYLE[data.lifestyle_tier] ?? TIER_STYLE.MODERATE;
  const flags   = data.red_flags ?? [];

  const rows = [
    { label: 'Monthly Card Spend',     value: data.total_monthly_spend_inr ?? '—' },
    { label: 'Cash Advances',          value: data.cash_advance_flag
        ? `Yes — ${data.cash_advance_count ?? 0} instance${data.cash_advance_count !== 1 ? 's' : ''}`
        : 'None detected' },
    { label: 'Min-Payment Months',     value: data.minimum_payment_months != null
        ? (data.minimum_payment_months > 0 ? `${data.minimum_payment_months} months` : 'None')
        : '—' },
    { label: 'Card DPD Months',        value: data.dpd_months != null
        ? (data.dpd_months > 0 ? `${data.dpd_months} months` : 'None')
        : '—' },
  ];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest flex-1">
          Spending &amp; Lifestyle
        </h2>
        {data.lifestyle_tier && (
          <span className={`px-2.5 py-1 rounded-full border text-xs font-bold ${tierCls}`}>
            {data.lifestyle_tier}
          </span>
        )}
      </div>

      <div className="divide-y divide-slate-100">
        {rows.map(({ label, value }) => (
          <div key={label} className="flex items-center justify-between px-5 py-3 hover:bg-slate-50">
            <span className="text-xs text-slate-500 font-medium">{label}</span>
            <span className={`text-sm font-semibold ${
              (label === 'Cash Advances' && data.cash_advance_flag) ||
              (label === 'Card DPD Months' && data.dpd_months > 0)
                ? 'text-red-600' : 'text-slate-800'
            }`}>{value}</span>
          </div>
        ))}
      </div>

      {flags.length > 0 && (
        <div className="px-5 py-3 border-t border-slate-100 space-y-1.5">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Flags</p>
          {flags.map((f, i) => (
            <div key={i} className="flex gap-2 items-start">
              <span className="flex-shrink-0 mt-1 w-1.5 h-1.5 rounded-full bg-amber-400" />
              <p className="text-xs text-slate-600 leading-snug">{f}</p>
            </div>
          ))}
        </div>
      )}

      {data.expenditure_summary && (
        <div className="px-5 py-3 border-t border-slate-100 bg-slate-50">
          <p className="text-xs text-slate-600 leading-relaxed">{data.expenditure_summary}</p>
        </div>
      )}
    </div>
  );
}
