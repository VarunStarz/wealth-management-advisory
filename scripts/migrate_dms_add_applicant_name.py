"""
Phase A Migration — DMS: Add applicant_name to document_repository.

applicant_name: name as extracted from the scanned document — may differ
from CBS canonical name (middle name absent, spelling variation, initials).

Populated from CBS customer_master using the existing customer_id link
(run this BEFORE dropping customer_id from document_repository).

Run from project root:
    python scripts/migrate_dms_add_applicant_name.py
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
        # ── Step 1: Add column (idempotent) ─────────────────────────────
        print("Adding applicant_name column to document_repository...")
        dms_cur.execute("""
            ALTER TABLE document_repository
            ADD COLUMN IF NOT EXISTS applicant_name VARCHAR(100)
        """)

        # ── Step 2: Fetch all document records with their customer_id ────
        dms_cur.execute("SELECT dms_id, customer_id FROM document_repository")
        dms_rows = dms_cur.fetchall()
        print(f"Found {len(dms_rows)} document records to populate.")

        # ── Step 3: Cross-DB populate from CBS ───────────────────────────
        # Cache CBS lookups to avoid repeated queries for the same customer
        cbs_cache: dict[str, str] = {}
        updated = 0
        skipped = 0

        for row in dms_rows:
            dms_id      = row["dms_id"]
            customer_id = row["customer_id"]

            if customer_id not in cbs_cache:
                cbs_cur.execute(
                    "SELECT full_name FROM customer_master WHERE customer_id = %s",
                    (customer_id,)
                )
                cbs_row = cbs_cur.fetchone()
                if cbs_row:
                    cbs_cache[customer_id] = cbs_row["full_name"]
                else:
                    cbs_cache[customer_id] = None

            full_name = cbs_cache[customer_id]

            if not full_name:
                print(f"  WARN: customer_id {customer_id} not found in CBS — skipping {dms_id}")
                skipped += 1
                continue

            dms_cur.execute(
                "UPDATE document_repository SET applicant_name = %s WHERE dms_id = %s",
                (full_name, dms_id)
            )
            updated += 1

        # ── Step 4: Commit ───────────────────────────────────────────────
        dms_conn.commit()
        print(f"\nDone. Updated: {updated}  Skipped: {skipped}")

        # ── Step 5: Verify ───────────────────────────────────────────────
        dms_cur.execute(
            "SELECT COUNT(*) AS total, COUNT(applicant_name) AS with_name FROM document_repository"
        )
        stats = dms_cur.fetchone()
        print(f"Verification — total rows: {stats['total']}, "
              f"with applicant_name: {stats['with_name']}")

    except Exception as e:
        dms_conn.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        dms_cur.close()
        cbs_cur.close()
        dms_conn.close()
        cbs_conn.close()


if __name__ == "__main__":
    main()
