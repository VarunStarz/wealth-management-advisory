--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 16.3

-- Started on 2026-05-11 19:30:13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 844 (class 1247 OID 16812)
-- Name: asset_class_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.asset_class_enum AS ENUM (
    'EQUITY',
    'DEBT',
    'HYBRID',
    'COMMODITY',
    'CASH',
    'GOLD',
    'REIT'
);


ALTER TYPE public.asset_class_enum OWNER TO postgres;

--
-- TOC entry 859 (class 1247 OID 16864)
-- Name: holding_asset_class_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.holding_asset_class_enum AS ENUM (
    'EQUITY',
    'DEBT',
    'HYBRID',
    'GOLD',
    'REIT',
    'CASH'
);


ALTER TYPE public.holding_asset_class_enum OWNER TO postgres;

--
-- TOC entry 868 (class 1247 OID 16904)
-- Name: initiated_by_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.initiated_by_enum AS ENUM (
    'CLIENT',
    'RM',
    'SYSTEM_SIP',
    'FUND_MANAGER'
);


ALTER TYPE public.initiated_by_enum OWNER TO postgres;

--
-- TOC entry 865 (class 1247 OID 16888)
-- Name: port_txn_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.port_txn_type_enum AS ENUM (
    'BUY',
    'SELL',
    'SWITCH_IN',
    'SWITCH_OUT',
    'SIP',
    'DIVIDEND',
    'REDEMPTION'
);


ALTER TYPE public.port_txn_type_enum OWNER TO postgres;

--
-- TOC entry 853 (class 1247 OID 16844)
-- Name: portfolio_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.portfolio_status_enum AS ENUM (
    'ACTIVE',
    'SUSPENDED',
    'CLOSED'
);


ALTER TYPE public.portfolio_status_enum OWNER TO postgres;

--
-- TOC entry 850 (class 1247 OID 16833)
-- Name: strategy_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.strategy_type_enum AS ENUM (
    'GROWTH',
    'BALANCED',
    'CONSERVATIVE',
    'INCOME',
    'CUSTOM'
);


ALTER TYPE public.strategy_type_enum OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 214 (class 1259 OID 16827)
-- Name: benchmark_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.benchmark_master (
    benchmark_id character varying(12) NOT NULL,
    benchmark_name character varying(100) NOT NULL,
    asset_class public.asset_class_enum NOT NULL,
    index_provider character varying(50),
    base_date date,
    rebalance_freq character varying(20),
    description character varying(200)
);


ALTER TABLE public.benchmark_master OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 32768)
-- Name: fund_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fund_master (
    fund_id character varying(20) NOT NULL,
    scheme_code integer,
    instrument_name character varying(200) NOT NULL,
    short_name character varying(100),
    category character varying(60) NOT NULL,
    asset_class character varying(30) NOT NULL,
    amc character varying(100),
    risk_tier character varying(20) NOT NULL,
    instrument_type character varying(20) NOT NULL,
    data_source character varying(10) DEFAULT 'MFAPI'::character varying NOT NULL,
    static_return_pct numeric(5,2),
    min_investment_inr integer DEFAULT 500,
    is_active boolean DEFAULT true,
    added_date date DEFAULT CURRENT_DATE
);


ALTER TABLE public.fund_master OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 32780)
-- Name: fund_performance_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fund_performance_cache (
    cache_id integer NOT NULL,
    fund_id character varying(20),
    scheme_code integer,
    cagr_3yr_pct numeric(6,2),
    cagr_1yr_pct numeric(6,2),
    volatility_pct numeric(6,2),
    max_drawdown_pct numeric(6,2),
    nav_as_of_date date,
    cached_at timestamp without time zone DEFAULT now(),
    expires_at timestamp without time zone
);


ALTER TABLE public.fund_performance_cache OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 32779)
-- Name: fund_performance_cache_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fund_performance_cache_cache_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fund_performance_cache_cache_id_seq OWNER TO postgres;

--
-- TOC entry 3423 (class 0 OID 0)
-- Dependencies: 220
-- Name: fund_performance_cache_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fund_performance_cache_cache_id_seq OWNED BY public.fund_performance_cache.cache_id;


--
-- TOC entry 216 (class 1259 OID 16877)
-- Name: holdings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.holdings (
    holding_id character varying(14) NOT NULL,
    portfolio_id character varying(12) NOT NULL,
    isin character varying(20) NOT NULL,
    instrument_name character varying(100) NOT NULL,
    asset_class public.holding_asset_class_enum NOT NULL,
    sub_class character varying(50),
    quantity numeric(15,4) NOT NULL,
    avg_cost numeric(12,4) NOT NULL,
    current_price numeric(12,4) NOT NULL,
    market_value numeric(15,2) NOT NULL,
    weight_pct numeric(5,2) NOT NULL,
    unrealised_pl numeric(15,2) NOT NULL
);


ALTER TABLE public.holdings OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16923)
-- Name: performance_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.performance_history (
    perf_id character varying(14) NOT NULL,
    portfolio_id character varying(12) NOT NULL,
    as_of_date date NOT NULL,
    portfolio_return numeric(8,4) NOT NULL,
    benchmark_return numeric(8,4) NOT NULL,
    alpha numeric(8,4),
    tracking_error numeric(8,4),
    sharpe_ratio numeric(8,4),
    max_drawdown numeric(8,4),
    volatility numeric(8,4)
);


ALTER TABLE public.performance_history OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16851)
-- Name: portfolio_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.portfolio_master (
    portfolio_id character varying(12) NOT NULL,
    client_id character varying(12) NOT NULL,
    portfolio_name character varying(100) NOT NULL,
    strategy_type public.strategy_type_enum NOT NULL,
    benchmark_id character varying(12) NOT NULL,
    inception_date date NOT NULL,
    base_currency character varying(3) DEFAULT 'INR'::character varying,
    aum numeric(15,2) NOT NULL,
    status public.portfolio_status_enum DEFAULT 'ACTIVE'::public.portfolio_status_enum,
    managed_by character varying(50)
);


ALTER TABLE public.portfolio_master OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16913)
-- Name: portfolio_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.portfolio_transactions (
    port_txn_id character varying(14) NOT NULL,
    portfolio_id character varying(12) NOT NULL,
    txn_date date NOT NULL,
    txn_type public.port_txn_type_enum NOT NULL,
    isin character varying(20) NOT NULL,
    quantity numeric(12,4) NOT NULL,
    price numeric(12,4) NOT NULL,
    amount numeric(15,2) NOT NULL,
    settlement_date date,
    broker_id character varying(20),
    initiated_by public.initiated_by_enum NOT NULL
);


ALTER TABLE public.portfolio_transactions OWNER TO postgres;

--
-- TOC entry 3247 (class 2604 OID 32783)
-- Name: fund_performance_cache cache_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_performance_cache ALTER COLUMN cache_id SET DEFAULT nextval('public.fund_performance_cache_cache_id_seq'::regclass);


--
-- TOC entry 3410 (class 0 OID 16827)
-- Dependencies: 214
-- Data for Name: benchmark_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.benchmark_master (benchmark_id, benchmark_name, asset_class, index_provider, base_date, rebalance_freq, description) FROM stdin;
BM001	Nifty 50 TRI	EQUITY	NSE Indices	1995-11-03	DAILY	Top 50 companies by market cap, total return
BM002	Nifty 500 TRI	EQUITY	NSE Indices	1994-01-03	DAILY	Broad market index, top 500 companies
BM003	Nifty Midcap 150 TRI	EQUITY	NSE Indices	2004-01-01	DAILY	Mid-cap segment benchmark
BM004	CRISIL Short Term Index	DEBT	CRISIL	2000-01-01	MONTHLY	Short term debt mutual fund benchmark
BM005	CRISIL Composite Index	HYBRID	CRISIL	2000-01-01	MONTHLY	65% Nifty 50 + 35% CRISIL debt composite
BM006	Gold - MCX Spot	COMMODITY	MCX	2003-01-01	DAILY	Domestic gold spot price benchmark
BM007	Nifty Smallcap 250 TRI	EQUITY	NSE Indices	2004-01-01	DAILY	Small cap segment benchmark
BM008	CRISIL Multi-Asset Balanced Index	HYBRID	CRISIL	2010-01-04	QUARTERLY	50% Nifty 50 TRI + 25% CRISIL Corporate Bond + 15% Gold + 10% Liquid/FD
BM009	CRISIL Conservative Credit Risk Index	DEBT	CRISIL	2012-04-01	MONTHLY	75% CRISIL Corporate Bond + 15% Sovereign Gold + 10% Overnight/Liquid
BM010	CRISIL Hybrid 85+15 Conservative Index	HYBRID	CRISIL	2011-06-01	QUARTERLY	85% CRISIL Composite Bond + 15% Nifty 50 TRI -- conservative blend
BM011	Nifty Midcap 150 TRI	EQUITY	NSE Indices	2007-01-01	DAILY	Nifty Midcap 150 Total Returns Index -- mid-cap benchmark for GROWTH portfolios
\.


--
-- TOC entry 3415 (class 0 OID 32768)
-- Dependencies: 219
-- Data for Name: fund_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fund_master (fund_id, scheme_code, instrument_name, short_name, category, asset_class, amc, risk_tier, instrument_type, data_source, static_return_pct, min_investment_inr, is_active, added_date) FROM stdin;
FUND001	145810	Nippon India Overnight Fund - Direct Plan - Growth Option	Nippon Overnight	Overnight Fund	DEBT	Nippon India MF	NO_RISK	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND002	119091	HDFC Liquid Fund - Growth Option - Direct Plan	HDFC Liquid	Liquid Fund	DEBT	HDFC AMC	NO_RISK	MUTUAL_FUND	MFAPI	\N	5000	t	2026-05-10
FUND003	\N	Public Provident Fund (PPF)	PPF	Government Savings Scheme	SAFE	Government of India	NO_RISK	GOVT_SCHEME	STATIC	7.10	500	t	2026-05-10
FUND004	\N	RBI Floating Rate Savings Bonds 2020 (Taxable)	RBI Floating Bonds	Government Bond	SAFE	Reserve Bank of India	NO_RISK	GOVT_SCHEME	STATIC	7.35	1000	t	2026-05-10
FUND005	\N	National Savings Certificate (NSC) VIII Issue	NSC	Government Savings Scheme	SAFE	India Post / Government of India	NO_RISK	GOVT_SCHEME	STATIC	7.70	1000	t	2026-05-10
FUND006	\N	SBI Fixed Deposit (1-3 Year)	SBI FD	Bank Fixed Deposit	SAFE	State Bank of India	NO_RISK	FD	STATIC	7.10	10000	t	2026-05-10
FUND007	\N	HDFC Bank Fixed Deposit (1-3 Year)	HDFC Bank FD	Bank Fixed Deposit	SAFE	HDFC Bank	NO_RISK	FD	STATIC	7.25	10000	t	2026-05-10
FUND008	\N	Employee Provident Fund (EPF)	EPF	Provident Fund	SAFE	EPFO / Government of India	LOW	GOVT_SCHEME	STATIC	8.25	0	t	2026-05-10
FUND009	120510	Axis Short Duration Fund - Direct Plan - Growth Option	Axis Short Duration	Short Duration Fund	DEBT	Axis AMC	LOW	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND010	120692	ICICI Prudential Corporate Bond Fund - Direct Plan - Growth	ICICI Corp Bond	Corporate Bond Fund	DEBT	ICICI Prudential AMC	LOW	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND011	133791	Kotak Corporate Bond Fund - Direct Plan - Growth Option	Kotak Corp Bond	Corporate Bond Fund	DEBT	Kotak Mahindra AMC	LOW	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND012	131061	ICICI Prudential Constant Maturity Gilt Fund - Direct Plan - Growth	ICICI Gilt	Gilt Fund	DEBT	ICICI Prudential AMC	LOW	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND013	119759	Kotak Gilt Fund - Investment Regular - Direct Growth	Kotak Gilt	Gilt Fund	DEBT	Kotak Mahindra AMC	LOW	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND014	120377	ICICI Prudential Balanced Advantage Fund - Direct Plan - Growth	ICICI Pru BAF	Balanced Advantage Fund	HYBRID	ICICI Prudential AMC	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND015	118968	HDFC Balanced Advantage Fund - Growth Plan - Direct Plan	HDFC BAF	Balanced Advantage Fund	HYBRID	HDFC AMC	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND016	120334	ICICI Prudential Multi-Asset Fund - Direct Plan - Growth	ICICI Multi Asset	Multi Asset Fund	HYBRID	ICICI Prudential AMC	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND017	148457	Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option	Nippon Multi Asset	Multi Asset Fund	HYBRID	Nippon India MF	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND018	118825	Mirae Asset Large Cap Fund - Direct Plan - Growth	Mirae Large Cap	Large Cap Fund	EQUITY	Mirae Asset MF	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND019	118989	HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan	HDFC Mid Cap	Mid Cap Fund	EQUITY	HDFC AMC	MEDIUM	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND020	\N	Sovereign Gold Bond (SGB) - Current Series	SGB	Sovereign Gold Bond	GOLD	Reserve Bank of India	MEDIUM	SGB	STATIC	2.50	5000	t	2026-05-10
FUND021	113049	HDFC Gold ETF - Growth Option	HDFC Gold ETF	Gold ETF	GOLD	HDFC AMC	MEDIUM	ETF	MFAPI	\N	500	t	2026-05-10
FUND022	140088	Nippon India ETF Gold BeES	Nippon Gold BeES	Gold ETF	GOLD	Nippon India MF	MEDIUM	ETF	MFAPI	\N	500	t	2026-05-10
FUND023	122639	Parag Parikh Flexi Cap Fund - Direct Plan - Growth	PPFAS Flexi Cap	Flexi Cap Fund	EQUITY	PPFAS MF	HIGH	MUTUAL_FUND	MFAPI	\N	1000	t	2026-05-10
FUND024	118955	HDFC Flexi Cap Fund - Growth Option - Direct Plan	HDFC Flexi Cap	Flexi Cap Fund	EQUITY	HDFC AMC	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND025	118668	Nippon India Growth Fund (Mid Cap) - Direct Plan Growth	Nippon Mid Cap	Mid Cap Fund	EQUITY	Nippon India MF	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND026	125497	SBI Small Cap Fund - Direct Plan - Growth	SBI Small Cap	Small Cap Fund	EQUITY	SBI Funds Management	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND027	118778	Nippon India Small Cap Fund - Direct Plan Growth Plan - Growth Option	Nippon Small Cap	Small Cap Fund	EQUITY	Nippon India MF	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND028	119060	HDFC ELSS Tax Saver - Growth Option - Direct Plan	HDFC ELSS	ELSS Tax Saver	EQUITY	HDFC AMC	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND029	119242	DSP ELSS Tax Saver Fund - Direct Plan - Growth	DSP ELSS	ELSS Tax Saver	EQUITY	DSP MF	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND030	145552	Motilal Oswal Nasdaq 100 Fund of Fund - Direct Plan Growth	Motilal NASDAQ 100	International FoF	INTERNATIONAL	Motilal Oswal MF	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND031	148928	Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth	Mirae NYSE FANG+	International FoF	INTERNATIONAL	Mirae Asset MF	HIGH	MUTUAL_FUND	MFAPI	\N	500	t	2026-05-10
FUND032	154279	Mirae Asset Silver ETF FOF - Direct Plan - Growth	Mirae Silver ETF	Silver ETF FoF	METALS	Mirae Asset MF	HIGH	ETF	MFAPI	\N	500	t	2026-05-10
\.


--
-- TOC entry 3417 (class 0 OID 32780)
-- Dependencies: 221
-- Data for Name: fund_performance_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fund_performance_cache (cache_id, fund_id, scheme_code, cagr_3yr_pct, cagr_1yr_pct, volatility_pct, max_drawdown_pct, nav_as_of_date, cached_at, expires_at) FROM stdin;
1	FUND001	145810	6.26	5.42	0.12	0.00	2026-05-10	2026-05-10 11:09:00.130904	2026-05-11 11:09:00.130904
2	FUND023	122639	17.60	4.21	9.74	-10.98	2026-05-08	2026-05-10 11:09:21.40929	2026-05-11 11:09:21.40929
3	FUND026	125497	15.19	8.65	13.86	-22.42	2026-05-08	2026-05-10 11:09:21.650328	2026-05-11 11:09:21.650328
4	FUND009	120510	7.69	6.19	0.88	-0.45	2026-05-08	2026-05-10 14:36:01.293094	2026-05-11 14:36:01.293094
5	FUND010	120692	7.55	5.85	0.84	-0.59	2026-05-08	2026-05-10 14:36:01.520063	2026-05-11 14:36:01.520063
6	FUND011	133791	7.43	5.33	1.00	-0.63	2026-05-08	2026-05-10 14:36:01.747187	2026-05-11 14:36:01.747187
7	FUND012	131061	6.99	2.86	2.68	-2.72	2026-05-08	2026-05-10 14:36:01.999956	2026-05-11 14:36:01.999956
8	FUND013	119759	5.70	-1.24	3.31	-4.71	2026-05-08	2026-05-10 14:36:02.228762	2026-05-11 14:36:02.228762
9	FUND018	118825	12.11	3.40	12.87	-15.85	2026-05-08	2026-05-10 14:36:02.45256	2026-05-11 14:36:02.45256
10	FUND019	118989	24.83	15.40	14.84	-16.76	2026-05-08	2026-05-10 14:36:03.043792	2026-05-11 14:36:03.043792
11	FUND021	113049	33.43	53.82	18.44	-22.27	2026-05-08	2026-05-10 14:36:03.298248	2026-05-11 14:36:03.298248
12	FUND022	140088	33.32	53.55	18.12	-22.28	2026-05-08	2026-05-10 14:36:03.581107	2026-05-11 14:36:03.581107
13	FUND014	120377	13.07	7.90	6.50	-8.24	2026-05-08	2026-05-10 14:36:03.836212	2026-05-11 14:36:03.836212
14	FUND015	118968	16.29	4.62	9.60	-10.18	2026-05-08	2026-05-10 14:36:04.07523	2026-05-11 14:36:04.07523
15	FUND016	120334	18.48	11.25	7.86	-9.51	2026-05-08	2026-05-10 14:36:04.309582	2026-05-11 14:36:04.309582
16	FUND017	148457	22.08	21.82	9.76	-10.78	2026-05-08	2026-05-10 14:36:04.492654	2026-05-11 14:36:04.492654
17	FUND002	119091	6.96	6.29	0.16	-0.01	2026-05-10	2026-05-10 15:05:59.428854	2026-05-11 15:05:59.428854
18	FUND024	118955	19.69	4.20	11.69	-13.32	2026-05-08	2026-05-10 15:53:43.705482	2026-05-11 15:53:43.705482
19	FUND025	118668	26.90	18.58	16.38	-19.87	2026-05-08	2026-05-10 15:53:43.96599	2026-05-11 15:53:43.96599
20	FUND027	118778	22.67	16.09	16.24	-24.21	2026-05-08	2026-05-10 15:53:44.260446	2026-05-11 15:53:44.260446
21	FUND028	119060	18.22	0.65	12.13	-14.81	2026-05-08	2026-05-10 15:53:44.539469	2026-05-11 15:53:44.539469
22	FUND029	119242	18.84	3.44	13.81	-16.16	2026-05-08	2026-05-10 15:53:44.7795	2026-05-11 15:53:44.7795
23	FUND030	145552	43.93	86.92	20.69	-26.21	2026-05-08	2026-05-10 15:53:45.005114	2026-05-11 15:53:45.005114
24	FUND031	148928	55.22	55.19	24.75	-30.31	2026-05-08	2026-05-10 15:53:45.192756	2026-05-11 15:53:45.192756
\.


--
-- TOC entry 3412 (class 0 OID 16877)
-- Dependencies: 216
-- Data for Name: holdings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.holdings (holding_id, portfolio_id, isin, instrument_name, asset_class, sub_class, quantity, avg_cost, current_price, market_value, weight_pct, unrealised_pl) FROM stdin;
HOLD0000000001	PORT000001	INF179K01VQ8	Axis Bluechip Fund - Direct Growth	HYBRID	Large Cap MF	12500.0000	580.0000	820.0000	10250000.00	82.00	3000000.00
HOLD0000000002	PORT000001	INF200K01RD7	ICICI Pru Technology Fund	EQUITY	Sectoral MF	4500.0000	220.0000	500.0000	2250000.00	18.00	126000.00
HOLD0000000005	PORT000003	INF090I01239	Nippon India Small Cap Fund	EQUITY	Small Cap MF	80000.0000	450.0000	980.0000	78400000.00	92.24	42400000.00
HOLD0000000006	PORT000003	INF179K01VQ8	Axis Bluechip Fund - Direct Growth	HYBRID	Large Cap MF	8000.0000	600.0000	820.0000	6560000.00	7.72	1760000.00
HOLD0000000007	PORT000004	INF277K01BQ1	HDFC Short Term Debt Fund	DEBT	Short Term	22500.0000	17.5000	20.0000	450000.00	100.00	56250.00
HOLD0000000008	PORT000005	INF204K01K34	Kotak Equity Arbitrage Fund	HYBRID	Arbitrage	85000.0000	155.0000	198.0000	16830000.00	90.97	3655000.00
HOLD0000000009	PORT000005	INF277K01BQ1	HDFC Short Term Debt Fund	DEBT	Short Term	84000.0000	17.0000	20.0000	1680000.00	9.08	252000.00
HOLD0000000010	PORT000006	NSE:RELIANCE	Reliance Industries Ltd	EQUITY	Large Cap	25000.0000	1800.0000	2890.0000	72250000.00	40.14	27250000.00
HOLD0000000011	PORT000006	NSE:HDFCBANK	HDFC Bank Ltd	EQUITY	Large Cap	50000.0000	1100.0000	1680.0000	84000000.00	46.67	29000000.00
HOLD0000000012	PORT000006	GOLD_MCX	Sovereign Gold Bond Series XII	GOLD	SGB	5000.0000	4800.0000	6500.0000	32500000.00	18.06	8500000.00
HOLD0000000013	PORT000007	INF179K01VQ8	Axis Bluechip Fund - Direct Growth	HYBRID	Large Cap MF	390.0000	720.0000	820.0000	319800.00	99.94	39000.00
HOLD0000000014	PORT000008	INF200K01RD7	ICICI Pru Technology Fund	EQUITY	Sectoral MF	18000.0000	320.0000	500.0000	9000000.00	32.14	3240000.00
HOLD0000000015	PORT000008	INF090I01239	Nippon India Small Cap Fund	EQUITY	Small Cap MF	15000.0000	700.0000	980.0000	14700000.00	52.50	4200000.00
HOLD0000000016	PORT000008	INF277K01BQ1	HDFC Short Term Debt Fund	DEBT	Short Term	15000.0000	17.0000	20.0000	300000.00	1.07	45000.00
HOLD0000000017	PORT000009	NSE:RELIANCE	Reliance Industries Ltd	EQUITY	Large Cap	100000.0000	1200.0000	2890.0000	289000000.00	68.81	169000000.00
HOLD0000000020	PORT000010	INF179K01VQ8	Axis Bluechip Fund - Direct Growth	HYBRID	Large Cap MF	103.0000	720.0000	820.0000	84460.00	99.36	10300.00
HOLD0000000021	PORT000011	IN0020210174	SGB 2021-22 Series IV	GOLD	Sovereign Gold Bond	207.3200	5850.0000	6150.0000	1275000.00	15.00	62196.00
HOLD0000000022	PORT000011	FD-SBI-20211201	SBI Fixed Deposit (6.0% p.a.)	CASH	Bank Fixed Deposit	1.0000	680000.0000	680000.0000	680000.00	8.00	0.00
HOLD0000000023	PORT000011	INF179K01BR7	HDFC Flexi Cap Fund - Regular Growth	EQUITY	Flexi Cap MF	22261.9000	168.0000	210.0000	4675000.00	55.00	935000.00
HOLD0000000024	PORT000011	INF109K01Z23	ICICI Pru Corporate Bond Fund	DEBT	Corporate Bond MF	63729.0000	27.5000	29.3400	1870000.00	22.00	117261.00
HOLD0000000025	PORT000012	INF109K01AH9	ICICI Pru Credit Risk Fund - Direct Growth	DEBT	Credit Risk MF	1459375.0000	29.1300	29.1300	4253906.00	44.78	0.00
HOLD0000000026	PORT000012	IN0020220120	SGB 2022-23 Series III	GOLD	Sovereign Gold Bond	259.7400	5525.0000	7300.0000	1896102.00	19.96	461031.00
HOLD0000000027	PORT000012	IN0020130025	RBI 7.26% Savings Bond 2032	DEBT	Govt Bond	237500.0000	100.0000	100.0000	2375000.00	25.00	0.00
HOLD0000000028	PORT000012	INF179K01XE2	HDFC Short Duration Fund - Direct Growth	CASH	Short Duration MF	438000.0000	21.4600	21.4600	940148.00	9.90	0.00
HOLD0000000029	PORT000013	INF209K01HV6	Mirae Asset Large Cap Fund - Direct Growth	EQUITY	Large Cap MF	13636.0000	660.0000	880.0000	3600000.00	30.00	300000.00
HOLD0000000030	PORT000013	INF194K01HB7	Kotak Corporate Bond Fund - Direct Growth	DEBT	Corporate Bond MF	1565217.0000	30.6700	30.6700	4800000.00	40.00	0.00
HOLD0000000031	PORT000013	IN0020220040	SGB 2022-23 Series I	GOLD	Sovereign Gold Bond	219.1800	5510.0000	7300.0000	1800000.00	15.00	392422.00
HOLD0000000032	PORT000013	FD-HDFC-20230715	HDFC Bank Fixed Deposit (6.8% p.a.)	CASH	Bank Fixed Deposit	1.0000	1800000.0000	1800000.0000	1800000.00	15.00	0.00
HOLD0000000033	PORT000014	INF277K01ZL8	Axis Midcap Fund - Direct Growth	EQUITY	Midcap MF	36603.2000	341.2000	341.2000	12500000.00	50.00	0.00
HOLD0000000034	PORT000014	INF209K01XW9	Nippon India Small Cap Fund - Direct Growth	EQUITY	Small Cap MF	65789.5000	114.0000	114.0000	7500000.00	30.00	0.00
HOLD0000000035	PORT000014	INF277K01ZZ8	Kotak Banking & Financial Services Fund	EQUITY	Sector Fund - BFSI	130208.3000	28.8000	28.8000	3750000.00	15.00	0.00
HOLD0000000036	PORT000014	INF179K01XE2	HDFC Overnight Fund - Direct Growth	CASH	Liquid MF	20812.2000	3006.0000	3006.0000	1250000.00	5.00	0.00
HOLD0000000003	PORT000002	INF209K01LQ8	Mirae Asset Large Cap Fund	EQUITY	Large Cap MF	3265.6250	480.0000	640.0000	2090000.00	55.00	522500.00
HOLD0000000004	PORT000002	INF277K01BQ1	HDFC Short Term Debt Fund	DEBT	Short Term	47500.0000	17.0000	20.0000	950000.00	25.00	142500.00
HOLD0000000037	PORT000002	IN0020230015	SGB 2023-24 Series I	GOLD	Sovereign Gold Bond	62.4700	5800.0000	7300.0000	456031.00	12.00	93705.00
HOLD0000000038	PORT000002	INF200K01UC8	SBI Liquid Fund - Direct Growth	CASH	Liquid MF	295.1500	1021.5000	1030.0000	304004.00	8.00	2509.00
HOLD0000000018	PORT000009	NSE:TATAMOTORS	Tata Motors Ltd	EQUITY	Mid Cap	100000.0000	200.0000	890.0000	89000000.00	21.19	69000000.00
HOLD0000000019	PORT000009	GOLD_MCX	Gold ETF - Nippon India	GOLD	ETF	8000.0000	3800.0000	5250.0000	42000000.00	10.00	11600000.00
\.


--
-- TOC entry 3414 (class 0 OID 16923)
-- Dependencies: 218
-- Data for Name: performance_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.performance_history (perf_id, portfolio_id, as_of_date, portfolio_return, benchmark_return, alpha, tracking_error, sharpe_ratio, max_drawdown, volatility) FROM stdin;
PERF0000000001	PORT000001	2024-01-31	2.1500	1.8200	0.3300	1.2000	1.8500	-3.2000	8.5000
PERF0000000002	PORT000001	2023-12-31	18.5000	15.2000	3.3000	1.5000	1.9200	-8.5000	11.2000
PERF0000000003	PORT000002	2024-01-31	1.8000	1.6000	0.2000	0.8000	1.5500	-2.1000	6.2000
PERF0000000004	PORT000003	2024-01-31	3.2000	1.8200	1.3800	3.5000	1.4200	-5.8000	16.5000
PERF0000000005	PORT000003	2023-12-31	28.5000	15.2000	13.3000	4.2000	1.6800	-15.2000	22.8000
PERF0000000006	PORT000004	2024-01-31	0.5500	0.4800	0.0700	0.2000	1.2000	-0.5000	1.8000
PERF0000000007	PORT000005	2024-01-31	1.2000	1.6000	-0.4000	1.0000	0.9800	-1.8000	5.2000
PERF0000000008	PORT000006	2024-01-31	4.5000	1.8200	2.6800	5.2000	1.8800	-6.5000	19.2000
PERF0000000009	PORT000006	2023-12-31	32.8000	15.2000	17.6000	6.0000	2.1200	-18.5000	24.5000
PERF0000000010	PORT000007	2024-01-31	2.0500	1.8200	0.2300	1.1000	1.6200	-2.8000	8.5000
PERF0000000011	PORT000008	2024-01-31	2.8000	1.6000	1.2000	2.8000	1.3500	-4.5000	14.2000
PERF0000000012	PORT000009	2024-01-31	5.8000	1.8200	3.9800	7.5000	1.9500	-8.2000	25.8000
PERF0000000013	PORT000009	2023-12-31	42.5000	15.2000	27.3000	8.8000	2.3500	-22.5000	30.2000
PERF0000000014	PORT000010	2024-01-31	2.1200	1.8200	0.3000	1.2000	1.7500	-2.5000	8.5000
PERF0000000021	PORT000011	2024-03-31	2.1000	5.8000	-3.7000	3.2000	0.6800	-4.5000	9.8000
PERF0000000022	PORT000011	2023-12-31	1.8500	4.2000	-2.3500	2.8000	0.7200	-3.8000	8.5000
PERF0000000023	PORT000011	2023-09-30	3.2000	6.1000	-2.9000	3.1000	0.7500	-5.2000	10.2000
PERF0000000024	PORT000011	2023-06-30	4.5000	7.2000	-2.7000	2.9000	0.8100	-3.1000	8.8000
PERF0000000025	PORT000011	2023-03-31	-1.2000	1.4000	-2.6000	3.5000	0.4800	-6.8000	12.5000
PERF0000000026	PORT000011	2022-12-31	1.6000	3.5000	-1.9000	2.6000	0.6500	-4.2000	9.1000
PERF0000000027	PORT000012	2023-09-30	3.9000	4.2000	-0.3000	0.8000	1.4200	-1.2000	2.1000
PERF0000000028	PORT000012	2023-12-31	3.6000	3.9000	-0.3000	0.7500	1.3800	-1.1000	2.0000
PERF0000000029	PORT000012	2024-03-31	4.2000	4.5000	-0.3000	0.8200	1.4500	-1.3000	2.2000
PERF0000000030	PORT000012	2024-06-30	3.8000	4.1000	-0.3000	0.7800	1.4000	-1.1500	2.0500
PERF0000000031	PORT000012	2024-09-30	4.4000	4.7000	-0.3000	0.8500	1.5000	-1.2000	2.1500
PERF0000000032	PORT000012	2024-12-31	3.7000	4.0000	-0.3000	0.8000	1.3800	-1.1000	2.0000
PERF0000000033	PORT000013	2023-09-30	3.2000	3.1000	0.1000	1.2000	1.4500	-2.1000	3.2000
PERF0000000034	PORT000013	2023-12-31	4.1000	3.9000	0.2000	1.1500	1.5500	-1.9000	3.1000
PERF0000000035	PORT000013	2024-03-31	3.8000	3.6000	0.2000	1.1800	1.4800	-2.0000	3.1500
PERF0000000036	PORT000013	2024-06-30	3.5000	3.3000	0.2000	1.2200	1.4200	-2.2000	3.2500
PERF0000000037	PORT000013	2024-09-30	4.2000	3.9000	0.3000	1.2500	1.5800	-1.8000	3.1000
PERF0000000038	PORT000013	2024-12-31	3.9000	3.7000	0.2000	1.2000	1.5000	-2.0000	3.2000
PERF0000000039	PORT000014	2022-09-30	2.1000	1.8000	0.3000	3.5000	0.4200	-8.2000	14.8000
PERF0000000040	PORT000014	2022-12-31	-18.3000	-15.6000	-2.7000	4.2000	-1.8500	-22.5000	18.9000
PERF0000000041	PORT000014	2023-03-31	-14.5000	-11.2000	-3.3000	4.5000	-1.6200	-19.8000	17.6000
PERF0000000042	PORT000014	2023-06-30	8.4000	6.7000	1.7000	3.8000	0.6800	-5.2000	12.5000
PERF0000000043	PORT000014	2023-09-30	7.2000	5.8000	1.4000	3.6000	0.7200	-4.8000	11.9000
PERF0000000044	PORT000014	2023-12-31	6.8000	5.5000	1.3000	3.4000	0.6500	-4.5000	11.2000
PERF0000000015	PORT000002	2023-03-31	3.2000	2.9000	0.3000	1.5000	1.2800	-3.1000	4.5000
PERF0000000016	PORT000002	2023-06-30	4.1000	3.8000	0.3000	1.4500	1.3800	-2.5000	3.9000
PERF0000000017	PORT000002	2023-09-30	3.6000	3.3000	0.3000	1.5500	1.3200	-2.8000	4.2000
PERF0000000018	PORT000002	2023-12-31	4.3000	4.0000	0.3000	1.4000	1.4500	-2.3000	3.8000
PERF0000000019	PORT000002	2024-03-31	3.8000	3.5000	0.3000	1.4800	1.3500	-2.6000	4.0000
\.


--
-- TOC entry 3411 (class 0 OID 16851)
-- Dependencies: 215
-- Data for Name: portfolio_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.portfolio_master (portfolio_id, client_id, portfolio_name, strategy_type, benchmark_id, inception_date, base_currency, aum, status, managed_by) FROM stdin;
PORT000001	CLI000001	Arjun - Growth Portfolio	GROWTH	BM001	2015-06-01	INR	12500000.00	ACTIVE	FundManager_01
PORT000002	CLI000002	Priya - Balanced Portfolio	BALANCED	BM005	2018-03-15	INR	3800000.00	ACTIVE	FundManager_01
PORT000003	CLI000003	Sharma - Aggressive Growth	GROWTH	BM002	2010-11-20	INR	85000000.00	ACTIVE	FundManager_02
PORT000004	CLI000004	Anita - Conservative Plan	CONSERVATIVE	BM004	2020-01-10	INR	450000.00	ACTIVE	FundManager_02
PORT000005	CLI000005	Sheikh - Income Portfolio	INCOME	BM005	2012-08-05	INR	18500000.00	ACTIVE	FundManager_03
PORT000006	CLI000006	Agarwal - Estate Portfolio	CUSTOM	BM002	2008-02-14	INR	180000000.00	ACTIVE	FundManager_03
PORT000007	CLI000007	Kiran - SIP Growth	GROWTH	BM001	2019-07-22	INR	320000.00	ACTIVE	FundManager_04
PORT000008	CLI000008	Deepika - Balanced Govt	BALANCED	BM005	2014-04-30	INR	28000000.00	ACTIVE	FundManager_04
PORT000009	CLI000009	Varma - Multi Asset	CUSTOM	BM002	2005-09-01	INR	420000000.00	ACTIVE	FundManager_05
PORT000010	CLI000010	Lakshmi - Starter SIP	GROWTH	BM001	2022-06-18	INR	85000.00	ACTIVE	FundManager_05
PORT000011	CLI000011	Vikram - Multi Asset Balanced	BALANCED	BM008	2016-11-10	INR	8500000.00	ACTIVE	FundManager_04
PORT000012	CLI000012	Prateek - Compliance INCOME Portfolio	INCOME	BM009	2019-04-01	INR	9500000.00	ACTIVE	FundManager_03
PORT000013	CLI000013	Sneha - Conservative Growth Portfolio	CONSERVATIVE	BM010	2017-08-01	INR	12000000.00	ACTIVE	FundManager_01
PORT000014	CLI000014	Rohit - Aggressive Growth Portfolio	GROWTH	BM011	2015-07-01	INR	25000000.00	ACTIVE	FundManager_02
\.


--
-- TOC entry 3413 (class 0 OID 16913)
-- Dependencies: 217
-- Data for Name: portfolio_transactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.portfolio_transactions (port_txn_id, portfolio_id, txn_date, txn_type, isin, quantity, price, amount, settlement_date, broker_id, initiated_by) FROM stdin;
PTXN0000000001	PORT000001	2024-01-02	SIP	INF179K01VQ8	500.0000	810.0000	405000.00	2024-01-04	BSE_STAR	SYSTEM_SIP
PTXN0000000002	PORT000001	2024-01-15	BUY	INF200K01RD7	200.0000	490.0000	98000.00	2024-01-17	BSE_STAR	CLIENT
PTXN0000000003	PORT000003	2024-01-10	BUY	INF090I01239	2000.0000	960.0000	1920000.00	2024-01-12	NSE	FUND_MANAGER
PTXN0000000004	PORT000003	2024-01-22	SELL	INF179K01VQ8	500.0000	815.0000	407500.00	2024-01-24	BSE_STAR	RM
PTXN0000000005	PORT000005	2024-01-05	SIP	INF204K01K34	2000.0000	196.0000	392000.00	2024-01-07	BSE_STAR	SYSTEM_SIP
PTXN0000000006	PORT000006	2024-01-08	BUY	NSE:RELIANCE	1000.0000	2850.0000	2850000.00	2024-01-10	NSE	FUND_MANAGER
PTXN0000000007	PORT000006	2024-01-20	SELL	NSE:HDFCBANK	2000.0000	1670.0000	3340000.00	2024-01-22	NSE	CLIENT
PTXN0000000008	PORT000007	2024-01-02	SIP	INF179K01VQ8	10.0000	815.0000	8150.00	2024-01-04	BSE_STAR	SYSTEM_SIP
PTXN0000000009	PORT000008	2024-01-10	BUY	INF090I01239	500.0000	970.0000	485000.00	2024-01-12	BSE_STAR	RM
PTXN0000000010	PORT000009	2024-01-03	BUY	NSE:TATAMOTORS	5000.0000	880.0000	4400000.00	2024-01-05	NSE	FUND_MANAGER
PTXN0000000011	PORT000010	2024-01-02	SIP	INF179K01VQ8	5.0000	815.0000	4075.00	2024-01-04	BSE_STAR	SYSTEM_SIP
PTXN0000000012	PORT000002	2024-02-01	SIP	INF209K01LQ8	100.0000	638.0000	63800.00	2024-02-03	BSE_STAR	SYSTEM_SIP
\.


--
-- TOC entry 3424 (class 0 OID 0)
-- Dependencies: 220
-- Name: fund_performance_cache_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fund_performance_cache_cache_id_seq', 24, true);


--
-- TOC entry 3250 (class 2606 OID 16831)
-- Name: benchmark_master benchmark_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.benchmark_master
    ADD CONSTRAINT benchmark_master_pkey PRIMARY KEY (benchmark_id);


--
-- TOC entry 3260 (class 2606 OID 32778)
-- Name: fund_master fund_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_master
    ADD CONSTRAINT fund_master_pkey PRIMARY KEY (fund_id);


--
-- TOC entry 3262 (class 2606 OID 32786)
-- Name: fund_performance_cache fund_performance_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_performance_cache
    ADD CONSTRAINT fund_performance_cache_pkey PRIMARY KEY (cache_id);


--
-- TOC entry 3254 (class 2606 OID 16881)
-- Name: holdings holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_pkey PRIMARY KEY (holding_id);


--
-- TOC entry 3258 (class 2606 OID 16927)
-- Name: performance_history performance_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.performance_history
    ADD CONSTRAINT performance_history_pkey PRIMARY KEY (perf_id);


--
-- TOC entry 3252 (class 2606 OID 16857)
-- Name: portfolio_master portfolio_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.portfolio_master
    ADD CONSTRAINT portfolio_master_pkey PRIMARY KEY (portfolio_id);


--
-- TOC entry 3256 (class 2606 OID 16917)
-- Name: portfolio_transactions portfolio_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_pkey PRIMARY KEY (port_txn_id);


--
-- TOC entry 3267 (class 2606 OID 32787)
-- Name: fund_performance_cache fund_performance_cache_fund_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fund_performance_cache
    ADD CONSTRAINT fund_performance_cache_fund_id_fkey FOREIGN KEY (fund_id) REFERENCES public.fund_master(fund_id);


--
-- TOC entry 3264 (class 2606 OID 16882)
-- Name: holdings holdings_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


--
-- TOC entry 3266 (class 2606 OID 16928)
-- Name: performance_history performance_history_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.performance_history
    ADD CONSTRAINT performance_history_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


--
-- TOC entry 3263 (class 2606 OID 16858)
-- Name: portfolio_master portfolio_master_benchmark_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.portfolio_master
    ADD CONSTRAINT portfolio_master_benchmark_id_fkey FOREIGN KEY (benchmark_id) REFERENCES public.benchmark_master(benchmark_id);


--
-- TOC entry 3265 (class 2606 OID 16918)
-- Name: portfolio_transactions portfolio_transactions_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


-- Completed on 2026-05-11 19:30:13

--
-- PostgreSQL database dump complete
--

