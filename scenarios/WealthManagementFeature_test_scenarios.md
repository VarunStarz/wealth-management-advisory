# ============================================================
# scenarios/WealthManagementFeature_test_scenarios.md
# Test scenarios for the Wealth Recommendation Feature
# (Steps 1–13 of the Wealth Recommendation Implementation Plan, 10 May 2026)
#
# Run with: python main.py --scenario <number>
# Interactive mode: python main.py  (type query + fill investable amount in UI)
# ============================================================

# Wealth Recommendation Feature — Test Scenarios

These scenarios verify every path through the WEALTH_RECOMMENDATION pipeline:
the happy path, the compliance block path, guardrail classification, amount
extraction variants, UI rendering, and database persistence.

---

## ✅ APPROVED — HAPPY PATH

---

### Scenario 18 (Built-in) — Standard Wealth Recommendation, HNI
**Client:** Vikram Anand Krishnan (CUST000011) | **RM:** RM002
**Expected pipeline:** WEALTH_RECOMMENDATION
**Investable amount:** Rs.20,00,000

**Run command:**
```
python main.py --scenario 18
```

**RM Query (exact):**
> "Vikram Krishnan (CUST000011) has Rs.20,00,000 he wants to deploy.
> Based on his risk profile, can you generate a wealth recommendation
> for how to invest this amount?"

**What to verify — Guardrail:**
- `guardrail_status`: PASS
- `approved_for`: WEALTH_RECOMMENDATION
- `investable_amount_inr`: 2000000 (extracted from "Rs.20,00,000")
- Pipeline log prints: `[Step 1] Client 360 → [Step 2] CDD → [Step 3b] Portfolio Recommendation → [Step 5] Report`
- Step 4 (Risk Assessment) is **absent** from console output

**What to verify — JSON output:**
```
wealth_recommendation.eligible                   = true
wealth_recommendation.investable_amount_inr      = "Rs.20,00,000" (or Rs.20,00,000.00)
wealth_recommendation.risk_tier_used             = "MEDIUM"  (CUST000011 CDD risk tier)
wealth_recommendation.recommended_instruments    = array of 5–7 instruments
wealth_recommendation.allocation_summary         = e.g. "35% equity / 20% debt / ..."
wealth_recommendation.total_instruments_evaluated >= 10
wealth_recommendation.instruments_excluded_existing_holdings >= 1 (client already holds 4 funds)
wealth_recommendation.disclaimer                 = non-null
income_validation                                = null
portfolio_summary                                = null
real_returns                                     = null
loans_summary                                    = null
expenditure_summary                              = null
cibil_summary                                    = null
```

**What to verify — each recommended instrument:**
- `fund_id`: present (e.g. FUND007)
- `name`, `category`, `asset_class`, `amc`: populated
- `cagr_3yr_pct`: non-null for MFAPI funds; matches ~17–20% for top equity funds
- `cagr_1yr_pct`: non-null
- `max_drawdown_pct`: negative value (e.g. -10.98)
- `suggested_allocation_pct`: integer, sums to ~100 across all instruments
- `suggested_amount_inr`: formatted as "Rs.X,XX,XXX"
- `rationale`: non-empty sentence specific to the instrument

**What to verify — DB persistence:**
```sql
-- connect to PMS DB (port 5435, db: portfolio_management_system)
SELECT fund_id, cagr_3yr_pct, cagr_1yr_pct, cached_at, expires_at
FROM fund_performance_cache
ORDER BY cached_at DESC;
-- Expected: rows for each MFAPI fund fetched, expires_at = cached_at + 24hrs

-- connect to CRM DB
SELECT rec_id, customer_id, investable_amount_inr, recommendation_date, risk_tier_used
FROM recommendation_log
ORDER BY recommendation_date DESC LIMIT 1;
-- Expected: REC20260510CUST000011, 2000000.00, risk_tier_used = MEDIUM
```

---

### Scenario WR-02 — Amount Written in Lakh Words (Interactive / UI)
**Client:** Vikram Anand Krishnan (CUST000011) | **RM:** RM002
**Expected pipeline:** WEALTH_RECOMMENDATION
**Investable amount extracted from:** natural language "15 lakh"

**RM Query:**
> "Vikram Krishnan (CUST000011) has 15 lakh he wants to put to work.
> Can you build a wealth recommendation for him?"

**What to verify — Guardrail extraction:**
- `investable_amount_inr`: 1500000 (guardrail converts "15 lakh" → 1500000)
- `approved_for`: WEALTH_RECOMMENDATION

**What to verify — output:**
- `wealth_recommendation.investable_amount_inr` reflects the Rs.15,00,000 figure
- `suggested_amount_inr` on each instrument sums to approximately Rs.15,00,000
- Pipeline does not run Risk Assessment (no Step 4 in console)

---

### Scenario WR-03 — Amount Written in Crore Words (Interactive / UI)
**Client:** Arjun Menon (CUST000001) | **RM:** RM001
**Expected pipeline:** WEALTH_RECOMMENDATION
**Investable amount extracted from:** natural language "1.5 crore"

**RM Query:**
> "Arjun Menon (CUST000001) has just received Rs.1.5 crore from a property
> sale. He wants to deploy this amount into a suitable portfolio. Can you
> give a wealth recommendation?"

**What to verify — Guardrail extraction:**
- `investable_amount_inr`: 15000000 (guardrail converts "1.5 crore" → 15000000)
- `approved_for`: WEALTH_RECOMMENDATION

**What to verify — risk tier:**
- CUST000001 stated_risk_appetite = MODERATE → RM selects MEDIUM from RiskPreferenceSelector
- CDD risk tier (LOW) is compliance risk — not the same as investment risk preference
- Allocation matrix for MEDIUM tier expected:
  EQUITY ~35% / DEBT ~20% / HYBRID ~15% / GOLD ~15% / SAFE ~15%
- Recommended instruments: 2 equity funds (large cap + mid/flexi cap), 1 debt,
  1 hybrid, 1 gold (SGB), 1 safe (PPF/EPF)
- Amounts sum = Rs.1,50,00,000

---

### Scenario WR-04 — Amount via UI Investable Amount Field
**Client:** Vikram Anand Krishnan (CUST000011) | **RM:** RM002
**Expected pipeline:** WEALTH_RECOMMENDATION
**Test method:** UI (browser), amount typed into the Rs. input field

**Steps:**
1. Start API server: `python api_server.py`
2. Start UI: `cd ui && npm run dev`
3. Open `http://localhost:5173`
4. In query box type:
   > "CUST000011 — generate a wealth recommendation for Vikram Krishnan"
5. In the **Investable Amount (Rs.)** field below the query box, type: `2500000`
6. The amber hint line should appear: "Investable amount will be included in the query"
7. Submit

**What to verify — submitted query (check browser network tab or server logs):**
- Query sent to API: `"...CUST000011... . Investable amount: Rs.2500000"`
- Guardrail extracts: `investable_amount_inr = 2500000`

**What to verify — UI panel rendering:**
- `Wealth Recommendation` dark-header panel appears **between** Compliance and Income sections
- Panel header shows: `MEDIUM Risk` badge + amber `Rs.25,00,000` amount
- Stacked horizontal allocation bar renders with colour-coded segments:
  - Blue = EQUITY, Green = DEBT, Purple = HYBRID, Amber = GOLD, Slate = SAFE
- Legend below bar shows each asset class with % value
- Stats row shows three tiles: `Recommended` / `Universe Scored` / `Already Held`
- 5–7 instrument cards visible; each card contains:
  - Rank badge (coloured per asset class), name, AMC · category, suggested amount
  - Three metric columns: 3yr CAGR (green), 1yr Return (green/red), Max Drawdown (amber/red)
  - Thin allocation progress bar + asset class pill
  - Italic rationale text
- Income Validation, Portfolio Summary, Loans, Expenditure, CIBIL panels are **absent**
- Italic disclaimer text at panel footer

---

## 🚫 COMPLIANCE BLOCK PATH

---

### Scenario WR-05 — Recommendation Withheld: HIGH-Risk Client, EDD Open
**Client:** Mohammed Farhan Sheikh (CUST000005) | **RM:** RM003
**Expected pipeline:** WEALTH_RECOMMENDATION
**Expected outcome:** `eligible = false` — compliance block, no instruments returned

**RM Query (run interactively):**
> "Farhan Sheikh (CUST000005) wants to deploy Rs.50,00,000 into a wealth
> portfolio. Can you generate a recommendation?"

**What to verify — output:**
```
wealth_recommendation.eligible          = false
wealth_recommendation.compliance_note   = non-null (explains why: HIGH risk / EDD open)
wealth_recommendation.recommended_instruments = null or []
```
- All other sections (income, portfolio, loans, etc.) = null (correct for WR scope)
- `compliance_and_due_diligence.cdd_status` = REFER_TO_EDD (populated from CDD agent)

**What to verify — UI (if testing via browser):**
- Red compliance block visible: "Recommendation Withheld — Compliance Block"
- `compliance_note` text appears inside the block
- No instrument cards, no allocation bar rendered

---

### Scenario WR-06 — Recommendation Withheld: VERY_HIGH Risk Client
**Client:** Suresh Chandran Varma (CUST000009) | **RM:** RM005
**Expected pipeline:** WEALTH_RECOMMENDATION
**Expected outcome:** `eligible = false` — VERY_HIGH risk + offshore EDD open

**RM Query (run interactively):**
> "Mr Suresh Varma (CUST000009) wants a wealth recommendation for Rs.1 crore
> he has available. Please generate a portfolio."

**What to verify — output:**
```
wealth_recommendation.eligible          = false
wealth_recommendation.compliance_note   = references VERY_HIGH risk / open EDD / offshore entities
```

---

## 🚫 GUARDRAIL BLOCK PATH

---

### Scenario WR-07 — Ad-Hoc Fund Tip Still Blocked (Regression)
**Expected outcome:** BLOCKED by guardrail — this is Scenario 6, re-run as regression

**Run command:**
```
python main.py --scenario 6
```

**RM Query:**
> "Based on Mr Sharma's profile (CUST000003), should I move his money
> into a small-cap fund? Give me an investment recommendation."

**What to verify:**
- `guardrail_status`: BLOCKED
- Reason references: ad-hoc product tip / directed buy instruction
- Platform does NOT enter WEALTH_RECOMMENDATION pipeline
- No `wealth_recommendation` field generated

**Why this matters:** The guardrail was modified in Step 7 to allow
WEALTH_RECOMMENDATION. This scenario confirms that the narrowing of the
block rule (from "investment recommendation" to "ad-hoc stock or fund tips")
did not accidentally open a loophole for directed buy/sell instructions.

---

### Scenario WR-08 — WEALTH_RECOMMENDATION Query Without Customer ID
**Expected outcome:** BLOCKED by guardrail — no customer context

**RM Query:**
> "Can you generate a wealth recommendation for Rs.10 lakh?"

**What to verify:**
- `guardrail_status`: BLOCKED
- Reason references: no customer ID or name provided
- Platform does not attempt to run the pipeline

---

### Scenario WR-09 — WEALTH_RECOMMENDATION Query Without Investable Amount
**Expected outcome:** APPROVED but `investable_amount_inr` = null

**RM Query:**
> "Can you give me a wealth recommendation for Vikram Krishnan (CUST000011)?"

**What to verify — Guardrail:**
- `guardrail_status`: PASS
- `approved_for`: WEALTH_RECOMMENDATION
- `investable_amount_inr`: null (no amount in query)

**What to verify — Portfolio Recommendation Agent:**
- Agent acknowledges no investable amount was specified
- Either asks for the amount in its output or proceeds with a relative allocation
  (% of portfolio only, no absolute Rs. amounts)
- `suggested_amount_inr` fields may be null or omitted for each instrument

---

## DATABASE VERIFICATION SCENARIOS

---

### Scenario WR-10 — Performance Cache Hit (Second Run)
**Purpose:** Verify the 24-hour cache prevents repeated MFAPI.in calls

**Steps:**
1. Run Scenario 18 (first run — populates cache via live MFAPI.in fetch)
2. Check `fund_performance_cache` is populated (see SQL below)
3. Run Scenario 18 again immediately (second run)
4. Observe that Step 3b completes noticeably faster the second time

**SQL to check cache before second run:**
```sql
-- connect to PMS DB (port 5435, db: portfolio_management_system)
SELECT
    fm.fund_id,
    fm.instrument_name,
    fm.data_source,
    fpc.cagr_3yr_pct,
    fpc.cached_at,
    fpc.expires_at,
    CASE WHEN fpc.expires_at > NOW() THEN 'VALID' ELSE 'EXPIRED' END AS cache_status
FROM fund_performance_cache fpc
JOIN fund_master fm ON fm.fund_id = fpc.fund_id
ORDER BY fpc.cached_at DESC;
```

**Expected:**
- Rows for each MFAPI fund fetched during the first run
- `data_source = MFAPI` funds have non-null `cagr_3yr_pct`, `cagr_1yr_pct`, `volatility_pct`, `max_drawdown_pct`
- `data_source = STATIC` funds not in cache (they use `static_return_pct` from `fund_master` directly)
- `cache_status = VALID` (within 24-hour window)

---

### Scenario WR-11 — Recommendation Log Accumulation
**Purpose:** Verify each run creates a new `recommendation_log` row

**Steps:**
1. Run Scenario 18 twice with different investable amounts
2. Run Scenario WR-03 (CUST000001, 1.5 crore)
3. Query the log

```sql
-- connect to CRM DB (port 5435, db: crm)
SELECT
    rec_id,
    customer_id,
    rm_id,
    investable_amount_inr,
    risk_tier_used,
    recommendation_date,
    jsonb_array_length(recommended_funds) AS instruments_count
FROM recommendation_log
ORDER BY recommendation_date DESC
LIMIT 5;
```

**Expected:**
- Separate row per run — rec_id pattern: `REC{YYYYMMDD}{customer_id}`
- Two rows for CUST000011, one for CUST000001
- `instruments_count` = 5–7
- `investable_amount_inr` matches the amount from each query

---

### Scenario WR-12 — fund_master Universe Integrity Check
**Purpose:** Verify the 32 seeded instruments span all risk tiers and data sources

```sql
-- connect to PMS DB
SELECT
    risk_tier,
    data_source,
    asset_class,
    COUNT(*) AS count
FROM fund_master
WHERE is_active = TRUE
GROUP BY risk_tier, data_source, asset_class
ORDER BY risk_tier, data_source;
```

**Expected coverage:**
| risk_tier | Expected instruments |
|-----------|---------------------|
| NO_RISK   | PPF, EPF, RBI Floating Rate Bond, NSC, SBI FD, HDFC FD, Axis FD (all STATIC) |
| LOW       | HDFC Short Term Debt, Axis Short Duration, ICICI Pru Corp Bond, Kotak Corp Bond, SBI Magnum Gilt, ICICI Pru Gilt, ICICI Pru BAF, HDFC BAF, Mirae Asset Silver ETF |
| MEDIUM    | Mirae Asset Large Cap, HDFC Top 100, Parag Parikh Flexi Cap, HDFC Flexi Cap, ICICI Pru Multi Asset, Nippon India Multi Asset, HDFC Gold ETF, SGB |
| HIGH      | Nippon India Mid Cap, HDFC Mid-Cap Opp., SBI Small Cap, Nippon India Small Cap, Axis Long Term Equity, DSP Tax Saver, Motilal Oswal NASDAQ 100, Mirae Asset NYSE FANG+ |

**Also check:**
```sql
SELECT COUNT(*) FROM fund_master WHERE is_active = TRUE;
-- Expected: 32
SELECT COUNT(*) FROM fund_master WHERE data_source = 'MFAPI' AND scheme_code IS NULL;
-- Expected: 0 (every MFAPI fund must have a scheme_code)
SELECT COUNT(*) FROM fund_master WHERE data_source = 'STATIC' AND static_return_pct IS NULL;
-- Expected: 0 (every STATIC fund must have a return rate)
```

---

## PIPELINE ISOLATION VERIFICATION

---

### Scenario WR-13 — Full Briefing for Same Client Still Works (Regression)
**Client:** Vikram Anand Krishnan (CUST000011) | **RM:** RM002
**Purpose:** Confirm CUST000011 full briefing is unaffected by the new pipeline branch

**Run command:**
```
python main.py --scenario 14
```

**What to verify:**
- Pipeline runs FULL_BRIEFING (not WEALTH_RECOMMENDATION)
- All sections populated: income_validation, portfolio_summary, loans_summary,
  expenditure_summary, cibil_summary, real_returns
- `wealth_recommendation` = null (correct — not a WR query)
- Portfolio underperformance flags still surface (Scenario 14 regression)
- Risk Assessment still runs (Step 4 visible in console)
- No reference to fund_master or MFAPI in output

---

### Scenario WR-14 — Scope Isolation: income_validation Null in WR Briefing
**Purpose:** Verify report_generation_agent correctly nulls out non-WR sections

**Run:** Scenario 18 and inspect raw JSON.

**Exhaustive null check:**
```
income_validation             must be null
portfolio_summary             must be null
real_returns                  must be null
loans_summary                 must be null
expenditure_summary           must be null
cibil_summary                 must be null
compliance_and_due_diligence.risk_score                    must be null
compliance_and_due_diligence.recommended_compliance_action must be null
```

**Must NOT be null:**
```
briefing_header               populated
executive_summary             populated (3-4 sentences)
client_snapshot               populated
compliance_and_due_diligence  partially populated (cdd_status, red_flags_high, caution_points_medium)
wealth_recommendation         populated
next_steps                    2-3 WR-specific action steps
disclaimer                    populated
```

---

## QUICK REFERENCE — WEALTH RECOMMENDATION SCENARIOS

| Scenario | Client | Amount | Expected Pipeline | Expected Eligible | Key Verification |
|---|---|---|---|---|---|
| 18 (built-in) | CUST000011 | Rs.20L | WEALTH_RECOMMENDATION | true | 5–7 instruments, MEDIUM allocation |
| WR-02 | CUST000011 | "15 lakh" | WEALTH_RECOMMENDATION | true | Guardrail lakh→number extraction |
| WR-03 | CUST000001 | "1.5 crore" | WEALTH_RECOMMENDATION | true | LOW tier → DEBT/SAFE heavy allocation |
| WR-04 | CUST000011 | UI field 2500000 | WEALTH_RECOMMENDATION | true | UI panel renders correctly |
| WR-05 | CUST000005 | Rs.50L | WEALTH_RECOMMENDATION | **false** | Compliance block — EDD open |
| WR-06 | CUST000009 | Rs.1Cr | WEALTH_RECOMMENDATION | **false** | Compliance block — VERY_HIGH risk |
| WR-07 | CUST000003 | n/a | **BLOCKED** | n/a | Ad-hoc fund tip still blocked |
| WR-08 | (none) | Rs.10L | **BLOCKED** | n/a | No customer ID |
| WR-09 | CUST000011 | (none) | WEALTH_RECOMMENDATION | true | Null investable amount handled |
| WR-10 | CUST000011 | Rs.20L | WEALTH_RECOMMENDATION | true | Cache hit on second run |
| WR-11 | multiple | various | WEALTH_RECOMMENDATION | true | recommendation_log rows created |
| WR-12 | — | — | DB check only | — | fund_master 32 instruments intact |
| WR-13 | CUST000011 | n/a | FULL_BRIEFING | n/a | wealth_recommendation = null in full briefing |
| WR-14 | CUST000011 | Rs.20L | WEALTH_RECOMMENDATION | true | Non-WR sections all null |
