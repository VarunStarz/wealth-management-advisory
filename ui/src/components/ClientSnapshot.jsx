const KYC_STYLES = {
  VERIFIED:           'bg-emerald-100 text-emerald-700',
  UNDER_REVIEW:       'bg-amber-100 text-amber-700',
  EXPIRED:            'bg-red-100 text-red-700',
  NOT_FOUND:          'bg-slate-100 text-slate-600',
};

const RISK_STYLES = {
  LOW:        'bg-emerald-100 text-emerald-700',
  MODERATE:   'bg-blue-100 text-blue-700',
  HIGH:       'bg-red-100 text-red-700',
  AGGRESSIVE: 'bg-red-100 text-red-700',
};

const SEG_STYLES = {
  HNI:    'bg-blue-100 text-blue-800',
  UHNI:   'bg-violet-100 text-violet-800',
  RETAIL: 'bg-slate-100 text-slate-700',
};

function Badge({ value, styleMap }) {
  const cls = styleMap[value] ?? 'bg-slate-100 text-slate-700';
  return (
    <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${cls}`}>
      {value}
    </span>
  );
}

export default function ClientSnapshot({ data }) {
  const rows = [
    {
      label: 'Segment',
      render: () => <Badge value={data.segment} styleMap={SEG_STYLES} />,
    },
    { label: 'Customer Since', value: data.customer_since },
    { label: 'Total AUM', value: data.aum_total_inr, bold: true },
    {
      label: 'KYC Status',
      render: () => <Badge value={data.kyc_status} styleMap={KYC_STYLES} />,
    },
    { label: 'Re-KYC Due', value: data.re_kyc_due },
    {
      label: 'Risk Appetite',
      render: () => <Badge value={data.stated_risk_appetite} styleMap={RISK_STYLES} />,
    },
    { label: 'Investment Goal', value: data.investment_goal?.replace(/_/g, ' ') },
    { label: 'Last RM Review', value: data.last_rm_review },
  ];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden h-full">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">
          Client Snapshot
        </h2>
      </div>
      <div className="divide-y divide-slate-100">
        {rows.map(({ label, value, render, bold }) => (
          <div key={label} className="flex items-center justify-between px-5 py-3 hover:bg-slate-50 transition-colors">
            <span className="text-slate-500 text-sm">{label}</span>
            {render
              ? render()
              : (
                <span className={`text-sm ${bold ? 'font-bold text-slate-900' : 'font-medium text-slate-700'}`}>
                  {value ?? '—'}
                </span>
              )}
          </div>
        ))}
      </div>
    </div>
  );
}
