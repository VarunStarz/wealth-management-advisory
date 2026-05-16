import { useState, useEffect } from 'react';

import NavBar            from './components/NavBar.jsx';
import BriefingHeader    from './components/BriefingHeader.jsx';
import ExecutiveSummary  from './components/ExecutiveSummary.jsx';
import ClientSnapshot    from './components/ClientSnapshot.jsx';
import RiskPanel         from './components/RiskPanel.jsx';
import ComplianceSection from './components/ComplianceSection.jsx';
import IncomeValidation  from './components/IncomeValidation.jsx';
import PortfolioSummary        from './components/PortfolioSummary.jsx';
import LoansPanel              from './components/LoansPanel.jsx';
import ExpenditurePanel        from './components/ExpenditurePanel.jsx';
import CIBILPanel              from './components/CIBILPanel.jsx';
import NextSteps               from './components/NextSteps.jsx';
import RiskPreferenceSelector  from './components/RiskPreferenceSelector.jsx';
import RealReturnsPanel        from './components/RealReturnsPanel.jsx';
import RecommendationPanel     from './components/RecommendationPanel.jsx';

const BASE     = 'http://localhost:8000';
const RM_IDS   = ['RM_USER', 'RM001', 'RM002', 'RM003', 'RM004', 'RM005'];

// ── Query input panel ─────────────────────────────────────────
function QueryPanel({ onSubmit, loading }) {
  const [query,          setQuery]          = useState('');
  const [rmId,           setRmId]           = useState('RM_USER');
  const [scenarios,      setScenarios]      = useState([]);
  const [tab,            setTab]            = useState('query'); // 'query' | 'scenario'
  const [investableAmt,  setInvestableAmt]  = useState('');

  // Fetch scenario list from the API on mount
  useEffect(() => {
    fetch(`${BASE}/api/scenarios`)
      .then(r => r.json())
      .then(data => setScenarios(data))
      .catch(() => {}); // silently ignore if server not yet running
  }, []);

  const handleScenarioSelect = (e) => {
    const id = parseInt(e.target.value, 10);
    const sc = scenarios.find(s => s.id === id);
    if (sc) {
      setQuery(sc.query);
      setRmId(sc.rm_id);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!query.trim()) return;
    let finalQuery = query.trim();
    if (investableAmt.trim()) {
      finalQuery += `. Investable amount: Rs.${investableAmt.trim()}`;
    }
    onSubmit(finalQuery, rmId);
  };

  return (
    <div className="min-h-screen bg-slate-100 flex flex-col">
      {/* Minimal nav */}
      <div className="fixed top-0 w-full z-50 bg-slate-900 border-b border-slate-700/60 shadow h-14 flex items-center px-4 gap-3">
        <div className="w-8 h-8 bg-amber-500 rounded-lg flex items-center justify-center shadow">
          <span className="text-slate-900 font-black text-sm">W</span>
        </div>
        <span className="text-white font-semibold text-sm tracking-wide">Wealth Advisory Intelligence</span>
        <span className="text-slate-500 text-sm">Platform</span>
      </div>

      <div className="flex-1 flex items-center justify-center px-4 pt-14 py-10">
        <div className="w-full max-w-2xl">
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold text-slate-800">Advisory Intelligence</h1>
            <p className="text-slate-500 mt-2 text-sm">
              Enter your RM query or pick a test scenario to generate a structured client briefing
            </p>
          </div>

          <div className="bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden">
            {/* Tabs */}
            <div className="flex border-b border-slate-200">
              {[
                { key: 'query',    label: 'Free Query' },
                { key: 'scenario', label: `Test Scenarios${scenarios.length ? ` (${scenarios.length})` : ''}` },
              ].map(t => (
                <button
                  key={t.key}
                  onClick={() => setTab(t.key)}
                  className={`flex-1 py-3 text-sm font-semibold transition-colors ${
                    tab === t.key
                      ? 'bg-slate-900 text-white'
                      : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-5">
              {/* Scenario picker tab */}
              {tab === 'scenario' && (
                <div>
                  {scenarios.length === 0 ? (
                    <p className="text-sm text-slate-400 text-center py-4">
                      Start <code className="bg-slate-100 px-1 rounded">api_server.py</code> to load scenarios.
                    </p>
                  ) : (
                    <>
                      <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                        Select Scenario
                      </label>
                      <select
                        defaultValue=""
                        onChange={handleScenarioSelect}
                        className="w-full border border-slate-200 rounded-xl px-4 py-2.5 text-sm text-slate-800 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-amber-400"
                      >
                        <option value="" disabled>-- choose a scenario --</option>
                        {scenarios.map(s => (
                          <option key={s.id} value={s.id}>
                            {s.id}. [{s.blocked ? 'BLOCKED' : 'APPROVED'}] {s.label}
                          </option>
                        ))}
                      </select>
                      {query && (
                        <p className="text-xs text-emerald-600 mt-2 font-medium">
                          Query and RM ID pre-filled below — you can edit before submitting.
                        </p>
                      )}
                    </>
                  )}
                </div>
              )}

              {/* RM ID */}
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

              {/* Query textarea */}
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                  Query
                </label>
                <textarea
                  value={query}
                  onChange={e => setQuery(e.target.value)}
                  rows={5}
                  placeholder="e.g. Mr Arjun Menon (CUST000001) is here for his annual wealth review. Can you give me a full briefing before I meet him?"
                  className="w-full border border-slate-200 rounded-xl px-4 py-3 text-sm text-slate-800 resize-none focus:outline-none focus:ring-2 focus:ring-amber-400 placeholder:text-slate-400"
                />
              </div>

              {/* Optional investable amount — for WEALTH_RECOMMENDATION queries */}
              <div>
                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">
                  Investable Amount{' '}
                  <span className="normal-case font-normal text-slate-400">
                    (Rs.) — optional, for wealth recommendations
                  </span>
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm font-medium select-none">
                    Rs.
                  </span>
                  <input
                    type="text"
                    value={investableAmt}
                    onChange={e => setInvestableAmt(e.target.value)}
                    placeholder="e.g. 15,00,000"
                    className="w-full border border-slate-200 rounded-xl pl-10 pr-4 py-2.5 text-sm text-slate-800 bg-slate-50 focus:outline-none focus:ring-2 focus:ring-amber-400 placeholder:text-slate-400"
                  />
                </div>
                {investableAmt.trim() && (
                  <p className="text-xs text-amber-600 mt-1.5 font-medium">
                    Amount will be included in the query for the wealth recommendation pipeline.
                  </p>
                )}
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
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Processing steps</p>
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
  const message = isCompliance
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
  const [briefing,    setBriefing]    = useState(null);
  const [loading,     setLoading]     = useState(false);
  const [error,       setError]       = useState('');
  // pending holds { query, rmId } while the risk preference screen is shown
  const [pending,     setPending]     = useState(null);

  // Step 1: query form submitted → show risk preference screen
  const handleSubmit = (query, rmId) => {
    setBriefing(null);
    setError('');
    setPending({ query, rmId });
  };

  // Step 2a: risk preference chosen (or skipped) → run pipeline
  const runPipeline = async (query, rmId, riskPreference) => {
    setPending(null);
    setLoading(true);
    setError('');

    const controller = new AbortController();
    const timeout    = setTimeout(() => controller.abort(), 360_000); // 6 min

    try {
      const res = await fetch(`${BASE}/api/query`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ query, rm_id: rmId, risk_preference: riskPreference }),
        signal:  controller.signal,
      });
      clearTimeout(timeout);
      if (!res.ok) {
        const detail = await res.json().catch(() => ({}));
        throw new Error(detail?.detail || `Server responded with ${res.status}`);
      }
      setBriefing(await res.json());
    } catch (err) {
      clearTimeout(timeout);
      setError(
        err.name === 'AbortError'
          ? 'Request timed out after 6 minutes. The pipeline may still be running on the server.'
          : err.message || 'Could not connect to the backend.'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => { setBriefing(null); setError(''); setPending(null); };

  if (loading)  return <LoadingView />;
  if (error)    return <ErrorView message={error} onReset={handleReset} />;

  // Risk preference screen (between query form and pipeline run)
  if (pending) {
    return (
      <RiskPreferenceSelector
        onSelect={pref => runPipeline(pending.query, pending.rmId, pref)}
        onSkip={() => runPipeline(pending.query, pending.rmId, 'MEDIUM')}
      />
    );
  }

  if (!briefing)                  return <QueryPanel onSubmit={handleSubmit} loading={loading} />;
  if (briefing.pipeline_error)    return <ErrorView  message={briefing.message} onReset={handleReset} />;
  if (briefing.error)             return <BlockedView data={briefing} onReset={handleReset} />;
  if (briefing.compliance_block)  return <BlockedView data={briefing} onReset={handleReset} />;
  if (!briefing.briefing_header)  return <ErrorView  message="Pipeline returned an unexpected response format. Please retry." onReset={handleReset} />;

  const b = briefing;
  return (
    <div className="min-h-screen bg-slate-100">
      <NavBar header={b.briefing_header} />

      <main className="pt-16 pb-14 px-4">
        <div className="max-w-5xl mx-auto space-y-5">

          <div className="flex justify-end pt-1">
            <button
              onClick={handleReset}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold rounded-xl transition-colors"
            >
              New Query
            </button>
          </div>

          <BriefingHeader    data={b.briefing_header} />
          <ExecutiveSummary  summary={b.executive_summary} />

          <div className="grid grid-cols-1 lg:grid-cols-5 gap-5 items-start">
            <div className="lg:col-span-3"><ClientSnapshot data={b.client_snapshot} /></div>
            <div className="lg:col-span-2"><RiskPanel      data={b.compliance_and_due_diligence} /></div>
          </div>

          <ComplianceSection     data={b.compliance_and_due_diligence} />
          <RecommendationPanel   data={b.wealth_recommendation} />
          <IncomeValidation      data={b.income_validation} />
          <PortfolioSummary  data={b.portfolio_summary} />
          <RealReturnsPanel  data={b.real_returns} />
          <LoansPanel        data={b.loans_summary} />
          <ExpenditurePanel  data={b.expenditure_summary} />
          <CIBILPanel        data={b.cibil_summary} />
          <NextSteps         steps={b.next_steps} />

          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 px-6 py-4 text-center">
            <p className="text-xs text-slate-400 leading-relaxed">{b.disclaimer}</p>
          </div>

        </div>
      </main>
    </div>
  );
}
