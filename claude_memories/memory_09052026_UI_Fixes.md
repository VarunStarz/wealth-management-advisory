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

## 7. Nothing Committed This Session
User requested no git operations without explicit approval.

---

## Key Learnings / Gotchas

- **SVG multi-segment stroked arcs** always produce visible gaps at boundaries — use filled donut sectors instead for zone gauges
- **SVG stroke with linearGradient** works in browsers but user found it too plain — donut sectors look more professional
- **benchmark_income() mock data** has all needed entries — the bug was agent prompting, not missing data
- **CRM sub_segment field** = "Promoter/HUF", "Tech", etc. — this is the income role signal
- PMS `portfolio_master` uses `client_id` (CLI000009) not `customer_id` — join via CRM
