--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 16.3

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

ALTER TABLE IF EXISTS ONLY public.portfolio_transactions DROP CONSTRAINT IF EXISTS portfolio_transactions_portfolio_id_fkey;
ALTER TABLE IF EXISTS ONLY public.portfolio_master DROP CONSTRAINT IF EXISTS portfolio_master_benchmark_id_fkey;
ALTER TABLE IF EXISTS ONLY public.performance_history DROP CONSTRAINT IF EXISTS performance_history_portfolio_id_fkey;
ALTER TABLE IF EXISTS ONLY public.holdings DROP CONSTRAINT IF EXISTS holdings_portfolio_id_fkey;
ALTER TABLE IF EXISTS ONLY public.portfolio_transactions DROP CONSTRAINT IF EXISTS portfolio_transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.portfolio_master DROP CONSTRAINT IF EXISTS portfolio_master_pkey;
ALTER TABLE IF EXISTS ONLY public.performance_history DROP CONSTRAINT IF EXISTS performance_history_pkey;
ALTER TABLE IF EXISTS ONLY public.holdings DROP CONSTRAINT IF EXISTS holdings_pkey;
ALTER TABLE IF EXISTS ONLY public.benchmark_master DROP CONSTRAINT IF EXISTS benchmark_master_pkey;
DROP TABLE IF EXISTS public.portfolio_transactions;
DROP TABLE IF EXISTS public.portfolio_master;
DROP TABLE IF EXISTS public.performance_history;
DROP TABLE IF EXISTS public.holdings;
DROP TABLE IF EXISTS public.benchmark_master;
DROP TYPE IF EXISTS public.strategy_type_enum;
DROP TYPE IF EXISTS public.portfolio_status_enum;
DROP TYPE IF EXISTS public.port_txn_type_enum;
DROP TYPE IF EXISTS public.initiated_by_enum;
DROP TYPE IF EXISTS public.holding_asset_class_enum;
DROP TYPE IF EXISTS public.asset_class_enum;
--
-- Name: asset_class_enum; Type: TYPE; Schema: public; Owner: -
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


--
-- Name: holding_asset_class_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.holding_asset_class_enum AS ENUM (
    'EQUITY',
    'DEBT',
    'HYBRID',
    'GOLD',
    'REIT',
    'CASH'
);


--
-- Name: initiated_by_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.initiated_by_enum AS ENUM (
    'CLIENT',
    'RM',
    'SYSTEM_SIP',
    'FUND_MANAGER'
);


--
-- Name: port_txn_type_enum; Type: TYPE; Schema: public; Owner: -
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


--
-- Name: portfolio_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.portfolio_status_enum AS ENUM (
    'ACTIVE',
    'SUSPENDED',
    'CLOSED'
);


--
-- Name: strategy_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.strategy_type_enum AS ENUM (
    'GROWTH',
    'BALANCED',
    'CONSERVATIVE',
    'INCOME',
    'CUSTOM'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: benchmark_master; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: holdings; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: performance_history; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: portfolio_master; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: portfolio_transactions; Type: TABLE; Schema: public; Owner: -
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


--
-- Data for Name: benchmark_master; Type: TABLE DATA; Schema: public; Owner: -
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
-- Data for Name: holdings; Type: TABLE DATA; Schema: public; Owner: -
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
-- Data for Name: performance_history; Type: TABLE DATA; Schema: public; Owner: -
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
-- Data for Name: portfolio_master; Type: TABLE DATA; Schema: public; Owner: -
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
-- Data for Name: portfolio_transactions; Type: TABLE DATA; Schema: public; Owner: -
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
-- Name: benchmark_master benchmark_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.benchmark_master
    ADD CONSTRAINT benchmark_master_pkey PRIMARY KEY (benchmark_id);


--
-- Name: holdings holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_pkey PRIMARY KEY (holding_id);


--
-- Name: performance_history performance_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_history
    ADD CONSTRAINT performance_history_pkey PRIMARY KEY (perf_id);


--
-- Name: portfolio_master portfolio_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_master
    ADD CONSTRAINT portfolio_master_pkey PRIMARY KEY (portfolio_id);


--
-- Name: portfolio_transactions portfolio_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_pkey PRIMARY KEY (port_txn_id);


--
-- Name: holdings holdings_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


--
-- Name: performance_history performance_history_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_history
    ADD CONSTRAINT performance_history_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


--
-- Name: portfolio_master portfolio_master_benchmark_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_master
    ADD CONSTRAINT portfolio_master_benchmark_id_fkey FOREIGN KEY (benchmark_id) REFERENCES public.benchmark_master(benchmark_id);


--
-- Name: portfolio_transactions portfolio_transactions_portfolio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.portfolio_transactions
    ADD CONSTRAINT portfolio_transactions_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES public.portfolio_master(portfolio_id);


--
-- PostgreSQL database dump complete
--

