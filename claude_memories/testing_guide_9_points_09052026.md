# Testing Guide — 9-Point Enhancement (09 May 2026)

Covers all 6 phases implemented in this session:
Phase 1: Loans/Expenditure/CIBIL agents + UI panels
Phase 2: Risk preference screen + benchmark returns (Yahoo Finance)
Phase 3: Inflation-adjusted returns (World Bank / IMF)
Phase 4: Expanded benchmark_income + forecast_income_growth + EDD agent
Phase 5: Employer stability validation (NSE CSV)
Phase 6: CIBIL multi-factor forecasting

---

## Step 1 — Start the servers

**Terminal 1 (backend):**
```powershell
cd "C:\Users\saico\Downloads\Varun\MSDSM IIT IIM Indore Documents\Trimester 6\Project\Project\wealth_platform"
python api_server.py
```

**Terminal 2 (frontend):**
```powershell
cd "...\wealth_platform\ui"
npm run dev
```

Open `http://localhost:5173` in your browser.

---

## Step 2 — Tool smoke test (run before the UI)

In a third terminal:

```powershell
python -c "
from tools.agent_tools import (
    fetch_benchmark_returns, fetch_india_inflation_forecast,
    forecast_income_growth, validate_employer_stability,
    get_cibil_credit_profile, benchmark_income
)
import json
print('--- benchmark_returns MEDIUM ---')
print(fetch_benchmark_returns('MEDIUM'))
print('--- benchmark_returns NO_RISK ---')
print(fetch_benchmark_returns('NO_RISK'))
print('--- inflation forecast ---')
print(fetch_india_inflation_forecast())
print('--- income growth ---')
print(forecast_income_growth('Promoter', 'Diversified', 'Mumbai', 70, 45))
print('--- employer stability ---')
print(validate_employer_stability('Reliance Industries Ltd'))
print('--- CIBIL profile CUST000009 ---')
print(get_cibil_credit_profile('CUST000009'))
"
```

**What to check:**
- No `OperationalError` or `column does not exist` errors
- `get_cibil_credit_profile` returns all 5 new fields: `payment_history_score`, `credit_utilisation_pct`, `credit_age_years`, `credit_mix_score`, `derogatory_marks`
- `fetch_benchmark_returns('MEDIUM')` returns a `cagr_3yr_pct` (Yahoo Finance or fallback 12.5%)
- `validate_employer_stability('Reliance Industries Ltd')` returns `listed_on_exchange: true`

---

## Step 3 — Risk preference screen (Phase 2)

Type any query in the UI → click **Generate Briefing**. Verify:
- Risk Preference Selector screen appears (4 cards: No Risk / Low / Medium / High)
- Each card shows product examples and return range
- "Skip — Use Default (Medium)" button works
- Selecting a card enables the "Continue" button

Test both paths: skip, and explicitly pick **High Risk**.

---

## Step 4 — Full briefing, Scenario 4 (primary test — CUST000009)

**Test Scenarios tab → Scenario 4** (UHNI — re-KYC overdue, complex structure)
Pick **MEDIUM** risk preference. Wait ~2 minutes.

| Panel | What to look for |
|-------|-----------------|
| Compliance Checklist | 7 items: KYC, EDD, Portfolio, Income, Credit Health, Loan Obligations, Spending & Lifestyle |
| Income Validation | `employer_stability` = **null** for CUST000009 (no income_proofs rows in DMS — that is the compliance gap). If a client has income proof records on file, `employer_stability` will be present with employer name, listed_on_exchange, and stability_rating. |
| Portfolio Summary | `benchmark_comparison` section with MEDIUM risk benchmark CAGR |
| Real Returns | CPI inflation % shown, real return calculated, verdict badge |
| Loans Panel | "No active loan obligations" (debt-free UHNI — correct) |
| Expenditure Panel | ~₹1.8L/month, **MODERATE** lifestyle tier (correct — AFFLUENT threshold is > ₹5L/month; ₹1.8L falls in ₹1L–₹5L = MODERATE), no cash advances |
| CIBIL Panel | Low utilisation (3.6%), `forecast_direction = DETERIORATING` (compliance derogatory marks override good payment history — correct per agent rules), ai_forecast cites actual numbers (100/100 payment score, 3.6% utilisation, 20.7yr credit age) |

---

## Step 5 — EDD income forecast (Phase 4)

Run **Scenario 2** (Farhan Sheikh CUST000005 — high risk, EDD open).
In the JSON response, the EDD section should include:
```json
"income_growth_forecast": {
  "projected_growth_rate_pct": ...,
  "career_stage": "...",
  "consistency_assessment": "CONSISTENT | FLAG_FOR_REVIEW | DISCREPANCY"
}
```

---

## Step 6 — Portfolio-only scope null-state test

Run **Scenario 5** (CUST000002, portfolio-only). Verify:
- Loans, Expenditure, CIBIL panels are hidden (data is null → components return null, no crash)
- Compliance section shows "CDD not run for this pipeline" — no crash
- Real Returns panel **does render** for PORTFOLIO_ONLY (agent derives nominal return from benchmark + alpha, so data is not null — this is correct behavior, not a bug)

---

## Step 7 — Risk preference effect on benchmark (Phases 2 & 3)

Run **Scenario 1** (CUST000001) twice — once with **No Risk**, once with **High Risk**.
In the Portfolio Summary JSON, check `benchmark_cagr_pct` differs:
- No Risk → ~7.1% (hardcoded FD rate)
- High Risk → Nifty 50 3yr CAGR from Yahoo Finance (^NSEI). As of May 2026 this is ~7–9% live (lower than historical long-run averages of 14–16%); fallback is 15.0% only if Yahoo Finance is unreachable. The key test is that the value **differs** from NO_RISK, not that it hits a specific number.

---

## Step 8 — Blocked scenarios still work

Run **Scenario 6** (investment recommendation — BLOCKED).
Verify the red COMPLIANCE BLOCK screen appears and nothing crashes.

---

## What a passing run looks like

- All panels render without "undefined" text or blank white cards
- CIBIL `ai_forecast` quotes actual numbers (e.g. "With a payment history score of 100/100 and utilisation at 3.6%...")
- Real Returns panel shows a CPI figure (from World Bank API or fallback 4.5%)
- Compliance checklist shows 7 rows for CUST000009
- No console errors in the browser DevTools Network tab

---

## Known fallback behaviour (not bugs)

- `fetch_benchmark_returns`: if Yahoo Finance is unreachable, returns hardcoded MEDIUM=12.5%, HIGH=15.0%
- `fetch_india_inflation_forecast`: if World Bank/IMF unreachable, returns CPI=4.5%, GDP=7.2%
- `validate_employer_stability`: if NSE CSV download fails, falls back to name-pattern heuristics
