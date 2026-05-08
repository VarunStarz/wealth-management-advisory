const SEGMENT_STYLES = {
  HNI:    'bg-blue-500 text-white',
  UHNI:   'bg-violet-500 text-white',
  RETAIL: 'bg-slate-500 text-white',
};

export default function BriefingHeader({ data }) {
  return (
    <div className="relative overflow-hidden rounded-2xl shadow-xl bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-7 text-white">
      {/* decorative rings */}
      <div className="pointer-events-none absolute -top-6 -right-6 w-44 h-44 rounded-full border-2 border-white/5" />
      <div className="pointer-events-none absolute -top-2 -right-2 w-28 h-28 rounded-full border-2 border-white/5" />
      <div className="pointer-events-none absolute bottom-4 left-1/2 w-64 h-1 bg-amber-500/20 rounded-full" />

      <div className="relative flex flex-wrap items-start justify-between gap-5">
        {/* Left — client identity */}
        <div>
          <div className="flex items-center gap-2.5 mb-2">
            <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold tracking-wide ${SEGMENT_STYLES[data.segment] ?? 'bg-slate-600 text-white'}`}>
              {data.segment}
            </span>
            <span className="text-slate-400 text-xs font-mono tracking-wider">{data.customer_id}</span>
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight">{data.client}</h1>
          <p className="text-slate-400 text-xs mt-2">{data.prepared_by}</p>
        </div>

        {/* Right — RM & date */}
        <div className="text-right">
          <div className="text-amber-400 font-semibold text-sm">{data.relationship_manager}</div>
          <div className="text-2xl font-bold text-white mt-1">{data.date}</div>
          <div className="text-slate-500 text-xs mt-1">Briefing Date</div>
        </div>
      </div>
    </div>
  );
}
