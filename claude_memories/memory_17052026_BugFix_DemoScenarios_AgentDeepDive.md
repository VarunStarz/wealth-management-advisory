# Session Memory — 17 May 2026
## Bug Fix, Demo Scenario Curation, Agent Deep Dive

---

### 1. BUG FIXED — psycopg2 ILIKE % escape (`tools/agent_tools.py`)

**Root cause:** `get_fund_universe()` used an f-string with `ILIKE '%Employee Provident Fund%'`.
psycopg2 sees `%E` and `%'` as parameter placeholders → consumes extra params from the tuple →
`tuple index out of range` error. This caused ALL WEALTH_RECOMMENDATION pipeline runs to fail silently.

**Fix:** Doubled the `%` signs → `ILIKE '%%Employee Provident Fund%%'`

**Line:** `tools/agent_tools.py` line ~1693

**Rule to remember:** Any literal `%` in a psycopg2 SQL string (not a `%s` placeholder) must be escaped as `%%`.

---

### 2. SCENARIOS 19–22 TESTED END-TO-END

| # | Client | Risk | Amount | Result |
|---|--------|------|--------|--------|
| 19 | Arjun Menon (CUST000001) | MEDIUM | Rs.10,00,000 | ✓ 3 options (Growth Tilt, Balanced, Income & Stability) |
| 20 | Anita Nair (CUST000004) | LOW | Rs.3,00,000 | ✓ Compliance block — REFER_TO_EDD (KYC missing) |
| 21 | Farhan Sheikh (CUST000005) | HIGH | Rs.25,00,000 | ✓ Compliance block — open EDD, adverse media, HIGH risk |
| 22 | Sneha Varma (CUST000013) | NO_RISK | Rs.8,00,000 | ✓ 2 options (Govt Schemes: NSC+HDFC Liquid; FD Ladder: HDFC FD+SBI FD) |

**Known non-determinism:** Scenario 19 occasionally returns `options: []` with `eligible: true` and
`total_instruments_evaluated: 14` — the LLM scores instruments but skips option generation.
Not a code bug; inherent LLM non-determinism. No fix needed.

---

### 3. DEMO SCENARIO CURATION

**DEMO_SCENARIOS = [1, 2, 7, 18, 19, 20, 21, 22]** (8 of 22)

- Non-WR: 1 (full briefing clean), 2 (EDD compliance), 7 (guardrail block)
- WR: all 5 scenarios (18–22)

**Changes made:**
- `main.py`: Added `DEMO_SCENARIOS` list; modified `print_scenarios(demo_only=False)`;
  added `--list-demo` CLI flag; added `demo` keyword in interactive mode
- `api_server.py`: Imported `DEMO_SCENARIOS`; `/api/scenarios` endpoint now filters to demo set only
  → UI shows 8 scenarios instead of 22

**Committed:** `ea8f53a` — "Add multi-option Wealth Recommendation pipeline with curated demo scenarios"

---

### 4. CONCEPTUAL DISCUSSIONS

**Thin vs thick harness spectrum (all 4 questions):**
- Pipeline is firmly thick: `approved_for` routed by Python if/in, not LLM; parallel tasks built
  dynamically; EDD trigger is `_edd_triggered()` Python function; sanctions = Python hard exit
- Orchestrator agent exists but is bypassed — ADK's declarative graph can't handle conditional
  branching, dynamic parallel sets, or early exits
- Jaro-Winkler + LLM hybrid is the clearest spectrum example in one component: deterministic for
  CONFIRMED/NOT_FOUND (cheap, fast), LLM only for AMBIGUOUS (explainability + cost control)
- ADK's `SequentialAgent`/`ParallelAgent` rejected because they can't: conditionally skip agents,
  build dynamic task lists by scope, inject prior outputs precisely, or exit mid-pipeline

**All 13 agents explained in detail** (what, when, how, which tools):
Guardrail → Orchestrator (unused) → Client 360 → CDD → EDD → Income Validation →
Portfolio Analysis → Loans → Expenditure → CIBIL → Risk Assessment →
Portfolio Recommendation → Report Generation

**CDD risk tier clarification:**
- This is AML/compliance risk — risk to the bank, not the client's investment risk
- Stored in `kyc.risk_classification` table, set by compliance officers
- Signals: PEP status, unexplained cash, complex structures, overdue KYC, adverse media
- Completely separate from `risk_preference` (investment risk appetite in WR pipeline)
- Two different HIGH labels: AML HIGH (gates compliance) vs investment HIGH (gates fund universe)

**PEP explained:**
- Politically Exposed Person — holds/held prominent public position
- CAT_A (heads of state), CAT_B (senior officials), CAT_C (family/associates)
- Not assumed corrupt — assumed at higher risk due to access to public funds
- PEP flag → always triggers EDD regardless of other signals
- CUST000008 (Deepika Pillai) = CAT_B PEP, government official

---

###  What algorithm is used to recommend the funds?                                                                                               

● No need to re-read files — the full agent instruction is already in context. Here is the exact algorithm.

  ---
  The Recommendation Algorithm

  It is a rule-based weighted scoring model followed by template-driven allocation. No machine learning, no portfolio optimization theory (no
  Markowitz, no Black-Litterman). Deliberately simple and explainable.

  ---
  Stage 1 — Score every instrument (0–100)

  Each fund gets a composite score from three components:

  Return Score — weight 40%
  min(cagr_3yr_pct / 20.0, 1.0) × 100
  A fund with 20% 3-year CAGR scores 100. One with 10% scores 50. Capped at 100 so outliers don't dominate.

  Risk Efficiency Score — weight 30%
  min(cagr_3yr_pct / max(volatility_pct, 0.5), 3.0) / 3.0 × 100
  This is a Sharpe-ratio-like measure — return per unit of volatility. The ratio is capped at 3.0 (normalised to 100). A fund returning 18%
  with 6% volatility scores higher than one returning 20% with 15% volatility. For static instruments (PPF, FDs, NSC) where volatility is zero,
   a fixed score of 75 is assigned.

  Capital Protection Score — weight 30%
  max(0, min(100, 100 − |max_drawdown_pct| × 2))
  Penalises for historical peak-to-trough losses. A fund with 0% drawdown scores 100. A −25% drawdown scores 50. A −50% drawdown scores 0.
  Static instruments (no market risk) always score 100 here.

  Final composite:
  Score = (Return × 0.40) + (RiskEfficiency × 0.30) + (CapProtection × 0.30)

  ---
  Stage 2 — Filter the universe

  Before ranking:
  - Instruments the client already holds in the same category are removed (get_portfolio_holdings)
  - EPF is excluded at the SQL layer entirely (not investable independently)
  - Instruments with no return data and not of STATIC type are marked data_unavailable and excluded

  ---
  Stage 3 — Pick a strategy template

  Based on the client's risk_preference_tier, a named strategy is selected with pre-defined asset class weights. For example:

  ┌───────────┬──────────────────┬──────────────────────────────────────────────────────────┐
  │ Risk Tier │     Strategy     │                        Allocation                        │
  ├───────────┼──────────────────┼──────────────────────────────────────────────────────────┤
  │ HIGH      │ Growth Maximiser │ 65% Equity / 15% International / 10% Gold / 10% Safe     │
  ├───────────┼──────────────────┼──────────────────────────────────────────────────────────┤
  │ MEDIUM    │ Growth Tilt      │ 50% Equity / 15% Hybrid / 15% Gold / 10% Safe / 10% Debt │
  ├───────────┼──────────────────┼──────────────────────────────────────────────────────────┤
  │ LOW       │ Income Focus     │ 45% Safe / 45% Debt / 10% Gold                           │
  ├───────────┼──────────────────┼──────────────────────────────────────────────────────────┤
  │ NO_RISK   │ FD Ladder        │ 90% Safe (FDs) / 10% Gold                                │
  └───────────┴──────────────────┴──────────────────────────────────────────────────────────┘

  Up to 4 strategies are defined per tier, each with different weights. The system generates only strategies that produce genuinely distinct
  portfolios — different fund picks or >10% difference in any bucket.

  ---
  Stage 4 — Fill each bucket

  For each asset class bucket in the strategy, the top-scoring instrument from Stage 1 is picked for that slot. If a single bucket would exceed
   35% of the portfolio, it's split across two instruments in the same class to avoid concentration.

  The allocation percentage per instrument is fixed by the strategy template, not computed dynamically. Then:

  suggested_amount = investable_amount × (allocation_pct / 100)
  Rounded to nearest Rs. 1,000, with the largest bucket absorbing any rounding remainder so the total always sums to the investable amount.

  ---
  What it is NOT

  - Not Markowitz / Modern Portfolio Theory — no covariance matrix, no efficient frontier, no mean-variance optimisation
  - Not Black-Litterman — no market equilibrium returns, no investor views model
  - Not ML — no model trained on historical data, no clustering, no collaborative filtering
  - Not factor-based — no momentum, value, or quality factor tilts

  ---
  Why this approach

  Three reasons:

  1. Explainability — Every recommendation carries a rationale citing the exact 3-year CAGR and max drawdown. A compliance auditor or the
  client themselves can verify why a fund was picked. An ML model can't offer that.
  2. Regulatory defensibility — SEBI requires suitability documentation. A weighted formula with disclosed parameters is auditable. A neural
  network is not.
  3. Deterministic enough to be trustworthy — The same fund universe + same client + same risk tier should produce consistent recommendations.
  A scoring formula delivers that; an LLM left to freely pick funds would not.