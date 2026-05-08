# ============================================================
# config/settings.py
# Central configuration — PostgreSQL connections + risk rules
# ============================================================

import os
from dotenv import load_dotenv

load_dotenv()

# ── Gemini model ─────────────────────────────────────────────
GEMINI_MODEL   = "gemini-3-pro-preview"
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "")

# ── PostgreSQL connection configs ────────────────────────────
# Each database is an isolated PostgreSQL instance/schema.
# Matches the six source systems defined in the project.
DB_CONFIGS: dict[str, dict] = {
    "cbs": {
        "host":     os.getenv("CBS_HOST", "localhost"),
        "port":     int(os.getenv("CBS_PORT", "5432")),
        "user":     os.getenv("CBS_USER", "postgres"),
        "password": os.getenv("CBS_PASS", ""),
        "dbname":   os.getenv("CBS_NAME", "cbs"),
    },
    "crm": {
        "host":     os.getenv("CRM_HOST", "localhost"),
        "port":     int(os.getenv("CRM_PORT", "5432")),
        "user":     os.getenv("CRM_USER", "postgres"),
        "password": os.getenv("CRM_PASS", ""),
        "dbname":   os.getenv("CRM_NAME", "crm"),
    },
    "kyc": {
        "host":     os.getenv("KYC_HOST", "localhost"),
        "port":     int(os.getenv("KYC_PORT", "5432")),
        "user":     os.getenv("KYC_USER", "postgres"),
        "password": os.getenv("KYC_PASS", ""),
        "dbname":   os.getenv("KYC_NAME", "kyc"),
    },
    "pms": {
        "host":     os.getenv("PMS_HOST", "localhost"),
        "port":     int(os.getenv("PMS_PORT", "5432")),
        "user":     os.getenv("PMS_USER", "postgres"),
        "password": os.getenv("PMS_PASS", ""),
        "dbname":   os.getenv("PMS_NAME", "pms"),
    },
    "card": {
        "host":     os.getenv("CARD_HOST", "localhost"),
        "port":     int(os.getenv("CARD_PORT", "5432")),
        "user":     os.getenv("CARD_USER", "postgres"),
        "password": os.getenv("CARD_PASS", ""),
        "dbname":   os.getenv("CARD_NAME", "card"),
    },
    "dms": {
        "host":     os.getenv("DMS_HOST", "localhost"),
        "port":     int(os.getenv("DMS_PORT", "5432")),
        "user":     os.getenv("DMS_USER", "postgres"),
        "password": os.getenv("DMS_PASS", ""),
        "dbname":   os.getenv("DMS_NAME", "dms"),
    },
}

# ── Risk thresholds ──────────────────────────────────────────
RISK_THRESHOLDS = {
    "edd_trigger_score":      50.0,   # risk_score above this triggers EDD
    "income_discrepancy_pct": 30.0,   # % gap between declared and inferred income
    "dpd_threshold_days":     10,     # days-past-due threshold for liability flag
    "portfolio_concentration": 45.0,  # single holding weight % = concentration risk
    "min_payment_months":     2,      # consecutive minimum-only card payments = flag
}

# ── Guardrail rules ──────────────────────────────────────────
GUARDRAIL_RULES = {
    # Queries must mention a customer identifier to proceed
    "require_customer_context": True,

    # Block queries that are clearly outside scope
    "blocked_intents": [
        "investment recommendation",
        "buy this stock",
        "sell this fund",
        "market prediction",
        "price target",
        "personal financial advice for the RM",
    ],

    # Maximum query length (chars) — reject garbage / injection attempts
    "max_query_length": 2000,

    # Minimum query length — reject empty or trivial inputs
    "min_query_length": 10,
}
