# Session Memory — 09 May 2026 — UI Fixes & Data Corrections

## Context
Continuing from previous session (memory_09052025_FastAPI_UI.md).
Google ADK multi-agent pipeline, FastAPI backend (port 8000), React 18 + Vite UI (port 5173).
Six PostgreSQL DBs: CBS, CRM, KYC, PMS, CARD, DMS.

---

## 1. PDF Verification Delivered (CUST000009)
Verified the CUST000009 briefing PDF against actual DB data.
- 18/20 data points were accurate.
- Two issues found — both data seeding problems, no code bugs.

---

## 2. PMS Holdings Fix (DB fix — executed)

**Problem:** PORT000009 holdings market_values summed to Rs.51.9Cr instead of AUM Rs.42Cr.
Weight_pct also summed to 123.57% (wrong).

**Fix applied via psycopg2:**
```sql
-- Tata Motors: qty 200K → 100K
UPDATE holdings SET quantity=100000, market_value=89000000,
  weight_pct=21.19, unrealised_pl=69000000
WHERE holding_id = 'HOLD0000000018';

-- Gold ETF: price 6500 → 5250
UPDATE holdings SET current_price=5250, market_value=42000000,
  weight_pct=10.00, unrealised_pl=11600000
WHERE holding_id = 'HOLD0000000019';
```

**After fix:**
| Holding | Market Value | Weight |
|---------|-------------|--------|
| Reliance Industries | Rs.28.9Cr | 68.81% |
| Tata Motors Ltd     | Rs.8.9Cr  | 21.19% |
| Gold ETF - Nippon   | Rs.4.2Cr  | 10.00% |
| **Total**           | **Rs.42Cr = AUM** | **100.00%** |

---

## 3. Income Benchmark Fix (agent instruction fix)

**Problem:** `benchmark_income()` mock data has correct entry for `("Promoter", "Diversified", "Mumbai") → P50 = Rs.2,50,00,000` but the income_validation_agent was calling with wrong args (fell through to default Rs.24,00,000).

**Root cause:** Agent instruction said "use client's occupation and city from Client 360 profile" but:
- No explicit occupation field in DB
- CRM has `sub_segment = "Promoter/HUF"` but agent wasn't mapping it
- No city field anywhere in DB

**Fix:** Updated `agents/income_validation/agent.py` instruction — added explicit mapping table:
```
sub_segment "Promoter/HUF" → role="Promoter", industry="Diversified"
city: default "Mumbai" for UHNI/HNI segments when city not available
```

---

## 4. Risk Profile Gauge — SpeedometerGauge (ui/src/components/RiskPanel.jsx)

### What was tried and failed:
1. **Multi-segment stroked arcs** (4 colored `<path>` arcs) → ugly gaps between segments, floating chunks
2. **Single gradient stroked arc** (`linearGradient` on stroke) → user rejected, wanted filled donut style

### Final working implementation:
**Filled donut sectors** — each zone is a proper closed SVG path (outer arc + inner arc + fill).

```jsx
function SpeedometerGauge({ score }) {
  const cx = 130, cy = 102;
  const ro = 88, ri = 54;       // outer/inner radius — thick donut
  const needleLen = 74;
  // score 0 → angle π (left/LOW), score 100 → angle 0 (right/HIGH)
  const rad = (sc) => Math.PI * (1 - sc / 100);
  const outerPt = (sc) => [cx + ro * Math.cos(rad(sc)), cy - ro * Math.sin(rad(sc))];
  const innerPt = (sc) => [cx + ri * Math.cos(rad(sc)), cy - ri * Math.sin(rad(sc))];

  const sector = (s1, s2) => {
    // outer arc sweep=0 (CCW upper), inner arc sweep=1 (CW back)
    ...
  };

  // 5 zones with 2-score-unit gap between each
  const ZONES = [
    { s1:  1, s2: 19, fill: '#22c55e' },  // green   – low risk
    { s1: 21, s2: 39, fill: '#84cc16' },  // lime
    { s1: 41, s2: 59, fill: '#eab308' },  // yellow
    { s1: 61, s2: 79, fill: '#f97316' },  // orange
    { s1: 81, s2: 99, fill: '#ef4444' },  // red – high risk
  ];
  // viewBox="0 0 260 138"
  // Gold hub: r=14 (#fbbf24), r=8 (#f59e0b), r=3.5 (#1c1917)
}
```

**Key geometry rule:**
- `A ro ro 0 0 0 ...` — outer arc, sweep=0 = CCW = upper semicircle ✓
- `A ri ri 0 0 1 ...` — inner arc, sweep=1 = CW = goes back ✓
- Score 0 → needle left, score 100 → needle right
- Low/High labels below arc endpoints at cy+15

---

## 5. Compliance Section — Checklist (ui/src/components/ComplianceSection.jsx)

**Added a compliance checklist BEFORE the flag details.**

Five canonical checks, status derived from flag data:
```js
const CANONICAL_CHECKS = [
  { src: 'CDD',       label: 'KYC & Due Diligence'    },
  { src: 'EDD',       label: 'Enhanced Due Diligence' },
  { src: 'PORTFOLIO', label: 'Portfolio Suitability'  },
  { src: 'INCOME',    label: 'Income Validation'      },
  { src: 'CIBIL',     label: 'Credit Health'          },
];

function getCheckStatus(src, high, medium) {
  const hFlags = high.filter(f => f.source === src);
  const mFlags = medium.filter(f => f.source === src);
  if (hFlags.length > 0) return { status: 'FAIL',    detail: hFlags[0].flag };
  if (mFlags.length > 0) return { status: 'CAUTION', detail: mFlags[0].flag };
  return { status: 'PASS', detail: 'No issues detected' };
}
```

**Statuses:**
- `PASS` → green circle ✓, badge "CLEAR"
- `CAUTION` → amber circle !, badge "CAUTION"  
- `FAIL` → red circle ✗, badge "NON-COMPLIANT"

**Section order in rendered component:**
1. Compliance Checklist (new)
2. Divider
3. High Severity Flags (existing)
4. Medium Severity Cautions (existing)
5. Divider + EDD Summary (existing)

---

## 6. Files Modified This Session

| File | Change |
|------|--------|
| `agents/income_validation/agent.py` | Added sub_segment→role/industry/city mapping table |
| `ui/src/components/RiskPanel.jsx` | Replaced SemiGauge with SpeedometerGauge (filled donut) |
| `ui/src/components/ComplianceSection.jsx` | Added compliance checklist with tick/cross icons |
| PMS DB (live) | Fixed PORT000009 holdings market_value + weight_pct |

## 7. Committed and Pushed
Commit `ba55cb2` pushed to `origin/main`.

**Files in commit:**
- `agents/income_validation/agent.py`
- `ui/src/components/RiskPanel.jsx`
- `ui/src/components/ComplianceSection.jsx`
- `database/dumps/*.sql` — all 6 dumps re-generated via `python scripts/dump_databases.py`
- `claude_memories/memory_09052026_FastAPI_UI.md`
- `claude_memories/memory_09052026_UI_Fixes.md`

**Note:** `scripts/.pids` was intentionally excluded (runtime process ID file, not source).

---

## 8. Approved Implementation Plan — 9-Point Enhancement

Plan file: `C:\Users\saico\.claude\plans\eager-sparking-reef.md`
User approved: 09 May 2026. Implementation NOT yet started (interrupted).

### Phase 1 — Wire Existing Agents (#1 Loans, #2 Expenditure, #8 CIBIL)
**Status: COMPLETE (09 May 2026)**
- `agents/orchestrator/agent.py` — imports added, sub_agents updated, STEP 2 updated with scope rules
- `agents/report_generation/agent.py` — 3 new JSON sections; scope nulling; LOANS/EXPENDITURE source labels
- `agents/risk_assessment/agent.py` — 4 compound credit/lifestyle patterns; updated source label list
- New: `ui/src/components/LoansPanel.jsx` — NPA/DPD badges, EMI, outstanding, red flags
- New: `ui/src/components/ExpenditurePanel.jsx` — lifestyle tier badge, spend, cash advances
- New: `ui/src/components/CIBILPanel.jsx` — CIBIL score (300–900), credit health, AI forecast
- `ui/src/App.jsx` — imports added; panels rendered after `<PortfolioSummary>`
- `ui/src/components/ComplianceSection.jsx` — LOANS + EXPENDITURE added to CANONICAL_CHECKS
- No DB changes needed: CUST000009 has card data (CARD00000009, ₹1.8L/mo spend, 0 DPD, full payments); no liability_accounts rows (debt-free UHNI, correct)

### Phase 2 — Risk Preference Screen + Benchmark Returns (#5, #6)
**Status: COMPLETE (09 May 2026)**
- New: `ui/src/components/RiskPreferenceSelector.jsx` — 4-card selector; Skip→MEDIUM; onSelect/onSkip callbacks
- `ui/src/App.jsx` — `pending` state captures {query, rmId}; selector shown between form submit and pipeline; `runPipeline(query, rmId, riskPreference)` sends risk_preference in POST body
- `api_server.py` — `risk_preference` field (default MEDIUM, validated to enum) added to QueryRequest; passed to process_rm_query
- `main.py` — `risk_preference` param threaded through process_rm_query → run_pipeline → _run_portfolio prompt + report_generation prompt
- `tools/agent_tools.py` — `fetch_benchmark_returns(risk_tier)`: NO_RISK=7.1% / LOW=7.5% hardcoded; MEDIUM=^CNX500 / HIGH=^NSEI from Yahoo Finance with 3yr CAGR; urllib (stdlib, no requests dep); graceful fallback
- `agents/portfolio_analysis/agent.py` — fetch_benchmark_returns added to tools; Step 3 calls it; benchmark_comparison added to output schema
- No DB changes needed (risk_preference is runtime-only, never persisted)

### Phase 3 — Inflation-Adjusted Returns (#7)
**Status: COMPLETE (09 May 2026)**
- `tools/agent_tools.py` — `fetch_india_inflation_forecast()`: World Bank CPI API → most recent year as current_cpi_pct, 5yr avg as forecast; IMF DataMapper NGDP_RPCH/IND for GDP; both have urllib fallback (CPI 4.5%, GDP 7.2%)
- `agents/report_generation/agent.py` — fetch_india_inflation_forecast imported + added to tools; instruction updated with mandatory call rule + real_return derivation formula; `real_returns` section added to briefing JSON schema; scope rules updated (null for CDD_ONLY / INCOME_ONLY)
- New: `ui/src/components/RealReturnsPanel.jsx` — CPI callout, dual-bar chart (grey=nominal, coloured=real), portfolio + benchmark rows, verdict badge (REAL_POSITIVE / INFLATION_ERODING / BELOW_INFLATION)
- `ui/src/App.jsx` — RealReturnsPanel imported; rendered between PortfolioSummary and LoansPanel
- No DB changes needed

### Phase 4 — EDD Income Intelligence (#3, #4)
**Status: COMPLETE (09 May 2026)**
- `tools/agent_tools.py` — `benchmark_income()` expanded from 6 → 62 entries; 9 sectors, 15 cities; source updated to "PLFS 2023-24 + EY/Aon India Salary Survey 2024"
- `tools/agent_tools.py` — `forecast_income_growth(role, industry, city, age, experience_years)`: IMF GDP base (urllib, fallback 7.2%); career multiplier: 1.3× (≤35), 1.1× (≤45), 0.9× (≤55), 0.7× (55+); sector premium: +2% (Tech/Finance/Legal/Pharma/Healthcare), 0% (Govt/Education), −1% (Retail/Manufacturing/Media), +0.5% (Diversified)
- `agents/edd/agent.py` — forecast_income_growth imported + added to tools; Step 4 added: derives role/industry/city/age/exp from identity map; cross-references projected growth vs declared income trajectory; income_growth_forecast block added to output schema with consistency_assessment field

### Phase 5 — Employer Stability (#9)
**Status: COMPLETE (09 May 2026)**
- `tools/agent_tools.py` — `get_declared_income()` updated to surface `employer_name` from most recent income_proofs row (column already exists in DMS schema, no DB change needed)
- `tools/agent_tools.py` — `validate_employer_stability(employer_name)`: Source 1 = NSE EQUITY_L.csv via urllib (normalised substring match on NAME OF COMPANY); Source 2 = name-pattern heuristics (Ltd→HIGH, LLP→MEDIUM, Pvt Ltd→MEDIUM, &Sons/Trading→LOW, unknown→UNKNOWN); graceful fallback; production note for MCA21 replacement
- `agents/income_validation/agent.py` — validate_employer_stability imported + added to tools; Step 4 added (call only if employer_name non-empty; skip for self-employed/DATA_GAP); employer_stability block added to output schema; step numbering shifted (detect_income_discrepancy→Step 5, return→Step 6)
- No DB changes needed

### Phase 6 — CIBIL Forecasting Enhancement (#8)
**Status: COMPLETE (09 May 2026)**
- `tools/agent_tools.py` — `get_cibil_credit_profile()` rewritten: added 5 multi-factor fields: payment_history_score (0–100, derived from DPD/min-pay months), credit_utilisation_pct (sum balance/limit), credit_age_years (from CBS customer_since), credit_mix_score (0/40/70/100 by account type count), derogatory_marks (npa_count + dpd_severe_count); also surfaces dpd_card_months, minimum_payment_months, npa_count, dpd_severe_count
- `agents/cibil/agent.py` — instruction updated with multi-factor forecast rules: DETERIORATING (payment_history <70 AND utilisation >80, any derogatory_marks, dpd_card_months >3), STABLE (payment 70–89, utilisation 30–79, no derogatory), IMPROVING (credit_age >10yr + utilisation <30 + no marks); composite rules for thin files, NPA override, payment stress; ai_forecast must cite actual numeric values; output schema extended with forecast_direction + all 5 new multi-factor fields
- No DB changes needed — all fields derived from existing CARD, CBS, KYC tables

### New Files to Create
| File | Purpose |
|------|---------|
| `ui/src/components/LoansPanel.jsx` | Loans UI panel |
| `ui/src/components/ExpenditurePanel.jsx` | Expenditure UI panel |
| `ui/src/components/CIBILPanel.jsx` | CIBIL UI panel |
| `ui/src/components/RiskPreferenceSelector.jsx` | Separate risk preference step screen |

### User Preferences Confirmed
- Public data: **External REST APIs** (Yahoo Finance, World Bank, NSE CSV, MCA21)
- Risk preference UI: **Separate screen** between query and pipeline run
- Build order: **All 9 points** implemented sequentially by phase

---

## 9. Testing Status (09 May 2026)

Testing guide saved to: `claude_memories/testing_guide_9_points_09052026.md`

**Status: PENDING — Gemini API rate limit hit. Testing deferred to next session.**

### Code bug fixed during DB verification (Phase 6):
- `tools/agent_tools.py` — `get_cibil_credit_profile()` query used `WHERE status = 'ACTIVE'`
  but `card_accounts` column is named `card_status`. Fixed to `WHERE card_status = 'ACTIVE'`.

### Testing plan summary:
1. Tool smoke test (no Gemini needed) — run first
2. Scenario 4 (CUST000009 FULL_BRIEFING, MEDIUM risk) — exercises all 6 phases in one run
3. Scenario 2 (CUST000005 EDD) — verifies income_growth_forecast in EDD section
4. Scenario 5 (CUST000002 PORTFOLIO_ONLY) — verifies null-state panels don't crash
5. Scenario 1 (CUST000001) × 2 with NO_RISK + HIGH_RISK — verifies benchmark_cagr_pct differs
6. Scenario 6 (BLOCKED) — verifies blocked flow still works

### Nothing committed yet — all changes are local, uncommitted.
User instruction: **Always ask before any git commands.**

---

## Key Learnings / Gotchas

- **SVG multi-segment stroked arcs** always produce visible gaps at boundaries — use filled donut sectors instead for zone gauges
- **SVG stroke with linearGradient** works in browsers but user found it too plain — donut sectors look more professional
- **benchmark_income() mock data** has all needed entries — the bug was agent prompting, not missing data
- **CRM sub_segment field** = "Promoter/HUF", "Tech", etc. — this is the income role signal
- PMS `portfolio_master` uses `client_id` (CLI000009) not `customer_id` — join via CRM
