"""
Seed script -- CUST000011 data-quality fixes + Scenarios 15, 16, 17.

  Fix  : CUST000011 -- benchmark BM008, identity docs, DMS docs, income proof, spend aggregates
  Sc15 : Prateek Anand Mathur    (CUST000012) -- NSE employee, equity-restricted INCOME portfolio
  Sc16 : Sneha Anand Varma       (CUST000013) -- conservative portfolio, client requests aggressive shift
  Sc17 : Rohit Suresh Kapoor     (CUST000014) -- aggressive portfolio, FY2022-23 heavy losses, wants conservative

Run from project root: python scenarios/seed_scenarios_15_16_17.py
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import psycopg2
from config.settings import DB_CONFIGS


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
    print(f"\n{'-'*60}")
    print(f"  {name}")
    print(f"{'-'*60}")


# ===========================================================================
# SECTION 0 -- CUST000011 data-quality fixes
# ===========================================================================

def fix_cust000011_pms():
    section("FIX: PMS -- BM008 + update PORT000011 benchmark")
    conn = connect_rw("pms")
    try:
        run(conn, """
            INSERT INTO benchmark_master
              (benchmark_id, benchmark_name, asset_class,
               index_provider, base_date, rebalance_freq, description)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (benchmark_id) DO NOTHING
        """, (
            "BM008", "CRISIL Multi-Asset Balanced Index",
            "HYBRID", "CRISIL", "2010-01-04", "QUARTERLY",
            "50% Nifty 50 TRI + 25% CRISIL Corporate Bond + 15% Gold + 10% Liquid/FD",
        ))
        print("  OK benchmark_master -- BM008")

        run(conn, """
            UPDATE portfolio_master SET benchmark_id = %s
            WHERE portfolio_id = %s AND benchmark_id != %s
        """, ("BM008", "PORT000011", "BM008"))
        print("  OK portfolio_master -- PORT000011 benchmark set to BM008")

        conn.commit()
        print("  PMS fix committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in PMS fix: {e}")
        raise
    finally:
        conn.close()


def fix_cust000011_dms():
    section("FIX: DMS -- insert DMS000000021-023 for CUST000011, fix income proof FK")
    conn = connect_rw("dms")
    try:
        docs = [
            ("DMS000000021", "CUST000011", "IDENTITY", "PAN Card",
             "CUST000011_PAN_KABVK3579N.pdf",
             "2016-11-10", "OnboardingAgent", 110, "application/pdf",
             "cbs/cust000011/identity/", "INTERNAL"),
            ("DMS000000022", "CUST000011", "IDENTITY", "Aadhaar Card",
             "CUST000011_AADHAAR_masked.pdf",
             "2016-11-10", "OnboardingAgent", 95, "application/pdf",
             "cbs/cust000011/identity/", "INTERNAL"),
            ("DMS000000023", "CUST000011", "INCOME", "ITR Filing",
             "CUST000011_ITR_AY2023-24.pdf",
             "2023-11-15", "RM002", 850, "application/pdf",
             "cbs/cust000011/income/", "RESTRICTED"),
        ]
        for d in docs:
            run(conn, """
                INSERT INTO document_repository
                  (dms_id, customer_id, doc_category, doc_type, file_name,
                   upload_date, uploaded_by, file_size_kb, mime_type,
                   storage_path, access_level)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (dms_id) DO NOTHING
            """, d)
            print(f"  OK document_repository -- {d[0]} ({d[3]})")

        run(conn, """
            UPDATE income_proofs SET dms_id = %s
            WHERE proof_id = %s AND dms_id != %s
        """, ("DMS000000023", "INCPR0000011", "DMS000000023"))
        print("  OK income_proofs -- INCPR0000011 dms_id corrected to DMS000000023")

        conn.commit()
        print("  DMS fix committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in DMS fix: {e}")
        raise
    finally:
        conn.close()


def fix_cust000011_kyc():
    section("FIX: KYC -- insert DOC000000015/016 for KYC000000011")
    conn = connect_rw("kyc")
    try:
        id_docs = [
            ("DOC000000015", "KYC000000011", "PAN", "KABVK3579N",
             "Income Tax Dept", "2005-03-15", "9999-12-31", "VALID", "DMS000000021"),
            ("DOC000000016", "KYC000000011", "AADHAAR", "56781255",
             "UIDAI", "2012-01-01", "9999-12-31", "VALID", "DMS000000022"),
        ]
        for d in id_docs:
            run(conn, """
                INSERT INTO identity_documents
                  (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
                   issue_date, expiry_date, doc_status, dms_ref)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (doc_id) DO NOTHING
            """, d)
            print(f"  OK identity_documents -- {d[0]} ({d[2]})")

        conn.commit()
        print("  KYC fix committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in KYC fix: {e}")
        raise
    finally:
        conn.close()


def fix_cust000011_card():
    section("FIX: CARD -- delete extra spend aggregates for CUST000011")
    conn = connect_rw("card")
    try:
        run(conn, """
            DELETE FROM spend_aggregates
            WHERE agg_id IN ('SAGG0000000012', 'SAGG0000000013')
        """)
        print("  OK spend_aggregates -- deleted SAGG0000000012, SAGG0000000013 (kept SAGG0000000011 only)")

        conn.commit()
        print("  CARD fix committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in CARD fix: {e}")
        raise
    finally:
        conn.close()


# ===========================================================================
# SECTION 1 -- Scenario 15: CUST000012 Prateek Anand Mathur (NSE Employee)
# ===========================================================================

def seed_sc15_cbs():
    section("SC15 CBS -- CUST000012 Prateek Anand Mathur")
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
            "CUST000012", "PARTY012", "Prateek Anand Mathur",
            "1985-06-15", "M", "Indian",
            "9876543212", "prateek.mathur@nseindia.com", "BKPMA5512L",
            "76543210", "ADDR012", "RM003",
            "2019-03-10", "HNI", "ACTIVE",
        ))
        print("  OK customer_master -- CUST000012")

        run(conn, """
            INSERT INTO account_master
              (account_id, customer_id, account_type, currency,
               current_balance, available_balance, od_limit,
               status, open_date, branch_code)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id) DO NOTHING
        """, (
            "ACC0000000014", "CUST000012", "SAVINGS", "INR",
            850000.00, 850000.00, 0.00,
            "ACTIVE", "2019-03-10", "DEL001",
        ))
        print("  OK account_master -- ACC0000000014")

        run(conn, """
            INSERT INTO liability_accounts
              (liability_id, customer_id, liability_type,
               principal_amount, outstanding_balance, emi_amount,
               start_date, maturity_date, dpd_days, npa_flag)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (liability_id) DO NOTHING
        """, (
            "LIAB00000012", "CUST000012", "HOME_LOAN",
            5000000.00, 3500000.00, 42000.00,
            "2020-06-01", "2040-06-01", 0, False,
        ))
        print("  OK liability_accounts -- LIAB00000012")

        run(conn, """
            INSERT INTO transaction_history
              (txn_id, account_id, txn_date, txn_type, amount, currency,
               channel, counterparty_name, counterparty_account,
               narration, balance_after)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (txn_id) DO NOTHING
        """, (
            "TXN0000000016", "ACC0000000014", "2025-04-01", "CREDIT",
            145000.00, "INR", "NEFT",
            "NSE Securities India Ltd", "HDFC0001122",
            "Salary credit Apr 2025 - NSE", 995000.00,
        ))
        print("  OK transaction_history -- TXN0000000016")

        conn.commit()
        print("  SC15 CBS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 CBS: {e}")
        raise
    finally:
        conn.close()


def seed_sc15_crm():
    section("SC15 CRM -- CLI000012")
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
            "CLI000012", "CUST000012", "HNI", "NSE Senior Analyst", "RM003",
            "2019-03-10", "EXPERIENCED", "CONSERVATIVE",
            "English", "Direct - Walk-in", "50L-1Cr",
            "2024-09-15", "2025-09-15",
        ))
        print("  OK client_profile -- CLI000012")

        run(conn, """
            INSERT INTO client_preferences
              (pref_id, client_id, goal_type, time_horizon,
               liquidity_need, excluded_sectors, esg_preference, last_updated)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (pref_id) DO NOTHING
        """, (
            "PREF00000012", "CLI000012", "INCOME_GENERATION", "LONG",
            "MEDIUM",
            "EQUITY - SEBI PFUTP Insider Trading Prevention (NSE Employee)",
            False, "2024-09-15",
        ))
        print("  OK client_preferences -- PREF00000012 (equity excluded)")

        run(conn, """
            INSERT INTO interaction_log
              (interaction_id, client_id, interaction_date, channel, type,
               summary, sentiment_score, follow_up_flag, created_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (interaction_id) DO NOTHING
        """, (
            "INT0000000012", "CLI000012", "2024-09-15", "IN_PERSON", "REVIEW",
            "Compliance review. Prateek confirmed continued employment at NSE. "
            "Per SEBI PFUTP Regulations 2003, equity investments in NSE-listed securities "
            "are prohibited. Portfolio restricted to Debt MFs, Sovereign Gold Bonds, "
            "and Government Securities. Compliance restriction confirmed active. "
            "Client satisfied with INCOME strategy performance.",
            0.78, False, "RM003",
        ))
        print("  OK interaction_log -- INT0000000012 (compliance review)")

        conn.commit()
        print("  SC15 CRM committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 CRM: {e}")
        raise
    finally:
        conn.close()


def seed_sc15_kyc():
    section("SC15 KYC -- KYC000000012")
    conn = connect_rw("kyc")
    try:
        run(conn, """
            INSERT INTO kyc_master
              (kyc_id, customer_id, kyc_type, kyc_status, kyc_tier,
               verification_method, verified_date, expiry_date,
               re_kyc_due, verified_by, notes)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (kyc_id) DO NOTHING
        """, (
            "KYC000000012", "CUST000012", "IN_PERSON", "VERIFIED", "STANDARD",
            "DOCUMENT", "2019-03-10", "2029-03-10",
            "2027-03-10", "ComplianceOfficer_01",
            "NSE employee -- SEBI PFUTP Regulations 2003. All equity investments in "
            "NSE-listed securities prohibited. Portfolio limited to Debt/Gold/Govt Bonds. "
            "Employer pre-clearance certificate on file.",
        ))
        print("  OK kyc_master -- KYC000000012")

        for doc in [
            ("DOC000000017", "KYC000000012", "PAN", "BKPMA5512L",
             "Income Tax Dept", "2008-07-20", "9999-12-31", "VALID", "DMS000000024"),
            ("DOC000000018", "KYC000000012", "AADHAAR", "76543210",
             "UIDAI", "2013-05-10", "9999-12-31", "VALID", "DMS000000025"),
        ]:
            run(conn, """
                INSERT INTO identity_documents
                  (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
                   issue_date, expiry_date, doc_status, dms_ref)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (doc_id) DO NOTHING
            """, doc)
            print(f"  OK identity_documents -- {doc[0]} ({doc[2]})")

        run(conn, """
            INSERT INTO pep_screening
              (screen_id, customer_id, screen_date, screen_type,
               pep_flag, pep_category, sanctions_list, sanctions_hit,
               adverse_media_hit, screened_by, next_review)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (screen_id) DO NOTHING
        """, (
            "SCR000000012", "CUST000012", "2024-09-15", "PERIODIC",
            False, "NONE", "OFAC,UN,SEBI", "None",
            "None", "AutoScreen_v2", "2025-09-15",
        ))
        print("  OK pep_screening -- SCR000000012 (clear)")

        run(conn, """
            INSERT INTO risk_classification
              (risk_class_id, customer_id, risk_tier, risk_score,
               classification_date, classification_basis,
               override_flag, override_reason, reviewed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (risk_class_id) DO NOTHING
        """, (
            "RCLASS00000012", "CUST000012", "LOW", 15.0,
            "2024-09-15",
            "Verified KYC, no PEP, no adverse media, CONSERVATIVE risk appetite. "
            "Compliance restriction (SEBI PFUTP) actively managed. Stable salaried income.",
            False, None, "ComplianceOfficer_01",
        ))
        print("  OK risk_classification -- RCLASS00000012 (LOW, 15.0)")

        conn.commit()
        print("  SC15 KYC committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 KYC: {e}")
        raise
    finally:
        conn.close()


def seed_sc15_pms():
    section("SC15 PMS -- BM009, PORT000012, 4 holdings, 6 perf records")
    conn = connect_rw("pms")
    try:
        run(conn, """
            INSERT INTO benchmark_master
              (benchmark_id, benchmark_name, asset_class,
               index_provider, base_date, rebalance_freq, description)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (benchmark_id) DO NOTHING
        """, (
            "BM009", "CRISIL Conservative Credit Risk Index",
            "DEBT", "CRISIL", "2012-04-01", "MONTHLY",
            "75% CRISIL Corporate Bond + 15% Sovereign Gold + 10% Overnight/Liquid",
        ))
        print("  OK benchmark_master -- BM009")

        run(conn, """
            INSERT INTO portfolio_master
              (portfolio_id, client_id, portfolio_name, strategy_type,
               benchmark_id, inception_date, base_currency, aum, status, managed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (portfolio_id) DO NOTHING
        """, (
            "PORT000012", "CLI000012", "Prateek - Compliance INCOME Portfolio",
            "INCOME", "BM009", "2019-04-01", "INR",
            9500000.00, "ACTIVE", "FundManager_03",
        ))
        print("  OK portfolio_master -- PORT000012 (AUM Rs.95,00,000)")

        # 4 holdings -- DEBT/GOLD/FIXED_INCOME/CASH only (no equity -- NSE compliance)
        # HOLD0000000025-028
        holdings = [
            ("HOLD0000000025", "PORT000012", "INF109K01AH9",
             "ICICI Pru Credit Risk Fund - Direct Growth",
             "DEBT", "Credit Risk MF",
             1459375.0, 29.13, 29.13, 4253906.00, 44.78, 0.00),
            ("HOLD0000000026", "PORT000012", "IN0020220120",
             "SGB 2022-23 Series III",
             "GOLD", "Sovereign Gold Bond",
             259.74, 5525.00, 7300.00, 1896102.00, 19.96, 461031.00),
            ("HOLD0000000027", "PORT000012", "IN0020130025",
             "RBI 7.26% Savings Bond 2032",
             "DEBT", "Govt Bond",
             237500.0, 100.00, 100.00, 2375000.00, 25.00, 0.00),
            ("HOLD0000000028", "PORT000012", "INF179K01XE2",
             "HDFC Short Duration Fund - Direct Growth",
             "CASH", "Short Duration MF",
             438000.0, 21.46, 21.46, 940148.00, 9.90, 0.00),
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
        print("  OK holdings -- HOLD0000000025-028 (4 positions, no equity)")

        # 6 quarters -- slight underperformance vs benchmark, Sharpe > 1.0 (stable income)
        # (perf_id, portfolio_id, as_of_date, port_ret, bm_ret, alpha,
        #  tracking_err, sharpe, max_dd, volatility)
        perf_rows = [
            ("PERF0000000027", "PORT000012", "2023-09-30", 3.90, 4.20, -0.30, 0.80, 1.42, -1.20, 2.10),
            ("PERF0000000028", "PORT000012", "2023-12-31", 3.60, 3.90, -0.30, 0.75, 1.38, -1.10, 2.00),
            ("PERF0000000029", "PORT000012", "2024-03-31", 4.20, 4.50, -0.30, 0.82, 1.45, -1.30, 2.20),
            ("PERF0000000030", "PORT000012", "2024-06-30", 3.80, 4.10, -0.30, 0.78, 1.40, -1.15, 2.05),
            ("PERF0000000031", "PORT000012", "2024-09-30", 4.40, 4.70, -0.30, 0.85, 1.50, -1.20, 2.15),
            ("PERF0000000032", "PORT000012", "2024-12-31", 3.70, 4.00, -0.30, 0.80, 1.38, -1.10, 2.00),
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
        print("  OK performance_history -- PERF0000000027-032")

        conn.commit()
        print("  SC15 PMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 PMS: {e}")
        raise
    finally:
        conn.close()


def seed_sc15_card():
    section("SC15 CARD -- CARD00000012")
    conn = connect_rw("card")
    try:
        run(conn, """
            INSERT INTO card_accounts
              (card_id, customer_id, card_type, credit_limit, current_balance,
               available_limit, min_payment_due, payment_due_date,
               card_status, issue_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (card_id) DO NOTHING
        """, (
            "CARD00000012", "CUST000012", "GOLD",
            200000.00, 50000.00, 150000.00,
            5000.00, "2025-05-10", "ACTIVE", "2019-04-01",
        ))
        print("  OK card_accounts -- CARD00000012 (Gold, Rs.2L limit)")

        # 1 row only -- inferred annual income = 50K x 12 x 3 = Rs.18L (matches declared Rs.18L)
        run(conn, """
            INSERT INTO spend_aggregates
              (agg_id, card_id, month_year, total_spend, travel_spend,
               dining_spend, retail_spend, utility_spend,
               emi_deductions, cash_advances, avg_txn_value)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (agg_id) DO NOTHING
        """, (
            "SAGG0000000014", "CARD00000012", "2025-03",
            50000.00, 8000.00, 5000.00, 15000.00, 10000.00, 0.00, 0.00, 2000.00,
        ))
        print("  OK spend_aggregates -- SAGG0000000014 (Rs.50K/month, no cash advances)")

        pay_rows = [
            ("PAYB0000000014", "CARD00000012", "2025-03",
             50000.00, 50000.00, "2025-04-09", "FULL", 0, False),
            ("PAYB0000000015", "CARD00000012", "2025-02",
             48000.00, 48000.00, "2025-03-09", "FULL", 0, False),
            ("PAYB0000000016", "CARD00000012", "2025-01",
             52000.00, 52000.00, "2025-02-09", "FULL", 0, False),
        ]
        for p in pay_rows:
            run(conn, """
                INSERT INTO payment_behaviour
                  (pay_id, card_id, statement_month, amount_due, amount_paid,
                   payment_date, payment_type, days_late, dpd_flag)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (pay_id) DO NOTHING
            """, p)
        print("  OK payment_behaviour -- PAYB0000000014-016 (all FULL, 0 DPD)")

        conn.commit()
        print("  SC15 CARD committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 CARD: {e}")
        raise
    finally:
        conn.close()


def seed_sc15_dms():
    section("SC15 DMS -- DMS000000024-026, INCPR0000012")
    conn = connect_rw("dms")
    try:
        docs = [
            ("DMS000000024", "CUST000012", "IDENTITY", "PAN Card",
             "CUST000012_PAN_BKPMA5512L.pdf",
             "2019-03-10", "OnboardingAgent", 112, "application/pdf",
             "cbs/cust000012/identity/", "INTERNAL"),
            ("DMS000000025", "CUST000012", "IDENTITY", "Aadhaar Card",
             "CUST000012_AADHAAR_masked.pdf",
             "2019-03-10", "OnboardingAgent", 98, "application/pdf",
             "cbs/cust000012/identity/", "INTERNAL"),
            ("DMS000000026", "CUST000012", "INCOME", "ITR Filing",
             "CUST000012_ITR_AY2024-25.pdf",
             "2024-11-10", "RM003", 760, "application/pdf",
             "cbs/cust000012/income/", "RESTRICTED"),
        ]
        for d in docs:
            run(conn, """
                INSERT INTO document_repository
                  (dms_id, customer_id, doc_category, doc_type, file_name,
                   upload_date, uploaded_by, file_size_kb, mime_type,
                   storage_path, access_level)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (dms_id) DO NOTHING
            """, d)
            print(f"  OK document_repository -- {d[0]} ({d[3]})")

        run(conn, """
            INSERT INTO income_proofs
              (proof_id, dms_id, customer_id, proof_type, assessment_year,
               gross_income, net_income, employer_name,
               filing_date, extracted_by, extraction_confidence)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (proof_id) DO NOTHING
        """, (
            "INCPR0000012", "DMS000000026", "CUST000012", "ITR", "2024-25",
            1800000.00, 1320000.00, "NSE Securities India Ltd",
            "2024-11-10", "MANUAL", 0.97,
        ))
        print("  OK income_proofs -- INCPR0000012 (gross Rs.18L, net Rs.13.2L)")

        conn.commit()
        print("  SC15 DMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC15 DMS: {e}")
        raise
    finally:
        conn.close()


# ===========================================================================
# SECTION 2 -- Scenario 16: CUST000013 Sneha Anand Varma (Conservative -> Aggressive)
# ===========================================================================

def seed_sc16_cbs():
    section("SC16 CBS -- CUST000013 Sneha Anand Varma")
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
            "CUST000013", "PARTY013", "Sneha Anand Varma",
            "1982-11-20", "F", "Indian",
            "9876543213", "sneha.varma@snehavarma.in", "CLPSV7723K",
            "86543210", "ADDR013", "RM001",
            "2017-07-22", "HNI", "ACTIVE",
        ))
        print("  OK customer_master -- CUST000013")

        run(conn, """
            INSERT INTO account_master
              (account_id, customer_id, account_type, currency,
               current_balance, available_balance, od_limit,
               status, open_date, branch_code)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id) DO NOTHING
        """, (
            "ACC0000000015", "CUST000013", "SAVINGS", "INR",
            1250000.00, 1250000.00, 0.00,
            "ACTIVE", "2017-07-22", "BLR001",
        ))
        print("  OK account_master -- ACC0000000015")

        # No liability -- conservative, debt-free profile
        run(conn, """
            INSERT INTO transaction_history
              (txn_id, account_id, txn_date, txn_type, amount, currency,
               channel, counterparty_name, counterparty_account,
               narration, balance_after)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (txn_id) DO NOTHING
        """, (
            "TXN0000000017", "ACC0000000015", "2025-04-01", "CREDIT",
            220000.00, "INR", "NEFT",
            "Varma Advisory Services LLP", "ICIC0098765",
            "Business income credit Apr 2025", 1470000.00,
        ))
        print("  OK transaction_history -- TXN0000000017")

        conn.commit()
        print("  SC16 CBS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 CBS: {e}")
        raise
    finally:
        conn.close()


def seed_sc16_crm():
    section("SC16 CRM -- CLI000013")
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
            "CLI000013", "CUST000013", "HNI", "Boutique Consulting Owner", "RM001",
            "2017-07-22", "EXPERIENCED", "CONSERVATIVE",
            "English", "Referral - existing client", "1Cr-5Cr",
            "2025-01-20", "2026-01-20",
        ))
        print("  OK client_profile -- CLI000013")

        run(conn, """
            INSERT INTO client_preferences
              (pref_id, client_id, goal_type, time_horizon,
               liquidity_need, excluded_sectors, esg_preference, last_updated)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (pref_id) DO NOTHING
        """, (
            "PREF00000013", "CLI000013", "WEALTH_GROWTH", "LONG",
            "LOW", None, True, "2025-01-20",
        ))
        print("  OK client_preferences -- PREF00000013")

        run(conn, """
            INSERT INTO interaction_log
              (interaction_id, client_id, interaction_date, channel, type,
               summary, sentiment_score, follow_up_flag, created_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (interaction_id) DO NOTHING
        """, (
            "INT0000000013", "CLI000013", "2025-01-20", "IN_PERSON", "REVIEW",
            "Annual review. Sneha's conservative portfolio is performing well -- positive "
            "alpha across 6 consecutive quarters. However, client has EXPLICITLY REQUESTED "
            "a shift to aggressive growth strategy. States she has a 10-year horizon and "
            "is willing to accept higher volatility for higher returns. Current on-record "
            "risk appetite is CONSERVATIVE. Formal suitability re-assessment required "
            "before any rebalancing. RM to initiate behavioural risk profiling questionnaire.",
            0.88, True, "RM001",
        ))
        print("  OK interaction_log -- INT0000000013 (aggressive shift requested)")

        conn.commit()
        print("  SC16 CRM committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 CRM: {e}")
        raise
    finally:
        conn.close()


def seed_sc16_kyc():
    section("SC16 KYC -- KYC000000013")
    conn = connect_rw("kyc")
    try:
        run(conn, """
            INSERT INTO kyc_master
              (kyc_id, customer_id, kyc_type, kyc_status, kyc_tier,
               verification_method, verified_date, expiry_date,
               re_kyc_due, verified_by, notes)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (kyc_id) DO NOTHING
        """, (
            "KYC000000013", "CUST000013", "IN_PERSON", "VERIFIED", "STANDARD",
            "DOCUMENT", "2017-07-22", "2027-07-22",
            "2027-07-22", "ComplianceOfficer_02",
            "Long-standing HNI client. Conservative investor. KYC current. "
            "Suitability review in progress following client request to upgrade risk appetite.",
        ))
        print("  OK kyc_master -- KYC000000013")

        for doc in [
            ("DOC000000019", "KYC000000013", "PAN", "CLPSV7723K",
             "Income Tax Dept", "2006-08-15", "9999-12-31", "VALID", "DMS000000027"),
            ("DOC000000020", "KYC000000013", "AADHAAR", "86543210",
             "UIDAI", "2014-02-28", "9999-12-31", "VALID", "DMS000000028"),
        ]:
            run(conn, """
                INSERT INTO identity_documents
                  (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
                   issue_date, expiry_date, doc_status, dms_ref)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (doc_id) DO NOTHING
            """, doc)
            print(f"  OK identity_documents -- {doc[0]} ({doc[2]})")

        run(conn, """
            INSERT INTO pep_screening
              (screen_id, customer_id, screen_date, screen_type,
               pep_flag, pep_category, sanctions_list, sanctions_hit,
               adverse_media_hit, screened_by, next_review)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (screen_id) DO NOTHING
        """, (
            "SCR000000013", "CUST000013", "2025-01-20", "PERIODIC",
            False, "NONE", "OFAC,UN,SEBI", "None",
            "None", "AutoScreen_v2", "2026-01-20",
        ))
        print("  OK pep_screening -- SCR000000013 (clear)")

        run(conn, """
            INSERT INTO risk_classification
              (risk_class_id, customer_id, risk_tier, risk_score,
               classification_date, classification_basis,
               override_flag, override_reason, reviewed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (risk_class_id) DO NOTHING
        """, (
            "RCLASS00000013", "CUST000013", "LOW", 18.0,
            "2025-01-20",
            "Verified KYC, no PEP, no adverse media. CONSERVATIVE risk appetite on record. "
            "Stable business income. Suitability re-assessment pending client's request "
            "to upgrade to aggressive strategy.",
            False, None, "ComplianceOfficer_02",
        ))
        print("  OK risk_classification -- RCLASS00000013 (LOW, 18.0)")

        conn.commit()
        print("  SC16 KYC committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 KYC: {e}")
        raise
    finally:
        conn.close()


def seed_sc16_pms():
    section("SC16 PMS -- BM010, PORT000013, 4 holdings, 6 perf records")
    conn = connect_rw("pms")
    try:
        run(conn, """
            INSERT INTO benchmark_master
              (benchmark_id, benchmark_name, asset_class,
               index_provider, base_date, rebalance_freq, description)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (benchmark_id) DO NOTHING
        """, (
            "BM010", "CRISIL Hybrid 85+15 Conservative Index",
            "HYBRID", "CRISIL", "2011-06-01", "QUARTERLY",
            "85% CRISIL Composite Bond + 15% Nifty 50 TRI -- conservative blend",
        ))
        print("  OK benchmark_master -- BM010")

        run(conn, """
            INSERT INTO portfolio_master
              (portfolio_id, client_id, portfolio_name, strategy_type,
               benchmark_id, inception_date, base_currency, aum, status, managed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (portfolio_id) DO NOTHING
        """, (
            "PORT000013", "CLI000013", "Sneha - Conservative Growth Portfolio",
            "CONSERVATIVE", "BM010", "2017-08-01", "INR",
            12000000.00, "ACTIVE", "FundManager_01",
        ))
        print("  OK portfolio_master -- PORT000013 (AUM Rs.1.2 Cr)")

        # 4 holdings -- conservative allocation (30% equity, 40% debt, 15% gold, 15% FD)
        # HOLD0000000029-032
        holdings = [
            ("HOLD0000000029", "PORT000013", "INF209K01HV6",
             "Mirae Asset Large Cap Fund - Direct Growth",
             "EQUITY", "Large Cap MF",
             13636.0, 660.00, 880.00, 12000000.00 * 0.30, 30.00, 300000.00),
            ("HOLD0000000030", "PORT000013", "INF194K01HB7",
             "Kotak Corporate Bond Fund - Direct Growth",
             "DEBT", "Corporate Bond MF",
             1565217.0, 30.67, 30.67, 12000000.00 * 0.40, 40.00, 0.00),
            ("HOLD0000000031", "PORT000013", "IN0020220040",
             "SGB 2022-23 Series I",
             "GOLD", "Sovereign Gold Bond",
             219.18, 5510.00, 7300.00, 12000000.00 * 0.15, 15.00, 392422.00),
            ("HOLD0000000032", "PORT000013", "FD-HDFC-20230715",
             "HDFC Bank Fixed Deposit (6.8% p.a.)",
             "CASH", "Bank Fixed Deposit",
             1.00, 1800000.00, 1800000.00, 12000000.00 * 0.15, 15.00, 0.00),
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
        print("  OK holdings -- HOLD0000000029-032 (conservative allocation)")

        # 6 quarters -- healthy conservative portfolio, slight positive alpha, Sharpe > 1.4
        perf_rows = [
            ("PERF0000000033", "PORT000013", "2023-09-30",  3.20,  3.10, +0.10, 1.20, 1.45, -2.10,  3.20),
            ("PERF0000000034", "PORT000013", "2023-12-31",  4.10,  3.90, +0.20, 1.15, 1.55, -1.90,  3.10),
            ("PERF0000000035", "PORT000013", "2024-03-31",  3.80,  3.60, +0.20, 1.18, 1.48, -2.00,  3.15),
            ("PERF0000000036", "PORT000013", "2024-06-30",  3.50,  3.30, +0.20, 1.22, 1.42, -2.20,  3.25),
            ("PERF0000000037", "PORT000013", "2024-09-30",  4.20,  3.90, +0.30, 1.25, 1.58, -1.80,  3.10),
            ("PERF0000000038", "PORT000013", "2024-12-31",  3.90,  3.70, +0.20, 1.20, 1.50, -2.00,  3.20),
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
        print("  OK performance_history -- PERF0000000033-038")

        conn.commit()
        print("  SC16 PMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 PMS: {e}")
        raise
    finally:
        conn.close()


def seed_sc16_card():
    section("SC16 CARD -- CARD00000013")
    conn = connect_rw("card")
    try:
        run(conn, """
            INSERT INTO card_accounts
              (card_id, customer_id, card_type, credit_limit, current_balance,
               available_limit, min_payment_due, payment_due_date,
               card_status, issue_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (card_id) DO NOTHING
        """, (
            "CARD00000013", "CUST000013", "PLATINUM",
            300000.00, 78000.00, 222000.00,
            7800.00, "2025-05-12", "ACTIVE", "2018-01-10",
        ))
        print("  OK card_accounts -- CARD00000013 (Platinum, Rs.3L limit)")

        # 1 row -- inferred annual = 78K x 12 x 3 = Rs.28.08L (matches declared Rs.28L)
        run(conn, """
            INSERT INTO spend_aggregates
              (agg_id, card_id, month_year, total_spend, travel_spend,
               dining_spend, retail_spend, utility_spend,
               emi_deductions, cash_advances, avg_txn_value)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (agg_id) DO NOTHING
        """, (
            "SAGG0000000015", "CARD00000013", "2025-03",
            78000.00, 12000.00, 8000.00, 28000.00, 14000.00, 0.00, 0.00, 3200.00,
        ))
        print("  OK spend_aggregates -- SAGG0000000015 (Rs.78K/month)")

        pay_rows = [
            ("PAYB0000000017", "CARD00000013", "2025-03",
             78000.00, 78000.00, "2025-04-11", "FULL", 0, False),
            ("PAYB0000000018", "CARD00000013", "2025-02",
             74000.00, 74000.00, "2025-03-11", "FULL", 0, False),
            ("PAYB0000000019", "CARD00000013", "2025-01",
             80000.00, 80000.00, "2025-02-11", "FULL", 0, False),
        ]
        for p in pay_rows:
            run(conn, """
                INSERT INTO payment_behaviour
                  (pay_id, card_id, statement_month, amount_due, amount_paid,
                   payment_date, payment_type, days_late, dpd_flag)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (pay_id) DO NOTHING
            """, p)
        print("  OK payment_behaviour -- PAYB0000000017-019 (all FULL, 0 DPD)")

        conn.commit()
        print("  SC16 CARD committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 CARD: {e}")
        raise
    finally:
        conn.close()


def seed_sc16_dms():
    section("SC16 DMS -- DMS000000027-029, INCPR0000013")
    conn = connect_rw("dms")
    try:
        docs = [
            ("DMS000000027", "CUST000013", "IDENTITY", "PAN Card",
             "CUST000013_PAN_CLPSV7723K.pdf",
             "2017-07-22", "OnboardingAgent", 108, "application/pdf",
             "cbs/cust000013/identity/", "INTERNAL"),
            ("DMS000000028", "CUST000013", "IDENTITY", "Aadhaar Card",
             "CUST000013_AADHAAR_masked.pdf",
             "2017-07-22", "OnboardingAgent", 92, "application/pdf",
             "cbs/cust000013/identity/", "INTERNAL"),
            ("DMS000000029", "CUST000013", "INCOME", "ITR Filing",
             "CUST000013_ITR_AY2024-25.pdf",
             "2024-10-25", "RM001", 820, "application/pdf",
             "cbs/cust000013/income/", "RESTRICTED"),
        ]
        for d in docs:
            run(conn, """
                INSERT INTO document_repository
                  (dms_id, customer_id, doc_category, doc_type, file_name,
                   upload_date, uploaded_by, file_size_kb, mime_type,
                   storage_path, access_level)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (dms_id) DO NOTHING
            """, d)
            print(f"  OK document_repository -- {d[0]} ({d[3]})")

        run(conn, """
            INSERT INTO income_proofs
              (proof_id, dms_id, customer_id, proof_type, assessment_year,
               gross_income, net_income, employer_name,
               filing_date, extracted_by, extraction_confidence)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (proof_id) DO NOTHING
        """, (
            "INCPR0000013", "DMS000000029", "CUST000013", "ITR", "2024-25",
            2800000.00, 2040000.00, "Varma Advisory Services LLP",
            "2024-10-25", "MANUAL", 0.96,
        ))
        print("  OK income_proofs -- INCPR0000013 (gross Rs.28L, net Rs.20.4L)")

        conn.commit()
        print("  SC16 DMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC16 DMS: {e}")
        raise
    finally:
        conn.close()


# ===========================================================================
# SECTION 3 -- Scenario 17: CUST000014 Rohit Suresh Kapoor (Aggressive + FY22-23 losses)
# ===========================================================================

def seed_sc17_cbs():
    section("SC17 CBS -- CUST000014 Rohit Suresh Kapoor")
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
            "CUST000014", "PARTY014", "Rohit Suresh Kapoor",
            "1978-04-05", "M", "Indian",
            "9876543214", "rohit.kapoor@kapoorindustries.com", "DKPRK8834M",
            "96543210", "ADDR014", "RM004",
            "2015-06-18", "HNI", "ACTIVE",
        ))
        print("  OK customer_master -- CUST000014")

        run(conn, """
            INSERT INTO account_master
              (account_id, customer_id, account_type, currency,
               current_balance, available_balance, od_limit,
               status, open_date, branch_code)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (account_id) DO NOTHING
        """, (
            "ACC0000000016", "CUST000014", "SAVINGS", "INR",
            2500000.00, 2500000.00, 0.00,
            "ACTIVE", "2015-06-18", "MUM002",
        ))
        print("  OK account_master -- ACC0000000016")

        run(conn, """
            INSERT INTO liability_accounts
              (liability_id, customer_id, liability_type,
               principal_amount, outstanding_balance, emi_amount,
               start_date, maturity_date, dpd_days, npa_flag)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (liability_id) DO NOTHING
        """, (
            "LIAB00000013", "CUST000014", "HOME_LOAN",
            10000000.00, 7500000.00, 95000.00,
            "2016-01-01", "2046-01-01", 0, False,
        ))
        print("  OK liability_accounts -- LIAB00000013 (Home loan Rs.75L outstanding)")

        run(conn, """
            INSERT INTO transaction_history
              (txn_id, account_id, txn_date, txn_type, amount, currency,
               channel, counterparty_name, counterparty_account,
               narration, balance_after)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (txn_id) DO NOTHING
        """, (
            "TXN0000000018", "ACC0000000016", "2025-04-01", "CREDIT",
            380000.00, "INR", "RTGS",
            "Kapoor Industries Pvt Ltd", "AXIS0044567",
            "Dividend payout Q4 FY2025 -- Kapoor Industries", 2880000.00,
        ))
        print("  OK transaction_history -- TXN0000000018")

        conn.commit()
        print("  SC17 CBS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 CBS: {e}")
        raise
    finally:
        conn.close()


def seed_sc17_crm():
    section("SC17 CRM -- CLI000014")
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
            "CLI000014", "CUST000014", "HNI", "Business Owner - Manufacturing", "RM004",
            "2015-06-18", "EXPERT", "AGGRESSIVE",
            "English", "Referral - HNI network", "1Cr-5Cr",
            "2024-12-05", "2025-12-05",
        ))
        print("  OK client_profile -- CLI000014")

        run(conn, """
            INSERT INTO client_preferences
              (pref_id, client_id, goal_type, time_horizon,
               liquidity_need, excluded_sectors, esg_preference, last_updated)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (pref_id) DO NOTHING
        """, (
            "PREF00000014", "CLI000014", "WEALTH_GROWTH", "LONG",
            "LOW", None, False, "2024-12-05",
        ))
        print("  OK client_preferences -- PREF00000014")

        run(conn, """
            INSERT INTO interaction_log
              (interaction_id, client_id, interaction_date, channel, type,
               summary, sentiment_score, follow_up_flag, created_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (interaction_id) DO NOTHING
        """, (
            "INT0000000014", "CLI000014", "2024-12-05", "IN_PERSON", "REVIEW",
            "Annual review following FY2022-23 portfolio losses. Rohit suffered -18.3% "
            "in Dec 2022 and -14.5% in Mar 2023 due to aggressive mid/small-cap positioning. "
            "Portfolio has partially recovered (+8.4%, +7.2%, +6.8%) but cumulative loss "
            "still not fully recovered. Client has FORMALLY REQUESTED a shift to conservative "
            "allocation citing emotional distress and reduced risk tolerance post-drawdown. "
            "On-record risk appetite remains AGGRESSIVE -- formal reclassification required "
            "before any rebalancing can proceed. RM to initiate revised risk profiling.",
            0.45, True, "RM004",
        ))
        print("  OK interaction_log -- INT0000000014 (conservative shift requested post-losses)")

        conn.commit()
        print("  SC17 CRM committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 CRM: {e}")
        raise
    finally:
        conn.close()


def seed_sc17_kyc():
    section("SC17 KYC -- KYC000000014")
    conn = connect_rw("kyc")
    try:
        run(conn, """
            INSERT INTO kyc_master
              (kyc_id, customer_id, kyc_type, kyc_status, kyc_tier,
               verification_method, verified_date, expiry_date,
               re_kyc_due, verified_by, notes)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (kyc_id) DO NOTHING
        """, (
            "KYC000000014", "CUST000014", "IN_PERSON", "VERIFIED", "STANDARD",
            "DOCUMENT", "2015-06-18", "2025-06-18",
            "2027-06-18", "ComplianceOfficer_01",
            "Aggressive HNI investor. Business owner. KYC current. "
            "Suffered heavy portfolio losses in FY2022-23. "
            "Risk reclassification in progress following client request to shift conservative.",
        ))
        print("  OK kyc_master -- KYC000000014")

        for doc in [
            ("DOC000000021", "KYC000000014", "PAN", "DKPRK8834M",
             "Income Tax Dept", "2003-11-10", "9999-12-31", "VALID", "DMS000000030"),
            ("DOC000000022", "KYC000000014", "AADHAAR", "96543210",
             "UIDAI", "2011-09-20", "9999-12-31", "VALID", "DMS000000031"),
        ]:
            run(conn, """
                INSERT INTO identity_documents
                  (doc_id, kyc_id, doc_type, doc_number, issuing_authority,
                   issue_date, expiry_date, doc_status, dms_ref)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (doc_id) DO NOTHING
            """, doc)
            print(f"  OK identity_documents -- {doc[0]} ({doc[2]})")

        run(conn, """
            INSERT INTO pep_screening
              (screen_id, customer_id, screen_date, screen_type,
               pep_flag, pep_category, sanctions_list, sanctions_hit,
               adverse_media_hit, screened_by, next_review)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (screen_id) DO NOTHING
        """, (
            "SCR000000014", "CUST000014", "2024-12-05", "PERIODIC",
            False, "NONE", "OFAC,UN,SEBI", "None",
            "None", "AutoScreen_v2", "2025-12-05",
        ))
        print("  OK pep_screening -- SCR000000014 (clear)")

        run(conn, """
            INSERT INTO risk_classification
              (risk_class_id, customer_id, risk_tier, risk_score,
               classification_date, classification_basis,
               override_flag, override_reason, reviewed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (risk_class_id) DO NOTHING
        """, (
            "RCLASS00000014", "CUST000014", "MEDIUM", 55.0,
            "2024-12-05",
            "AGGRESSIVE risk appetite on record. Concentrated mid/small-cap equity exposure. "
            "FY2022-23 heavy losses: -18.3% (Dec-22), -14.5% (Mar-23). "
            "Behavioural risk elevated post-drawdown. Risk reclassification pending.",
            False, None, "ComplianceOfficer_01",
        ))
        print("  OK risk_classification -- RCLASS00000014 (MEDIUM, 55.0)")

        conn.commit()
        print("  SC17 KYC committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 KYC: {e}")
        raise
    finally:
        conn.close()


def seed_sc17_pms():
    section("SC17 PMS -- BM011, PORT000014, 4 holdings, 6 perf records (showing FY22-23 losses)")
    conn = connect_rw("pms")
    try:
        run(conn, """
            INSERT INTO benchmark_master
              (benchmark_id, benchmark_name, asset_class,
               index_provider, base_date, rebalance_freq, description)
            VALUES (%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (benchmark_id) DO NOTHING
        """, (
            "BM011", "Nifty Midcap 150 TRI",
            "EQUITY", "NSE Indices", "2007-01-01", "DAILY",
            "Nifty Midcap 150 Total Returns Index -- mid-cap benchmark for GROWTH portfolios",
        ))
        print("  OK benchmark_master -- BM011")

        run(conn, """
            INSERT INTO portfolio_master
              (portfolio_id, client_id, portfolio_name, strategy_type,
               benchmark_id, inception_date, base_currency, aum, status, managed_by)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (portfolio_id) DO NOTHING
        """, (
            "PORT000014", "CLI000014", "Rohit - Aggressive Growth Portfolio",
            "GROWTH", "BM011", "2015-07-01", "INR",
            25000000.00, "ACTIVE", "FundManager_02",
        ))
        print("  OK portfolio_master -- PORT000014 (AUM Rs.2.5 Cr)")

        # 4 holdings -- heavily equity-concentrated (GROWTH strategy)
        # HOLD0000000033-036
        holdings = [
            ("HOLD0000000033", "PORT000014", "INF277K01ZL8",
             "Axis Midcap Fund - Direct Growth",
             "EQUITY", "Midcap MF",
             36603.2, 341.20, 341.20, 25000000.00 * 0.50, 50.00, 0.00),
            ("HOLD0000000034", "PORT000014", "INF209K01XW9",
             "Nippon India Small Cap Fund - Direct Growth",
             "EQUITY", "Small Cap MF",
             65789.5, 114.00, 114.00, 25000000.00 * 0.30, 30.00, 0.00),
            ("HOLD0000000035", "PORT000014", "INF277K01ZZ8",
             "Kotak Banking & Financial Services Fund",
             "EQUITY", "Sector Fund - BFSI",
             130208.3, 28.80, 28.80, 25000000.00 * 0.15, 15.00, 0.00),
            ("HOLD0000000036", "PORT000014", "INF179K01XE2",
             "HDFC Overnight Fund - Direct Growth",
             "CASH", "Liquid MF",
             20812.2, 3006.00, 3006.00, 25000000.00 * 0.05, 5.00, 0.00),
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
        print("  OK holdings -- HOLD0000000033-036 (95% equity, 5% liquid)")

        # 6 quarters -- showing FY2022-23 heavy losses and partial recovery
        # PERF0000000039-044
        perf_rows = [
            # Before crash: mild positive
            ("PERF0000000039", "PORT000014", "2022-09-30",  +2.10,  +1.80, +0.30,  3.50,  0.42,  -8.20, 14.80),
            # Dec-22 CRASH: -18.3% vs bench -15.6% (alpha -2.7%)
            ("PERF0000000040", "PORT000014", "2022-12-31", -18.30, -15.60, -2.70,  4.20, -1.85, -22.50, 18.90),
            # Mar-23 second drop: -14.5% vs bench -11.2% (alpha -3.3%)
            ("PERF0000000041", "PORT000014", "2023-03-31", -14.50, -11.20, -3.30,  4.50, -1.62, -19.80, 17.60),
            # Jun-23 recovery begins
            ("PERF0000000042", "PORT000014", "2023-06-30",  +8.40,  +6.70, +1.70,  3.80,  0.68,  -5.20, 12.50),
            # Sep-23 continued recovery
            ("PERF0000000043", "PORT000014", "2023-09-30",  +7.20,  +5.80, +1.40,  3.60,  0.72,  -4.80, 11.90),
            # Dec-23 recovery slowing
            ("PERF0000000044", "PORT000014", "2023-12-31",  +6.80,  +5.50, +1.30,  3.40,  0.65,  -4.50, 11.20),
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
        print("  OK performance_history -- PERF0000000039-044 (FY22-23 crash + recovery)")

        conn.commit()
        print("  SC17 PMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 PMS: {e}")
        raise
    finally:
        conn.close()


def seed_sc17_card():
    section("SC17 CARD -- CARD00000014")
    conn = connect_rw("card")
    try:
        run(conn, """
            INSERT INTO card_accounts
              (card_id, customer_id, card_type, credit_limit, current_balance,
               available_limit, min_payment_due, payment_due_date,
               card_status, issue_date)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (card_id) DO NOTHING
        """, (
            "CARD00000014", "CUST000014", "PLATINUM",
            500000.00, 140000.00, 360000.00,
            14000.00, "2025-05-15", "ACTIVE", "2016-01-10",
        ))
        print("  OK card_accounts -- CARD00000014 (Platinum, Rs.5L limit)")

        # 1 row -- inferred annual = 140K x 12 x 3 = Rs.50.4L (matches declared Rs.50L)
        run(conn, """
            INSERT INTO spend_aggregates
              (agg_id, card_id, month_year, total_spend, travel_spend,
               dining_spend, retail_spend, utility_spend,
               emi_deductions, cash_advances, avg_txn_value)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (agg_id) DO NOTHING
        """, (
            "SAGG0000000016", "CARD00000014", "2025-03",
            140000.00, 35000.00, 18000.00, 45000.00, 22000.00, 0.00, 0.00, 6500.00,
        ))
        print("  OK spend_aggregates -- SAGG0000000016 (Rs.1.4L/month)")

        pay_rows = [
            ("PAYB0000000020", "CARD00000014", "2025-03",
             140000.00, 140000.00, "2025-04-14", "FULL", 0, False),
            ("PAYB0000000021", "CARD00000014", "2025-02",
             130000.00, 130000.00, "2025-03-14", "FULL", 0, False),
            ("PAYB0000000022", "CARD00000014", "2025-01",
             145000.00, 145000.00, "2025-02-14", "FULL", 0, False),
        ]
        for p in pay_rows:
            run(conn, """
                INSERT INTO payment_behaviour
                  (pay_id, card_id, statement_month, amount_due, amount_paid,
                   payment_date, payment_type, days_late, dpd_flag)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (pay_id) DO NOTHING
            """, p)
        print("  OK payment_behaviour -- PAYB0000000020-022 (all FULL, 0 DPD)")

        conn.commit()
        print("  SC17 CARD committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 CARD: {e}")
        raise
    finally:
        conn.close()


def seed_sc17_dms():
    section("SC17 DMS -- DMS000000030-032, INCPR0000014")
    conn = connect_rw("dms")
    try:
        docs = [
            ("DMS000000030", "CUST000014", "IDENTITY", "PAN Card",
             "CUST000014_PAN_DKPRK8834M.pdf",
             "2015-06-18", "OnboardingAgent", 115, "application/pdf",
             "cbs/cust000014/identity/", "INTERNAL"),
            ("DMS000000031", "CUST000014", "IDENTITY", "Aadhaar Card",
             "CUST000014_AADHAAR_masked.pdf",
             "2015-06-18", "OnboardingAgent", 90, "application/pdf",
             "cbs/cust000014/identity/", "INTERNAL"),
            ("DMS000000032", "CUST000014", "INCOME", "ITR Filing",
             "CUST000014_ITR_AY2024-25.pdf",
             "2024-11-20", "RM004", 980, "application/pdf",
             "cbs/cust000014/income/", "RESTRICTED"),
        ]
        for d in docs:
            run(conn, """
                INSERT INTO document_repository
                  (dms_id, customer_id, doc_category, doc_type, file_name,
                   upload_date, uploaded_by, file_size_kb, mime_type,
                   storage_path, access_level)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                ON CONFLICT (dms_id) DO NOTHING
            """, d)
            print(f"  OK document_repository -- {d[0]} ({d[3]})")

        run(conn, """
            INSERT INTO income_proofs
              (proof_id, dms_id, customer_id, proof_type, assessment_year,
               gross_income, net_income, employer_name,
               filing_date, extracted_by, extraction_confidence)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (proof_id) DO NOTHING
        """, (
            "INCPR0000014", "DMS000000032", "CUST000014", "ITR", "2024-25",
            5000000.00, 3500000.00, "Kapoor Industries Pvt Ltd",
            "2024-11-20", "MANUAL", 0.95,
        ))
        print("  OK income_proofs -- INCPR0000014 (gross Rs.50L, net Rs.35L)")

        conn.commit()
        print("  SC17 DMS committed.")
    except Exception as e:
        conn.rollback()
        print(f"  ERROR in SC17 DMS: {e}")
        raise
    finally:
        conn.close()


# ===========================================================================
# MAIN
# ===========================================================================

if __name__ == "__main__":
    print("\n" + "="*60)
    print("  Seeding: CUST000011 fixes + Scenarios 15/16/17")
    print("="*60)

    print("\n--- SECTION 0: CUST000011 data-quality fixes ---")
    fix_cust000011_pms()
    fix_cust000011_dms()
    fix_cust000011_kyc()
    fix_cust000011_card()

    print("\n--- SECTION 1: Scenario 15 -- Prateek Anand Mathur (CUST000012) ---")
    seed_sc15_cbs()
    seed_sc15_crm()
    seed_sc15_kyc()
    seed_sc15_pms()
    seed_sc15_card()
    seed_sc15_dms()

    print("\n--- SECTION 2: Scenario 16 -- Sneha Anand Varma (CUST000013) ---")
    seed_sc16_cbs()
    seed_sc16_crm()
    seed_sc16_kyc()
    seed_sc16_pms()
    seed_sc16_card()
    seed_sc16_dms()

    print("\n--- SECTION 3: Scenario 17 -- Rohit Suresh Kapoor (CUST000014) ---")
    seed_sc17_cbs()
    seed_sc17_crm()
    seed_sc17_kyc()
    seed_sc17_pms()
    seed_sc17_card()
    seed_sc17_dms()

    print("\n" + "="*60)
    print("  All fixes and 3 new scenarios seeded successfully.")
    print("="*60 + "\n")
