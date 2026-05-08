export default function NavBar({ header }) {
  return (
    <nav className="fixed top-0 w-full z-50 bg-slate-900 border-b border-slate-700/60 shadow-lg">
      <div className="max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-amber-500 rounded-lg flex items-center justify-center shadow">
            <span className="text-slate-900 font-black text-sm tracking-tight">W</span>
          </div>
          <div>
            <span className="text-white font-semibold text-sm tracking-wide">
              Wealth Advisory Intelligence
            </span>
            <span className="text-slate-500 text-sm"> Platform</span>
          </div>
        </div>
        <div className="hidden sm:flex items-center gap-3 text-xs">
          <span className="text-slate-400">{header.date}</span>
          <span className="text-slate-600">|</span>
          <span className="text-slate-400">{header.relationship_manager}</span>
          <span className="text-slate-600">|</span>
          <span className="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 font-semibold">
            {header.segment}
          </span>
        </div>
      </div>
    </nav>
  );
}
