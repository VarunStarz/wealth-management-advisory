# ============================================================
# agents/edd/agent.py
# EDD Agent — Enhanced Due Diligence (Layer 3b)
# Activated only when CDD returns edd_trigger = true
# ============================================================

import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from google.adk.agents import Agent
from config.settings import GEMINI_MODEL
from tools.agent_tools import (
    get_edd_case_history,
    get_external_bank_statements,
    get_interaction_red_flags,
)

edd_agent = Agent(
    name="edd_agent",
    model=GEMINI_MODEL,
    description=(
        "Performs Enhanced Due Diligence for high-risk or PEP-flagged clients. "
        "Reviews open EDD cases, source of wealth verification, external bank "
        "statements, adverse media, and RM interaction history."
    ),
    instruction="""
You are the EDD (Enhanced Due Diligence) Agent. You are ONLY activated when the
CDD Agent has flagged this client as HIGH risk or PEP.

Context: This client has come to a wealth manager seeking advice. Your findings
will determine whether the bank can proceed with the advisory relationship.

STEPS — execute in this exact order:

1. Call get_edd_case_history(customer_id)
   Review all open cases, escalation flags, and source-of-wealth gaps.

2. Call get_external_bank_statements(customer_id)
   Look for flagged statements — round-figure cash credits, undisclosed accounts.

3. Call get_interaction_red_flags(customer_id)
   Scan RM logs for EDD discussions, low sentiment, unresolved follow-ups.

4. Return a structured EDD finding:
   {
     "edd_status":           "CLEARED"|"IN_PROGRESS"|"ESCALATE_TO_COMPLIANCE",
     "open_cases":           [ { "edd_id": "...", "status": "...", "trigger": "..." } ],
     "source_of_wealth": {
       "verified":           true | false,
       "gaps":               [ "<unverified item>" ]
     },
     "external_bank_flags":  [ "<flagged pattern>" ],
     "rm_red_flags":         [ "<RM log concern>" ],
     "escalation_required":  true | false,
     "escalation_reason":    "<reason if required>",
     "edd_summary":          "<2-3 sentence plain English finding>"
   }

EDD DECISION RULES:
- Any open case with escalation_flag = true  → escalation_required = true
- source_of_wealth_verified = false on open case → highlight as CRITICAL gap
- External statements flagged for cash patterns → include in external_bank_flags
- RM logs show EDD_DISCUSSION type → cross-reference with case history
- Be precise: cite case IDs, document references, and specific dates.
""",
    tools=[
        get_edd_case_history,
        get_external_bank_statements,
        get_interaction_red_flags,
    ],
)
