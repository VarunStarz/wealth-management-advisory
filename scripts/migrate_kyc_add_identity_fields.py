"""
Phase A Migration — KYC: Add registered_name and dob to kyc_master.

registered_name: name as it appears on the identity document used for KYC.
dob:             date of birth from the identity document.

Both are populated from CBS customer_master using the existing customer_id
link (run this BEFORE dropping customer_id from kyc_master).

Run from project root:
    python scripts/migrate_kyc_add_identity_fields.py
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
    kyc_conn = write_conn("kyc")
    cbs_conn = read_conn("cbs")
    kyc_cur  = kyc_conn.cursor()
    cbs_cur  = cbs_conn.cursor()

    try:
        # ── Step 1: Add columns (idempotent) ────────────────────────────
        print("Adding registered_name column to kyc_master...")
        kyc_cur.execute("""
            ALTER TABLE kyc_master
            ADD COLUMN IF NOT EXISTS registered_name VARCHAR(100)
        """)

        print("Adding dob column to kyc_master...")
        kyc_cur.execute("""
            ALTER TABLE kyc_master
            ADD COLUMN IF NOT EXISTS dob DATE
        """)

        # ── Step 2: Fetch all kyc records with their customer_id ─────────
        kyc_cur.execute("SELECT kyc_id, customer_id FROM kyc_master")
        kyc_rows = kyc_cur.fetchall()
        print(f"Found {len(kyc_rows)} KYC records to populate.")

        # ── Step 3: Cross-DB populate from CBS ───────────────────────────
        updated = 0
        skipped = 0
        for row in kyc_rows:
            kyc_id      = row["kyc_id"]
            customer_id = row["customer_id"]

            cbs_cur.execute(
                "SELECT full_name, dob FROM customer_master WHERE customer_id = %s",
                (customer_id,)
            )
            cbs_row = cbs_cur.fetchone()

            if not cbs_row:
                print(f"  WARN: customer_id {customer_id} not found in CBS — skipping {kyc_id}")
                skipped += 1
                continue

            kyc_cur.execute(
                "UPDATE kyc_master SET registered_name = %s, dob = %s WHERE kyc_id = %s",
                (cbs_row["full_name"], cbs_row["dob"], kyc_id)
            )
            updated += 1

        # ── Step 4: Commit ───────────────────────────────────────────────
        kyc_conn.commit()
        print(f"\nDone. Updated: {updated}  Skipped: {skipped}")

        # ── Step 5: Verify ───────────────────────────────────────────────
        kyc_cur.execute(
            "SELECT COUNT(*) AS total, COUNT(registered_name) AS with_name, COUNT(dob) AS with_dob FROM kyc_master"
        )
        stats = kyc_cur.fetchone()
        print(f"Verification — total rows: {stats['total']}, "
              f"with registered_name: {stats['with_name']}, "
              f"with dob: {stats['with_dob']}")

    except Exception as e:
        kyc_conn.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        kyc_cur.close()
        cbs_cur.close()
        kyc_conn.close()
        cbs_conn.close()


if __name__ == "__main__":
    main()
