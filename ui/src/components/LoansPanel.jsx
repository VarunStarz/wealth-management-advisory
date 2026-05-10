const BADGE = {
  NPA: 'bg-red-100 text-red-700 border-red-200',
  DPD: 'bg-amber-100 text-amber-700 border-amber-200',
  OK:  'bg-emerald-100 text-emerald-700 border-emerald-200',
};

function StatusBadge({ label, active, type }) {
  const cls = active ? BADGE[type] : BADGE.OK;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-xs font-bold ${cls}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${active ? 'bg-current' : 'bg-current opacity-60'}`} />
      {active ? label : `No ${label}`}
    </span>
  );
}

export default function LoansPanel({ data }) {
  if (!data) return null;

  const rows = [
    { label: 'Total Outstanding',  value: data.total_outstanding_inr  ?? '—' },
    { label: 'Monthly EMI Burden', value: data.total_monthly_emi_inr  ?? '—' },
    { label: 'Loan Accounts',      value: data.liability_count != null ? `${data.liability_count} active` : '—' },
  ];

  const flags = data.red_flags ?? [];
  const npaAccounts = data.npa_accounts ?? [];
  const dpdAccounts = data.dpd_accounts ?? [];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest flex-1">
          Loan Obligations
        </h2>
        <div className="flex gap-2">
          <StatusBadge label="NPA" active={data.npa_flag} type="NPA" />
          <StatusBadge label="DPD" active={data.dpd_flag} type="DPD" />
        </div>
      </div>

      <div className="divide-y divide-slate-100">
        {rows.map(({ label, value }) => (
          <div key={label} className="flex items-center justify-between px-5 py-3 hover:bg-slate-50">
            <span className="text-xs text-slate-500 font-medium">{label}</span>
            <span className="text-sm font-semibold text-slate-800">{value}</span>
          </div>
        ))}
      </div>

      {(npaAccounts.length > 0 || dpdAccounts.length > 0) && (
        <div className="px-5 py-3 space-y-2 border-t border-slate-100">
          {npaAccounts.map((a, i) => (
            <div key={i} className="flex gap-2 items-start text-xs">
              <span className="flex-shrink-0 px-1.5 py-0.5 rounded bg-red-100 text-red-700 font-bold">NPA</span>
              <span className="text-slate-600">{a.liability_type}{a.outstanding_balance ? ` — ${a.outstanding_balance}` : ''}</span>
            </div>
          ))}
          {dpdAccounts.map((a, i) => (
            <div key={i} className="flex gap-2 items-start text-xs">
              <span className="flex-shrink-0 px-1.5 py-0.5 rounded bg-amber-100 text-amber-700 font-bold">DPD</span>
              <span className="text-slate-600">{a.liability_type}{a.dpd_days ? ` — ${a.dpd_days} days overdue` : ''}</span>
            </div>
          ))}
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

      {data.loans_summary && (
        <div className="px-5 py-3 border-t border-slate-100 bg-slate-50">
          <p className="text-xs text-slate-600 leading-relaxed">{data.loans_summary}</p>
        </div>
      )}
    </div>
  );
}
