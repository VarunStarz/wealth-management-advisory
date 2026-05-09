# Session Memory — 09 May 2025
## FastAPI Backend + React UI Integration

---

## 1. What Was Built

### `api_server.py` (FastAPI backend)
Located at: `wealth_platform/api_server.py`

**Endpoints:**
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Server health check → `{"status": "ok"}` |
| GET | `/api/scenarios` | Returns all 17 test scenarios (id, label, rm_id, query, blocked) |
| POST | `/api/query` | Runs free-form RM query through full pipeline |
| POST | `/api/scenario/{n}` | Runs numbered test scenario (1–17) directly |

**Key details:**
- Uses `FastAPI` + `uvicorn` (both already installed in `.venv`)
- CORS configured for `http://localhost:5173` (Vite dev server)
- Imports `process_rm_query` and `SCENARIOS` from `main.py`
- Input validation via Pydantic `field_validator`
- Swagger UI auto-generated at `http://localhost:8000/docs`
- Run: `.venv\Scripts\python api_server.py`
- Optional args: `--host`, `--port` (default: 127.0.0.1:8000)

---

### `ui/src/App.jsx` (React frontend)
Located at: `wealth_platform/ui/src/App.jsx`

**States:**
- `briefing` — the parsed JSON response from the API (null = show query panel)
- `loading` — pipeline running (show LoadingView)
- `error` — connection/server error (show ErrorView)

**Views:**
1. **QueryPanel** — tabbed form with "Free Query" and "Test Scenarios" tabs
   - Scenarios tab fetches `/api/scenarios` on mount via `useEffect`
   - Selecting a scenario pre-fills `query` and `rm_id`
   - Silently fails if backend not running (tab still usable manually)
2. **LoadingView** — spinner + 6-step pipeline progress list
3. **BlockedView** — shown for BLOCKED queries and SANCTIONS_HIT compliance blocks
4. **ErrorView** — shown on fetch failure with hint to start `api_server.py`
5. **Full briefing layout** — NavBar + all 9 components + "New Query" button

**API call:**
- POST to `http://localhost:8000/api/query` with `{ query, rm_id }`
- 6-minute AbortController timeout
- Handles: normal briefing, blocked string, compliance_block JSON, HTTP errors

---

## 2. UI Component Map

All 9 components in `ui/src/components/` are complete and unchanged:

| Component | Prop | Data source |
|-----------|------|-------------|
| `NavBar` | `header` | `briefing_header` |
| `BriefingHeader` | `data` | `briefing_header` |
| `ExecutiveSummary` | `summary` | `executive_summary` |
| `ClientSnapshot` | `data` | `client_snapshot` |
| `RiskPanel` | `data` | `compliance_and_due_diligence` |
| `ComplianceSection` | `data` | `compliance_and_due_diligence` |
| `IncomeValidation` | `data` | `income_validation` |
| `PortfolioSummary` | `data` | `portfolio_summary` |
| `NextSteps` | `steps` | `next_steps` |

Disclaimer rendered as a plain `<p>` at the bottom from `briefing.disclaimer`.

---

## 3. Response Handling Logic

The pipeline (`process_rm_query`) returns a string. The API parses it:
- Valid JSON briefing → returned as-is to frontend
- BLOCKED string → `{ error: True, message: "BLOCKED: ..." }`
- SANCTIONS_HIT → `{ compliance_block: True, status: "...", message: "...", action: "..." }`

Frontend routing:
```
briefing.error            → BlockedView (amber badge "QUERY BLOCKED")
briefing.compliance_block → BlockedView (red badge "COMPLIANCE BLOCK")
!briefing.briefing_header → BlockedView (fallback)
briefing.briefing_header  → Full briefing layout
```

---

## 4. Tech Stack

| Layer | Stack |
|-------|-------|
| Backend agents | Google ADK (multi-agent, async) |
| API server | FastAPI + uvicorn |
| Frontend | React 18 + Vite 4.5.5 |
| Styling | Tailwind CSS (CDN in index.html) |
| Font | Inter (Google Fonts) |
| Node version | v16.17.0 (Vite 5 requires Node 18+ — use Vite 4.x) |

---

## 5. How to Run

```bash
# Terminal 1 — Backend (from wealth_platform/)
.venv\Scripts\python api_server.py

# Terminal 2 — Frontend (from wealth_platform/ui/)
node_modules\.bin\vite
```

- UI: http://localhost:5173
- API: http://localhost:8000
- Swagger: http://localhost:8000/docs

---

## 6. Git Repository

- Remote: https://github.com/VarunStarz/wealth-management-advisory
- Branch: main
- `.env_bkp` and `.claude/` are gitignored (contain API keys)
- `config/settings.py` is safe to commit (reads from env vars via dotenv)
- `logs/` is gitignored (runtime output)

**Commits in this session:**
1. `ce62c2c` — Initial commit (62 files, full project)
2. `ce5f4b0` — Merge: keep project README over GitHub default
3. `d51f167` — Add FastAPI endpoints and scenario picker UI

---

## 7. Previous Session Work (summarised)

- Scenarios 15, 16, 17 seeded across all 6 PostgreSQL DBs (CBS, CRM, KYC, PMS, CARD, DMS)
- CUST000011 data quality fixes (benchmark, identity docs, DMS links, duplicate spend aggregates)
- Scenario 5 (PORT000002) fixed: rebalanced to 55/25/12/8%, added 5 performance records
- `agent_tools.py` — CIBIL scores added for CUST000012, 000013, 000014
- `main.py` — Scenarios 15–17 added to SCENARIOS dict
- `scenarios/test_scenarios.md` — documentation blocks added for all new scenarios

---

## 8. Key Decisions / Notes

- Vite downgraded from 5.x to 4.5.5 because Node 16 is installed (Vite 5 requires Node 18+)
- `mockBriefing.js` kept in repo but no longer used by App.jsx (real API calls only)
- Pipeline timeout set to 6 minutes in the frontend AbortController
- Scenarios tab silently fails if backend not running — no crash, just shows a message
- `field_validator` used instead of `validator` (Pydantic v2 syntax)
