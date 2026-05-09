function FlagCard({ flag, level }) {
  const styles = {
    high: {
      wrap:  'bg-red-50 border-red-200',
      badge: 'bg-red-100 text-red-700',
      text:  'text-red-900',
    },
    medium: {
      wrap:  'bg-amber-50 border-amber-200',
      badge: 'bg-amber-100 text-amber-700',
      text:  'text-amber-900',
    },
  };
  const s = styles[level];
  return (
    <div className={`flex gap-3 border rounded-xl p-4 ${s.wrap}`}>
      <span className={`flex-shrink-0 mt-0.5 px-2 py-0.5 rounded text-xs font-bold tracking-wide ${s.badge}`}>
        {flag.source}
      </span>
      <p className={`text-sm leading-relaxed ${s.text}`}>{flag.flag}</p>
    </div>
  );
}

export default function ComplianceSection({ data }) {
  if (!data) return null;

  const high   = data.red_flags_high ?? [];
  const medium = data.caution_points_medium ?? [];

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">
          Compliance &amp; Due Diligence
        </h2>
      </div>
      <div className="p-5 space-y-6">
        {high.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <div className="w-2.5 h-2.5 rounded-full bg-red-500 flex-shrink-0" />
              <span className="text-xs font-bold text-red-600 uppercase tracking-wider">
                High Severity Flags
              </span>
            </div>
            <div className="space-y-2">
              {high.map((f, i) => <FlagCard key={i} flag={f} level="high" />)}
            </div>
          </div>
        )}

        {medium.length > 0 && (
          <div>
            <div className="flex items-center gap-2 mb-3">
              <div className="w-2.5 h-2.5 rounded-full bg-amber-500 flex-shrink-0" />
              <span className="text-xs font-bold text-amber-600 uppercase tracking-wider">
                Medium Severity Cautions
              </span>
            </div>
            <div className="space-y-2">
              {medium.map((f, i) => <FlagCard key={i} flag={f} level="medium" />)}
            </div>
          </div>
        )}

        {high.length === 0 && medium.length === 0 && (
          <p className="text-emerald-600 text-sm font-medium">No compliance flags detected.</p>
        )}

        {data.edd_summary && (
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4">
            <div className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">EDD Summary</div>
            <p className="text-slate-700 text-sm leading-relaxed">{data.edd_summary}</p>
          </div>
        )}
      </div>
    </div>
  );
}
