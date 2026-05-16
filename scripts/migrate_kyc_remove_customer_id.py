"""
Phase A Prerequisite — KYC: Remove customer_id, wire child tables via kyc_id.

Changes:
  pep_screening:       ADD kyc_id FK → kyc_master, DROP customer_id
  risk_classification: ADD kyc_id FK → kyc_master, DROP customer_id + UNIQUE constraint
  edd_cases:           ADD kyc_id FK → kyc_master, DROP customer_id
  kyc_master:          DROP customer_id + UNIQUE constraint

Entry point into the KYC system after this migration: pan_number on kyc_master.
Child tables are reached via kyc_id.

Run from project root:
    python scripts/migrate_kyc_remove_customer_id.py
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


def main():
    conn = write_conn("kyc")
    cur  = conn.cursor()

    try:
        # ── 1. pep_screening: add kyc_id, populate, NOT NULL, FK, drop customer_id ──
        print("pep_screening: adding kyc_id...")
        cur.execute("ALTER TABLE pep_screening ADD COLUMN IF NOT EXISTS kyc_id VARCHAR(12)")

        cur.execute("""
            UPDATE pep_screening ps
            SET kyc_id = km.kyc_id
            FROM kyc_master km
            WHERE ps.customer_id = km.customer_id
        """)

        cur.execute("SELECT COUNT(*) AS nulls FROM pep_screening WHERE kyc_id IS NULL")
        nulls = cur.fetchone()["nulls"]
        if nulls:
            print(f"  WARN: {nulls} pep_screening rows have no matching kyc_master record — they will be skipped.")
            cur.execute("DELETE FROM pep_screening WHERE kyc_id IS NULL")
            print(f"  Deleted {nulls} unresolvable rows from pep_screening.")

        cur.execute("ALTER TABLE pep_screening ALTER COLUMN kyc_id SET NOT NULL")
        cur.execute("""
            ALTER TABLE pep_screening
            ADD CONSTRAINT pep_screening_kyc_id_fkey
            FOREIGN KEY (kyc_id) REFERENCES kyc_master(kyc_id)
        """)
        cur.execute("ALTER TABLE pep_screening DROP COLUMN customer_id")
        print("  pep_screening: done.")

        # ── 2. risk_classification: add kyc_id, populate, UNIQUE, FK, drop customer_id ──
        print("risk_classification: adding kyc_id...")
        cur.execute("ALTER TABLE risk_classification ADD COLUMN IF NOT EXISTS kyc_id VARCHAR(12)")

        cur.execute("""
            UPDATE risk_classification rc
            SET kyc_id = km.kyc_id
            FROM kyc_master km
            WHERE rc.customer_id = km.customer_id
        """)

        cur.execute("SELECT COUNT(*) AS nulls FROM risk_classification WHERE kyc_id IS NULL")
        nulls = cur.fetchone()["nulls"]
        if nulls:
            print(f"  WARN: {nulls} risk_classification rows unresolvable — deleting.")
            cur.execute("DELETE FROM risk_classification WHERE kyc_id IS NULL")

        cur.execute("ALTER TABLE risk_classification ALTER COLUMN kyc_id SET NOT NULL")
        cur.execute("""
            ALTER TABLE risk_classification
            ADD CONSTRAINT risk_classification_kyc_id_key UNIQUE (kyc_id)
        """)
        cur.execute("""
            ALTER TABLE risk_classification
            ADD CONSTRAINT risk_classification_kyc_id_fkey
            FOREIGN KEY (kyc_id) REFERENCES kyc_master(kyc_id)
        """)
        cur.execute("ALTER TABLE risk_classification DROP CONSTRAINT IF EXISTS risk_classification_customer_id_key")
        cur.execute("ALTER TABLE risk_classification DROP COLUMN customer_id")
        print("  risk_classification: done.")

        # ── 3. edd_cases: add kyc_id, populate, FK, drop customer_id ──────────────
        print("edd_cases: adding kyc_id...")
        cur.execute("ALTER TABLE edd_cases ADD COLUMN IF NOT EXISTS kyc_id VARCHAR(12)")

        cur.execute("""
            UPDATE edd_cases ec
            SET kyc_id = km.kyc_id
            FROM kyc_master km
            WHERE ec.customer_id = km.customer_id
        """)

        cur.execute("SELECT COUNT(*) AS nulls FROM edd_cases WHERE kyc_id IS NULL")
        nulls = cur.fetchone()["nulls"]
        if nulls:
            print(f"  WARN: {nulls} edd_cases rows unresolvable — deleting.")
            cur.execute("DELETE FROM edd_cases WHERE kyc_id IS NULL")

        cur.execute("SELECT COUNT(*) FROM edd_cases")
        edd_count = cur.fetchone()["count"]
        if edd_count > 0:
            cur.execute("ALTER TABLE edd_cases ALTER COLUMN kyc_id SET NOT NULL")
            cur.execute("""
                ALTER TABLE edd_cases
                ADD CONSTRAINT edd_cases_kyc_id_fkey
                FOREIGN KEY (kyc_id) REFERENCES kyc_master(kyc_id)
            """)
        cur.execute("ALTER TABLE edd_cases DROP COLUMN customer_id")
        print("  edd_cases: done.")

        # ── 4. kyc_master: drop UNIQUE constraint and customer_id column ──────────
        print("kyc_master: dropping customer_id...")
        cur.execute("ALTER TABLE kyc_master DROP CONSTRAINT IF EXISTS kyc_master_customer_id_key")
        cur.execute("ALTER TABLE kyc_master DROP COLUMN customer_id")
        print("  kyc_master: done.")

        conn.commit()
        print("\nKYC migration committed successfully.")

        # ── 5. Verify ─────────────────────────────────────────────────────────────
        cur.execute("SELECT COUNT(*) AS n FROM kyc_master")
        print(f"Verification — kyc_master rows: {cur.fetchone()['n']}")
        cur.execute("SELECT COUNT(*) AS n FROM pep_screening WHERE kyc_id IS NOT NULL")
        print(f"             — pep_screening with kyc_id: {cur.fetchone()['n']}")
        cur.execute("SELECT COUNT(*) AS n FROM risk_classification WHERE kyc_id IS NOT NULL")
        print(f"             — risk_classification with kyc_id: {cur.fetchone()['n']}")
        cur.execute("SELECT COUNT(*) AS n FROM edd_cases")
        print(f"             — edd_cases total: {cur.fetchone()['n']}")

    except Exception as e:
        conn.rollback()
        print(f"ERROR — rolled back: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
