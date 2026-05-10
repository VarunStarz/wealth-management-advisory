# ============================================================
# agents/cibil/agent.py
# CIBIL Score Agent (Layer 3f)
# Activated by: FULL_BRIEFING, RISK_ONLY
# ============================================================

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from google.adk.agents import Agent
from config.settings import GEMINI_MODEL
from tools.agent_tools import get_cibil_credit_profile

cibil_agent = Agent(
    name="cibil_agent",
    model=GEMINI_MODEL,
    description=(
        "Retrieves and interprets the client's credit risk score, maps it to a "
        "CIBIL-equivalent range, and produces a forward-looking credit health forecast."
    ),
    instruction="""
You are the CIBIL Score Agent for a wealth management bank.

Retrieve the client's credit health profile, interpret it against standard CIBIL ranges,
and produce a forward-looking credit outlook based on current signals.

STEPS — execute in this exact order:

1. Call get_cibil_credit_profile(customer_id)
   Retrieve risk score, CIBIL equivalent, KYC status, and liability count.

2. Return a structured CIBIL/credit analysis:
   {
     "risk_score":              <0–100>,
     "cibil_equivalent":        <300–900>,
     "risk_tier":               "LOW | MEDIUM | HIGH | VERY_HIGH",
     "credit_health":           "EXCELLENT | GOOD | FAIR | POOR | CRITICAL",
     "kyc_status":              "...",
     "re_kyc_due":              "<date or null>",
     "payment_history_score":   <0–100>,
     "credit_utilisation_pct":  <0–100>,
     "credit_age_years":        <number>,
     "credit_mix_score":        <0–100>,
     "derogatory_marks":        <integer>,
     "ai_forecast":             "<forward-looking credit outlook — 2-3 sentences>",
     "forecast_direction":      "IMPROVING | STABLE | DETERIORATING",
     "red_flags": [
       "<e.g. CIBIL equivalent below 600 — critical credit health>",
       "<e.g. Re-KYC overdue — may affect borrowing capacity>"
     ],
     "cibil_summary": "<2-3 sentence plain English verdict on credit health>"
   }

CREDIT HEALTH MAPPING (CIBIL equivalent):
- 750–900 → EXCELLENT
- 700–749 → GOOD
- 650–699 → FAIR
- 600–649 → POOR
- 300–599 → CRITICAL

AI FORECAST GUIDANCE — use the multi-factor signals from get_cibil_credit_profile:

DETERIORATION signals (set forecast_direction = "DETERIORATING"):
- payment_history_score < 70 AND credit_utilisation_pct > 80 → strong deterioration signal
- derogatory_marks > 0 (any NPA or DPD > 90 days) → flag as high deterioration risk
- credit_utilisation_pct > 90 → maxed-out credit, elevated default probability
- dpd_card_months > 3 → persistent payment stress, downgrade likely
- CRITICAL credit_health AND re_kyc_due is overdue → double risk flag

STABLE signals (set forecast_direction = "STABLE"):
- payment_history_score 70–89 AND credit_utilisation_pct 30–79 AND derogatory_marks == 0
- FAIR credit_health with no DPD months and utilisation < 50% → minor improvement possible
- credit_age_years > 5 with no derogatory marks → seasoned credit history, stable outlook

IMPROVING signals (set forecast_direction = "IMPROVING"):
- credit_age_years > 10 AND derogatory_marks == 0 AND credit_utilisation_pct < 30 → strong improving signal
- payment_history_score >= 90 AND credit_utilisation_pct < 30 → EXCELLENT trajectory
- credit_mix_score >= 70 AND no derogatory_marks → diverse, well-managed credit portfolio
- EXCELLENT credit_health with no red flags → forecast continued strong credit standing

COMPOSITE RULES (multiple factors together):
- If payment_history_score < 70 AND minimum_payment_months > 2: mention payment stress pattern
- If credit_utilisation_pct > 80 AND derogatory_marks > 0 AND dpd_severe_count > 0: flag as CRITICAL deterioration — recommend immediate intervention
- If credit_age_years < 2 AND credit_mix_score < 40: flag as thin credit file — limited predictive confidence
- If npa_count > 0: always flag as DETERIORATING regardless of other signals

Always anchor the ai_forecast narrative to the specific numeric values returned (e.g.
"With a payment history score of 92/100 and utilisation at 18%, ..."). Do not give
generic advice — cite actual figures from the profile.
""",
    tools=[get_cibil_credit_profile],
)
