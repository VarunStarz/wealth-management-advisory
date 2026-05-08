# Scenario 14 — Well-Diversified but Suboptimal Returns
### Implementation Plan

**Scenario:** Client has a textbook-diversified portfolio (Equity + Bonds + Gold + FD) but every component is underperforming its segment benchmark. The overall portfolio delivers ~8.1% vs benchmark ~11.3% — 320 bps left on the table annually. Client doesn't know this. RM's job: explain the gap, discuss rebalancing.

Run with: `python main.py --scenario 14`

---

## Client — CUST000011

| Field | Value |
|---|---|
| customer_id | CUST000011 |
| Full name | Vikram Anand Krishnan |
| DOB | 1979-08-14 |
| PAN | KABVK3579N |
| RM | RM002 |
| Segment | HNI |
| Risk appetite | MODERATE |
| KYC | VERIFIED, LOW risk (~20), no PEP |

---

## Portfolio — PORT000011

- **Strategy:** BALANCED
- **AUM:** ₹85,00,000
- **Benchmark:** BM006 — CRISIL Multi-Asset Balanced Index (50% Nifty 50 + 25% CRISIL Bond + 15% Gold + 10% Liquid)
- **Target weights:** 50% EQ / 25% DEBT / 15% GOLD / 10% FD
- **Actual weights:** 55% EQ / 22% DEBT / 15% GOLD / 8% FD ← **drift detected**

### Holdings

| # | Instrument | Class | Weight | Market Value | Why Suboptimal |
|---|---|---|---|---|---|
| 1 | HDFC Flexi Cap Fund – Regular Growth | EQUITY | 55% | ₹46,75,000 | Equity alpha -3.5% p.a. vs Nifty |
| 2 | ICICI Pru Corporate Bond Fund | DEBT | 22% | ₹18,70,000 | YTM 6.2% vs comparable 7.8% |
| 3 | SGB 2021-22 Series IV | GOLD | 15% | ₹12,75,000 | Bought ₹5,850/g, now ₹6,150/g — only 5.1% gain |
| 4 | SBI Fixed Deposit (6.0% p.a.) | FIXED_DEPOSIT | 8% | ₹6,80,000 | Locked 6% vs market FD rate 7.5%+ |

### Performance History (6 quarters — all negative alpha, all Sharpe < 1.0)

| Period | Portfolio Return | Benchmark | Alpha | Sharpe |
|---|---|---|---|---|
| 2024-Q1 | 2.10% | 5.80% | **-3.70** | 0.68 |
| 2023-Q4 | 1.85% | 4.20% | **-2.35** | 0.72 |
| 2023-Q3 | 3.20% | 6.10% | **-2.90** | 0.75 |
| 2023-Q2 | 4.50% | 7.20% | **-2.70** | 0.81 |
| 2023-Q1 | -1.20% | 1.40% | **-2.60** | 0.48 |
| 2022-Q4 | 1.60% | 3.50% | **-1.90** | 0.65 |

---

## Flags the Platform Should Raise

- `underperforming: true` — alpha < 0 for all 6 consecutive periods
- `Sharpe ratio < 1.0` — risk-adjusted return concern (max 0.81)
- `portfolio_drift` — equity allocation 55% vs 50% target (+5% drift)
- No suitability mismatch (MODERATE appetite, BALANCED strategy — aligned)
- No compliance flags (LOW risk, VERIFIED KYC, no PEP, no EDD)

---

## Files to Modify

| File | What |
|---|---|
| `tools/agent_tools.py` | Add CUST000011 to `get_cibil_score` mock (score: 790, GOOD) |
| `scenarios/test_scenarios.md` | Add Scenario 14 documentation block |
| `main.py` | Add entry `14: {...}` to `SCENARIOS` dict |
| PostgreSQL (all 6 DBs) | Insert seed rows — see memory file for exact values |

---

## RM Query

> "Vikram Krishnan (CUST000011) is here for his annual review. He has a balanced allocation across equity, bonds, gold, and fixed deposits and seems quite comfortable with his portfolio. I want to check whether his returns are actually keeping up with what a well-managed diversified portfolio should deliver. Can you run a full briefing?"

**Expected:** FULL_BRIEFING — LOW risk, clean compliance, portfolio underperformance surfaced, drift flagged, Sharpe concern raised, RM prompted to discuss rebalancing.
