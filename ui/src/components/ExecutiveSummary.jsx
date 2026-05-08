export default function ExecutiveSummary({ summary }) {
  return (
    <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="flex items-center gap-3 px-5 py-3 bg-slate-900">
        <div className="w-1 h-5 bg-amber-400 rounded-full flex-shrink-0" />
        <h2 className="text-white font-semibold text-xs uppercase tracking-widest">
          Executive Summary
        </h2>
      </div>
      <div className="px-6 py-5">
        <p className="text-slate-700 leading-7 text-sm">{summary}</p>
      </div>
    </div>
  );
}
