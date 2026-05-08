# ============================================================
# scenarios/test_scenarios.md
# Test scenarios for the Wealth Advisory Intelligence Platform
# These simulate real wealth manager queries in a bank setting.
# ============================================================

# Wealth Management Advisory Platform — Test Scenarios

These scenarios simulate real queries a wealth manager might type while
a client is sitting in front of them. They cover the full spectrum of
platform use cases including two intentionally BLOCKED queries.

Run with: `python main.py --scenario <number>`

---

## ✅ APPROVED SCENARIOS

---

### Scenario 1 — Annual Review, Standard HNI (Clean Profile)
**Client:** Arjun Menon (CUST000001) | **RM:** RM001
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** Clean briefing, LOW risk, no compliance flags

**RM Query:**
> "Mr Arjun Menon (CUST000001) is here for his annual wealth review.
> He wants to know how his portfolio is doing and whether there are any
> areas we should look at. Can you give me a full briefing before I meet him?"

**What to look for:**
- Identity resolves cleanly across all six systems
- CDD PASS — KYC verified, no PEP, no sanctions
- Income consistent with declared salary
- Portfolio performance vs Nifty 50 benchmark
- LOW risk score (expected ~22)

---

### Scenario 2 — High-Risk Client, EDD Open, Cash Deposits
**Client:** Mohammed Farhan Sheikh (CUST000005) | **RM:** RM003
**Expected pipeline:** FULL_BRIEFING including EDD
**Expected outcome:** HIGH risk, EDD triggered, income discrepancy flagged

**RM Query:**
> "Farhan Sheikh (CUST000005) has come in asking about restructuring his
> wealth. Before I proceed, I need a complete intelligence briefing.
> What's his current compliance status and risk profile?"

**What to look for:**
- CDD returns REFER_TO_EDD → EDD agent activates
- Open EDD case (EDD00000001) — cash deposits unexplained
- Aadhaar document PENDING_VERIFICATION
- KYC status UNDER_REVIEW
- Cash advance on credit card (₹2,00,000)
- Income discrepancy: declared ₹1.5Cr vs inferred ~₹3.5Cr
- Risk score HIGH (~78)
- Recommended action: COMPLIANCE_ESCALATION

---

### Scenario 3 — PEP Client, Government Official
**Client:** Deepika Rajan Pillai (CUST000008) | **RM:** RM004
**Expected pipeline:** FULL_BRIEFING including EDD
**Expected outcome:** HIGH risk, PEP Category-B, mandatory EDD

**RM Query:**
> "Mrs Deepika Pillai (CUST000008) is a government official and wants to
> discuss long-term wealth planning. Pull up her full advisory briefing
> including compliance and portfolio status."

**What to look for:**
- PEP flag = TRUE, Category B (government official)
- CDD returns REFER_TO_EDD automatically
- Prior EDD case (EDD00000002) — CLOSED_CLEARED with annual re-screening scheduled
- KYC tier = ENHANCED
- Balanced portfolio — tech + small cap concentration
- Risk score HIGH (~72)
- Recommended action: ENHANCED_MONITORING (PEP cleared but annual screening due)

---

### Scenario 4 — UHNI, Re-KYC Overdue, Complex Structure
**Client:** Suresh Chandran Varma (CUST000009) | **RM:** RM005
**Expected pipeline:** FULL_BRIEFING including EDD
**Expected outcome:** VERY_HIGH risk, multiple critical flags

**RM Query:**
> "Mr Suresh Varma (CUST000009) is here. He's a UHNI client with a complex
> holding structure. I need his full briefing — especially compliance,
> re-KYC status, and portfolio performance."

**What to look for:**
- Re-KYC overdue since September 2023
- Passport EXPIRED
- Open EDD case (EDD00000003) — 3 offshore entities unverified
- Adverse media mention (2017 regulatory probe)
- UHNI portfolio: ₹42 crore+ AUM, heavy Reliance concentration (68.81%)
- Risk score VERY_HIGH (~100)
- Recommended action: COMPLIANCE_ESCALATION, possible RELATIONSHIP_EXIT review

---

### Scenario 5 — Portfolio-Only Query, HNI
**Client:** Priya Suresh Iyer (CUST000002) | **RM:** RM001
**Expected pipeline:** PORTFOLIO_ONLY
**Expected outcome:** Focused portfolio report, no compliance flags

**RM Query:**
> "Can you quickly tell me how Priya Iyer's (CUST000002) portfolio is
> performing against the benchmark? Just the portfolio summary please."

**What to look for:**
- Guardrail identifies this as PORTFOLIO_ONLY scope
- Balanced portfolio vs CRISIL Composite benchmark
- Alpha and Sharpe ratio reported
- Minimal compliance section (LOW risk client)
- Faster output — not a full pipeline run

---

### Scenario 8 — New Client Onboarding, Retail
**Client:** Anita Vijay Nair (CUST000004) | **RM:** RM002
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** LOW risk, standard onboarding brief, CONSERVATIVE profile

**RM Query:**
> "Anita Nair (CUST000004) is a new customer who just came in. She's a
> salaried professional interested in starting her wealth management journey.
> Can I get her full onboarding briefing?"

**What to look for:**
- Standard KYC via e-KYC / Aadhaar OTP — VERIFIED
- RETAIL segment, NOVICE experience, CONSERVATIVE risk appetite
- Low AUM (₹1.25L savings account)
- Personal loan with 15 DPD — flag for RM awareness
- Credit card near-maxed — payment stress
- Goal: TAX_SAVING, SHORT horizon
- Risk score LOW (~12)

---

### Scenario 9 — RM-Initiated Income Concern
**Client:** Mohammed Farhan Sheikh (CUST000005) | **RM:** RM003
**Expected pipeline:** INCOME_ONLY
**Expected outcome:** Income discrepancy flagged, cash advance surfaced

**RM Query:**
> "I have a concern about Farhan Sheikh (CUST000005). His lifestyle seems
> inconsistent with what he's declared as income. Can you run an income
> validation check and tell me if there are any discrepancies?"

**What to look for:**
- Guardrail identifies INCOME_ONLY scope
- Declared income (Business P&L): ₹1.5Cr gross
- Card monthly spend: ₹9.8L → inferred annual minimum: ₹3.5Cr+
- Discrepancy: >130% → FLAGGED
- Direction: UNDER_DECLARED
- Cash advance ₹2L on business card
- Minimum payment on card with ₹8.5L outstanding

---

### Scenario 11 — Suitability Review, Risk Appetite Change
**Client:** Priya Suresh Iyer (CUST000002) | **RM:** RM001
**Expected pipeline:** PORTFOLIO_ONLY (suitability focus)
**Expected outcome:** Portfolio suitability mismatch surfaced, rebalancing discussion triggered

**RM Query:**
> "Mrs Iyer (CUST000002) is asking whether her current portfolio still
> matches her risk appetite. She says she has become more conservative
> recently and is worried her current allocation is too aggressive."

**What to look for:**
- Guardrail identifies this as PORTFOLIO_ONLY with suitability emphasis
- Stated risk appetite in CRM: MODERATE — but client now says CONSERVATIVE
- Portfolio allocation checked against both old and updated appetite
- Any equity-heavy or concentrated positions flagged as mismatched
- Suitability Notes section in briefing highlights specific rebalancing options
- No income validation or EDD run — PORTFOLIO_ONLY scope
- RM next steps should include updating stated risk appetite in CRM

---

### Scenario 12 — Loan Eligibility Check, Top-Up Home Loan
**Client:** Arjun Menon (CUST000001) | **RM:** RM001
**Expected pipeline:** INCOME_ONLY (liability and income focus)
**Expected outcome:** Liability position and income adequacy assessed for loan eligibility

**RM Query:**
> "Mr Menon (CUST000001) wants to know if he can take a top-up home loan.
> Can you pull his liability and income position so I can assess eligibility
> before I refer him to the loans desk?"

**What to look for:**
- Guardrail identifies this as INCOME_ONLY scope (liability + income read)
- Loan Analysis agent: existing home loan outstanding balance and EMI surfaced
- No DPD on existing liabilities — clean repayment record
- Declared income vs total EMI burden — FOIR (Fixed Obligation to Income Ratio) check
- Income consistent with declared salary — no discrepancy flag
- Inferred annual income (spend signals) aligns with declared
- CIBIL score 765 (GOOD) — supports eligibility referral
- RM next steps: refer to loans desk with income and liability summary

---

## 🚫 BLOCKED SCENARIOS

---

### Scenario 6 — Investment Recommendation Request
**Expected outcome:** BLOCKED by guardrail

**RM Query:**
> "Based on Mr Sharma's profile (CUST000003), should I move his money
> into a small-cap fund? Give me an investment recommendation."

**Why blocked:**
This system produces intelligence briefings — it does not replace the RM's
judgment. Product recommendations are outside scope and would create regulatory
liability. The guardrail will redirect the RM to ask for a portfolio analysis
briefing instead.

---

### Scenario 7 — Out-of-Scope Market Query
**Expected outcome:** BLOCKED by guardrail

**RM Query:**
> "What do you think the Nifty will do next quarter?"

**Why blocked:**
Market predictions are outside the platform's scope. The platform analyses
individual client profiles — not market direction.

---

### Scenario 10 — Missing Customer Context
**Expected outcome:** BLOCKED / ASK FOR CLARIFICATION by guardrail

**RM Query:**
> "Run a full report please."

**Why blocked:**
No customer ID or name provided. The guardrail will ask the RM to specify
which client they want the briefing for.

---

### Scenario 13 — Walk-In Customer, No Prior Relationship
**Expected outcome:** BLOCKED / ASK FOR CLARIFICATION by guardrail

**RM Query:**
> "A walk-in customer, Mr Rajesh Iyer, PAN ABCDE1234F, wants to open a
> wealth management account. No customer ID yet. Can you pull his briefing?"

**Why blocked:**
No customer_id exists in CBS for this individual — they have not been onboarded.
The guardrail must not attempt to run the pipeline with a missing or fabricated
customer_id, as doing so would produce empty tables or misleading N/A values.

**What to look for:**
- Platform correctly identifies that no CBS record exists for the given PAN
- No partial or empty briefing is generated
- Guardrail responds with a clear explanation: customer must be onboarded
  through the standard KYC and CBS registration process first
- RM is directed to initiate a new customer onboarding workflow
- Platform does not fabricate a customer_id or proceed with null data

---

### Scenario 14 — Portfolio Return Gap: Diversified but Underperforming
**Client:** Vikram Anand Krishnan (CUST000011) | **RM:** RM002
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** LOW risk, NO compliance flags, portfolio underperformance flagged across all 4 asset classes, equity drift detected, Sharpe < 1.0 highlighted, RM prompted to discuss rebalancing

**RM Query:**
> "Vikram Krishnan (CUST000011) is here for his annual review. He has a balanced
> allocation across equity, bonds, gold, and fixed deposits and seems quite comfortable
> with his portfolio. I want to check whether his returns are actually keeping up with
> what a well-managed diversified portfolio should deliver. Can you run a full briefing?"

**What to look for:**
- Identity resolves cleanly across all six systems — KYC VERIFIED, LOW risk (~20)
- CDD PASS — no PEP, no sanctions, no EDD cases
- Income consistent: declared gross Rs.35L, inferred ~Rs.32.4L (card spend Rs.90K/month × 12 × 3), gap < 30%
- Portfolio: 4 holdings across EQUITY / DEBT / GOLD / CASH (FD), AUM Rs.85L
- Benchmark: BM006 — CRISIL Multi-Asset Balanced Index
- **Underperformance flag**: alpha negative for all 6 consecutive quarters (-1.90 to -3.70)
- **Sharpe < 1.0** for all 6 periods (worst: 0.48 in 2023-Q1)
- **Portfolio drift**: equity at 55% vs 50% target (+5% over-weight)
- Each component underperforms its segment: equity -3.5% p.a. alpha, bond YTM 6.2% vs 7.8%, SGB 5.1% gain vs gold index, FD locked at 6.0% vs market 7.5%+
- RM advised to discuss rebalancing: switch Regular Plan equity fund to Direct, improve bond YTM, renew FD at better rate when it matures
- CIBIL score: 790 (GOOD), 0 DPD, home loan serviced on time

---

### Scenario 15 — Equity-Restricted Employee: NSE Insider Trading Compliance
**Client:** Prateek Anand Mathur (CUST000012) | **RM:** RM003
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** LOW risk, CDD PASS, SEBI PFUTP equity restriction surfaced, INCOME portfolio performing consistently, RM briefed on why equity is excluded

**RM Query:**
> "Prateek Mathur (CUST000012) is in for his annual review. He works at NSE and I know
> there are equity trading restrictions on his account. I want to confirm his compliance
> status is in order, understand what his portfolio is allowed to hold, and check how his
> restricted INCOME portfolio is performing. Full briefing please."

**What to look for:**
- Identity resolves cleanly — KYC VERIFIED, LOW risk (~15), employer: NSE Securities India Ltd
- CDD PASS — no PEP, no sanctions, no EDD trigger
- `client_preferences.excluded_sectors`: "EQUITY - SEBI PFUTP Insider Trading Prevention (NSE Employee)"
- `kyc_master.notes`: references SEBI PFUTP Regulations 2003 and employer pre-clearance
- Portfolio: INCOME strategy — 4 holdings (DEBT 44.8%, GOLD 19.9%, DEBT/Govt Bond 25%, CASH/Short Duration 9.9%)
- **No equity holdings at all** — compliant with NSE employee restrictions
- Benchmark: BM009 — CRISIL Conservative Credit Risk Index
- Performance: slight negative alpha (-0.30 bps) across 6 quarters but Sharpe > 1.35 (stable income)
- Income consistent: declared Rs.18L, inferred Rs.18L (card spend Rs.50K × 12 × 3)
- CIBIL score: 775 (GOOD), 0 DPD, home loan serviced on time

---

### Scenario 16 — Suitability Mismatch: Conservative Client Requests Aggressive Shift
**Client:** Sneha Anand Varma (CUST000013) | **RM:** RM001
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** LOW risk, NO compliance flags, conservative portfolio performing well (positive alpha), suitability mismatch flagged — on-record CONSERVATIVE vs. client's verbal AGGRESSIVE request, formal risk reclassification required before any rebalancing

**RM Query:**
> "Sneha Varma (CUST000013) is here and she's asking me to move her entire portfolio to an
> aggressive growth strategy. She says her conservative portfolio is too slow and she wants
> higher returns. I need to understand her current portfolio performance and risk profile
> before I can respond to her request. Can you run a full briefing?"

**What to look for:**
- Identity resolves cleanly — KYC VERIFIED, LOW risk (~18)
- CDD PASS — no PEP, no sanctions, debt-free profile (no liabilities)
- Risk appetite on record: **CONSERVATIVE** — mismatch with verbal request to shift aggressive
- `interaction_log` note: "EXPLICITLY REQUESTED shift to aggressive growth strategy"
- Portfolio: CONSERVATIVE — 4 holdings (EQUITY 30%, DEBT 40%, GOLD 15%, CASH/FD 15%), AUM Rs.1.2Cr
- Benchmark: BM010 — CRISIL Hybrid 85+15 Conservative Index
- **Healthy performance**: positive alpha (+0.10 to +0.30) for all 6 quarters, Sharpe > 1.40
- Platform should flag: current portfolio well-suited to CONSERVATIVE profile — upgrade to AGGRESSIVE requires formal suitability re-assessment
- Income consistent: declared Rs.28L, inferred Rs.28.1L (card spend Rs.78K × 12 × 3)
- CIBIL score: 800 (EXCELLENT), 0 DPD, debt-free

---

### Scenario 17 — Post-Loss Conservative Shift: Aggressive Portfolio with FY2022-23 Crash
**Client:** Rohit Suresh Kapoor (CUST000014) | **RM:** RM004
**Expected pipeline:** FULL_BRIEFING
**Expected outcome:** MEDIUM risk, CDD PASS, FY2022-23 losses prominently surfaced in portfolio analysis, client's conservative shift request flagged, formal reclassification required before rebalancing

**RM Query:**
> "Rohit Kapoor (CUST000014) is here. He had a very rough time in 2022-23 — I recall he
> took heavy losses on his aggressive mid and small-cap positions. He's now asking to shift
> to a conservative strategy. I need the full picture on what happened to his portfolio,
> his current risk profile, and what the process is for rebalancing. Please run a full briefing."

**What to look for:**
- Identity resolves cleanly — KYC VERIFIED, MEDIUM risk (~55)
- CDD PASS — no PEP, no sanctions; risk score elevated (55) due to concentrated equity exposure
- Risk appetite on record: **AGGRESSIVE** — mismatch with formal request to shift conservative
- `interaction_log` note: "FORMALLY REQUESTED shift to conservative" + FY22-23 loss context
- Portfolio: GROWTH — 4 holdings (EQUITY 95%, CASH/Liquid 5%), AUM Rs.2.5Cr
- Benchmark: BM011 — Nifty Midcap 150 TRI
- **FY2022-23 crash**: Dec-2022: **-18.30%** (alpha -2.70), Mar-2023: **-14.50%** (alpha -3.30)
- Recovery quarters: Jun-2023 +8.4%, Sep-2023 +7.2%, Dec-2023 +6.8% — partial but incomplete
- Sharpe ratio: -1.85 (Dec-22), -1.62 (Mar-23) — extreme negative during crash
- Platform should flag: risk reclassification must precede any rebalancing; behavioural risk elevated
- Income consistent: declared Rs.50L, inferred Rs.50.4L (card spend Rs.1.4L × 12 × 3)
- CIBIL score: 745 (GOOD), 0 DPD — portfolio losses did not affect credit conduct

---

## Quick Reference — Expected Risk Outcomes

| Customer | Name | Risk Score | Risk Tier | EDD | Key Flag |
|---|---|---|---|---|---|
| CUST000001 | Arjun Menon | ~22 | LOW | No | Clean profile |
| CUST000002 | Priya Iyer | ~18 | LOW | No | Standard HNI |
| CUST000003 | Rajesh Sharma | ~55 | MEDIUM | No | UHNI, large transactions |
| CUST000004 | Anita Nair | ~12 | LOW | No | New client, DPD on loan |
| CUST000005 | Farhan Sheikh | ~78 | HIGH | Yes | Cash deposits, EDD open |
| CUST000006 | Sunita Agarwal | ~48 | MEDIUM | No | Re-KYC overdue |
| CUST000007 | Kiran Balachandran | ~15 | LOW | No | Retail, standard |
| CUST000008 | Deepika Pillai | ~72 | HIGH | Yes | PEP Cat-B |
| CUST000009 | Suresh Varma | ~100 | VERY_HIGH | Yes | Re-KYC overdue, offshore EDD |
| CUST000010 | Lakshmi Patel | ~10 | LOW | No | New retail, near-maxed card |
| CUST000011 | Vikram Krishnan | ~20 | LOW | No | Diversified but underperforming, equity drift |
| CUST000012 | Prateek Mathur | ~15 | LOW | No | NSE employee, SEBI PFUTP equity restriction |
| CUST000013 | Sneha Varma | ~18 | LOW | No | Conservative portfolio, client requests aggressive shift |
| CUST000014 | Rohit Kapoor | ~55 | MEDIUM | No | Aggressive portfolio, FY2022-23 heavy losses |
