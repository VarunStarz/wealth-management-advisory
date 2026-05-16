"""
Phase A Prerequisite — DMS: Remove customer_id from all DMS tables.

Changes:
  income_proofs:       DROP customer_id (already linked via dms_id FK)
  bank_statements:     DROP customer_id (already linked via dms_id FK)
  audit_trail:         ADD pan_number (cross-DB from CBS), DROP customer_id
  document_repository: DROP customer_id (entry point is now pan_number)

Run from project root:
    python scripts/migrate_dms_remove_customer_id.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import psycopg2
import psycopg2.extras
from config.settings import DB_CONFIGS


def write_conn(db_name: str):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"],
        cursor_factory=psycopg2.extras.RealDictCursor,
    )
    conn.autocommit = False
    return conn


def read_conn(db_name: str):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"],
        cursor_factory=psycopg2.extras.RealDictCursor,
    )
    conn.autocommit = True
    return conn


def main():
    dms_conn = write_conn("dms")
    cbs_conn = read_conn("cbs")
    dms_cur  = dms_conn.cursor()
    cbs_cur  = cbs_conn.cursor()

    try:
        # ── 1. income_proofs: drop customer_id (linked via dms_id) ───────────────
        print("income_proofs: dropping customer_id...")
        dms_cur.execute("ALTER TABLE income_proofs DROP COLUMN customer_id")
        print("  income_proofs: done.")

        # ── 2. bank_statements: drop customer_id (linked via dms_id) ─────────────
        print("bank_statements: dropping customer_id...")
        dms_cur.execute("ALTER TABLE bank_statements DROP COLUMN customer_id")
        print("  bank_statements: done.")

        # ── 3. audit_trail: add pan_number, populate from CBS, drop customer_id ───
        print("audit_trail: adding pan_number...")
        dms_cur.execute("ALTER TABLE audit_trail ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10)")

        dms_cur.execute("SELECT DISTINCT customer_id FROM audit_trail WHERE customer_id IS NOT NULL")
        customer_ids = [row["customer_id"] for row in dms_cur.fetchall()]
        print(f"  Resolving PAN for {len(customer_ids)} distinct customers in audit_trail...")

        updated_audit = 0
        skipped_audit = 0
        for cid in customer_ids:
            cbs_cur.execute(
                "SELECT pan_number FROM customer_master WHERE customer_id = %s", (cid,)
            )
            cbs_row = cbs_cur.fetchone()
            if cbs_row and cbs_row["pan_number"]:
                dms_cur.execute(
                    "UPDATE audit_trail SET pan_number = %s WHERE customer_id = %s",
                    (cbs_row["pan_number"], cid)
                )
                updated_audit += 1
            else:
                print(f"  WARN: {cid} not found in CBS — audit_trail rows for this customer will lose customer_id")
                skipped_audit += 1

        dms_cur.execute("ALTER TABLE audit_trail DROP COLUMN customer_id")
        print(f"  audit_trail: pan_number set for {updated_audit} customers, {skipped_audit} skipped.")

        # ── 4. document_repository: drop customer_id ─────────────────────────────
        print("document_repository: dropping customer_id...")
        dms_cur.execute("ALTER TABLE document_repository DROP COLUMN customer_id")
        print("  document_repository: done.")

        dms_conn.commit()
        print("\nDMS migration committed successfully.")

        # ── 5. Verify ─────────────────────────────────────────────────────────────
        dms_cur.execute("SELECT COUNT(*) AS n, COUNT(pan_number) AS with_pan FROM document_repository")
        row = dms_cur.fetchone()
        print(f"Verification — document_repository rows: {row['n']}, with pan_number: {row['with_pan']}")

        dms_cur.execute("SELECT COUNT(*) AS n, COUNT(pan_number) AS with_pan FROM audit_trail")
        row = dms_cur.fetchone()
        print(f"             — audit_trail rows: {row['n']}, with pan_number: {row['with_pan']}")

        dms_cur.execute("SELECT COUNT(*) AS n FROM income_proofs")
        print(f"             — income_proofs rows: {dms_cur.fetchone()['n']}")

        dms_cur.execute("SELECT COUNT(*) AS n FROM bank_statements")
        print(f"             — bank_statements rows: {dms_cur.fetchone()['n']}")

    except Exception as e:
        dms_conn.rollback()
        print(f"ERROR — rolled back: {e}")
        raise
    finally:
        dms_cur.close()
        cbs_cur.close()
        dms_conn.close()
        cbs_conn.close()


if __name__ == "__main__":
    main()
