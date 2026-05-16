"""
Phase A Migration — Card: Add cardholder_name to card_accounts.

cardholder_name: name embossed on the physical card — may differ from
CBS canonical name (abbreviation, middle name absent, initials).

Populated from CBS customer_master using the existing customer_id link
(run this BEFORE dropping customer_id from card_accounts).

Run from project root:
    python scripts/migrate_card_add_cardholder_name.py
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
    card_conn = write_conn("card")
    cbs_conn  = read_conn("cbs")
    card_cur  = card_conn.cursor()
    cbs_cur   = cbs_conn.cursor()

    try:
        # ── Step 1: Add column (idempotent) ─────────────────────────────
        print("Adding cardholder_name column to card_accounts...")
        card_cur.execute("""
            ALTER TABLE card_accounts
            ADD COLUMN IF NOT EXISTS cardholder_name VARCHAR(100)
        """)

        # ── Step 2: Fetch all card records with their customer_id ────────
        card_cur.execute("SELECT card_id, customer_id FROM card_accounts")
        card_rows = card_cur.fetchall()
        print(f"Found {len(card_rows)} card records to populate.")

        # ── Step 3: Cross-DB populate from CBS ───────────────────────────
        updated = 0
        skipped = 0
        for row in card_rows:
            card_id     = row["card_id"]
            customer_id = row["customer_id"]

            cbs_cur.execute(
                "SELECT full_name FROM customer_master WHERE customer_id = %s",
                (customer_id,)
            )
            cbs_row = cbs_cur.fetchone()

            if not cbs_row:
                print(f"  WARN: customer_id {customer_id} not found in CBS — skipping {card_id}")
                skipped += 1
                continue

            card_cur.execute(
                "UPDATE card_accounts SET cardholder_name = %s WHERE card_id = %s",
                (cbs_row["full_name"], card_id)
            )
            updated += 1

        # ── Step 4: Commit ───────────────────────────────────────────────
        card_conn.commit()
        print(f"\nDone. Updated: {updated}  Skipped: {skipped}")

        # ── Step 5: Verify ───────────────────────────────────────────────
        card_cur.execute(
            "SELECT COUNT(*) AS total, COUNT(cardholder_name) AS with_name FROM card_accounts"
        )
        stats = card_cur.fetchone()
        print(f"Verification — total rows: {stats['total']}, "
              f"with cardholder_name: {stats['with_name']}")

    except Exception as e:
        card_conn.rollback()
        print(f"ERROR: {e}")
        raise
    finally:
        card_cur.close()
        cbs_cur.close()
        card_conn.close()
        cbs_conn.close()


if __name__ == "__main__":
    main()
