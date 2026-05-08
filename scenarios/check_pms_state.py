"""Check benchmarks, portfolios, and existing data gaps for CUST000011."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import psycopg2
from config.settings import DB_CONFIGS

def connect_ro(db_name):
    cfg = DB_CONFIGS[db_name]
    return psycopg2.connect(host=cfg["host"], port=cfg["port"], user=cfg["user"],
        password=cfg["password"], dbname=cfg["dbname"], connect_timeout=5)

conn = connect_ro("pms")
cur = conn.cursor()
print("=== All benchmarks ===")
cur.execute("SELECT benchmark_id, benchmark_name, asset_class FROM benchmark_master ORDER BY benchmark_id")
for r in cur.fetchall():
    print(f"  {r}")

print("\n=== All portfolios ===")
cur.execute("SELECT portfolio_id, client_id, strategy_type, benchmark_id, aum FROM portfolio_master ORDER BY portfolio_id")
for r in cur.fetchall():
    print(f"  {r}")
conn.close()

conn = connect_ro("kyc")
cur = conn.cursor()
print("\n=== identity_documents for KYC000000011 (CUST000011) ===")
cur.execute("SELECT doc_id, doc_type, doc_number FROM identity_documents WHERE kyc_id='KYC000000011'")
rows = cur.fetchall()
print(f"  Count: {len(rows)}")
for r in rows:
    print(f"  {r}")
conn.close()

conn = connect_ro("dms")
cur = conn.cursor()
print("\n=== income_proofs for CUST000011 ===")
cur.execute("SELECT proof_id, dms_id, gross_income, net_income FROM income_proofs WHERE customer_id='CUST000011'")
for r in cur.fetchall():
    print(f"  {r}")

print("\n=== document_repository for CUST000011 ===")
cur.execute("SELECT dms_id, doc_type, doc_category FROM document_repository WHERE customer_id='CUST000011'")
for r in cur.fetchall():
    print(f"  {r}")
conn.close()
