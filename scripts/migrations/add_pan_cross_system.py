"""
Migration: Add pan_number to CRM, KYC, CARD, and DMS for realistic identity resolution.

Reads PAN numbers from cbs.customer_master (system of record) and
writes them into:
  - crm.client_profile
  - kyc.kyc_master
  - card.card_accounts
  - dms.document_repository

Run from project root:
    python scripts/migrations/add_pan_cross_system.py
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

import psycopg2
from config.settings import DB_CONFIGS


def connect_ro(db_name):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"], connect_timeout=10,
    )
    conn.autocommit = True
    return conn


def connect_rw(db_name):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"], connect_timeout=10,
    )
    conn.autocommit = False
    return conn


def section(name):
    print(f"\n{'-'*60}\n  {name}\n{'-'*60}")


def apply(db_name, label, alter_sqls, update_sql, records):
    conn = connect_rw(db_name)
    total = 0
    try:
        with conn.cursor() as cur:
            for sql in alter_sqls:
                cur.execute(sql)
            for customer_id, pan_number in records:
                cur.execute(update_sql, (pan_number, customer_id))
                rows = cur.rowcount
                total += rows
                print(f"  {label}: {customer_id} -> {pan_number}  ({rows} row{'s' if rows != 1 else ''})")
        conn.commit()
        print(f"  OK -- {total} total rows updated")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR: {e}")
        raise
    finally:
        conn.close()


def main():
    # ── Step 1: Read CBS golden record ───────────────────────────
    section("Step 1: Read PAN numbers from CBS (system of record)")
    cbs = connect_ro("cbs")
    with cbs.cursor() as cur:
        cur.execute(
            "SELECT customer_id, pan_number FROM customer_master "
            "WHERE pan_number IS NOT NULL ORDER BY customer_id"
        )
        records = cur.fetchall()
    cbs.close()
    print(f"  Found {len(records)} records with PAN")

    # ── Step 2: CRM ──────────────────────────────────────────────
    section("Step 2: CRM -- crm.client_profile")
    apply(
        "crm", "CRM",
        [
            "ALTER TABLE client_profile ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10)",
            "CREATE INDEX IF NOT EXISTS idx_client_profile_pan ON client_profile (pan_number)",
        ],
        "UPDATE client_profile SET pan_number = %s WHERE customer_id = %s",
        records,
    )

    # ── Step 3: KYC ──────────────────────────────────────────────
    section("Step 3: KYC -- kyc.kyc_master")
    apply(
        "kyc", "KYC",
        [
            "ALTER TABLE kyc_master ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10)",
            "CREATE INDEX IF NOT EXISTS idx_kyc_master_pan ON kyc_master (pan_number)",
        ],
        "UPDATE kyc_master SET pan_number = %s WHERE customer_id = %s",
        records,
    )

    # ── Step 4: CARD ─────────────────────────────────────────────
    section("Step 4: CARD -- card.card_accounts")
    apply(
        "card", "CARD",
        [
            "ALTER TABLE card_accounts ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10)",
            "CREATE INDEX IF NOT EXISTS idx_card_accounts_pan ON card_accounts (pan_number)",
        ],
        "UPDATE card_accounts SET pan_number = %s WHERE customer_id = %s",
        records,
    )

    # ── Step 5: DMS ──────────────────────────────────────────────
    section("Step 5: DMS -- dms.document_repository")
    apply(
        "dms", "DMS",
        [
            "ALTER TABLE document_repository ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10)",
            "CREATE INDEX IF NOT EXISTS idx_doc_repository_pan ON document_repository (pan_number)",
        ],
        "UPDATE document_repository SET pan_number = %s WHERE customer_id = %s",
        records,
    )

    section("Done")
    print("  pan_number added and populated across CRM, KYC, CARD, and DMS.")
    print("  Next: get_identity_resolution_map() now resolves via PAN first.")


if __name__ == "__main__":
    main()
