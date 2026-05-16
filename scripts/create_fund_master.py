"""
Step 1 of Wealth Recommendation plan.
Creates fund_master and fund_performance_cache tables in PMS DB,
then seeds ~32 instruments across all risk tiers.
"""
import psycopg2
import psycopg2.extras

conn = psycopg2.connect(
    host="localhost", port=5435, user="postgres",
    password="password", dbname="portfolio_management_system",
    cursor_factory=psycopg2.extras.RealDictCursor
)
conn.autocommit = False
cur = conn.cursor()

# ── 1. Create fund_master ──────────────────────────────────────
cur.execute("""
CREATE TABLE IF NOT EXISTS fund_master (
    fund_id             VARCHAR(20)  PRIMARY KEY,
    scheme_code         INTEGER,
    instrument_name     VARCHAR(200) NOT NULL,
    short_name          VARCHAR(100),
    category            VARCHAR(60)  NOT NULL,
    asset_class         VARCHAR(30)  NOT NULL,
    amc                 VARCHAR(100),
    risk_tier           VARCHAR(20)  NOT NULL,
    instrument_type     VARCHAR(20)  NOT NULL,
    data_source         VARCHAR(10)  NOT NULL DEFAULT 'MFAPI',
    static_return_pct   NUMERIC(5,2),
    min_investment_inr  INTEGER      DEFAULT 500,
    is_active           BOOLEAN      DEFAULT TRUE,
    added_date          DATE         DEFAULT CURRENT_DATE
)
""")
print("fund_master table ready.")

# ── 2. Create fund_performance_cache ──────────────────────────
cur.execute("""
CREATE TABLE IF NOT EXISTS fund_performance_cache (
    cache_id            SERIAL       PRIMARY KEY,
    fund_id             VARCHAR(20)  REFERENCES fund_master(fund_id),
    scheme_code         INTEGER,
    cagr_3yr_pct        NUMERIC(6,2),
    cagr_1yr_pct        NUMERIC(6,2),
    volatility_pct      NUMERIC(6,2),
    max_drawdown_pct    NUMERIC(6,2),
    nav_as_of_date      DATE,
    cached_at           TIMESTAMP    DEFAULT NOW(),
    expires_at          TIMESTAMP
)
""")
print("fund_performance_cache table ready.")

# ── 3. Seed instruments ────────────────────────────────────────
# Columns: fund_id, scheme_code, instrument_name, short_name,
#          category, asset_class, amc, risk_tier,
#          instrument_type, data_source, static_return_pct, min_investment_inr

instruments = [

    # ── NO_RISK ──────────────────────────────────────────────────
    ("FUND001", 145810,
     "Nippon India Overnight Fund - Direct Plan - Growth Option",
     "Nippon Overnight", "Overnight Fund", "DEBT",
     "Nippon India MF", "NO_RISK", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND002", 119091,
     "HDFC Liquid Fund - Growth Option - Direct Plan",
     "HDFC Liquid", "Liquid Fund", "DEBT",
     "HDFC AMC", "NO_RISK", "MUTUAL_FUND", "MFAPI", None, 5000),

    ("FUND003", None,
     "Public Provident Fund (PPF)",
     "PPF", "Government Savings Scheme", "SAFE",
     "Government of India", "NO_RISK", "GOVT_SCHEME", "STATIC", 7.10, 500),

    ("FUND004", None,
     "RBI Floating Rate Savings Bonds 2020 (Taxable)",
     "RBI Floating Bonds", "Government Bond", "SAFE",
     "Reserve Bank of India", "NO_RISK", "GOVT_SCHEME", "STATIC", 7.35, 1000),

    ("FUND005", None,
     "National Savings Certificate (NSC) VIII Issue",
     "NSC", "Government Savings Scheme", "SAFE",
     "India Post / Government of India", "NO_RISK", "GOVT_SCHEME", "STATIC", 7.70, 1000),

    ("FUND006", None,
     "SBI Fixed Deposit (1-3 Year)",
     "SBI FD", "Bank Fixed Deposit", "SAFE",
     "State Bank of India", "NO_RISK", "FD", "STATIC", 7.10, 10000),

    ("FUND007", None,
     "HDFC Bank Fixed Deposit (1-3 Year)",
     "HDFC Bank FD", "Bank Fixed Deposit", "SAFE",
     "HDFC Bank", "NO_RISK", "FD", "STATIC", 7.25, 10000),

    # ── LOW ──────────────────────────────────────────────────────
    ("FUND008", None,
     "Employee Provident Fund (EPF)",
     "EPF", "Provident Fund", "SAFE",
     "EPFO / Government of India", "LOW", "GOVT_SCHEME", "STATIC", 8.25, 0),

    ("FUND009", 120510,
     "Axis Short Duration Fund - Direct Plan - Growth Option",
     "Axis Short Duration", "Short Duration Fund", "DEBT",
     "Axis AMC", "LOW", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND010", 120692,
     "ICICI Prudential Corporate Bond Fund - Direct Plan - Growth",
     "ICICI Corp Bond", "Corporate Bond Fund", "DEBT",
     "ICICI Prudential AMC", "LOW", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND011", 133791,
     "Kotak Corporate Bond Fund - Direct Plan - Growth Option",
     "Kotak Corp Bond", "Corporate Bond Fund", "DEBT",
     "Kotak Mahindra AMC", "LOW", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND012", 131061,
     "ICICI Prudential Constant Maturity Gilt Fund - Direct Plan - Growth",
     "ICICI Gilt", "Gilt Fund", "DEBT",
     "ICICI Prudential AMC", "LOW", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND013", 119759,
     "Kotak Gilt Fund - Investment Regular - Direct Growth",
     "Kotak Gilt", "Gilt Fund", "DEBT",
     "Kotak Mahindra AMC", "LOW", "MUTUAL_FUND", "MFAPI", None, 500),

    # ── MEDIUM ───────────────────────────────────────────────────
    ("FUND014", 120377,
     "ICICI Prudential Balanced Advantage Fund - Direct Plan - Growth",
     "ICICI Pru BAF", "Balanced Advantage Fund", "HYBRID",
     "ICICI Prudential AMC", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND015", 118968,
     "HDFC Balanced Advantage Fund - Growth Plan - Direct Plan",
     "HDFC BAF", "Balanced Advantage Fund", "HYBRID",
     "HDFC AMC", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND016", 120334,
     "ICICI Prudential Multi-Asset Fund - Direct Plan - Growth",
     "ICICI Multi Asset", "Multi Asset Fund", "HYBRID",
     "ICICI Prudential AMC", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND017", 148457,
     "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option",
     "Nippon Multi Asset", "Multi Asset Fund", "HYBRID",
     "Nippon India MF", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND018", 118825,
     "Mirae Asset Large Cap Fund - Direct Plan - Growth",
     "Mirae Large Cap", "Large Cap Fund", "EQUITY",
     "Mirae Asset MF", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND019", 118989,
     "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan",
     "HDFC Mid Cap", "Mid Cap Fund", "EQUITY",
     "HDFC AMC", "MEDIUM", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND020", None,
     "Sovereign Gold Bond (SGB) - Current Series",
     "SGB", "Sovereign Gold Bond", "GOLD",
     "Reserve Bank of India", "MEDIUM", "SGB", "STATIC", 2.50, 5000),

    ("FUND021", 113049,
     "HDFC Gold ETF - Growth Option",
     "HDFC Gold ETF", "Gold ETF", "GOLD",
     "HDFC AMC", "MEDIUM", "ETF", "MFAPI", None, 500),

    ("FUND022", 140088,
     "Nippon India ETF Gold BeES",
     "Nippon Gold BeES", "Gold ETF", "GOLD",
     "Nippon India MF", "MEDIUM", "ETF", "MFAPI", None, 500),

    # ── HIGH ─────────────────────────────────────────────────────
    ("FUND023", 122639,
     "Parag Parikh Flexi Cap Fund - Direct Plan - Growth",
     "PPFAS Flexi Cap", "Flexi Cap Fund", "EQUITY",
     "PPFAS MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 1000),

    ("FUND024", 118955,
     "HDFC Flexi Cap Fund - Growth Option - Direct Plan",
     "HDFC Flexi Cap", "Flexi Cap Fund", "EQUITY",
     "HDFC AMC", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND025", 118668,
     "Nippon India Growth Fund (Mid Cap) - Direct Plan Growth",
     "Nippon Mid Cap", "Mid Cap Fund", "EQUITY",
     "Nippon India MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND026", 125497,
     "SBI Small Cap Fund - Direct Plan - Growth",
     "SBI Small Cap", "Small Cap Fund", "EQUITY",
     "SBI Funds Management", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND027", 118778,
     "Nippon India Small Cap Fund - Direct Plan Growth Plan - Growth Option",
     "Nippon Small Cap", "Small Cap Fund", "EQUITY",
     "Nippon India MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND028", 119060,
     "HDFC ELSS Tax Saver - Growth Option - Direct Plan",
     "HDFC ELSS", "ELSS Tax Saver", "EQUITY",
     "HDFC AMC", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND029", 119242,
     "DSP ELSS Tax Saver Fund - Direct Plan - Growth",
     "DSP ELSS", "ELSS Tax Saver", "EQUITY",
     "DSP MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND030", 145552,
     "Motilal Oswal Nasdaq 100 Fund of Fund - Direct Plan Growth",
     "Motilal NASDAQ 100", "International FoF", "INTERNATIONAL",
     "Motilal Oswal MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND031", 148928,
     "Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth",
     "Mirae NYSE FANG+", "International FoF", "INTERNATIONAL",
     "Mirae Asset MF", "HIGH", "MUTUAL_FUND", "MFAPI", None, 500),

    ("FUND032", 154279,
     "Mirae Asset Silver ETF FOF - Direct Plan - Growth",
     "Mirae Silver ETF", "Silver ETF FoF", "METALS",
     "Mirae Asset MF", "HIGH", "ETF", "MFAPI", None, 500),
]

INSERT_SQL = """
    INSERT INTO fund_master
        (fund_id, scheme_code, instrument_name, short_name, category,
         asset_class, amc, risk_tier, instrument_type, data_source,
         static_return_pct, min_investment_inr)
    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    ON CONFLICT (fund_id) DO NOTHING
"""

inserted = 0
for inst in instruments:
    cur.execute(INSERT_SQL, inst)
    if cur.rowcount > 0:
        inserted += 1

conn.commit()
print(f"Seeded {inserted} new instruments into fund_master.")

# ── Verify ────────────────────────────────────────────────────
cur.execute("""
    SELECT risk_tier, COUNT(*) as cnt
    FROM fund_master
    GROUP BY risk_tier
    ORDER BY CASE risk_tier
        WHEN 'NO_RISK' THEN 1
        WHEN 'LOW'     THEN 2
        WHEN 'MEDIUM'  THEN 3
        WHEN 'HIGH'    THEN 4
    END
""")
print("\nDistribution by risk tier:")
for row in cur.fetchall():
    print(f"  {row['risk_tier']:10s}: {row['cnt']} instruments")

cur.execute("SELECT COUNT(*) as total FROM fund_master")
print(f"\nTotal instruments in fund_master: {cur.fetchone()['total']}")
conn.close()
print("\nDone.")
