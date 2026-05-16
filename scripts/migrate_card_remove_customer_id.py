"""
Phase A Prerequisite — Card: Remove customer_id from card_accounts.

Entry point into the Card system after this migration: pan_number on card_accounts.
Child tables (card_transactions, spend_aggregates, payment_behaviour) are already
linked via card_id FK — no changes needed there.

Run from project root:
    python scripts/migrate_card_remove_customer_id.py
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
    conn = write_conn("card")
    cur  = conn.cursor()

    try:
        # Verify pan_number is fully populated before dropping customer_id
        cur.execute("SELECT COUNT(*) AS nulls FROM card_accounts WHERE pan_number IS NULL")
        nulls = cur.fetchone()["nulls"]
        if nulls:
            print(f"WARN: {nulls} card_accounts rows have NULL pan_number.")
            print("      These rows will lose their only cross-system identifier.")
            print("      Proceeding — ambiguity records will be seeded later.")

        print("card_accounts: dropping customer_id...")
        cur.execute("ALTER TABLE card_accounts DROP COLUMN customer_id")

        conn.commit()
        print("Card migration committed successfully.")

        # Verify
        cur.execute("SELECT COUNT(*) AS n, COUNT(pan_number) AS with_pan FROM card_accounts")
        row = cur.fetchone()
        print(f"Verification — card_accounts rows: {row['n']}, with pan_number: {row['with_pan']}")

    except Exception as e:
        conn.rollback()
        print(f"ERROR — rolled back: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
