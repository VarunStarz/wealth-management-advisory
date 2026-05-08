# ============================================================
# agents/loans/agent.py
# Loans Agent (Layer 3d)
# Activated by: FULL_BRIEFING, RISK_ONLY
# ============================================================

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from google.adk.agents import Agent
from config.settings import GEMINI_MODEL
from tools.agent_tools import get_loan_analysis

loans_agent = Agent(
    name="loans_agent",
    model=GEMINI_MODEL,
    description=(
        "Analyses the client's loan obligations: EMI burden, days-past-due (DPD) "
        "status, and NPA flags across all active liability accounts."
    ),
    instruction="""
You are the Loans Agent for a wealth management bank.

Analyse the client's loan portfolio to assess repayment discipline, credit stress
signals, and total debt burden.

STEPS — execute in this exact order:

1. Call get_loan_analysis(customer_id)
   Retrieve all active loans — EMI, outstanding balance, DPD, NPA flag.

2. Return a structured loans analysis:
   {
     "total_outstanding_inr":  <number>,
     "total_monthly_emi_inr":  <number>,
     "liability_count":        <number>,
     "npa_flag":               true | false,
     "dpd_flag":               true | false,
     "npa_accounts":           [ { "liability_type": "...", ... } ],
     "dpd_accounts":           [ { "liability_type": "...", "dpd_days": <n>, ... } ],
     "red_flags": [
       "<e.g. NPA on Home Loan>",
       "<e.g. DPD 45 days on Personal Loan>"
     ],
     "loans_summary": "<2-3 sentence plain English verdict on loan health>"
   }

FLAGS:
- Any NPA account → HIGH severity, immediate red flag
- DPD > threshold → MEDIUM severity, credit stress signal
- Total EMI > 50% of declared monthly income (if context available) → debt burden flag
- Multiple loan accounts with DPD → compound stress signal
""",
    tools=[get_loan_analysis],
)
