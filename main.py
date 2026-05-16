# ============================================================
# main.py
# Entry point — Wealth Management Advisory Intelligence Platform
#
# Flow (scope-driven, parallel where possible):
#
#   FULL_BRIEFING:
#     Guardrail → Client 360
#       → CDD + Income Validation + Portfolio Analysis
#         + Loans + Expenditure + CIBIL Score  (all six, parallel)
#         → EDD (only if CDD triggers)
#           → Risk Assessment → Report Generation
#
#   RISK_ONLY:
#     Guardrail → Client 360
#       → CDD + Income Validation + Portfolio Analysis
#         + Loans + Expenditure + CIBIL Score  (all six, parallel)
#         → EDD (only if CDD triggers)
#           → Risk Assessment → Report Generation
#
#   CDD_ONLY:
#     Guardrail → Client 360 → CDD → EDD (if triggered) → Risk Assessment → Report Generation
#
#   INCOME_ONLY:
#     Guardrail → Client 360 → Income Validation → Risk Assessment → Report Generation
#
#   PORTFOLIO_ONLY:
#     Guardrail → Client 360 → Portfolio Analysis → Risk Assessment → Report Generation
#
#   WEALTH_RECOMMENDATION:
#     Guardrail → Client 360 → CDD → Portfolio Recommendation → Report Generation
#
# Usage:
#   python main.py                       # interactive mode
#   python main.py --customer CUST000005 # specific customer
#   python main.py --scenario 3          # run a test scenario
# ============================================================

import asyncio
import argparse
import json
import logging
import os
import sys
import time
import re
from datetime import datetime

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.path.dirname(__file__))

from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types as genai_types

#from config.settings import GOOGLE_API_KEY
from config.settings import GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION
from agents.guardrail.agent          import guardrail_agent, validate_query
from agents.client_360.agent         import client_360_agent
from agents.cdd.agent                import cdd_agent
from agents.edd.agent                import edd_agent
from agents.income_validation.agent  import income_validation_agent
from agents.portfolio_analysis.agent import portfolio_analysis_agent
from agents.loans.agent              import loans_agent
from agents.expenditure.agent        import expenditure_agent
from agents.cibil.agent              import cibil_agent
from agents.risk_assessment.agent             import risk_assessment_agent
from agents.report_generation.agent           import report_generation_agent
from agents.portfolio_recommendation.agent    import portfolio_recommendation_agent

#os.environ["GOOGLE_API_KEY"] = GOOGLE_API_KEY
os.environ["GOOGLE_GENAI_USE_VERTEXAI"]  = "1"
os.environ["GOOGLE_CLOUD_PROJECT"]       = GOOGLE_CLOUD_PROJECT
os.environ["GOOGLE_CLOUD_LOCATION"]      = GOOGLE_CLOUD_LOCATION

# ── Logging setup ─────────────────────────────────────────────
def _setup_logging() -> None:
    os.makedirs("logs", exist_ok=True)
    fmt = logging.Formatter(
        "%(asctime)s [%(levelname)-8s] [%(name)-28s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    # File handler — DEBUG: full technical detail
    fh = logging.FileHandler(
        os.path.join("logs", f"pipeline_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"),
        encoding="utf-8",
    )
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(fmt)
    # Console handler — WARNING: anomalies and errors only (print() handles info output)
    ch = logging.StreamHandler(sys.stderr)
    ch.setLevel(logging.WARNING)
    ch.setFormatter(fmt)
    root = logging.getLogger()
    root.setLevel(logging.DEBUG)
    root.addHandler(fh)
    root.addHandler(ch)
    # Suppress noisy third-party loggers
    for lib in ("google", "urllib3", "httpx", "httpcore", "grpc", "asyncio"):
        logging.getLogger(lib).setLevel(logging.WARNING)

_setup_logging()

session_service = InMemorySessionService()
APP_NAME = "wealth_advisory_platform"
logger   = logging.getLogger(__name__)


# ── Core runner ───────────────────────────────────────────────
async def _run_agent(agent, user_id: str, session_id: str, prompt: str) -> str:
    """
    Runs a single agent and returns its final text response.
    Tracks last_seen as fallback in case the final event carries no text
    (can happen with tool-calling agents in ADK).
    """
    runner = Runner(
        agent=agent,
        app_name=APP_NAME,
        session_service=session_service,
    )
    message = genai_types.Content(
        role="user",
        parts=[genai_types.Part(text=prompt)]
    )

    final_text = ""
    last_seen  = ""

    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message=message,
    ):
        if event.content and event.content.parts:
            parts_text = "\n".join(
                p.text for p in event.content.parts
                if hasattr(p, "text") and p.text
            ).strip()
            if parts_text:
                last_seen = parts_text

        if event.is_final_response():
            if event.content and event.content.parts:
                final_text = "\n".join(
                    p.text for p in event.content.parts
                    if hasattr(p, "text") and p.text
                ).strip()

    return final_text if final_text else last_seen


async def _run_agent_with_retry(
    agent, user_id: str, session_id: str, prompt: str, max_retries: int = 3
) -> str:
    """Wraps _run_agent with exponential back-off on rate-limit errors."""
    for attempt in range(max_retries):
        try:
            return await _run_agent(agent, user_id, session_id, prompt)
        except Exception as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                wait = 40 * (attempt + 1)
                logger.warning(f"Rate limit hit (attempt {attempt+1}/{max_retries}) — waiting {wait}s")
                print(f"  [WAIT] Rate limit hit. Waiting {wait}s (retry {attempt+1}/{max_retries})...")
                await asyncio.sleep(wait)
            else:
                logger.error(f"Agent execution error: {e}")
                raise
    logger.error("Max retries exceeded due to quota limits")
    raise RuntimeError("Max retries exceeded due to quota limits.")


# ── Helpers ───────────────────────────────────────────────────
def _sid(rm_id: str, step: str) -> str:
    return f"{rm_id}_{step}_{int(time.time() * 1000)}"


def _extract_json(text: str) -> dict:
    raw = text.strip()
    if "```" in raw:
        for part in raw.split("```"):
            candidate = part.strip().lstrip("json").strip()
            try:
                return json.loads(candidate)
            except json.JSONDecodeError:
                continue
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def _extract_customer_id(query: str) -> str:
    match = re.search(r"CUST\d{6}", query, re.IGNORECASE)
    return match.group(0).upper() if match else "UNKNOWN"


def _edd_triggered(cdd_output: str) -> bool:
    return bool(_extract_json(cdd_output).get("edd_trigger", False))


def _sanctions_fail(cdd_output: str) -> bool:
    return _extract_json(cdd_output).get("cdd_status", "") == "FAIL"


# ── Pipeline ──────────────────────────────────────────────────
async def run_pipeline(
    customer_id: str,
    approved_for: str,
    original_query: str,
    rm_id: str,
    guardrail_notes: str = "",
    risk_preference: str = "MEDIUM",
    investable_amount_inr: float = None,
) -> str:
    """
    Runs agents in the correct order for the given scope.
    Parallel where agents are independent; serial where one depends on another.
    """
    t_pipeline = time.time()
    logger.info(f"[{customer_id}] Pipeline starting — scope: {approved_for}, RM: {rm_id}")
    outputs: dict[str, str] = {}

    # ── STEP 1: Client 360 (always, always first) ─────────────
    print("  [Step 1] Client 360 Agent...")
    logger.info(f"[{customer_id}] Step 1 → Client 360 Agent starting")
    t0 = time.time()
    sid = _sid(rm_id, "c360")
    await session_service.create_session(
        app_name=APP_NAME, user_id=rm_id, session_id=sid
    )
    logger.debug(f"[{customer_id}] Client 360 session: {sid}")
    outputs["client_360"] = await _run_agent_with_retry(
        client_360_agent, rm_id, sid,
        f"Customer ID: {customer_id}\n"
        f"Build the complete Client 360 profile for this customer."
    )
    logger.info(f"[{customer_id}] Step 1 ✓ Client 360 done ({time.time()-t0:.1f}s)")
    print("     ✓ Client 360 done")

    # ── STEP 2: Parallel analysis (scope-driven) ───────────────
    run_cdd         = approved_for in ("FULL_BRIEFING", "CDD_ONLY",       "RISK_ONLY", "WEALTH_RECOMMENDATION")
    run_income      = approved_for in ("FULL_BRIEFING", "INCOME_ONLY",    "RISK_ONLY")
    run_portfolio   = approved_for in ("FULL_BRIEFING", "PORTFOLIO_ONLY", "RISK_ONLY")
    run_loans       = approved_for in ("FULL_BRIEFING",                   "RISK_ONLY")
    run_expenditure = approved_for in ("FULL_BRIEFING",                   "RISK_ONLY")
    run_cibil       = approved_for in ("FULL_BRIEFING",                   "RISK_ONLY")

    if run_cdd or run_income or run_portfolio or run_loans or run_expenditure or run_cibil:
        agents_running = []
        if run_cdd:         agents_running.append("CDD")
        if run_income:      agents_running.append("Income Validation")
        if run_portfolio:   agents_running.append("Portfolio Analysis")
        if run_loans:       agents_running.append("Loans")
        if run_expenditure: agents_running.append("Expenditure")
        if run_cibil:       agents_running.append("CIBIL Score")
        print(f"  [Step 2] Running in parallel: {', '.join(agents_running)}...")

    async def _run_cdd():
        sid = _sid(rm_id, "cdd")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            cdd_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Run the CDD check for this customer."
        )

    async def _run_income():
        sid = _sid(rm_id, "inc")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            income_validation_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Validate income for this customer."
        )

    async def _run_portfolio():
        sid = _sid(rm_id, "port")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            portfolio_analysis_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Risk preference tier for this customer: {risk_preference}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Analyse the portfolio for this customer. "
            f"Call fetch_benchmark_returns('{risk_preference}') to get the expected return "
            f"for this risk tier and compare it against actual portfolio performance."
        )

    async def _run_loans():
        sid = _sid(rm_id, "loans")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            loans_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Analyse all loan obligations for this customer."
        )

    async def _run_expenditure():
        sid = _sid(rm_id, "expend")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            expenditure_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Analyse card spend and lifestyle expenditure patterns for this customer."
        )

    async def _run_cibil():
        sid = _sid(rm_id, "cibil")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        return await _run_agent_with_retry(
            cibil_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360 context:\n{outputs['client_360']}\n\n"
            f"Retrieve and interpret the CIBIL score and credit health for this customer."
        )

    # Build and run only the tasks needed for this scope
    tasks     = []
    task_keys = []
    if run_cdd:         tasks.append(_run_cdd());         task_keys.append("cdd")
    if run_income:      tasks.append(_run_income());      task_keys.append("income")
    if run_portfolio:   tasks.append(_run_portfolio());   task_keys.append("portfolio")
    if run_loans:       tasks.append(_run_loans());       task_keys.append("loans")
    if run_expenditure: tasks.append(_run_expenditure()); task_keys.append("expenditure")
    if run_cibil:       tasks.append(_run_cibil());       task_keys.append("cibil")

    if tasks:
        results = await asyncio.gather(*tasks)
        for key, result in zip(task_keys, results):
            outputs[key] = result
        print("     ✓ Parallel step done")

    # ── Sanctions hard stop (after CDD) ───────────────────────
    if "cdd" in outputs and _sanctions_fail(outputs["cdd"]):
        msg = json.dumps({
            "compliance_block": True,
            "status": "SANCTIONS_HIT",
            "message": (
                "This client has a SANCTIONS HIT on their CDD check. "
                "The advisory relationship CANNOT proceed."
            ),
            "action": "Refer immediately to the Compliance team.",
        }, indent=2, ensure_ascii=False)
        print(f"\n{msg}")
        return msg

    # ── STEP 3: EDD (conditional — only if CDD triggered it) ──
    if "cdd" in outputs and _edd_triggered(outputs["cdd"]):
        print("  [Step 3] EDD Agent (triggered by CDD)...")
        sid = _sid(rm_id, "edd")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        outputs["edd"] = await _run_agent_with_retry(
            edd_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"CDD findings:\n{outputs['cdd']}\n\n"
            f"Run the EDD assessment for this customer."
        )
        print("     ✓ EDD done")
    else:
        if "cdd" in outputs:
            print("  [Step 3] EDD — skipped (not triggered by CDD)")
        outputs["edd"] = "EDD not triggered — client cleared CDD."

    # ── STEP 3b: Portfolio Recommendation (WEALTH_RECOMMENDATION only) ──
    if approved_for == "WEALTH_RECOMMENDATION":
        print("  [Step 3b] Portfolio Recommendation Agent...")
        sid = _sid(rm_id, "rec")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        amt_str = f"Rs.{int(investable_amount_inr):,}" if investable_amount_inr else "not specified"
        outputs["portfolio_recommendation"] = await _run_agent_with_retry(
            portfolio_recommendation_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Investable amount: {amt_str}\n"
            f"Investment risk preference tier: {risk_preference}\n"
            f"Client 360 context:\n{outputs.get('client_360', '')}\n\n"
            f"CDD findings:\n{outputs.get('cdd', '')}\n\n"
            f"Generate the portfolio recommendation for this customer."
        )
        print("     ✓ Portfolio Recommendation done")

    # ── STEP 4: Risk Assessment (skipped for WEALTH_RECOMMENDATION) ──
    run_risk = approved_for != "WEALTH_RECOMMENDATION"
    if run_risk:
        print("  [Step 4] Risk Assessment Agent...")
        sid = _sid(rm_id, "risk")
        await session_service.create_session(
            app_name=APP_NAME, user_id=rm_id, session_id=sid
        )
        outputs["risk"] = await _run_agent_with_retry(
            risk_assessment_agent, rm_id, sid,
            f"Customer ID: {customer_id}\n"
            f"Client 360:\n{outputs.get('client_360', '')}\n\n"
            f"CDD:\n{outputs.get('cdd', 'Not run')}\n\n"
            f"EDD:\n{outputs.get('edd', 'Not run')}\n\n"
            f"Income Validation:\n{outputs.get('income', 'Not run')}\n\n"
            f"Portfolio:\n{outputs.get('portfolio', 'Not run')}\n\n"
            f"Loans:\n{outputs.get('loans', 'Not run')}\n\n"
            f"Expenditure:\n{outputs.get('expenditure', 'Not run')}\n\n"
            f"CIBIL Score:\n{outputs.get('cibil', 'Not run')}\n\n"
            f"Compute the composite 360 risk score and red flag list."
        )
        print("     ✓ Risk Assessment done")

    # ── STEP 5: Report Generation (always last) ────────────────
    print("  [Step 5] Generating advisory briefing...")
    sid = _sid(rm_id, "report")
    await session_service.create_session(
        app_name=APP_NAME, user_id=rm_id, session_id=sid
    )
    briefing = await _run_agent_with_retry(
        report_generation_agent, rm_id, sid,
        f"Original RM query: {original_query}\n"
        f"Pipeline scope: {approved_for}\n"
        f"Customer risk preference: {risk_preference}\n\n"
        f"=== CLIENT 360 ===\n{outputs.get('client_360', '')}\n\n"
        f"=== CDD ===\n{outputs.get('cdd', 'Not run for this scope')}\n\n"
        f"=== EDD ===\n{outputs.get('edd', 'Not run for this scope')}\n\n"
        f"=== INCOME VALIDATION ===\n{outputs.get('income', 'Not run for this scope')}\n\n"
        f"=== PORTFOLIO ANALYSIS ===\n{outputs.get('portfolio', 'Not run for this scope')}\n\n"
        f"=== LOANS ANALYSIS ===\n{outputs.get('loans', 'Not run for this scope')}\n\n"
        f"=== EXPENDITURE ANALYSIS ===\n{outputs.get('expenditure', 'Not run for this scope')}\n\n"
        f"=== CIBIL SCORE ===\n{outputs.get('cibil', 'Not run for this scope')}\n\n"
        f"=== RISK ASSESSMENT ===\n{outputs.get('risk', 'Not run for this scope')}\n\n"
        f"=== PORTFOLIO RECOMMENDATION ===\n{outputs.get('portfolio_recommendation', 'Not run for this scope')}\n\n"
        f"Using all of the above, produce the complete structured advisory briefing."
    )
    print("     ✓ Briefing ready\n")
    if not briefing or not briefing.strip():
        return json.dumps({
            "pipeline_error": True,
            "message": "Report generation agent returned an empty response. Please retry the query."
        })
    # Strip markdown code fences if the LLM wrapped the JSON (e.g. ```json ... ```)
    parsed = _extract_json(briefing)
    if parsed:
        return json.dumps(parsed, ensure_ascii=False)
    return briefing


# ── Query handler ─────────────────────────────────────────────
async def process_rm_query(query: str, rm_id: str = "RM_USER", risk_preference: str = "MEDIUM") -> str:
    print(f"\n{'='*68}")
    print(f"  WEALTH ADVISORY INTELLIGENCE PLATFORM")
    print(f"  RM: {rm_id}")
    print(f"{'='*68}")
    print(f"\nQuery: {query}\n")

    # Programmatic pre-check
    pre_check = validate_query(query)
    if not pre_check["passed"]:
        print(f"[BLOCKED] GUARDRAIL (pre-check): {pre_check['reason']}")
        return pre_check["reason"]

    # Guardrail Agent
    print("Running guardrail check...")
    sid = _sid(rm_id, "guardrail")
    await session_service.create_session(
        app_name=APP_NAME, user_id=rm_id, session_id=sid
    )
    guardrail_response = await _run_agent_with_retry(
        guardrail_agent, rm_id, sid, query
    )

    guardrail_result = _extract_json(guardrail_response)
    if not guardrail_result:
        print("[BLOCKED] GUARDRAIL (parse failure): agent returned non-JSON response.")
        return (
            "BLOCKED: The guardrail agent returned an unreadable response. "
            "Please rephrase your query and try again."
        )

    if guardrail_result.get("guardrail_status") == "BLOCKED":
        reason = guardrail_result.get("block_reason", "Query not permitted.")
        alt    = guardrail_result.get("suggested_alternative", "")
        print(f"\n[BLOCKED] GUARDRAIL")
        print(f"   Reason: {reason}")
        if alt:
            print(f"   Suggestion: {alt}")
        return f"BLOCKED: {reason}" + (f"\n\nSuggested: {alt}" if alt else "")

    customer_id           = guardrail_result.get("customer_id", _extract_customer_id(query))
    approved_for          = guardrail_result.get("approved_for", "FULL_BRIEFING")
    notes                 = guardrail_result.get("notes", "")
    investable_amount_inr = guardrail_result.get("investable_amount_inr")

    print(f"Guardrail APPROVED")
    print(f"   Customer : {customer_id}")
    print(f"   Intent   : {guardrail_result.get('query_intent', query[:80])}")
    print(f"   Pipeline : {approved_for}")
    if notes:
        print(f"   Notes    : {notes}")
    print(f"\nRunning pipeline...\n")

    briefing = await run_pipeline(
        customer_id=customer_id,
        approved_for=approved_for,
        original_query=query,
        rm_id=rm_id,
        guardrail_notes=notes,
        risk_preference=risk_preference,
        investable_amount_inr=investable_amount_inr,
    )

    try:
        _parsed = json.loads(briefing)
        if not _parsed.get("compliance_block"):
            print(json.dumps(_parsed, indent=2, ensure_ascii=False))
    except (json.JSONDecodeError, AttributeError):
        print(briefing)
    return briefing


# ── Test scenarios ────────────────────────────────────────────
SCENARIOS = {
    1:  {"label": "Full briefing — standard HNI (clean profile)",        "rm_id": "RM001", "query": "Mr Arjun Menon (CUST000001) is here for his annual wealth review. He wants to know how his portfolio is doing and whether there are any areas we should look at. Can you give me a full briefing before I meet him?"},
    2:  {"label": "High-risk client — cash deposits + EDD open",         "rm_id": "RM003", "query": "Farhan Sheikh (CUST000005) has come in asking about restructuring his wealth. Before I proceed, I need a complete intelligence briefing. What's his current compliance status and risk profile?"},
    3:  {"label": "PEP case — government official",                      "rm_id": "RM004", "query": "Mrs Deepika Pillai (CUST000008) is a government official and wants to discuss long-term wealth planning. Pull up her full advisory briefing including compliance and portfolio status."},
    4:  {"label": "UHNI — re-KYC overdue, complex structure",            "rm_id": "RM005", "query": "Mr Suresh Varma (CUST000009) is here. He's a UHNI client with a complex holding structure. I need his full briefing — especially compliance, re-KYC status, and portfolio performance."},
    5:  {"label": "Portfolio-only query — HNI client",                   "rm_id": "RM001", "query": "Can you quickly tell me how Priya Iyer's (CUST000002) portfolio is performing against the benchmark? Just the portfolio summary please."},
    6:  {"label": "BLOCKED — investment recommendation request",         "rm_id": "RM002", "query": "Based on Mr Sharma's profile (CUST000003), should I move his money into a small-cap fund? Give me an investment recommendation."},
    7:  {"label": "BLOCKED — out of scope query",                        "rm_id": "RM001", "query": "What do you think the Nifty will do next quarter?"},
    8:  {"label": "New client onboarding — retail",                      "rm_id": "RM002", "query": "Anita Nair (CUST000004) is a new customer who just came in. She's a salaried professional interested in starting her wealth management journey. Can I get her full onboarding briefing?"},
    9:  {"label": "Income validation concern — RM-initiated",            "rm_id": "RM003", "query": "I have a concern about Farhan Sheikh (CUST000005). His lifestyle seems inconsistent with what he's declared as income. Can you run an income validation check and tell me if there are any discrepancies?"},
    10: {"label": "BLOCKED — missing customer context",                  "rm_id": "RM001", "query": "Run a full report please."},
    11: {"label": "Suitability review — risk appetite change (CUST000002)", "rm_id": "RM001", "query": "Mrs Iyer (CUST000002) is asking whether her current portfolio still matches her risk appetite. She says she has become more conservative recently and is worried her current allocation is too aggressive."},
    12: {"label": "Loan eligibility check — top-up home loan (CUST000001)", "rm_id": "RM001", "query": "Mr Menon (CUST000001) wants to know if he can take a top-up home loan. Can you pull his liability and income position so I can assess eligibility before I refer him to the loans desk?"},
    13: {"label": "BLOCKED — walk-in customer, no customer ID on file",    "rm_id": "RM001", "query": "A walk-in customer, Mr Rajesh Iyer, PAN ABCDE1234F, wants to open a wealth management account. No customer ID yet. Can you pull his briefing?"},
    14: {
        "label": "Portfolio return gap — diversified but underperforming (CUST000011)",
        "rm_id": "RM002",
        "query": (
            "Vikram Krishnan (CUST000011) is here for his annual review. "
            "He has a balanced allocation across equity, bonds, gold, and fixed deposits "
            "and seems quite comfortable with his portfolio. I want to check whether his "
            "returns are actually keeping up with what a well-managed diversified portfolio "
            "should deliver. Can you run a full briefing?"
        ),
    },
    15: {
        "label": "Equity-restricted employee — NSE insider trading compliance (CUST000012)",
        "rm_id": "RM003",
        "query": (
            "Prateek Mathur (CUST000012) is in for his annual review. He works at NSE and I "
            "know there are equity trading restrictions on his account. I want to confirm his "
            "compliance status is in order, understand what his portfolio is allowed to hold, "
            "and check how his restricted INCOME portfolio is performing. Full briefing please."
        ),
    },
    16: {
        "label": "Suitability mismatch — conservative client requests aggressive shift (CUST000013)",
        "rm_id": "RM001",
        "query": (
            "Sneha Varma (CUST000013) is here and she's asking me to move her entire portfolio "
            "to an aggressive growth strategy. She says her conservative portfolio is too slow "
            "and she wants higher returns. I need to understand her current portfolio performance "
            "and risk profile before I can respond to her request. Can you run a full briefing?"
        ),
    },
    17: {
        "label": "Post-loss conservative shift — aggressive portfolio with FY22-23 crash (CUST000014)",
        "rm_id": "RM004",
        "query": (
            "Rohit Kapoor (CUST000014) is here. He had a very rough time in 2022-23 — I recall "
            "he took heavy losses on his aggressive mid and small-cap positions. He's now asking "
            "to shift to a conservative strategy. I need the full picture on what happened to "
            "his portfolio, his current risk profile, and what the process is for rebalancing. "
            "Please run a full briefing."
        ),
    },
    18: {
        "label": "WEALTH_RECOMMENDATION — portfolio deployment for HNI (CUST000011)",
        "rm_id": "RM002",
        "query": (
            "Vikram Krishnan (CUST000011) has Rs.20,00,000 he wants to deploy. "
            "Based on his risk profile, can you generate a wealth recommendation "
            "for how to invest this amount?"
        ),
    },
}


def print_scenarios():
    print("\nAvailable Test Scenarios:\n")
    for num, s in SCENARIOS.items():
        tag = "BLOCKED" if "BLOCKED" in s["label"] else "APPROVED"
        print(f"  {num:2d}. [{tag}] {s['label']}")
    print()


async def main():
    parser = argparse.ArgumentParser(description="Wealth Management Advisory Intelligence Platform")
    parser.add_argument("--customer", help="Customer ID for a full briefing")
    parser.add_argument("--scenario", type=int, help="Run a numbered test scenario (1-18)")
    parser.add_argument("--list", action="store_true", help="List all test scenarios")
    parser.add_argument("--rm", default="RM_USER", help="RM identifier")
    args = parser.parse_args()

    if args.list:
        print_scenarios()
        return

    if args.scenario:
        s = SCENARIOS.get(args.scenario)
        if not s:
            print(f"Scenario {args.scenario} not found. Use --list to see options.")
            return
        print(f"\nScenario {args.scenario}: {s['label']}")
        await process_rm_query(s["query"], s["rm_id"])
        return

    if args.customer:
        await process_rm_query(
            f"Customer {args.customer} is here for a wealth advisory meeting. "
            f"Please provide a full advisory briefing.",
            args.rm
        )
        return

    print("\n" + "="*68)
    print("  WEALTH ADVISORY INTELLIGENCE PLATFORM — Interactive Mode")
    print("  Type your query as a wealth manager. Type 'quit' to exit.")
    print("  Type 'scenarios' to see test scenarios.")
    print("="*68 + "\n")

    while True:
        try:
            query = input("RM Query > ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye.")
            break
        if not query:
            continue
        if query.lower() in ("quit", "exit", "q"):
            print("Goodbye.")
            break
        if query.lower() == "scenarios":
            print_scenarios()
            continue
        await process_rm_query(query, args.rm)


if __name__ == "__main__":
    asyncio.run(main())