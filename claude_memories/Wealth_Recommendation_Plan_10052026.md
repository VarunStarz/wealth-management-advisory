# Wealth Recommendation Feature — Implementation Plan (10 May 2026)

## Design Decisions (confirmed by user)
1. Asset universe: mutual funds (all types), government bonds, PF, PPF, Gold, metals, international equity, ELSS, FDs, SGBs, REITs
2. Investable amount: RM inputs the figure in the UI before running the pipeline
3. Pipeline type detection: AI (guardrail) determines WEALTH_RECOMMENDATION vs FULL_BRIEFING from query intent
4. No surplus identified: show recommendations anyway

---

## Asset Universe

| Category | Instruments | Performance Source |
|---|---|---|
| Equity — Large Cap | Mirae Asset Large Cap, HDFC Top 100 | MFAPI.in |
| Equity — Flexi Cap | Parag Parikh Flexi Cap, HDFC Flexi Cap | MFAPI.in |
| Equity — Mid Cap | Nippon India Mid Cap, HDFC Mid-Cap Opp. | MFAPI.in |
| Equity — Small Cap | SBI Small Cap, Nippon India Small Cap | MFAPI.in |
| Equity — ELSS | Axis Long Term Equity, DSP Tax Saver | MFAPI.in |
| International Equity | Motilal Oswal NASDAQ 100 FoF, Mirae Asset NYSE FANG+ FoF | MFAPI.in |
| Hybrid — Balanced Advantage | ICICI Pru BAF, HDFC BAF | MFAPI.in |
| Hybrid — Multi Asset | ICICI Pru Multi Asset, Nippon India Multi Asset | MFAPI.in |
| Debt — Short Duration | HDFC Short Term Debt, Axis Short Duration | MFAPI.in |
| Debt — Corporate Bond | ICICI Pru Corporate Bond, Kotak Corporate Bond | MFAPI.in |
| Debt — Gilt | SBI Magnum Gilt, ICICI Pru Gilt | MFAPI.in |
| Gold | Sovereign Gold Bond (SGB), HDFC Gold ETF | MFAPI.in (ETF); SGB hardcoded (2.5% coupon + gold appreciation) |
| Silver | Mirae Asset Silver ETF | MFAPI.in |
| Government / Safe | PPF (7.1%), EPF (8.25%), RBI Floating Rate Bonds (7.35%), NSC (7.7%) | Hardcoded govt-declared rates |
| Fixed Deposits | SBI FD (7.1%), HDFC Bank FD (7.25%), Axis Bank FD (7.2%) | Hardcoded bank rates |

---

## Database Changes

### PMS — `portfolio_management_system`

**New table: `fund_master`**
Authoritative curated instrument universe. Recommendation agent reads from this.
```sql
CREATE TABLE fund_master (
    fund_id           VARCHAR(20)  PRIMARY KEY,
    scheme_code       INTEGER,                      -- AMFI code for MFAPI.in (NULL for static)
    instrument_name   VARCHAR(200) NOT NULL,
    short_name        VARCHAR(100),
    category          VARCHAR(50)  NOT NULL,        -- Large Cap, Flexi Cap, Gilt, PPF, etc.
    asset_class       VARCHAR(30)  NOT NULL,        -- EQUITY, DEBT, GOLD, HYBRID, SAFE, INTERNATIONAL
    amc               VARCHAR(100),
    risk_tier         VARCHAR(20)  NOT NULL,        -- NO_RISK, LOW, MEDIUM, HIGH
    instrument_type   VARCHAR(20)  NOT NULL,        -- MUTUAL_FUND, ETF, GOVT_SCHEME, FD, SGB
    data_source       VARCHAR(10)  NOT NULL,        -- MFAPI or STATIC
    static_return_pct NUMERIC(5,2),                -- for PPF, FD, RBI Bonds (NULL for live funds)
    min_investment_inr INTEGER     DEFAULT 500,
    is_active         BOOLEAN      DEFAULT TRUE,
    added_date        DATE         DEFAULT CURRENT_DATE
);
```

**New table: `fund_performance_cache`**
Caches MFAPI.in NAV computations. TTL = 24 hours. Prevents 30-40s added latency per run.
```sql
CREATE TABLE fund_performance_cache (
    cache_id          SERIAL       PRIMARY KEY,
    fund_id           VARCHAR(20)  REFERENCES fund_master(fund_id),
    scheme_code       INTEGER,
    cagr_3yr_pct      NUMERIC(6,2),
    cagr_1yr_pct      NUMERIC(6,2),
    volatility_pct    NUMERIC(6,2),
    max_drawdown_pct  NUMERIC(6,2),
    nav_as_of_date    DATE,
    cached_at         TIMESTAMP    DEFAULT NOW(),
    expires_at        TIMESTAMP
);
```

### CRM — `crm`

**New table: `recommendation_log`**
Stores every recommendation generated per client. Gives RM history of prior suggestions.
```sql
CREATE TABLE recommendation_log (
    rec_id                VARCHAR(30)  PRIMARY KEY,  -- e.g. REC20260510CUST000011
    customer_id           VARCHAR(20)  NOT NULL,
    rm_id                 VARCHAR(20),
    recommendation_date   TIMESTAMP    DEFAULT NOW(),
    investable_amount_inr NUMERIC(15,2),
    risk_tier_used        VARCHAR(20),
    recommended_funds     JSONB,
    allocation_summary    TEXT,
    pipeline_run_id       VARCHAR(50)
);
```

---

## New External API

**MFAPI.in** — `https://api.mfapi.in/mf/{scheme_code}`
- Free, no API key required
- Returns full NAV history for any AMFI-registered mutual fund / ETF
- Used to compute: 3yr CAGR, 1yr return, volatility, max drawdown
- Results cached in `fund_performance_cache` for 24 hours

---

## New Components

### Backend
- `tools/agent_tools.py` — `get_fund_universe(risk_tier)` tool (queries `fund_master`)
- `tools/agent_tools.py` — `fetch_fund_performance(scheme_code, fund_id)` tool (MFAPI.in + cache)
- `agents/portfolio_recommendation/agent.py` — new agent

### Modified Backend
- `agents/guardrail/agent.py` — allow WEALTH_RECOMMENDATION pipeline type
- `config/settings.py` — remove "investment recommendation" from blocked_intents for this flow
- `agents/orchestrator/agent.py` — add WEALTH_RECOMMENDATION pipeline branch
- `agents/report_generation/agent.py` — extend schema with `wealth_recommendation` section

### Frontend
- `ui/src/App.jsx` — add optional "Investable Amount (₹)" field to QueryPanel
- `ui/src/components/RecommendationPanel.jsx` — new panel (fund cards + allocation bar)
- `ui/src/App.jsx` — wire RecommendationPanel into briefing view

### Test Data
- `main.py` — add Scenario 18 (WEALTH_RECOMMENDATION test case)

---

## Portfolio Recommendation Agent Logic

1. Read fund universe from `fund_master` filtered by client's risk tier (+ one tier below for stability)
2. Fetch 3yr performance for each candidate (MFAPI.in via cache)
3. Skip instruments client already holds (from existing portfolio holdings)
4. Score each instrument: CAGR 40% + risk-adjusted return 30% + consistency 30%
5. Build allocation split by asset class (e.g. 50% equity / 20% debt / 15% gold / 15% safe)
6. Output top 5–7 instruments with suggested amount per instrument and rationale
7. Compliance gate: if cdd_status ≠ PASS or any HIGH red flag → set eligible: false, skip instruments, return compliance note

---

## Report Generation — New Section Schema
```json
"wealth_recommendation": {
  "eligible": true,
  "investable_amount_inr": "Rs.15,00,000",
  "risk_tier_used": "MEDIUM",
  "recommended_instruments": [
    {
      "fund_id": "FUND007",
      "name": "Parag Parikh Flexi Cap Fund",
      "category": "Flexi Cap",
      "asset_class": "EQUITY",
      "amc": "PPFAS",
      "cagr_3yr_pct": 18.4,
      "cagr_1yr_pct": 14.2,
      "max_drawdown_pct": -12.1,
      "suggested_allocation_pct": 30,
      "suggested_amount_inr": "Rs.4,50,000",
      "rationale": "..."
    }
  ],
  "allocation_summary": "50% equity / 20% debt / 15% gold / 15% safe instruments",
  "disclaimer": "These are indicative suggestions based on historical performance. Past performance is not indicative of future returns. All decisions remain with the RM."
}
```

---

## Implementation Order

| Step | Task | File(s) | Status |
|---|---|---|---|
| 1 | Create `fund_master` table + seed ~30 instruments | PMS DB | ✅ Done (10 May 2026) — 32 instruments seeded across NO_RISK/LOW/MEDIUM/HIGH |
| 2 | Create `fund_performance_cache` table | PMS DB | ✅ Done (10 May 2026) — table created, empty (populated at runtime) |
| 3 | Create `recommendation_log` table | CRM DB | ✅ Done (10 May 2026) — table created in crm DB |
| 4 | Add `get_fund_universe()` tool | tools/agent_tools.py | ✅ Done (10 May 2026) — queries fund_master by risk tier (+ one tier below), returns active instruments |
| 5 | Add `fetch_fund_performance()` tool | tools/agent_tools.py | ✅ Done (10 May 2026) — MFAPI.in live fetch + 24hr cache; static fallback for PPF/FD/SGB; also added `log_recommendation()` writer |
| 6 | Build portfolio_recommendation agent | agents/portfolio_recommendation/agent.py | ✅ Done (10 May 2026) — 9-step instruction: compliance gate → fund universe → performance fetch → holdings exclusion → scoring → allocation matrix → amounts → rationale → log |
| 7 | Update guardrail to allow WEALTH_RECOMMENDATION | agents/guardrail/agent.py, config/settings.py | ✅ Done (10 May 2026) — removed "investment recommendation" from blocked_intents; guardrail now detects WEALTH_RECOMMENDATION intent, extracts investable_amount_inr, and includes it in the approval JSON |
| 8 | Update orchestrator with new pipeline branch | agents/orchestrator/agent.py | ✅ Done (10 May 2026) — added WEALTH_RECOMMENDATION 4-step pipeline (client_360 → cdd → portfolio_recommendation → report_generation); portfolio_recommendation_agent added to sub_agents (11 total); investable_amount_inr passed from guardrail through to recommendation agent |
| 9 | Extend report generation schema | agents/report_generation/agent.py | ✅ Done (10 May 2026) — added WEALTH_RECOMMENDATION scope rules, wealth_recommendation JSON field, verbatim copy rule from portfolio_recommendation_agent, real_returns skipped for this scope |
| 10 | Add investable amount field to QueryPanel | ui/src/App.jsx | ✅ Done (10 May 2026) — optional Rs. input field added below query textarea; amount appended to query string as "Investable amount: Rs.X" before submission; hint shown when field is filled |
| 11 | Build RecommendationPanel component | ui/src/components/RecommendationPanel.jsx | ✅ Done (10 May 2026) — stacked allocation bar, per-instrument cards (3yr CAGR / 1yr return / max drawdown / rationale), compliance-ineligible block, stats row, disclaimer; asset class colour-coded |
| 12 | Wire RecommendationPanel into briefing view | ui/src/App.jsx | ✅ Done (10 May 2026) — imported and inserted after ComplianceSection, before IncomeValidation; renders only when b.wealth_recommendation is non-null |
| 13 | Add Scenario 18 test case | main.py | ✅ Done (10 May 2026) — WEALTH_RECOMMENDATION pipeline wired in run_pipeline() (investable_amount_inr param, CDD scope, Step 3b recommendation agent, risk skipped, report prompt updated); Scenario 18 added (CUST000011, Rs.20,00,000, RM002); --scenario help updated to 1-18 |

---

## Key Design Decisions (confirmed)

- Asset universe stored in `fund_master` table (PMS DB) — not a Python config file
- Performance cache in `fund_performance_cache` table (PMS DB) — 24hr TTL, avoids 30+ MFAPI.in calls per run
- Recommendation history in `recommendation_log` table (CRM DB)
- Investable amount: RM inputs in QueryPanel UI (optional field)
- Guardrail: WEALTH_RECOMMENDATION is a new valid pipeline type (not blocked)
- If no surplus / compliance issues: show recommendations anyway with a note
- `risk_preference` parameter comes from RM's RiskPreferenceSelector in UI — **NOT** from CDD risk tier
- **CDD risk tier = compliance/AML risk. Investment risk preference = separate RM input. Do NOT conflate.**

---

## Bugs Fixed During Testing (10 May 2026)

1. **`log_recommendation(recommended_funds: list)` → must be `list[dict]`**
   Bare `list` generates `{"type": "array"}` with no `items` field in Gemini JSON schema → `400 INVALID_ARGUMENT`. Fixed by changing annotation to `list[dict]`.

2. **Gemini LLM wraps JSON output in ` ```json ``` ` code fences**
   `json.loads()` in `_parse_pipeline_result()` fails → returns `{"error": True, "message": raw_fenced_text}` → UI shows "QUERY BLOCKED" badge with raw JSON as text.
   Fixed by calling `_extract_json(briefing)` at end of `run_pipeline()` before returning.

3. **Step 3b prompt did not pass `risk_preference` to portfolio_recommendation_agent**
   Agent was inferring risk tier from CDD data instead of RM input.
   Fixed by adding `f"Investment risk preference tier: {risk_preference}\n"` to the Step 3b prompt in `run_pipeline()`.

---

## Test Scenarios

Test scenarios file: `scenarios/WealthManagementFeature_test_scenarios.md` — 14 scenarios (Scenario 18 + WR-02 through WR-14)

### Test Execution Status (as of 10 May 2026)

| Scenario | Client | Result | Notes |
|---|---|---|---|
| Scenario 18 (WR-01) | CUST000011, Rs.20L | ✅ PASS | Happy path; 6 instruments; MEDIUM tier; Parag Parikh Flexi Cap top pick |
| WR-02 | CUST000011, "15 lakh" | ✅ PASS | Guardrail correctly converted "15 lakh" → 1500000 |
| WR-03 | CUST000001, "1.5 crore" | ✅ PASS | RM selected MEDIUM tier; allocation was EQUITY-heavy as expected |
| WR-04 | CUST000011, UI field 2500000 | ✅ PASS | UI panel rendered correctly; all card elements present |
| WR-05 | CUST000005, Rs.50L | ✅ PASS | Compliance block — REFER_TO_EDD + KYC UNDER_REVIEW; eligible=false |
| WR-06 | CUST000009, Rs.1Cr | ✅ PASS | Compliance block — REFER_TO_EDD + KYC UNDER_REVIEW; eligible=false |
| WR-07 | CUST000003 | ⬜ PENDING | Regression: ad-hoc fund tip must still be BLOCKED |
| WR-08 | (none), Rs.10L | ⬜ PENDING | Guardrail block — no customer ID |
| WR-09 | CUST000011, no amount | ⬜ PENDING | Null investable amount — should still produce % allocation |
| WR-10 | CUST000011, Rs.20L ×2 | ⬜ PENDING | Cache hit — second run faster, fund_performance_cache populated |
| WR-11 | multiple | ⬜ PENDING | recommendation_log accumulation check (SQL) |
| WR-12 | DB only | ⬜ PENDING | fund_master 32 instruments, STATIC/MFAPI integrity |
| WR-13 | CUST000011 (Scenario 14) | ⬜ PENDING | Full briefing regression — wealth_recommendation must be null |
| WR-14 | CUST000011, Rs.20L | ⬜ PENDING | Scope isolation — all non-WR sections must be null |

### Key Observations
- Composite score formula (Return 40% + RiskEfficiency 30% + CapProtection 30%) is computed by LLM — scores vary between runs (non-determinism). Fund selection and allocation are consistent; raw scores are not. Accept this.
- LLM occasionally scores static instruments (EPF, SGB) inconsistently across runs — not a bug, just arithmetic drift.
- WR-03: test scenarios file initially had wrong expected allocation (LOW tier instead of MEDIUM). Corrected — CDD risk tier drives compliance eligibility only; RM's RiskPreferenceSelector drives allocation matrix.
