"""
Seed script -- Scenario 14: Well-diversified but suboptimal returns.
Customer: Vikram Anand Krishnan (CUST000011)
Run from project root: python scenarios/seed_scenario_14.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import psycopg2
from config.settings import DB_CONFIGS

# ── helpers ──────────────────────────────────────────────────────────────────

def connect_rw(db_name: str):
    cfg = DB_CONFIGS[db_name]
    conn = psycopg2.connect(
        host=cfg["host"], port=cfg["port"], user=cfg["user"],
        password=cfg["password"], dbname=cfg["dbname"], connect_timeout=10
    )
    conn.autocommit = False
    return conn

def run(conn, sql: str, params: tuple = ()):
    with conn.cursor() as cur:
        cur.execute(sql, params)

def section(name: str):
    print(f"\n{'-'*55}")
    print(f"  {name}")
    print(f"{'-'*55}")


# ── CBS ───────────────────────────────────────────────────────────────────────
# ID formats: customer_id=CUST000011, party_id=PARTY011(8), aadhaar_ref=56781244(8)
# address_id=ADDR011(7), account_id=ACC0000000011(13), liability_id=LIAB00000011(12)
# txn_id=TXN0000000011(13)

def seed_cbs():
    section("CBS -- customer, account, liability, transaction")
    conn = connect_rw("cbs")
    try:
        run(conn, """
            INSERT INTO customer_master
              (customer_id, party_id, full_name, dob, gender, nationality,
               mobile, email, pan_number, aadhaar_ref, address_id,
               relationship_manager_id, customer_since, segment_code, status)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (customer_id) DO NOTHING
        """, (
            "CUST000011", "PARTY011", "Vikram Anand Krishnan",
            "1979-08-14", "M", "Indian",
            "9876543210", "vikram.krishnan@email.com", "KABVK3579N",
            "56781255", "ADDR011", "RM002",
            "2016-11-10", "HNI", "ACTIVE",
        ))
        print("  OK customer_master -- CUST000011")

        run(conn, """
            INSERT INTO account_master
              (account_id, customer_id, account_type, currency,
               current_balance, available_balance, od_limit,
               status, open_date, branch_code)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id) DO NOTHING
        """, (
            "ACC0000000011", "CUST000011", "SAVINGS", "INR",
            500000.00, 500000.00, 0.00,
            "ACTIVE", "2016-11-10", "MUM001",
        ))
        print("  OK account_master -- ACC0000000011")

        run(conn, """
            INSERT INTO liability_accounts
              (liability_id, customer_id, liability_type,
               principal_amount, outstanding_balance, emi_amount,
               start_date, maturity_date, dpd_days, npa_flag)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (liability_id) DO NOTHING
        """, (
            "LIAB00000011", "CUST000011", "HOME_LOAN",
            5000000.00, 3200000.00, 42000.00,
            "2018-04-01", "2038-04-01", 0, False,
        ))
        print("  OK liability_accounts -- LIAB00000011")

        run(conn, """
            INSERT INTO transaction_history
              (txn_id, account_id, txn_date, txn_type, amount, currency,
               channel, counterparty_name, counterparty_account,
               narration, balance_after)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (txn_id) DO NOTHING
        """, (
            "TXN0000000011", "ACC0000000011", "2024-03-01", "CREDIT",
            291667.00, "INR", "NEFT",
            "Krishnan Consulting Services LLP", "HDFC0099876",
            "Monthly consulting fee Mar 2024", 791667.00,
        ))
        print("  OK transaction_history -- TXN0000000011")

        conn.commit()
        print("  CBS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in CBS: {e}")
        raise
    finally:
        conn.close()


# ── CRM ───────────────────────────────────────────────────────────────────────
# ID formats: client_id=CLI000011, pref_id=PREF00000011(12), interaction_id=INT0000000011(13)

def seed_crm():
    section("CRM -- client_profile, preferences, interaction")
    conn = connect_rw("crm")
    try:
        run(conn, """
            INSERT INTO client_profile
              (client_id, customer_id, segment, sub_segment, rm_id,
               onboarding_date, investment_experience, risk_appetite_stated,
               preferred_language, referral_source, aum_band,
               last_review_date, next_review_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (client_id) DO NOTHING
        """, (
            "CLI000011", "CUST000011", "HNI", "Senior Consultant", "RM002",
            "2016-11-10", "EXPERIENCED", "MODERATE",
            "English", "Referral - existing client", "50L-1Cr",
            "2023-04-01", "2024-04-01",
        ))
        print("  OK client_profile -- CLI000011")

        run(conn, """
            INSERT INTO client_preferences
              (pref_id, client_id, goal_type, time_horizon,
               liquidity_need, excluded_sectors, esg_preference, last_updated)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (pref_id) DO NOTHING
        """, (
            "PREF00000011", "CLI000011", "WEALTH_GROWTH", "LONG",
            "LOW", None, False, "2023-04-01",
        ))
        print("  OK client_preferences -- PREF00000011")

        run(conn, """
            INSERT INTO interaction_log
              (interaction_id, client_id, interaction_date, channel, type,
               summary, sentiment_score, follow_up_flag, created_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (interaction_id) DO NOTHING
        """, (
            "INT0000000011", "CLI000011", "2024-03-15", "IN_PERSON", "REVIEW",
            "Annual portfolio review. Client comfortable with diversified allocation across "
            "equity, bonds, gold, and FD. No concerns raised. Discussion on performance "
            "against benchmark deferred to next meeting.",
            0.85, False, "RM002",
        ))
        print("  OK interaction_log -- INT0000000011")

        conn.commit()
        print("  CRM committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in CRM: {e}")
        raise
    finally:
        conn.close()


# ── KYC ───────────────────────────────────────────────────────────────────────
# ID formats: kyc_id=KYC000000011(12), doc_id=DOC000000011/012(12)
# screen_id=SCR000000011(12), risk_class_id=RCLASS00000011(14)

def seed_kyc():
    section("KYC -- kyc_master, identity_docs, pep_screening, risk_classification")
    conn = connect_rw("kyc")
    try:
        run(conn, """
            INSERT INTO kyc_master
              (kyc_id, pan_number, registered_name, dob,
               kyc_type, kyc_status, kyc_tier,
               verification_method, verified_date, expiry_date,
               re_kyc_due, verified_by, notes)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (kyc_id) DO NOTHING
        """, (
            "KYC000000011", "KABVK3579N", "Vikram Anand Krishnan", "1979-08-14",
            "IN_PERSON", "VERIFIED", "STANDARD",
            "DOCUMENT", "2016-11-10", "2026-11-10",
            "2026-11-10", "ComplianceOfficer_01",
            "KYC verified at branch. HNI segment. MODERATE risk. Clean profile.",
        ))
        print("  OK kyc_master -- KYC000000011")

        run(conn, """
            INSERT INTO identity_documents
              (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
               issue_date, expiry_date, doc_status, dms_ref)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (doc_id) DO NOTHING
        """, (
            "DOC000000011", "KYC000000011", "PAN", "KABVK3579N",
            "Income Tax Dept", "2005-03-15",
            "9999-12-31", "VALID", "DMS000000011",
        ))
        print("  OK identity_documents -- DOC000000011 (PAN)")

        run(conn, """
            INSERT INTO identity_documents
              (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
               issue_date, expiry_date, doc_status, dms_ref)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (doc_id) DO NOTHING
        """, (
            "DOC000000012", "KYC000000011", "AADHAAR", "56781255",
            "UIDAI", "2012-01-01",
            "9999-12-31", "VALID", "DMS000000012",
        ))
        print("  OK identity_documents -- DOC000000012 (Aadhaar)")

        run(conn, """
            INSERT INTO pep_screening
              (screen_id, kyc_id, screen_date, screen_type,
               pep_flag, pep_category, sanctions_list, sanctions_hit,
               adverse_media_hit, screened_by, next_review)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (screen_id) DO NOTHING
        """, (
            "SCR000000011", "KYC000000011", "2024-01-15", "PERIODIC",
            False, "NONE", "OFAC,UN,SEBI", "None",
            "None", "AutoScreen_v2", "2025-01-15",
        ))
        print("  OK pep_screening -- SCR000000011 (clean, no PEP)")

        run(conn, """
            INSERT INTO risk_classification
              (risk_class_id, kyc_id, risk_tier, risk_score,
               classification_date, classification_basis,
               override_flag, override_reason, reviewed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (risk_class_id) DO NOTHING
        """, (
            "RCLASS00000011", "KYC000000011", "LOW", 20.0,
            "2024-01-15",
            "Verified KYC, no PEP, no adverse media, no EDD cases, MODERATE risk appetite, stable income.",
            False, None, "ComplianceOfficer_01",
        ))
        print("  OK risk_classification -- RCLASS00000011 (LOW, score 20.0)")

        conn.commit()
        print("  KYC committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in KYC: {e}")
        raise
    finally:
        conn.close()


# ── PMS ───────────────────────────────────────────────────────────────────────
# benchmark_id=BM006, portfolio_id=PORT000011
# holding_id=HOLD0000000019-22, perf_id=PERF0000000021-26

def seed_pms():
    section("PMS -- benchmark BM006, portfolio, 4 holdings, 6 perf records")
    conn = connect_rw("pms")
    try:
        run(conn, """
            INSERT INTO benchmark_master
              (benchmark_id, benchmark_name, asset_class,
               index_provider, base_date, rebalance_freq, description)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (benchmark_id) DO NOTHING
        """, (
            "BM006", "CRISIL Multi-Asset Balanced Index",
            "HYBRID", "CRISIL", "2010-01-04", "QUARTERLY",
            "50% Nifty 50 TRI + 25% CRISIL Corporate Bond + 15% Gold + 10% Liquid/FD",
        ))
        print("  OK benchmark_master -- BM006")

        run(conn, """
            INSERT INTO portfolio_master
              (portfolio_id, client_id, portfolio_name, strategy_type,
               benchmark_id, inception_date, base_currency, aum, status, managed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (portfolio_id) DO NOTHING
        """, (
            "PORT000011", "CLI000011", "Vikram - Multi Asset Balanced",
            "BALANCED", "BM006", "2016-11-10", "INR",
            8500000.00, "ACTIVE", "FundManager_04",
        ))
        print("  OK portfolio_master -- PORT000011 (AUM Rs.85,00,000)")

        # IDs 19/20 were pre-occupied by earlier scenarios; using 21-24 for this portfolio.
        holdings = [
            # (holding_id, portfolio_id, isin, name, asset_class, sub_class,
            #  qty, avg_cost, cur_price, mkt_val, weight_pct, unrealised_pl)
            ("HOLD0000000023", "PORT000011", "INF179K01BR7",
             "HDFC Flexi Cap Fund - Regular Growth",
             "EQUITY", "Flexi Cap MF",
             22261.9, 168.00, 210.00, 4675000.00, 55.00, 935000.00),
            ("HOLD0000000024", "PORT000011", "INF109K01Z23",
             "ICICI Pru Corporate Bond Fund",
             "DEBT", "Corporate Bond MF",
             63729.0, 27.50, 29.34, 1870000.00, 22.00, 117261.00),
            ("HOLD0000000021", "PORT000011", "IN0020210174",
             "SGB 2021-22 Series IV",
             "GOLD", "Sovereign Gold Bond",
             207.32, 5850.00, 6150.00, 1275000.00, 15.00, 62196.00),
            ("HOLD0000000022", "PORT000011", "FD-SBI-20211201",
             "SBI Fixed Deposit (6.0% p.a.)",
             "CASH", "Bank Fixed Deposit",
             1.00, 680000.00, 680000.00, 680000.00, 8.00, 0.00),
        ]
        for h in holdings:
            run(conn, """
                INSERT INTO holdings
                  (holding_id, portfolio_id, isin, instrument_name, asset_class,
                   sub_class, quantity, avg_cost, current_price, market_value,
                   weight_pct, unrealised_pl)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (holding_id) DO NOTHING
            """, h)
        print("  OK holdings -- HOLD0000000021-24 (4 positions)")

        # 6 quarters of negative alpha -- all Sharpe < 1.0
        # (perf_id, portfolio_id, as_of_date, port_ret, bm_ret, alpha,
        #  tracking_err, sharpe, max_dd, volatility)
        perf_rows = [
            ("PERF0000000021", "PORT000011", "2024-03-31",  2.10,  5.80, -3.70, 3.20, 0.68, -4.50,  9.80),
            ("PERF0000000022", "PORT000011", "2023-12-31",  1.85,  4.20, -2.35, 2.80, 0.72, -3.80,  8.50),
            ("PERF0000000023", "PORT000011", "2023-09-30",  3.20,  6.10, -2.90, 3.10, 0.75, -5.20, 10.20),
            ("PERF0000000024", "PORT000011", "2023-06-30",  4.50,  7.20, -2.70, 2.90, 0.81, -3.10,  8.80),
            ("PERF0000000025", "PORT000011", "2023-03-31", -1.20,  1.40, -2.60, 3.50, 0.48, -6.80, 12.50),
            ("PERF0000000026", "PORT000011", "2022-12-31",  1.60,  3.50, -1.90, 2.60, 0.65, -4.20,  9.10),
        ]
        for p in perf_rows:
            run(conn, """
                INSERT INTO performance_history
                  (perf_id, portfolio_id, as_of_date, portfolio_return,
                   benchmark_return, alpha, tracking_error, sharpe_ratio,
                   max_drawdown, volatility)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (perf_id) DO NOTHING
            """, p)
        print("  OK performance_history -- PERF0000000021 to PERF0000000026")

        conn.commit()
        print("  PMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in PMS: {e}")
        raise
    finally:
        conn.close()


# ── CARD ──────────────────────────────────────────────────────────────────────
# ID formats: card_id=CARD00000011(12), agg_id=SAGG0000000011(14)
# pay_id=PAYB0000000011(14)

def seed_card():
    section("CARD -- card account, spend aggregates, payment behaviour")
    conn = connect_rw("card")
    try:
        run(conn, """
            INSERT INTO card_accounts
              (card_id, pan_number, cardholder_name, card_type, credit_limit, current_balance,
               available_limit, min_payment_due, payment_due_date,
               card_status, issue_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (card_id) DO NOTHING
        """, (
            "CARD00000011", "KABVK3579N", "Vikram Anand Krishnan", "GOLD",
            200000.00, 90000.00, 110000.00,
            9000.00, "2024-04-15", "ACTIVE", "2017-01-15",
        ))
        print("  OK card_accounts -- CARD00000011 (Gold, Rs.2L limit)")

        # Monthly spend ~Rs.90K; inferred annual = 90K x 12 x 3 = Rs.32.4L (within 30% of declared Rs.35L)
        agg_rows = [
            ("SAGG0000000011", "CARD00000011", "2024-03",
             90000.00, 15000.00, 12000.00, 35000.00, 8000.00, 0.00, 0.00, 2500.00),
            ("SAGG0000000012", "CARD00000011", "2024-02",
             88000.00, 14000.00, 11000.00, 34000.00, 9000.00, 0.00, 0.00, 2450.00),
            ("SAGG0000000013", "CARD00000011", "2024-01",
             92000.00, 16000.00, 13000.00, 35000.00, 8000.00, 0.00, 0.00, 2560.00),
        ]
        for a in agg_rows:
            run(conn, """
                INSERT INTO spend_aggregates
                  (agg_id, card_id, month_year, total_spend, travel_spend,
                   dining_spend, retail_spend, utility_spend,
                   emi_deductions, cash_advances, avg_txn_value)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (agg_id) DO NOTHING
            """, a)
        print("  OK spend_aggregates -- SAGG0000000011-13 (~Rs.90K/month, no cash advances)")

        pay_rows = [
            ("PAYB0000000011", "CARD00000011", "2024-03",
             90000.00, 90000.00, "2024-04-14", "FULL", 0, False),
            ("PAYB0000000012", "CARD00000011", "2024-02",
             88000.00, 88000.00, "2024-03-13", "FULL", 0, False),
            ("PAYB0000000013", "CARD00000011", "2024-01",
             92000.00, 92000.00, "2024-02-14", "FULL", 0, False),
        ]
        for p in pay_rows:
            run(conn, """
                INSERT INTO payment_behaviour
                  (pay_id, card_id, statement_month, amount_due, amount_paid,
                   payment_date, payment_type, days_late, dpd_flag)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (pay_id) DO NOTHING
            """, p)
        print("  OK payment_behaviour -- PAYB0000000011-13 (all FULL, 0 DPD)")

        conn.commit()
        print("  CARD committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in CARD: {e}")
        raise
    finally:
        conn.close()


# ── DMS ───────────────────────────────────────────────────────────────────────
# ID formats: dms_id=DMS000000011(12), proof_id=INCPR0000011(12)

def seed_dms():
    section("DMS -- document_repository, income_proofs")
    conn = connect_rw("dms")
    try:
        # PAN document (DMS000000021 — 011-013 were taken by other customers)
        run(conn, """
            INSERT INTO document_repository
              (dms_id, pan_number, applicant_name, doc_category, doc_type, file_name,
               upload_date, uploaded_by, file_size_kb, mime_type,
               storage_path, access_level)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (dms_id) DO NOTHING
        """, (
            "DMS000000021", "KABVK3579N", "Vikram Anand Krishnan", "IDENTITY", "PAN Card",
            "CUST000011_PAN_KABVK3579N.pdf",
            "2016-11-10", "OnboardingAgent", 110, "application/pdf",
            "cbs/cust000011/identity/", "INTERNAL",
        ))
        print("  OK document_repository -- DMS000000021 (PAN)")

        # Aadhaar document
        run(conn, """
            INSERT INTO document_repository
              (dms_id, pan_number, applicant_name, doc_category, doc_type, file_name,
               upload_date, uploaded_by, file_size_kb, mime_type,
               storage_path, access_level)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (dms_id) DO NOTHING
        """, (
            "DMS000000022", "KABVK3579N", "Vikram Anand Krishnan", "IDENTITY", "Aadhaar Card",
            "CUST000011_AADHAAR_masked.pdf",
            "2016-11-10", "OnboardingAgent", 95, "application/pdf",
            "cbs/cust000011/identity/", "INTERNAL",
        ))
        print("  OK document_repository -- DMS000000022 (Aadhaar)")

        # ITR document -- must be inserted before income_proofs (FK on dms_id)
        run(conn, """
            INSERT INTO document_repository
              (dms_id, pan_number, applicant_name, doc_category, doc_type, file_name,
               upload_date, uploaded_by, file_size_kb, mime_type,
               storage_path, access_level)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (dms_id) DO NOTHING
        """, (
            "DMS000000023", "KABVK3579N", "Vikram Anand Krishnan", "INCOME", "ITR Filing",
            "CUST000011_ITR_AY2023-24.pdf",
            "2023-11-15", "RM002", 850, "application/pdf",
            "cbs/cust000011/income/", "RESTRICTED",
        ))
        print("  OK document_repository -- DMS000000023 (ITR AY2023-24)")

        # income_proofs -- ITR FY2023-24: gross Rs.35L, net Rs.28L
        run(conn, """
            INSERT INTO income_proofs
              (proof_id, dms_id, proof_type, assessment_year,
               gross_income, net_income, employer_name,
               filing_date, extracted_by, extraction_confidence)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (proof_id) DO NOTHING
        """, (
            "INCPR0000011", "DMS000000023", "ITR", "2023-24",
            3500000.00, 2800000.00, "Krishnan Consulting Services LLP",
            "2023-11-15", "MANUAL", 0.95,
        ))
        print("  OK income_proofs -- INCPR0000011 (gross Rs.35L, net Rs.28L)")

        conn.commit()
        print("  DMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in DMS: {e}")
        raise
    finally:
        conn.close()


# ── main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("\n" + "="*55)
    print("  Seeding Scenario 14 -- CUST000011 Vikram Anand Krishnan")
    print("="*55)

    seed_cbs()
    seed_crm()
    seed_kyc()
    seed_pms()
    seed_card()
    seed_dms()

    print("\n" + "="*55)
    print("  All 6 databases seeded successfully.")
    print("="*55 + "\n")
