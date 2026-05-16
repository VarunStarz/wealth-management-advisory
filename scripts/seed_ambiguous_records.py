"""
Phase B — Introduce deliberate data ambiguity for entity resolution testing.

Three customers get corrupted identity attributes so the probabilistic engine
has to do real work (LLM arbitration for AMBIGUOUS tier):

  CUST000002  Priya Suresh Iyer    PAN BQCPI5678D
    → Card:   cardholder_name = "PRIYA S IYER",  pan_number = NULL
      Effect: no PAN block, middle name reduced to initial → Jaro-Winkler ≈ 0.94 → score 0.45 → AMBIGUOUS

  CUST000004  Anita Vijay Nair     PAN DSERT3456F
    → KYC:    registered_name = "Anitha Vijay Nair",  pan_number = NULL
      Effect: transliteration variant (Anita→Anitha), DOB exact → score ≈ 0.57 → AMBIGUOUS

  CUST000008  Deepika Rajan Pillai PAN HWIXC0123K
    → DMS:    applicant_name = "Deepika Pillai",  pan_number = NULL
      Effect: middle name dropped, no PAN → score ≈ 0.36 → AMBIGUOUS (low end)

Run from project root:
    python scripts/seed_ambiguous_records.py
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
    # ── 1. Card — CUST000002 (Priya Suresh Iyer, PAN BQCPI5678D) ────────────
    print("Card: introducing ambiguity for Priya Suresh Iyer (BQCPI5678D)...")
    card_conn = write_conn("card")
    card_cur  = card_conn.cursor()
    try:
        card_cur.execute(
            "SELECT card_id, pan_number, cardholder_name FROM card_accounts WHERE pan_number = %s",
            ("BQCPI5678D",)
        )
        row = card_cur.fetchone()
        if not row:
            print("  ERROR: card_accounts row for BQCPI5678D not found — skipping.")
        else:
            print(f"  Found card_id={row['card_id']}, current name={row['cardholder_name']!r}")
            card_cur.execute(
                "UPDATE card_accounts SET pan_number = NULL, cardholder_name = %s WHERE pan_number = %s",
                ("PRIYA S IYER", "BQCPI5678D")
            )
            print("  Set pan_number=NULL, cardholder_name='PRIYA S IYER'")
        card_conn.commit()
        print("  Card ambiguity committed.")
    except Exception as e:
        card_conn.rollback()
        print(f"  ERROR — rolled back: {e}")
        raise
    finally:
        card_cur.close()
        card_conn.close()

    # ── 2. KYC — CUST000004 (Anita Vijay Nair, PAN DSERT3456F) ─────────────
    print("\nKYC: introducing ambiguity for Anita Vijay Nair (DSERT3456F)...")
    kyc_conn = write_conn("kyc")
    kyc_cur  = kyc_conn.cursor()
    try:
        kyc_cur.execute(
            "SELECT kyc_id, pan_number, registered_name, dob FROM kyc_master WHERE pan_number = %s",
            ("DSERT3456F",)
        )
        row = kyc_cur.fetchone()
        if not row:
            print("  ERROR: kyc_master row for DSERT3456F not found — skipping.")
        else:
            print(f"  Found kyc_id={row['kyc_id']}, current name={row['registered_name']!r}, dob={row['dob']}")
            kyc_cur.execute(
                "UPDATE kyc_master SET pan_number = NULL, registered_name = %s WHERE pan_number = %s",
                ("Anitha Vijay Nair", "DSERT3456F")
            )
            print("  Set pan_number=NULL, registered_name='Anitha Vijay Nair'")
        kyc_conn.commit()
        print("  KYC ambiguity committed.")
    except Exception as e:
        kyc_conn.rollback()
        print(f"  ERROR — rolled back: {e}")
        raise
    finally:
        kyc_cur.close()
        kyc_conn.close()

    # ── 3. DMS — CUST000008 (Deepika Rajan Pillai, PAN HWIXC0123K) ──────────
    print("\nDMS: introducing ambiguity for Deepika Rajan Pillai (HWIXC0123K)...")
    dms_conn = write_conn("dms")
    dms_cur  = dms_conn.cursor()
    try:
        dms_cur.execute(
            "SELECT dms_id, pan_number, applicant_name FROM document_repository WHERE pan_number = %s",
            ("HWIXC0123K",)
        )
        rows = dms_cur.fetchall()
        if not rows:
            print("  ERROR: document_repository rows for HWIXC0123K not found — skipping.")
        else:
            print(f"  Found {len(rows)} DMS record(s) for HWIXC0123K:")
            for r in rows:
                print(f"    dms_id={r['dms_id']}, current name={r['applicant_name']!r}")
            # Update all records for this customer (all documents should reflect the abbreviated name)
            dms_cur.execute(
                "UPDATE document_repository SET pan_number = NULL, applicant_name = %s WHERE pan_number = %s",
                ("Deepika Pillai", "HWIXC0123K")
            )
            print(f"  Set pan_number=NULL, applicant_name='Deepika Pillai' on {len(rows)} record(s)")
        dms_conn.commit()
        print("  DMS ambiguity committed.")
    except Exception as e:
        dms_conn.rollback()
        print(f"  ERROR — rolled back: {e}")
        raise
    finally:
        dms_cur.close()
        dms_conn.close()

    # ── 4. Verify ─────────────────────────────────────────────────────────────
    print("\n-- Verification --")

    card_conn2 = write_conn("card")
    card_conn2.autocommit = True
    cur2 = card_conn2.cursor()
    cur2.execute("SELECT card_id, pan_number, cardholder_name FROM card_accounts WHERE cardholder_name = 'PRIYA S IYER'")
    rows = cur2.fetchall()
    print(f"Card  — rows with cardholder_name='PRIYA S IYER': {len(rows)}")
    for r in rows:
        print(f"  card_id={r['card_id']}, pan_number={r['pan_number']!r}")
    cur2.close(); card_conn2.close()

    kyc_conn2 = write_conn("kyc")
    kyc_conn2.autocommit = True
    cur3 = kyc_conn2.cursor()
    cur3.execute("SELECT kyc_id, pan_number, registered_name, dob FROM kyc_master WHERE registered_name = 'Anitha Vijay Nair'")
    rows = cur3.fetchall()
    print(f"KYC   — rows with registered_name='Anitha Vijay Nair': {len(rows)}")
    for r in rows:
        print(f"  kyc_id={r['kyc_id']}, pan_number={r['pan_number']!r}, dob={r['dob']}")
    cur3.close(); kyc_conn2.close()

    dms_conn2 = write_conn("dms")
    dms_conn2.autocommit = True
    cur4 = dms_conn2.cursor()
    cur4.execute("SELECT dms_id, pan_number, applicant_name FROM document_repository WHERE applicant_name = 'Deepika Pillai'")
    rows = cur4.fetchall()
    print(f"DMS   — rows with applicant_name='Deepika Pillai': {len(rows)}")
    for r in rows:
        print(f"  dms_id={r['dms_id']}, pan_number={r['pan_number']!r}")
    cur4.close(); dms_conn2.close()

    print("\nPhase B complete — ambiguity seeded in Card, KYC, DMS.")


if __name__ == "__main__":
    main()
