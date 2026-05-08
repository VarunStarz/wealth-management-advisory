"""Check who actually owns DOC000000011-014 and DMS000000011-020."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import psycopg2
from config.settings import DB_CONFIGS

def connect_ro(db_name):
    cfg = DB_CONFIGS[db_name]
    return psycopg2.connect(host=cfg["host"], port=cfg["port"], user=cfg["user"],
        password=cfg["password"], dbname=cfg["dbname"], connect_timeout=5)

print("=== KYC identity_documents: docs 011-020 ===")
conn = connect_ro("kyc")
cur = conn.cursor()
cur.execute("""
    SELECT d.doc_id, k.customer_id, d.doc_type, d.doc_number
    FROM identity_documents d JOIN kyc_master k ON d.kyc_id = k.kyc_id
    WHERE d.doc_id >= 'DOC000000010'
    ORDER BY d.doc_id
""")
for r in cur.fetchall():
    print(f"  {r}")

print("\n  Docs for KYC000000011 (CUST000011):")
cur.execute("SELECT doc_id, doc_type, doc_number FROM identity_documents WHERE kyc_id = 'KYC000000011'")
for r in cur.fetchall():
    print(f"  {r}")
conn.close()

print("\n=== DMS document_repository: dms_id 010-022 ===")
conn = connect_ro("dms")
cur = conn.cursor()
cur.execute("""
    SELECT dms_id, customer_id, doc_type, doc_category
    FROM document_repository
    WHERE dms_id >= 'DMS000000010'
    ORDER BY dms_id
""")
for r in cur.fetchall():
    print(f"  {r}")
conn.close()
