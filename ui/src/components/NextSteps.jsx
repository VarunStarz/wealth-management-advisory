const STEP_COLORS = ['bg-blue-500', 'bg-violet-500', 'bg-amber-500', 'bg-emerald-500', 'bg-red-500'];

export default function NextSteps({ steps }) {
  if (!steps?.length) return null;

  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">
          Next Steps for the RM
        </h2>
        <span className="ml-auto text-slate-500 text-xs">{steps.length} actions</span>
      </div>
      <div className="p-5 space-y-3">
        {steps.map((step, i) => (
          <div
            key={i}
            className="flex gap-4 p-4 rounded-xl bg-slate-50 border border-slate-100 hover:border-slate-200 hover:shadow-sm transition-all"
          >
            <div
              className={`w-7 h-7 rounded-full flex-shrink-0 flex items-center justify-center text-white text-xs font-bold shadow-sm ${STEP_COLORS[i % STEP_COLORS.length]}`}
            >
              {i + 1}
            </div>
            <p className="text-slate-700 text-sm leading-relaxed">{step}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
