"""
Migration 03: Populate pan_number in CRM and KYC from CBS golden record.

Cross-DB SQL JOINs are not possible since each system is a separate
PostgreSQL instance. This script reads PAN numbers from cbs.customer_master
(the system of record) and writes them into crm.client_profile and
kyc.kyc_master, enabling PAN-based identity resolution.

Prerequisites:
    Run migrations 01 and 02 first to add the pan_number columns.

Run from project root:
    python scripts/migrations/03_populate_pan_cross_db.py
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

import psycopg2
from config.settings import DB_CONFIGS


def connect_ro(db_name: str):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"], connect_timeout=10,
    )
    conn.autocommit = True
    return conn


def connect_rw(db_name: str):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"],
        user=cfg["user"], password=cfg["password"],
        dbname=cfg["dbname"], connect_timeout=10,
    )
    conn.autocommit = False
    return conn


def section(name: str):
    print(f"\n{'-'*60}")
    print(f"  {name}")
    print(f"{'-'*60}")


def main():
    # ── Step 1: Read golden record from CBS ──────────────────────
    section("Step 1: Read PAN numbers from CBS (system of record)")
    cbs = connect_ro("cbs")
    with cbs.cursor() as cur:
        cur.execute(
            "SELECT customer_id, pan_number "
            "FROM customer_master "
            "WHERE pan_number IS NOT NULL"
        )
        records = cur.fetchall()
    cbs.close()
    print(f"  Found {len(records)} CBS records with PAN")
    for cid, pan in records:
        print(f"    {cid}  →  {pan}")

    # ── Step 2: Populate CRM ──────────────────────────────────────
    section("Step 2: Populate pan_number in crm.client_profile")
    crm = connect_rw("crm")
    updated_crm = 0
    try:
        with crm.cursor() as cur:
            for customer_id, pan_number in records:
                cur.execute(
                    "UPDATE client_profile SET pan_number = %s "
                    "WHERE customer_id = %s",
                    (pan_number, customer_id),
                )
                updated_crm += cur.rowcount
        crm.commit()
        print(f"  OK — updated {updated_crm} rows in crm.client_profile")
    except Exception as e:
        crm.rollback()
        print(f"  ERROR: {e}")
        raise
    finally:
        crm.close()

    # ── Step 3: Populate KYC ──────────────────────────────────────
    section("Step 3: Populate pan_number in kyc.kyc_master")
    kyc = connect_rw("kyc")
    updated_kyc = 0
    try:
        with kyc.cursor() as cur:
            for customer_id, pan_number in records:
                cur.execute(
                    "UPDATE kyc_master SET pan_number = %s "
                    "WHERE customer_id = %s",
                    (pan_number, customer_id),
                )
                updated_kyc += cur.rowcount
        kyc.commit()
        print(f"  OK — updated {updated_kyc} rows in kyc.kyc_master")
    except Exception as e:
        kyc.rollback()
        print(f"  ERROR: {e}")
        raise
    finally:
        kyc.close()

    section("Done")
    print("  PAN numbers populated in CRM and KYC.")
    print("  Next: update get_identity_resolution_map() in tools/agent_tools.py")
    print("        to resolve CRM and KYC via pan_number instead of customer_id.")


if __name__ == "__main__":
    main()
