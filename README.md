# Wealth Management Advisory Intelligence Platform
### Agentic AI System — Google ADK + PostgreSQL
#### IIM Indore & IIT Indore | M.S. Data Science and Management

---

## What This Does

A wealth manager opens this application before or during a client meeting.
They type a natural language query about their client — the system validates
the query, runs a multi-agent intelligence pipeline across six banking databases,
and delivers a structured advisory briefing the RM uses to guide the conversation.

**The system never makes investment recommendations.**
It produces client intelligence — the RM makes the decisions.

---

## Architecture

```
RM Query
   │
   ▼
┌─────────────────────┐
│   Guardrail Agent   │ ← Validates scope, blocks out-of-scope queries
└─────────┬───────────┘
          │ APPROVED
          ▼
┌─────────────────────┐
│  Orchestrator Agent │ ← Coordinates the full pipeline
└─────────┬───────────┘
          │
    ┌─────┴──────────────────────────────────┐
    │                                        │
    ▼                                        │
┌──────────────┐   Layer 2                  │
│ Client 360   │ ← Identity resolution       │
│    Agent     │   across all 6 databases    │
└──────┬───────┘                             │
       │                                     │
    ┌──┴──────────────────────┐             │
    │         Layer 3         │             │
    ├─────────────────────────┤             │
    │ CDD Agent               │             │
    │ EDD Agent (conditional) │             │
    │ Income Validation Agent │             │
    └──────────┬──────────────┘             │
               │                            │
    ┌──────────┴──────────────┐             │
    │         Layer 4         │             │
    ├─────────────────────────┤             │
    │ Portfolio Analysis Agent│             │
    │ Risk Assessment Agent   │             │
    └──────────┬──────────────┘             │
               │                            │
    ┌──────────┴──────────────┐             │
    │         Layer 5         │             │
    │ Report Generation Agent │             │
    └──────────┬──────────────┘             │
               │                            │
               ▼                            │
        Advisory Briefing ◄─────────────────┘
```

### Six Source Databases (PostgreSQL)

| Database | System | Key Tables |
|---|---|---|
| `cbs` | Core Banking System | customer_master, account_master, transaction_history, liability_accounts |
| `crm` | CRM / Relationship | client_profile, interaction_log, client_preferences |
| `kyc` | KYC / Compliance | kyc_master, identity_documents, pep_screening, risk_classification, edd_cases |
| `pms` | Portfolio Management | portfolio_master, holdings, performance_history, benchmark_master |
| `card` | Card & Payments | card_accounts, card_transactions, spend_aggregates, payment_behaviour |
| `dms` | Document Management | document_repository, income_proofs, bank_statements, audit_trail |

---

## Project Structure

```
wealth_platform/
├── main.py                              ← Entry point + guardrail→orchestrator flow
├── requirements.txt
├── .env.example                         ← Copy to .env and fill credentials
├── .gitignore
├── .vscode/
│   └── launch.json                      ← 13 pre-built run configs (10 scenarios)
├── config/
│   └── settings.py                      ← PostgreSQL configs + risk thresholds
├── tools/
│   ├── db_utils.py                      ← psycopg2 connection + query helpers
│   └── agent_tools.py                   ← 15 tool functions (all agents)
├── agents/
│   ├── guardrail/agent.py               ← Gate 1: validates RM queries
│   ├── orchestrator/agent.py            ← Gate 2: coordinates pipeline
│   ├── client_360/agent.py              ← Layer 2: unified client profile
│   ├── cdd/agent.py                     ← Layer 3a: KYC + PEP screening
│   ├── edd/agent.py                     ← Layer 3b: Enhanced due diligence
│   ├── income_validation/agent.py       ← Layer 3c: Income vs spend analysis
│   ├── portfolio_analysis/agent.py      ← Layer 4a: Holdings + performance
│   ├── risk_assessment/agent.py         ← Layer 4b: 360° risk score
│   └── report_generation/agent.py       ← Layer 5: Advisory briefing
└── scenarios/
    └── test_scenarios.md                ← 10 documented test scenarios
```

---

## Setup

### Prerequisites
- Python 3.11 or 3.12
- VS Code with Python extension
- PostgreSQL running with all six databases populated
- Google Gemini API key (free at https://aistudio.google.com)

### Step 1 — Open in VS Code
```bash
# Unzip, then:
code wealth_platform
```

### Step 2 — Create virtual environment
```bash
python -m venv .venv
```
`Ctrl+Shift+P` → "Python: Select Interpreter" → choose `.venv`

### Step 3 — Install dependencies
```bash
pip install -r requirements.txt
```

### Step 4 — Configure environment
```bash
cp .env.example .env
# Open .env and fill in:
# - GOOGLE_API_KEY
# - PostgreSQL host/port/user/password for each of the 6 databases
```

### Step 5 — Run
**VS Code:** Press `F5` → pick a scenario from the dropdown

**Terminal:**
```bash
# List all scenarios
python main.py --list

# Run a specific scenario
python main.py --scenario 2      # High-risk client, EDD open
python main.py --scenario 3      # PEP case
python main.py --scenario 6      # Watch the guardrail block this one

# Specific customer
python main.py --customer CUST000005

# Interactive mode (type queries as an RM would)
python main.py
```

---

## Test Scenarios at a Glance

| # | Client | Type | Expected |
|---|---|---|---|
| 1 | Arjun Menon (CUST000001) | Annual review, clean HNI | ✅ FULL_BRIEFING, LOW risk |
| 2 | Farhan Sheikh (CUST000005) | High-risk, EDD open | ✅ FULL_BRIEFING + EDD, HIGH risk |
| 3 | Deepika Pillai (CUST000008) | PEP Cat-B, govt official | ✅ FULL_BRIEFING + EDD, HIGH risk |
| 4 | Suresh Varma (CUST000009) | UHNI, re-KYC overdue | ✅ FULL_BRIEFING + EDD, VERY_HIGH |
| 5 | Priya Iyer (CUST000002) | Portfolio check only | ✅ PORTFOLIO_ONLY |
| 6 | Rajesh Sharma (CUST000003) | "Give me a recommendation" | 🚫 BLOCKED |
| 7 | *(none)* | "What will Nifty do?" | 🚫 BLOCKED |
| 8 | Anita Nair (CUST000004) | New client onboarding | ✅ FULL_BRIEFING, LOW risk |
| 9 | Farhan Sheikh (CUST000005) | Income concern raised by RM | ✅ INCOME_ONLY |
| 10 | *(none)* | "Run a full report" | 🚫 BLOCKED (no customer) |

---

## Key Design Decisions

**Guardrail first** — Every query passes through the guardrail agent before any database is touched. The guardrail blocks investment recommendations, market predictions, out-of-scope queries, and missing-context requests. A programmatic pre-check runs before the LLM to catch obvious violations instantly.

**Conditional EDD** — The EDD agent only activates when the CDD agent sets `edd_trigger = true`. This prevents unnecessary processing for low-risk clients.

**Identity resolution as foundation** — The Client 360 agent always runs first. The identity map it produces (linking all six PostgreSQL databases on `customer_id`) is passed to every downstream agent.

**Human-in-the-loop** — The report generation agent explicitly labels all output as "for RM use only" and never makes a product recommendation. The RM retains all advisory judgment.

**PostgreSQL throughout** — All six source databases are PostgreSQL. `psycopg2` with `RealDictCursor` ensures rows are returned as dicts. All queries use `%s` placeholders (PostgreSQL style, not `?`).

---

*IIM Indore & IIT Indore | M.S. Data Science and Management | Final Trimester Project*
