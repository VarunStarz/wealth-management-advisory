# ============================================================
# tools/agent_tools.py
# All ADK tool functions — PostgreSQL edition (%s placeholders)
# Organised by the agent layer that consumes each tool.
# ============================================================

import json
import logging
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from tools.db_utils import query_db, query_one, to_json
from config.settings import RISK_THRESHOLDS

logger = logging.getLogger(__name__)


# ============================================================
# LAYER 2 — CLIENT 360 AGENT
# ============================================================

def get_identity_resolution_map(customer_id: str) -> str:
    """
    Resolves the customer's golden record across all six source systems.

    Resolution strategy per system:
      1. PAN number  — primary cross-system identifier (confidence: EXACT)
      2. customer_id — legacy fallback if PAN lookup fails  (confidence: LOW)

    PMS is always resolved via CRM's client_id, which is the correct
    inter-system link (PMS never stores customer_id directly).

    Returns a resolution_log showing which key matched each system so
    downstream agents and the RM know how the profile was assembled.

    Args:
        customer_id: CBS master customer identifier (e.g. CUST000001)

    Returns:
        JSON string with cross-system identity map and resolution_log
    """
    logger.debug("→ entering get_identity_resolution_map(customer_id=%s)", customer_id)

    # ── Step 1: CBS — system of record, always queried by customer_id ──
    cbs = query_one("cbs",
        "SELECT customer_id, party_id, full_name, pan_number, segment_code, "
        "mobile, email, customer_since, status "
        "FROM customer_master WHERE customer_id = %s", (customer_id,))

    if not cbs:
        logger.debug("← returning from get_identity_resolution_map(customer_id=%s) — not found in CBS", customer_id)
        return to_json({"error": f"Customer {customer_id} not found in CBS"})

    pan    = cbs.get("pan_number")
    resolution_log = {"cbs": {"matched_via": "customer_id", "confidence": "EXACT"}}

    def resolve(db, table, select_cols):
        """Try PAN first, fall back to customer_id."""
        if pan:
            row = query_one(db,
                f"SELECT {select_cols} FROM {table} WHERE pan_number = %s", (pan,))
            if row:
                return row, "pan_number", "EXACT"
        row = query_one(db,
            f"SELECT {select_cols} FROM {table} WHERE customer_id = %s", (customer_id,))
        if row:
            return row, "customer_id", "LOW"
        return None, None, "NOT_FOUND"

    # ── Step 2: CRM — resolve via PAN, fallback to customer_id ──
    crm, crm_via, crm_conf = resolve("crm", "client_profile",
        "client_id, rm_id, segment, aum_band, risk_appetite_stated, "
        "last_review_date, next_review_date")
    resolution_log["crm"] = {"matched_via": crm_via, "confidence": crm_conf}

    # ── Step 3: KYC — resolve via PAN, fallback to customer_id ──
    kyc, kyc_via, kyc_conf = resolve("kyc", "kyc_master",
        "kyc_id, kyc_status, kyc_tier, re_kyc_due, notes")
    resolution_log["kyc"] = {"matched_via": kyc_via, "confidence": kyc_conf}

    # ── Step 4: CARD — resolve via PAN, fallback to customer_id ──
    card, card_via, card_conf = resolve("card", "card_accounts", "card_id")
    resolution_log["card"] = {"matched_via": card_via, "confidence": card_conf}

    # ── Step 5: DMS — resolve via PAN, fallback to customer_id ──
    dms_row, dms_via, dms_conf = resolve("dms", "document_repository", "dms_id")
    resolution_log["dms"] = {"matched_via": dms_via, "confidence": dms_conf}

    # ── Step 6: PMS — always via CRM client_id (correct inter-system link) ──
    pms_row = None
    if crm and crm.get("client_id"):
        pms_row = query_one("pms",
            "SELECT portfolio_id FROM portfolio_master WHERE client_id = %s",
            (crm["client_id"],))
        resolution_log["pms"] = {
            "matched_via": "crm.client_id",
            "confidence": "EXACT" if pms_row else "NOT_FOUND",
        }
    else:
        resolution_log["pms"] = {"matched_via": None, "confidence": "NOT_FOUND"}

    result = to_json({
        "customer_id":    customer_id,
        "party_id":       cbs.get("party_id"),
        "full_name":      cbs.get("full_name"),
        "pan_number":     pan,
        "segment":        cbs.get("segment_code"),
        "mobile":         cbs.get("mobile"),
        "email":          cbs.get("email"),
        "customer_since": cbs.get("customer_since"),
        "cbs_status":     cbs.get("status"),
        "crm_client_id":  crm.get("client_id") if crm else None,
        "rm_id":          crm.get("rm_id") if crm else None,
        "aum_band":       crm.get("aum_band") if crm else None,
        "risk_appetite":  crm.get("risk_appetite_stated") if crm else None,
        "kyc_id":         kyc.get("kyc_id") if kyc else None,
        "kyc_status":     kyc.get("kyc_status") if kyc else "NOT_FOUND",
        "kyc_tier":       kyc.get("kyc_tier") if kyc else None,
        "re_kyc_due":     kyc.get("re_kyc_due") if kyc else None,
        "kyc_notes":      kyc.get("notes") if kyc else None,
        "resolution_log": resolution_log,
    })
    logger.debug("← returning from get_identity_resolution_map(customer_id=%s)", customer_id)
    return result


def get_client_core_profile(customer_id: str) -> str:
    """
    Retrieves the complete client profile from CBS and CRM:
    demographics, all accounts, liabilities, and stated investment preferences.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with full client profile
    """
    logger.debug("→ entering get_client_core_profile(customer_id=%s)", customer_id)

    cbs  = query_one("cbs",
        "SELECT * FROM customer_master WHERE customer_id = %s", (customer_id,))
    crm  = query_one("crm",
        "SELECT * FROM client_profile WHERE customer_id = %s", (customer_id,))
    pref = None
    if crm:
        pref = query_one("crm",
            "SELECT * FROM client_preferences WHERE client_id = %s",
            (crm["client_id"],))

    accounts = query_db("cbs",
        "SELECT account_type, currency, current_balance, available_balance, "
        "od_limit, status FROM account_master WHERE customer_id = %s",
        (customer_id,))

    liabilities = query_db("cbs",
        "SELECT liability_type, outstanding_balance, emi_amount, "
        "dpd_days, npa_flag FROM liability_accounts WHERE customer_id = %s",
        (customer_id,))

    result = to_json({
        "demographics":  cbs,
        "crm_profile":   crm,
        "preferences":   pref,
        "accounts":      accounts,
        "liabilities":   liabilities,
    })
    logger.debug("← returning from get_client_core_profile(customer_id=%s)", customer_id)
    return result


def get_transaction_summary(customer_id: str, months: int = 3) -> str:
    """
    Fetches the last N months of transaction history for a customer.
    Used to infer actual income flows and detect unknown-source credits.

    Args:
        customer_id: CBS master customer identifier
        months: Number of months of history to retrieve (default 3)

    Returns:
        JSON string with transaction summary and flagged items
    """
    logger.debug("→ entering get_transaction_summary(customer_id=%s, months=%d)", customer_id, months)

    accounts = query_db("cbs",
        "SELECT account_id FROM account_master WHERE customer_id = %s",
        (customer_id,))

    if not accounts:
        logger.debug("← returning from get_transaction_summary(customer_id=%s) — no accounts", customer_id)
        return to_json({"error": "No accounts found", "customer_id": customer_id})

    account_ids = tuple(a["account_id"] for a in accounts)

    txns = query_db("cbs",
        "SELECT txn_date, txn_type, amount, channel, counterparty_name, narration "
        "FROM transaction_history "
        "WHERE account_id = ANY(%s) "
        "AND txn_date >= CURRENT_DATE - make_interval(months => %s) "
        "ORDER BY txn_date DESC",
        (list(account_ids), months))

    credits = [t for t in txns if t["txn_type"] == "CREDIT"]
    total_credits = sum(float(t["amount"]) for t in credits)
    unknown_credits = [
        t for t in credits
        if "unknown" in (t.get("counterparty_name") or "").lower()
        or "unspecified" in (t.get("narration") or "").lower()
    ]

    result = to_json({
        "account_count":         len(accounts),
        "total_transactions":    len(txns),
        "total_credits_inr":     total_credits,
        "unknown_source_credits": unknown_credits,
        "recent_transactions":   txns[:20],
    })
    logger.debug("← returning from get_transaction_summary(customer_id=%s) — %d txns", customer_id, len(txns))
    return result


# ============================================================
# LAYER 3a — CDD AGENT
# ============================================================

def get_kyc_status(customer_id: str) -> str:
    """
    Retrieves KYC record and identity documents. Flags expired or
    pending-verification documents and re-KYC overdue status.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with KYC master record, documents, and issue summary
    """
    logger.debug("→ entering get_kyc_status(customer_id=%s)", customer_id)

    kyc = query_one("kyc",
        "SELECT * FROM kyc_master WHERE customer_id = %s", (customer_id,))

    if not kyc:
        logger.debug("← returning from get_kyc_status(customer_id=%s) — NOT_FOUND", customer_id)
        return to_json({"kyc_status": "NOT_FOUND", "customer_id": customer_id})

    docs = query_db("kyc",
        "SELECT doc_type, doc_number, expiry_date, doc_status "
        "FROM identity_documents WHERE kyc_id = %s", (kyc["kyc_id"],))

    expired_docs = [d for d in docs if d["doc_status"] == "EXPIRED"]
    pending_docs = [d for d in docs if d["doc_status"] == "PENDING_VERIFICATION"]

    result = to_json({
        "kyc_record":    kyc,
        "documents":     docs,
        "expired_docs":  expired_docs,
        "pending_docs":  pending_docs,
        "issues_found":  len(expired_docs) + len(pending_docs),
    })
    logger.debug(
        "← returning from get_kyc_status(customer_id=%s) — status=%s, issues=%d",
        customer_id, kyc.get("kyc_status"), len(expired_docs) + len(pending_docs)
    )
    return result


def run_pep_sanctions_check(customer_id: str) -> str:
    """
    Retrieves PEP screening and sanctions check results. Returns PEP flag,
    category, adverse media findings, risk tier, and next review date.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with full screening result and risk classification
    """
    logger.debug("→ entering run_pep_sanctions_check(customer_id=%s)", customer_id)

    screens = query_db("kyc",
        "SELECT * FROM pep_screening WHERE customer_id = %s "
        "ORDER BY screen_date DESC LIMIT 3", (customer_id,))

    risk = query_one("kyc",
        "SELECT risk_tier, risk_score, classification_basis, override_flag "
        "FROM risk_classification WHERE customer_id = %s", (customer_id,))

    latest = screens[0] if screens else {}
    pep_flag  = bool(latest.get("pep_flag", False))
    adv_media = latest.get("adverse_media_hit", "None")
    has_adverse = adv_media and adv_media.lower() not in ("none", "", "null")

    result = to_json({
        "customer_id":       customer_id,
        "pep_flag":          pep_flag,
        "pep_category":      latest.get("pep_category", "NONE"),
        "sanctions_hit":     latest.get("sanctions_hit", "None"),
        "adverse_media":     adv_media,
        "has_adverse_media": has_adverse,
        "risk_tier":         risk.get("risk_tier") if risk else "UNKNOWN",
        "risk_score":        risk.get("risk_score") if risk else 0,
        "risk_basis":        risk.get("classification_basis") if risk else None,
        "screening_history": screens,
    })
    logger.debug(
        "← returning from run_pep_sanctions_check(customer_id=%s) — pep=%s, tier=%s",
        customer_id, pep_flag, risk.get("risk_tier") if risk else "UNKNOWN"
    )
    return result


# ============================================================
# LAYER 3b — EDD AGENT
# ============================================================

def get_edd_case_history(customer_id: str) -> str:
    """
    Retrieves all EDD cases — open cases, escalation flags,
    and source-of-wealth verification status.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with EDD case history and current risk status
    """
    logger.debug("→ entering get_edd_case_history(customer_id=%s)", customer_id)

    cases = query_db("kyc",
        "SELECT * FROM edd_cases WHERE customer_id = %s ORDER BY open_date DESC",
        (customer_id,))

    open_cases      = [c for c in cases if c["case_status"] in
                       ("OPEN", "IN_PROGRESS", "PENDING_DOCS")]
    escalated       = [c for c in cases if c.get("escalation_flag")]
    sow_unverified  = [c for c in cases if not c.get("source_of_wealth_verified")
                       and c["case_status"] != "CLOSED_CLEARED"]

    result = to_json({
        "total_edd_cases":   len(cases),
        "open_cases":        open_cases,
        "escalated_cases":   escalated,
        "sow_unverified":    sow_unverified,
        "edd_required":      len(open_cases) > 0,
        "all_cases":         cases,
    })
    logger.debug(
        "← returning from get_edd_case_history(customer_id=%s) — total=%d, open=%d",
        customer_id, len(cases), len(open_cases)
    )
    return result


def get_external_bank_statements(customer_id: str) -> str:
    """
    Retrieves parsed external bank statements submitted during onboarding or EDD.
    Identifies round-figure cash credits and undisclosed account patterns.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with external statement analysis and flagged items
    """
    logger.debug("→ entering get_external_bank_statements(customer_id=%s)", customer_id)

    stmts = query_db("dms",
        "SELECT * FROM bank_statements WHERE customer_id = %s", (customer_id,))

    flagged = [
        s for s in stmts
        if s.get("notes") and any(
            kw in (s["notes"] or "").lower()
            for kw in ["flagged", "suspicious", "round-figure", "cash credits"]
        )
    ]

    result = to_json({
        "statement_count":    len(stmts),
        "flagged_statements": flagged,
        "statements":         stmts,
    })
    logger.debug(
        "← returning from get_external_bank_statements(customer_id=%s) — total=%d, flagged=%d",
        customer_id, len(stmts), len(flagged)
    )
    return result


def get_interaction_red_flags(customer_id: str) -> str:
    """
    Scans RM interaction logs for EDD discussions, low sentiment scores,
    and unresolved follow-up flags indicating relationship concerns.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with flagged interaction records
    """
    logger.debug("→ entering get_interaction_red_flags(customer_id=%s)", customer_id)

    crm = query_one("crm",
        "SELECT client_id FROM client_profile WHERE customer_id = %s",
        (customer_id,))
    if not crm:
        logger.debug("← returning from get_interaction_red_flags(customer_id=%s) — no CRM record", customer_id)
        return to_json({"error": "No CRM record found", "customer_id": customer_id})

    interactions = query_db("crm",
        "SELECT * FROM interaction_log WHERE client_id = %s "
        "ORDER BY interaction_date DESC", (crm["client_id"],))

    edd_logs     = [i for i in interactions if i["type"] == "EDD_DISCUSSION"]
    low_sent     = [i for i in interactions
                    if (i.get("sentiment_score") or 1.0) < 0.70]
    with_followup = [i for i in interactions if i.get("follow_up_flag")]

    result = to_json({
        "edd_discussions":    edd_logs,
        "low_sentiment_logs": low_sent,
        "open_follow_ups":    with_followup,
        "all_interactions":   interactions,
    })
    logger.debug(
        "← returning from get_interaction_red_flags(customer_id=%s) — edd_logs=%d, low_sent=%d",
        customer_id, len(edd_logs), len(low_sent)
    )
    return result


# ============================================================
# LAYER 3c — INCOME VALIDATION AGENT
# ============================================================

def get_declared_income(customer_id: str) -> str:
    """
    Retrieves structured income proof data from DMS — salary slips,
    ITR filings, Form 16, CA certificates, and business P&L.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with income proofs and latest declared annual figures
    """
    logger.debug("→ entering get_declared_income(customer_id=%s)", customer_id)

    proofs = query_db("dms",
        "SELECT * FROM income_proofs WHERE customer_id = %s "
        "ORDER BY filing_date DESC", (customer_id,))

    latest_gross = float(proofs[0]["gross_income"]) if proofs else 0.0
    latest_net   = float(proofs[0]["net_income"]) if proofs else 0.0

    result = to_json({
        "latest_declared_gross_annual": latest_gross,
        "latest_declared_net_annual":   latest_net,
        "proof_count":                  len(proofs),
        "income_proofs":                proofs,
    })
    logger.debug(
        "← returning from get_declared_income(customer_id=%s) — gross=%.0f, proofs=%d",
        customer_id, latest_gross, len(proofs)
    )
    return result


def get_card_spend_analysis(customer_id: str) -> str:
    """
    Analyses credit card spend patterns and payment behaviour to infer
    lifestyle-consistent income. High spend + minimum payments = red flag.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with spend aggregates, payment behaviour, and risk signals
    """
    logger.debug("→ entering get_card_spend_analysis(customer_id=%s)", customer_id)

    cards = query_db("card",
        "SELECT card_id, card_type, credit_limit, current_balance "
        "FROM card_accounts WHERE customer_id = %s", (customer_id,))

    if not cards:
        logger.debug("← returning from get_card_spend_analysis(customer_id=%s) — no card accounts", customer_id)
        return to_json({"error": "No card accounts found", "customer_id": customer_id})

    card_ids = [c["card_id"] for c in cards]

    aggregates = query_db("card",
        "SELECT * FROM spend_aggregates WHERE card_id = ANY(%s)",
        (card_ids,))

    payments = query_db("card",
        "SELECT * FROM payment_behaviour WHERE card_id = ANY(%s) "
        "ORDER BY statement_month DESC", (card_ids,))

    cash_txns = query_db("card",
        "SELECT * FROM card_transactions "
        "WHERE card_id = ANY(%s) AND txn_type = 'CASH_ADVANCE'",
        (card_ids,))

    total_monthly = sum(float(a.get("total_spend", 0)) for a in aggregates)
    min_pay_months = [p for p in payments if p.get("payment_type") == "MINIMUM"]
    dpd_months     = [p for p in payments if p.get("dpd_flag")]
    inferred_min   = total_monthly * 12 * 3  # spend ~33% of income heuristic

    result = to_json({
        "card_count":                 len(cards),
        "total_credit_limit":         sum(float(c["credit_limit"]) for c in cards),
        "total_monthly_spend":        total_monthly,
        "inferred_annual_income_min": inferred_min,
        "cash_advance_count":         len(cash_txns),
        "cash_advance_flag":          len(cash_txns) > 0,
        "minimum_payment_months":     len(min_pay_months),
        "dpd_months":                 len(dpd_months),
        "spend_aggregates":           aggregates,
        "payment_behaviour":          payments,
        "cash_advances":              cash_txns,
    })
    logger.debug(
        "← returning from get_card_spend_analysis(customer_id=%s) — cards=%d, monthly_spend=%.0f, cash_advances=%d",
        customer_id, len(cards), total_monthly, len(cash_txns)
    )
    return result


def benchmark_income(role: str, industry: str, city: str) -> str:
    """
    Returns market compensation benchmark ranges (P25/P50/P75) for a given
    role, industry, and city. In production this calls a compensation API
    (Mercer, Aon, LinkedIn Salary). Currently returns curated mock data.

    Args:
        role: Job title or business type (e.g. 'Director', 'Pharma Distributor')
        industry: Industry sector (e.g. 'Pharmaceuticals', 'Technology')
        city: City of work (e.g. 'Mumbai', 'Hyderabad')

    Returns:
        JSON string with P25, P50, P75 annual income benchmarks in INR
    """
    logger.debug("→ entering benchmark_income(role=%s, industry=%s, city=%s)", role, industry, city)

    mock_data = {
        ("Director",           "Government",         "Kochi"):       (3600000,  5400000,  7200000),
        ("Pharma Distributor", "Pharmaceuticals",    "Hyderabad"):   (4000000,  9000000, 18000000),
        ("Consultant",         "Professional Svcs",  "Mumbai"):      (3000000,  6000000, 12000000),
        ("Tech Professional",  "Technology",         "Chennai"):     (1500000,  2400000,  4000000),
        ("Business Owner",     "Real Estate",        "Mumbai"):      (5000000, 15000000, 40000000),
        ("Promoter",           "Diversified",        "Mumbai"):      (8000000, 25000000, 80000000),
    }
    p25, p50, p75 = mock_data.get((role, industry, city), (1200000, 2400000, 6000000))
    result = to_json({
        "role": role, "industry": industry, "city": city,
        "benchmark_p25_annual_inr": p25,
        "benchmark_p50_annual_inr": p50,
        "benchmark_p75_annual_inr": p75,
        "source": "Compensation Benchmark API (replace with Mercer/Aon in production)",
    })
    logger.debug("← returning from benchmark_income(role=%s, city=%s) — p50=%d", role, city, p50)
    return result


def detect_income_discrepancy(
    customer_id: str,
    declared_annual_gross: float,
    inferred_annual_min: float
) -> str:
    """
    Compares declared income from DMS against spend-inferred income.
    Flags discrepancies beyond the configured threshold.

    Args:
        customer_id: CBS master customer identifier
        declared_annual_gross: Gross annual income from income proofs (INR)
        inferred_annual_min: Minimum annual income inferred from card/transaction data (INR)

    Returns:
        JSON string with discrepancy analysis and flag status
    """
    logger.debug(
        "→ entering detect_income_discrepancy(customer_id=%s, declared=%.0f, inferred=%.0f)",
        customer_id, declared_annual_gross, inferred_annual_min
    )

    if declared_annual_gross <= 0:
        logger.debug("← returning from detect_income_discrepancy(customer_id=%s) — no declared income", customer_id)
        return to_json({"error": "No declared income", "customer_id": customer_id})

    gap_pct   = ((inferred_annual_min - declared_annual_gross) / declared_annual_gross) * 100
    threshold = RISK_THRESHOLDS["income_discrepancy_pct"]
    flagged   = abs(gap_pct) > threshold
    direction = ("OVER_DECLARED" if gap_pct < -threshold
                 else "UNDER_DECLARED" if gap_pct > threshold
                 else "CONSISTENT")

    result = to_json({
        "customer_id":              customer_id,
        "declared_annual_gross":    declared_annual_gross,
        "inferred_annual_minimum":  inferred_annual_min,
        "gap_percentage":           round(gap_pct, 2),
        "threshold_pct":            threshold,
        "discrepancy_flagged":      flagged,
        "direction":                direction,
        "action": ("Escalate to compliance for income source clarification"
                   if flagged else "Income consistent — no action required"),
    })
    logger.debug(
        "← returning from detect_income_discrepancy(customer_id=%s) — gap=%.1f%%, flagged=%s, direction=%s",
        customer_id, gap_pct, flagged, direction
    )
    return result


# ============================================================
# LAYER 4a — PORTFOLIO ANALYSIS AGENT
# ============================================================

def get_portfolio_holdings(customer_id: str) -> str:
    """
    Retrieves current portfolio holdings, calculates asset class allocation,
    and flags single-position concentration above threshold.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with holdings, AUM, allocation, and concentration alerts
    """
    logger.debug("→ entering get_portfolio_holdings(customer_id=%s)", customer_id)

    crm = query_one("crm",
        "SELECT client_id FROM client_profile WHERE customer_id = %s",
        (customer_id,))
    if not crm:
        logger.debug("← returning from get_portfolio_holdings(customer_id=%s) — no CRM record", customer_id)
        return to_json({"error": "No CRM record", "customer_id": customer_id})

    portfolios = query_db("pms",
        "SELECT * FROM portfolio_master WHERE client_id = %s AND status = 'ACTIVE'",
        (crm["client_id"],))

    if not portfolios:
        logger.debug("← returning from get_portfolio_holdings(customer_id=%s) — no active portfolios", customer_id)
        return to_json({"error": "No active portfolios", "customer_id": customer_id})

    result = []
    for port in portfolios:
        holdings = query_db("pms",
            "SELECT * FROM holdings WHERE portfolio_id = %s",
            (port["portfolio_id"],))

        by_class: dict[str, float] = {}
        for h in holdings:
            ac = h["asset_class"]
            by_class[ac] = by_class.get(ac, 0.0) + float(h["market_value"])

        concentrated = [
            h for h in holdings
            if float(h["weight_pct"]) > RISK_THRESHOLDS["portfolio_concentration"]
        ]

        result.append({
            "portfolio_id":      port["portfolio_id"],
            "portfolio_name":    port["portfolio_name"],
            "strategy":          port["strategy_type"],
            "aum":               float(port["aum"]),
            "asset_class_split": by_class,
            "concentrated_bets": concentrated,
            "holdings":          holdings,
        })

    serialised = to_json(result)
    logger.debug(
        "← returning from get_portfolio_holdings(customer_id=%s) — %d portfolio(s)",
        customer_id, len(result)
    )
    return serialised


def get_portfolio_performance(customer_id: str) -> str:
    """
    Retrieves portfolio performance history vs benchmark — alpha, Sharpe,
    tracking error, and max drawdown. Flags underperformance.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with performance metrics and benchmark comparison
    """
    logger.debug("→ entering get_portfolio_performance(customer_id=%s)", customer_id)

    crm = query_one("crm",
        "SELECT client_id FROM client_profile WHERE customer_id = %s",
        (customer_id,))
    if not crm:
        logger.debug("← returning from get_portfolio_performance(customer_id=%s) — no CRM record", customer_id)
        return to_json({"error": "No CRM record", "customer_id": customer_id})

    portfolios = query_db("pms",
        "SELECT portfolio_id, portfolio_name, benchmark_id "
        "FROM portfolio_master WHERE client_id = %s",
        (crm["client_id"],))

    result = []
    for port in portfolios:
        perf = query_db("pms",
            "SELECT * FROM performance_history WHERE portfolio_id = %s "
            "ORDER BY as_of_date DESC LIMIT 6",
            (port["portfolio_id"],))

        bm = query_one("pms",
            "SELECT benchmark_name FROM benchmark_master WHERE benchmark_id = %s",
            (port["benchmark_id"],))

        result.append({
            "portfolio_id":   port["portfolio_id"],
            "portfolio_name": port["portfolio_name"],
            "benchmark":      bm["benchmark_name"] if bm else "Unknown",
            "performance":    perf,
            "underperforming": any(
                float(p.get("alpha", 0)) < 0 for p in perf
            ) if perf else False,
        })

    serialised = to_json(result)
    logger.debug(
        "← returning from get_portfolio_performance(customer_id=%s) — %d portfolio(s)",
        customer_id, len(result)
    )
    return serialised


# ============================================================
# LAYER 3d — LOANS AGENT
# ============================================================

def get_loan_analysis(customer_id: str) -> str:
    """
    Retrieves all active loan obligations from CBS: EMI burden, days-past-due,
    and NPA flags. Provides a dedicated view of the client's liability profile.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with loan details, EMI totals, DPD, and NPA flags
    """
    logger.debug("→ entering get_loan_analysis(customer_id=%s)", customer_id)

    liabilities = query_db("cbs",
        "SELECT liability_type, outstanding_balance, emi_amount, "
        "dpd_days, npa_flag FROM liability_accounts WHERE customer_id = %s",
        (customer_id,))

    if not liabilities:
        logger.debug("← returning from get_loan_analysis(customer_id=%s) — no liabilities", customer_id)
        return to_json({
            "customer_id": customer_id,
            "liability_count": 0,
            "liabilities": [],
            "summary": "No active loan accounts found.",
        })

    total_outstanding = sum(float(l["outstanding_balance"]) for l in liabilities)
    total_emi         = sum(float(l["emi_amount"]) for l in liabilities)
    npa_accounts      = [l for l in liabilities if l.get("npa_flag")]
    dpd_accounts      = [
        l for l in liabilities
        if int(l.get("dpd_days") or 0) > RISK_THRESHOLDS["dpd_threshold_days"]
    ]

    result = to_json({
        "customer_id":            customer_id,
        "liability_count":        len(liabilities),
        "total_outstanding_inr":  total_outstanding,
        "total_monthly_emi_inr":  total_emi,
        "npa_flag":               len(npa_accounts) > 0,
        "dpd_flag":               len(dpd_accounts) > 0,
        "npa_accounts":           npa_accounts,
        "dpd_accounts":           dpd_accounts,
        "liabilities":            liabilities,
    })
    logger.debug(
        "← returning from get_loan_analysis(customer_id=%s) — liabilities=%d, npa=%s, dpd=%s",
        customer_id, len(liabilities), bool(npa_accounts), bool(dpd_accounts)
    )
    return result


# ============================================================
# LAYER 3e — CIBIL SCORE AGENT
# ============================================================

def get_cibil_credit_profile(customer_id: str) -> str:
    """
    Retrieves the client's credit risk score and maps it to a CIBIL-equivalent
    range (300-900). Also surfaces KYC status and re-KYC overdue signals.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with risk score, CIBIL equivalent, tier, and KYC status
    """
    logger.debug("→ entering get_cibil_credit_profile(customer_id=%s)", customer_id)

    risk = query_one("kyc",
        "SELECT risk_tier, risk_score, classification_basis, override_flag "
        "FROM risk_classification WHERE customer_id = %s", (customer_id,))

    kyc = query_one("kyc",
        "SELECT kyc_status, re_kyc_due FROM kyc_master WHERE customer_id = %s",
        (customer_id,))

    liabilities = query_db("cbs",
        "SELECT liability_type, outstanding_balance FROM liability_accounts "
        "WHERE customer_id = %s", (customer_id,))

    risk_score = float(risk["risk_score"]) if risk else 0.0
    # Map risk score (0=clean, 100=very risky) to CIBIL-like scale (900=excellent, 300=poor)
    cibil_equivalent = round(900 - (risk_score / 100) * 600) if risk else None

    result = to_json({
        "customer_id":          customer_id,
        "risk_score":           risk_score,
        "cibil_equivalent":     cibil_equivalent,
        "risk_tier":            risk.get("risk_tier") if risk else "UNKNOWN",
        "classification_basis": risk.get("classification_basis") if risk else None,
        "override_flag":        bool(risk.get("override_flag")) if risk else False,
        "kyc_status":           kyc.get("kyc_status") if kyc else "UNKNOWN",
        "re_kyc_due":           str(kyc.get("re_kyc_due")) if kyc else None,
        "total_liability_count": len(liabilities),
    })
    logger.debug(
        "← returning from get_cibil_credit_profile(customer_id=%s) — score=%.1f, cibil=%s, tier=%s",
        customer_id, risk_score, cibil_equivalent, risk.get("risk_tier") if risk else "UNKNOWN"
    )
    return result


def get_cibil_score(customer_id: str) -> dict:
    """
    Returns the CIBIL credit score and payment behaviour profile for a customer.

    In production, replace this entire mock with a live CIBIL TransUnion API call
    using the customer's PAN number after obtaining written consent. The API returns
    a credit score, DPD history, active loan summary, and enquiry history.

    Args:
        customer_id: CBS master customer identifier (e.g. CUST000001)

    Returns:
        dict with cibil_score, rating, dpd_history, remark, and source
    """
    logger.debug("→ entering get_cibil_score(customer_id=%s)", customer_id)

    mock_scores = {
        "CUST000001": {
            "cibil_score": 765,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments, home loan serviced on time",
            "remark": "Stable HNI consultant. Strong repayment track record.",
        },
        "CUST000002": {
            "cibil_score": 780,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments, no liabilities in stress",
            "remark": "Tech professional with clean credit history.",
        },
        "CUST000003": {
            "cibil_score": 810,
            "rating": "EXCELLENT",
            "dpd_history": "Clean — 0 DPD, large balances, full payments on all accounts",
            "remark": "UHNI business owner with excellent credit discipline.",
        },
        "CUST000004": {
            "cibil_score": 620,
            "rating": "FAIR",
            "dpd_history": "5 days late on card payment, minimum-only payment detected",
            "remark": "Retail salaried customer showing early payment stress signals.",
        },
        "CUST000005": {
            "cibil_score": 429,
            "rating": "POOR",
            "dpd_history": "10 DPD on credit card, minimum-only payments, cash advance detected",
            "remark": "High-risk profile. Cash advance and consistent minimum payments indicate credit distress.",
        },
        "CUST000006": {
            "cibil_score": 790,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments, no adverse credit behaviour",
            "remark": "UHNI real estate client with clean credit profile.",
        },
        "CUST000007": {
            "cibil_score": 640,
            "rating": "FAIR",
            "dpd_history": "13 days late, partial payment only, DPD flag on record",
            "remark": "Retail client with emerging credit stress. Monitor closely.",
        },
        "CUST000008": {
            "cibil_score": 780,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD across all accounts, full card payments every month",
            "remark": "PEP Category B government official. Clean credit despite enhanced monitoring.",
            "source": "Mock — replace with CIBIL TransUnion API using customer PAN in production",
        },
        "CUST000009": {
            "cibil_score": 800,
            "rating": "EXCELLENT",
            "dpd_history": "Clean — 0 DPD, full payments, low credit utilisation relative to limits",
            "remark": "UHNI promoter with excellent credit health. Complex corporate structure.",
            "source": "Mock — replace with CIBIL TransUnion API using customer PAN in production",
        },
        "CUST000010": {
            "cibil_score": 510,
            "rating": "POOR",
            "dpd_history": "17 days late, minimum-only payment, credit card near-maxed (₹38,500 of ₹40,000)",
            "remark": "New retail customer showing immediate credit stress post-onboarding.",
        },
        "CUST000011": {
            "cibil_score": 790,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments every month, home loan serviced on time",
            "remark": "HNI consultant with strong credit discipline. No adverse credit history.",
        },
        "CUST000012": {
            "cibil_score": 775,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments, home loan serviced on time",
            "remark": "NSE employee with stable salaried income. Clean credit history. Compliance-restricted portfolio.",
        },
        "CUST000013": {
            "cibil_score": 800,
            "rating": "EXCELLENT",
            "dpd_history": "Clean — 0 DPD, full card payments, no liabilities outstanding",
            "remark": "Debt-free HNI business owner with excellent credit discipline. Conservative investor.",
        },
        "CUST000014": {
            "cibil_score": 745,
            "rating": "GOOD",
            "dpd_history": "Clean — 0 DPD, full card payments, large home loan serviced on time",
            "remark": "Aggressive HNI investor. Suffered portfolio losses FY2022-23 but credit conduct unaffected.",
        },
    }

    default = {
        "cibil_score": 650,
        "rating": "FAIR",
        "dpd_history": "No data available",
        "remark": "Score unavailable — request CIBIL consent form from customer",
    }

    entry = mock_scores.get(customer_id, default)
    result = {**entry, "source": "Mock — replace with CIBIL TransUnion API using customer PAN in production"}

    logger.debug(
        "← returning from get_cibil_score(customer_id=%s) — score=%d, rating=%s",
        customer_id, result["cibil_score"], result["rating"]
    )
    return result


def get_today_date() -> str:
    """
    Returns today's date as a formatted string for use in the
    advisory briefing header.

    Returns:
        String in format 'DD Month YYYY' e.g. '07 May 2026'
    """
    from datetime import date
    today = date.today()
    return today.strftime("%d %B %Y")


# ============================================================
# LAYER 4b — RISK ASSESSMENT AGENT
# ============================================================

def compute_composite_risk_score(customer_id: str) -> str:
    """
    Aggregates live risk signals from all six source systems to produce a
    composite 360-degree risk score with prioritised red flags.

    Args:
        customer_id: CBS master customer identifier

    Returns:
        JSON string with composite score, risk tier, and ranked red flag list
    """
    import datetime

    logger.debug("→ entering compute_composite_risk_score(customer_id=%s)", customer_id)

    risk = query_one("kyc",
        "SELECT risk_tier, risk_score FROM risk_classification "
        "WHERE customer_id = %s", (customer_id,))

    pep = query_one("kyc",
        "SELECT pep_flag, pep_category, adverse_media_hit "
        "FROM pep_screening WHERE customer_id = %s "
        "ORDER BY screen_date DESC LIMIT 1", (customer_id,))

    edd_open = query_db("kyc",
        "SELECT edd_id, case_status, escalation_flag FROM edd_cases "
        "WHERE customer_id = %s AND case_status NOT IN "
        "('CLOSED_CLEARED', 'CLOSED_ESCALATED')", (customer_id,))

    kyc_rec = query_one("kyc",
        "SELECT kyc_status, re_kyc_due FROM kyc_master WHERE customer_id = %s",
        (customer_id,))

    liabilities = query_db("cbs",
        "SELECT dpd_days, npa_flag FROM liability_accounts "
        "WHERE customer_id = %s", (customer_id,))

    red_flags: list[dict] = []
    base_score = float(risk["risk_score"]) if risk else 30.0
    score = base_score

    if pep and pep.get("pep_flag"):
        red_flags.append({
            "severity": "HIGH",
            "flag": f"PEP {pep.get('pep_category')} — enhanced monitoring mandatory"
        })
        score = min(score + 20, 100)

    for e in edd_open:
        sev = "HIGH" if e.get("escalation_flag") else "MEDIUM"
        red_flags.append({
            "severity": sev,
            "flag": f"Open EDD case {e['edd_id']} — {e['case_status']}"
        })
        score = min(score + 15, 100)

    if kyc_rec and kyc_rec.get("kyc_status") == "UNDER_REVIEW":
        red_flags.append({
            "severity": "HIGH",
            "flag": "KYC under review — transactions may be restricted"
        })
        score = min(score + 10, 100)

    if kyc_rec and kyc_rec.get("re_kyc_due"):
        try:
            due = kyc_rec["re_kyc_due"]
            if hasattr(due, "date"):
                due = due.date()
            elif isinstance(due, str):
                due = datetime.date.fromisoformat(due)
            if due < datetime.date.today():
                red_flags.append({
                    "severity": "HIGH",
                    "flag": f"Re-KYC overdue since {due}"
                })
                score = min(score + 12, 100)
        except Exception:
            pass

    for lib in liabilities:
        dpd = int(lib.get("dpd_days") or 0)
        if dpd > RISK_THRESHOLDS["dpd_threshold_days"]:
            red_flags.append({
                "severity": "MEDIUM",
                "flag": f"Liability DPD {dpd} days — credit stress signal"
            })
            score = min(score + 8, 100)
        if lib.get("npa_flag"):
            red_flags.append({
                "severity": "HIGH",
                "flag": "NPA flag on liability account"
            })
            score = min(score + 20, 100)

    adv = pep.get("adverse_media_hit", "") if pep else ""
    if adv and adv.lower() not in ("none", ""):
        red_flags.append({
            "severity": "MEDIUM",
            "flag": f"Adverse media: {adv[:100]}"
        })
        score = min(score + 5, 100)

    score = round(score, 2)
    tier = ("VERY_HIGH" if score >= 80 else "HIGH" if score >= 60
            else "MEDIUM" if score >= 40 else "LOW")

    result = to_json({
        "customer_id":      customer_id,
        "composite_score":  score,
        "risk_tier":        tier,
        "red_flags":        sorted(
            red_flags,
            key=lambda x: {"HIGH": 0, "MEDIUM": 1, "LOW": 2}[x["severity"]]
        ),
        "base_score":        base_score,
        "score_adjustments": round(score - base_score, 2),
    })
    logger.debug(
        "← returning from compute_composite_risk_score(customer_id=%s) — score=%.1f, tier=%s, flags=%d",
        customer_id, score, tier, len(red_flags)
    )
    return result
