"""Find the highest existing IDs in every table we'll be inserting into."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import psycopg2
from config.settings import DB_CONFIGS

def connect_ro(db_name):
    cfg = DB_CONFIGS[db_name]
    return psycopg2.connect(host=cfg["host"], port=cfg["port"], user=cfg["user"],
        password=cfg["password"], dbname=cfg["dbname"], connect_timeout=5)

def max_id(conn, table, pk_col):
    cur = conn.cursor()
    cur.execute(f"SELECT MAX({pk_col}) FROM {table}")
    row = cur.fetchone()
    return row[0] if row else None

print("\n=== Max IDs in each target table ===\n")

for db, checks in {
    "cbs":  [("customer_master",    "customer_id"),
             ("account_master",     "account_id"),
             ("liability_accounts", "liability_id"),
             ("transaction_history","txn_id")],
    "crm":  [("client_profile",     "client_id"),
             ("client_preferences", "pref_id"),
             ("interaction_log",    "interaction_id")],
    "kyc":  [("kyc_master",         "kyc_id"),
             ("identity_documents", "doc_id"),
             ("pep_screening",      "screen_id"),
             ("risk_classification","risk_class_id")],
    "pms":  [("benchmark_master",   "benchmark_id"),
             ("portfolio_master",   "portfolio_id"),
             ("holdings",           "holding_id"),
             ("performance_history","perf_id")],
    "card": [("card_accounts",      "card_id"),
             ("spend_aggregates",   "agg_id"),
             ("payment_behaviour",  "pay_id")],
    "dms":  [("document_repository","dms_id"),
             ("income_proofs",      "proof_id")],
}.items():
    conn = connect_ro(db)
    print(f"  DB: {db}")
    for table, pk in checks:
        val = max_id(conn, table, pk)
        print(f"    {table:<30} max {pk} = {val}")
    conn.close()
    print()
