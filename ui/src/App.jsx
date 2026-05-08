import { useState } from 'react';

import NavBar            from './components/NavBar.jsx';
import BriefingHeader    from './components/BriefingHeader.jsx';
import ExecutiveSummary  from './components/ExecutiveSummary.jsx';
import ClientSnapshot    from './components/ClientSnapshot.jsx';
import RiskPanel         from './components/RiskPanel.jsx';
import ComplianceSection from './components/ComplianceSection.jsx';
import IncomeValidation  from './components/IncomeValidation.jsx';
import PortfolioSummary  from './components/PortfolioSummary.jsx';
import NextSteps         from './components/NextSteps.jsx';

const API_URL  = 'http://localhost:8000/api/query';
const RM_IDS   = ['RM_USER', 'RM001', 'RM002', 'RM003', 'RM004', 'RM005'];

// ── Query input panel ─────────────────────────────────────────
function QueryPanel({ onSubmit, loading }) {
  const [query, setQuery] = useState('');
  const [rmId,  setRmId]  = useState('RM_USER');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (query.trim()) onSubmit(query.trim(), rmId);
  };

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col">
      {/* Minimal nav */}
      <div className="fixed top-0 w-full z-50 bg-slate-900 border-b border-slate-700/60 shadow h-14 flex items-center px-4 gap-3">
        <div className="w-8 h-8 bg-amber-500 rounded-lg flex items-center justify-center shadow">
          <span className="text-slate-900 font-black text-sm">W</span>
        </div>
        <span className="text-white font-semibold text-sm tracking-wide">
          Wealth Advisory Intelligence
        </span>
        <span className="text-slate-500 text-sm">Platform</span>
      </div>

      <div className="flex-1 flex items-center justify-center px-4 pt-14">
        <div className="w-full max-w-2xl">
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold text-slate-800">Advisory Intelligence</h1>
            <p className="text-slate-500 mt-2 text-sm">
              Enter your RM query to generate a structured client briefing
            </p>
          </div>

          <form
            onSubmit={handleSubmit}
            className="bg-white rounded-2xl shadow-lg border border-slate-200 p-6 space-y-5"
          >
            <div>
              <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                RM ID
              </label>
              <select
                value={rmId}
                onChange={e => setRmId(e.target.value)}
                className="w-full border border-slate-200 rounded-xl px-4 py-2.5 text-sm text-slate-800 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                {RM_IDS.map(id => <option key={id} value={id}>{id}</option>)}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                Your Query
              </label>
              <textarea
                value={query}
                onChange={e => setQuery(e.target.value)}
                rows={5}
                placeholder={
                  'e.g. Mr Arjun Menon (CUST000001) is here for his annual wealth review. ' +
                  'Can you give me a full briefing before I meet him?'
                }
                className="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm text-slate-800 resize-none focus:outline-none focus:ring-2 focus:ring-amber-400 placeholder:text-slate-400"
              />
            </div>

            <button
              type="submit"
              disabled={loading || !query.trim()}
              className="w-full py-3 bg-amber-500 hover:bg-amber-400 disabled:bg-slate-200 disabled:text-slate-400 text-slate-900 font-bold rounded-xl text-sm transition-colors"
            >
              {loading ? 'Running Pipeline...' : 'Generate Briefing'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}

// ── Loading state ─────────────────────────────────────────────
function LoadingView() {
  const steps = [
    'Guardrail check',
    'Client 360 profile',
    'CDD + Income + Portfolio + Loans + Expenditure + CIBIL (parallel)',
    'EDD (if triggered by CDD)',
    'Risk assessment',
    'Generating advisory briefing',
  ];

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col items-center justify-center gap-7 px-4">
      <div className="w-12 h-12 border-4 border-amber-500 border-t-transparent rounded-full animate-spin" />
      <div className="text-center">
        <p className="text-slate-700 font-semibold text-lg">Pipeline running</p>
        <p className="text-slate-400 text-sm mt-1">This typically takes 1–3 minutes</p>
      </div>
      <div className="w-full max-w-sm bg-white rounded-2xl border border-slate-200 p-5 space-y-2.5">
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">
          Processing steps
        </p>
        {steps.map((s, i) => (
          <div key={i} className="flex items-start gap-3 text-sm text-slate-500">
            <span className="flex-shrink-0 w-5 h-5 rounded-full bg-slate-100 text-slate-400 text-xs font-bold flex items-center justify-center mt-0.5">
              {i + 1}
            </span>
            {s}
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Blocked / compliance block view ──────────────────────────
function BlockedView({ data, onReset }) {
  const isCompliance = data?.compliance_block;
  const message      = isCompliance
    ? `${data.message}\n\n${data.action}`
    : data?.message || JSON.stringify(data, null, 2);

  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center px-4">
      <div className="w-full max-w-xl bg-white rounded-2xl border border-red-200 shadow p-8 space-y-5">
        <div>
          <div className={`inline-block px-3 py-1 rounded-full text-xs font-bold mb-3 ${
            isCompliance ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'
          }`}>
            {isCompliance ? 'COMPLIANCE BLOCK' : 'QUERY BLOCKED'}
          </div>
          <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-wrap">{message}</p>
        </div>
        <button
          onClick={onReset}
          className="px-6 py-2.5 bg-slate-900 text-white text-sm font-semibold rounded-xl hover:bg-slate-700 transition-colors"
        >
          Ask Another Query
        </button>
      </div>
    </div>
  );
}

// ── Error view ────────────────────────────────────────────────
function ErrorView({ message, onReset }) {
  return (
    <div className="min-h-screen bg-slate-100 flex items-center justify-center px-4">
      <div className="w-full max-w-lg bg-white rounded-2xl border border-red-200 shadow p-8 space-y-4 text-center">
        <p className="text-red-700 font-semibold">Connection Error</p>
        <p className="text-sm text-slate-600 leading-relaxed">{message}</p>
        <p className="text-xs text-slate-400">
          Make sure <code className="bg-slate-100 px-1 rounded">api_server.py</code> is running on port 8000.
        </p>
        <button
          onClick={onReset}
          className="px-6 py-2.5 bg-slate-900 text-white text-sm font-semibold rounded-xl hover:bg-slate-700 transition-colors"
        >
          Try Again
        </button>
      </div>
    </div>
  );
}

// ── Main App ──────────────────────────────────────────────────
export default function App() {
  const [briefing, setBriefing] = useState(null);
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState('');

  const handleSubmit = async (query, rmId) => {
    setLoading(true);
    setError('');
    setBriefing(null);

    const controller = new AbortController();
    const timeout    = setTimeout(() => controller.abort(), 360_000); // 6 min

    try {
      const res = await fetch(API_URL, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ query, rm_id: rmId }),
        signal:  controller.signal,
      });
      clearTimeout(timeout);

      if (!res.ok) throw new Error(`Server responded with ${res.status}`);
      const data = await res.json();
      setBriefing(data);
    } catch (err) {
      clearTimeout(timeout);
      if (err.name === 'AbortError') {
        setError('Request timed out after 6 minutes. The pipeline may still be running on the server.');
      } else {
        setError(err.message || 'Could not connect to the backend.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setBriefing(null);
    setError('');
  };

  if (loading)           return <LoadingView />;
  if (error)             return <ErrorView message={error} onReset={handleReset} />;
  if (!briefing)         return <QueryPanel onSubmit={handleSubmit} loading={loading} />;
  if (briefing.error)    return <BlockedView data={briefing} onReset={handleReset} />;
  if (briefing.compliance_block) return <BlockedView data={briefing} onReset={handleReset} />;
  if (!briefing.briefing_header) return <BlockedView data={briefing} onReset={handleReset} />;

  const b = briefing;

  return (
    <div className="min-h-screen bg-slate-100">
      <NavBar header={b.briefing_header} />

      <main className="pt-16 pb-14 px-4">
        <div className="max-w-5xl mx-auto space-y-5">

          {/* New query button */}
          <div className="flex justify-end pt-1">
            <button
              onClick={handleReset}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold rounded-xl transition-colors"
            >
              New Query
            </button>
          </div>

          <BriefingHeader data={b.briefing_header} />

          <ExecutiveSummary summary={b.executive_summary} />

          <div className="grid grid-cols-1 lg:grid-cols-5 gap-5 items-start">
            <div className="lg:col-span-3">
              <ClientSnapshot data={b.client_snapshot} />
            </div>
            <div className="lg:col-span-2">
              <RiskPanel data={b.compliance_and_due_diligence} />
            </div>
          </div>

          <ComplianceSection data={b.compliance_and_due_diligence} />

          <IncomeValidation data={b.income_validation} />

          <PortfolioSummary data={b.portfolio_summary} />

          <NextSteps steps={b.next_steps} />

          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 px-6 py-4 text-center">
            <p className="text-xs text-slate-400 leading-relaxed">{b.disclaimer}</p>
          </div>

        </div>
      </main>
    </div>
  );
}
