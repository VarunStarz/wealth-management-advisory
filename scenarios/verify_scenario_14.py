"""Verify all Scenario 14 data is accessible via the agent_tools functions."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import json
from tools.agent_tools import (
    get_identity_resolution_map,
    get_client_core_profile,
    get_kyc_status,
    run_pep_sanctions_check,
    get_portfolio_holdings,
    get_portfolio_performance,
    get_declared_income,
    get_card_spend_analysis,
    get_cibil_score,
    compute_composite_risk_score,
)

CID = "CUST000011"

def check(label, result_str):
    try:
        data = json.loads(result_str) if isinstance(result_str, str) else result_str
        if isinstance(data, dict) and "error" in data:
            print(f"  FAIL  {label}: {data['error']}")
        elif isinstance(data, list) and data and "error" in data[0]:
            print(f"  FAIL  {label}: {data[0]['error']}")
        else:
            print(f"  OK    {label}")
        return data
    except Exception as e:
        print(f"  FAIL  {label}: {e}")
        return {}

print(f"\nVerifying Scenario 14 data -- {CID}\n")

d = check("identity_resolution_map",   get_identity_resolution_map(CID))
d = check("client_core_profile",       get_client_core_profile(CID))
d = check("kyc_status",                get_kyc_status(CID))
d = check("pep_sanctions_check",       run_pep_sanctions_check(CID))
d = check("portfolio_holdings",        get_portfolio_holdings(CID))
d = check("portfolio_performance",     get_portfolio_performance(CID))
d = check("declared_income",           get_declared_income(CID))
d = check("card_spend_analysis",       get_card_spend_analysis(CID))
cibil = get_cibil_score(CID)
check("cibil_score",                   json.dumps(cibil))
print(f"         score={cibil['cibil_score']}, rating={cibil['rating']}")
d = check("composite_risk_score",      compute_composite_risk_score(CID))

# spot-check key values
print("\n--- Spot checks ---")
port = json.loads(get_portfolio_holdings(CID))
holdings = port[0]["holdings"]
print(f"  holdings count     : {len(holdings)} (expected 4)")
print(f"  AUM                : Rs.{port[0]['aum']:,.0f} (expected Rs.85,00,000)")

perf_raw = json.loads(get_portfolio_performance(CID))
perf = perf_raw[0]["performance"]
print(f"  perf periods       : {len(perf)} (expected 6)")
alphas = [float(p["alpha"]) for p in perf if p.get("alpha") is not None]
print(f"  all alpha negative : {all(a < 0 for a in alphas)} (expected True)")

risk_raw = json.loads(compute_composite_risk_score(CID))
print(f"  risk tier          : {risk_raw['risk_tier']} (expected LOW)")
print(f"  risk score         : {risk_raw['composite_score']} (expected ~20)")
print()
