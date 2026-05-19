# Session Memory — 19 May 2026
## Sharpe-Optimised Algorithm, Python Post-Processor, SAFE Universe Fix

---

### What Was Done

#### 1. Sharpe-Optimised Algorithm (Algorithm 2) — `agents/portfolio_recommendation/agent.py`

Added Step 5b to the LLM instruction string (5 total changes to the instruction):

- **Step 5b** — Sharpe-Optimised allocation: `sharpe_i = cagr/max(vol,0.5)` for market funds; `cagr/1.5` for STATIC. Class representative = highest composite-score fund per asset class. `raw_weight = sharpe_class/sum_sharpe × 100`. MEDIUM constraints: EQUITY floor=10%, ceiling=60%. Round to nearest 5%. Produces one option named "Sharpe Maximiser" (`algorithm="SHARPE_OPTIMISED"`).
- **Step 6** — Added `"algorithm": "TEMPLATE_DRIVEN"` label sentence for template options.
- **Step 7b** — 5 option-level metrics: expected_portfolio_return_pct, expected_portfolio_max_drawdown_pct, portfolio_sharpe_approx, projected_corpus_3yr_inr, projected_gain_3yr_inr.
- **Step 8** — Replaced old distinctness check with: pool all options → distinctness check → rank by portfolio_sharpe_approx desc → trim to 4 → renumber 1–4.
- **Output schema** — Extended with 6 new fields per option.

#### 2. SAFE Universe Fix — `tools/agent_tools.py` (line ~1688, `get_fund_universe()`)

**Problem**: SAFE instruments (PPF, NSC, FDs, RBI Bonds) tagged `NO_RISK` in `fund_master`. MEDIUM eligible_tiers = `["LOW","MEDIUM"]` — excluded NO_RISK tier entirely. LLM substituted SGB (GOLD) in SAFE bucket. MEDIUM universe was 14 instruments.

**Fix**:
```python
# OLD:
f"FROM fund_master WHERE risk_tier IN ({placeholders}) AND is_active = TRUE "

# NEW:
f"FROM fund_master WHERE (risk_tier IN ({placeholders}) OR asset_class = 'SAFE') "
f"AND is_active = TRUE "
```
Effect: MEDIUM universe grew 14 → 19 instruments. PPF (FUND003), RBI Bonds (FUND004), NSC (FUND005), SBI FD (FUND006), HDFC FD (FUND007) now included.

#### 3. Python Post-Processor — `main.py` (`_fix_wr_metrics()`)

**Problem**: LLM arithmetic was unreliable — wrong expected returns (off by 0.8–3.47pp), wrong corpus values, ranking not applied.

**Fix**: Added `_fix_wr_metrics(raw: str, investable_amount: float | None) -> str` before `# ── Pipeline ──`. Function:
- Recomputes all 5 metrics deterministically from `suggested_allocation_pct` and `cagr_3yr_pct` per instrument
- `_inr(n)` formatter: Indian notation (groups of 2 from right after last 3 digits), prefixed `Rs.`
- Sorts `data["options"]` by `portfolio_sharpe_approx` descending
- Renumbers option_ids 1–4

Pipeline Step 3b changed:
```python
# OLD:
outputs["portfolio_recommendation"] = await _run_agent_with_retry(...)

# NEW:
_raw_rec = await _run_agent_with_retry(...)
outputs["portfolio_recommendation"] = _fix_wr_metrics(_raw_rec, investable_amount_inr)
```

#### 4. UI — `ui/src/components/RecommendationPanel.jsx`

- Tab text: `"Growth Tilt · 19.9%"` format (old plain name commented above)
- `ReturnSummaryCard` component added — 3-tile grid (Expected Return / Projected Corpus / Net Gain) + footer row (drawdown + algorithm badge: indigo=SHARPE_OPTIMISED, slate=TEMPLATE_DRIVEN)
- `<ReturnSummaryCard opt={activeOpt} />` rendered immediately before allocation bar

#### 5. Report Files Updated

- `Report_Contents/Fund_Recommendation_Algorithm.txt` — full rewrite to describe both algorithms, option-level metrics, SAFE universe fix, post-processor note
- `Report_Contents/Algorithms.txt` — Algorithm 7 updated (SAFE universe note, post-processor note in step 6); Algorithm 21 (Sharpe-Optimised) inserted; summary updated 20 → 21

---

### Verified: Scenario 18 (CUST000011, Rs.20,00,000, MEDIUM) — Second Run

- 19 instruments evaluated (was 14)
- 3 options returned, ranked correctly:
  - Option 1 "Balanced" — Sharpe=1.78, return=19.48%, corpus Rs.34,11,000 ✓
  - Option 2 "Sharpe Maximiser" — Sharpe=1.69, return=21.67%, corpus Rs.36,02,000 ✓
  - Option 3 "Growth Tilt" — Sharpe=1.63, return=21.86%, corpus Rs.36,19,000 ✓
- All SAFE buckets use NSC (FUND005) not SGB ✓
- All metrics manually verified against formula ✓
- Ranking 1.78 > 1.69 > 1.63 confirmed ✓

---

### Key Architecture Decision

LLM determines fund selection and option structure; Python post-processor (`_fix_wr_metrics`) corrects all numbers. Clean separation: qualitative decisions to LLM, deterministic arithmetic to Python.

---

### DEMO_SCENARIOS (unchanged)
`[1, 2, 7, 18, 19, 20, 21, 22]`
