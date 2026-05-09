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

ALTER TABLE IF EXISTS ONLY public.transaction_history DROP CONSTRAINT IF EXISTS transaction_history_account_id_fkey;
ALTER TABLE IF EXISTS ONLY public.liability_accounts DROP CONSTRAINT IF EXISTS liability_accounts_customer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.account_master DROP CONSTRAINT IF EXISTS account_master_customer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction_history DROP CONSTRAINT IF EXISTS transaction_history_pkey;
ALTER TABLE IF EXISTS ONLY public.liability_accounts DROP CONSTRAINT IF EXISTS liability_accounts_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_master DROP CONSTRAINT IF EXISTS customer_master_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_master DROP CONSTRAINT IF EXISTS customer_master_party_id_key;
ALTER TABLE IF EXISTS ONLY public.customer_master DROP CONSTRAINT IF EXISTS customer_master_pan_number_key;
ALTER TABLE IF EXISTS ONLY public.account_master DROP CONSTRAINT IF EXISTS account_master_pkey;
DROP TABLE IF EXISTS public.transaction_history;
DROP TABLE IF EXISTS public.liability_accounts;
DROP TABLE IF EXISTS public.customer_master;
DROP TABLE IF EXISTS public.account_master;
DROP TYPE IF EXISTS public.txn_type_enum;
DROP TYPE IF EXISTS public.txn_channel_enum;
DROP TYPE IF EXISTS public.segment_enum;
DROP TYPE IF EXISTS public.liability_type_enum;
DROP TYPE IF EXISTS public.gender_enum;
DROP TYPE IF EXISTS public.customer_status_enum;
DROP TYPE IF EXISTS public.account_type_enum;
DROP TYPE IF EXISTS public.account_status_enum;
--
-- Name: account_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_status_enum AS ENUM (
    'ACTIVE',
    'FROZEN',
    'CLOSED'
);


--
-- Name: account_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.account_type_enum AS ENUM (
    'SAVINGS',
    'CURRENT',
    'FD',
    'NRE',
    'NRO',
    'OD'
);


--
-- Name: customer_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.customer_status_enum AS ENUM (
    'ACTIVE',
    'DORMANT',
    'CLOSED',
    'BLOCKED'
);


--
-- Name: gender_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gender_enum AS ENUM (
    'M',
    'F',
    'O'
);


--
-- Name: liability_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.liability_type_enum AS ENUM (
    'HOME_LOAN',
    'PERSONAL_LOAN',
    'BUSINESS_LOAN',
    'OD',
    'MORTGAGE',
    'AUTO_LOAN'
);


--
-- Name: segment_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.segment_enum AS ENUM (
    'RETAIL',
    'HNI',
    'UHNI',
    'NRI',
    'CORP'
);


--
-- Name: txn_channel_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.txn_channel_enum AS ENUM (
    'NEFT',
    'RTGS',
    'IMPS',
    'UPI',
    'CASH',
    'CHEQUT',
    'ATM',
    'AUTO_DEBIT'
);


--
-- Name: txn_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.txn_type_enum AS ENUM (
    'CREDIT',
    'DEBIT'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_master (
    account_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    account_type public.account_type_enum NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying,
    current_balance numeric(15,2) NOT NULL,
    available_balance numeric(15,2) NOT NULL,
    od_limit numeric(15,2) DEFAULT 0.00,
    status public.account_status_enum DEFAULT 'ACTIVE'::public.account_status_enum,
    open_date date NOT NULL,
    branch_code character varying(10) NOT NULL
);


--
-- Name: customer_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_master (
    customer_id character varying(12) NOT NULL,
    party_id character varying(12) NOT NULL,
    full_name character varying(100) NOT NULL,
    dob date NOT NULL,
    gender public.gender_enum NOT NULL,
    nationality character varying(50) DEFAULT 'Indian'::character varying,
    mobile character varying(15) NOT NULL,
    email character varying(100),
    pan_number character varying(10) NOT NULL,
    aadhaar_ref character varying(8),
    address_id character varying(12),
    relationship_manager_id character varying(10),
    customer_since date NOT NULL,
    segment_code public.segment_enum NOT NULL,
    status public.customer_status_enum DEFAULT 'ACTIVE'::public.customer_status_enum,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: liability_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.liability_accounts (
    liability_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    liability_type public.liability_type_enum NOT NULL,
    principal_amount numeric(15,2) NOT NULL,
    outstanding_balance numeric(15,2) NOT NULL,
    emi_amount numeric(12,2),
    start_date date NOT NULL,
    maturity_date date NOT NULL,
    dpd_days integer DEFAULT 0,
    npa_flag boolean DEFAULT false
);


--
-- Name: transaction_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_history (
    txn_id character varying(16) NOT NULL,
    account_id character varying(14) NOT NULL,
    txn_date date NOT NULL,
    txn_type public.txn_type_enum NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying,
    channel public.txn_channel_enum NOT NULL,
    counterparty_name character varying(100),
    counterparty_account character varying(20),
    narration character varying(200),
    balance_after numeric(15,2) NOT NULL
);


--
-- Data for Name: account_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.account_master (account_id, customer_id, account_type, currency, current_balance, available_balance, od_limit, status, open_date, branch_code) FROM stdin;
ACC0000000001	CUST000001	SAVINGS	INR	4250000.00	4250000.00	0.00	ACTIVE	2015-06-01	MUM001
ACC0000000002	CUST000001	FD	INR	10000000.00	10000000.00	0.00	ACTIVE	2020-01-15	MUM001
ACC0000000003	CUST000002	SAVINGS	INR	875000.00	875000.00	0.00	ACTIVE	2018-03-15	CHN001
ACC0000000004	CUST000003	CURRENT	INR	25000000.00	23500000.00	2000000.00	ACTIVE	2010-11-20	DEL001
ACC0000000005	CUST000003	FD	INR	50000000.00	50000000.00	0.00	ACTIVE	2015-03-01	DEL001
ACC0000000006	CUST000004	SAVINGS	INR	125000.00	125000.00	0.00	ACTIVE	2020-01-10	BNG001
ACC0000000007	CUST000005	SAVINGS	INR	3100000.00	3100000.00	0.00	ACTIVE	2012-08-05	HYD001
ACC0000000008	CUST000005	OD	INR	0.00	2000000.00	2000000.00	ACTIVE	2018-06-01	HYD001
ACC0000000009	CUST000006	SAVINGS	INR	18000000.00	18000000.00	0.00	ACTIVE	2008-02-14	MUM002
ACC0000000010	CUST000007	SAVINGS	INR	220000.00	220000.00	0.00	ACTIVE	2019-07-22	CHN002
ACC0000000011	CUST000008	SAVINGS	INR	5400000.00	5400000.00	0.00	ACTIVE	2014-04-30	KOC001
ACC0000000012	CUST000009	CURRENT	INR	42000000.00	40000000.00	5000000.00	ACTIVE	2005-09-01	MUM001
ACC0000000013	CUST000010	SAVINGS	INR	45000.00	45000.00	0.00	ACTIVE	2022-06-18	AHM001
ACC0000000014	CUST000012	SAVINGS	INR	850000.00	850000.00	0.00	ACTIVE	2019-03-10	DEL001
ACC0000000015	CUST000013	SAVINGS	INR	1250000.00	1250000.00	0.00	ACTIVE	2017-07-22	BLR001
ACC0000000016	CUST000014	SAVINGS	INR	2500000.00	2500000.00	0.00	ACTIVE	2015-06-18	MUM002
\.


--
-- Data for Name: customer_master; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_master (customer_id, party_id, full_name, dob, gender, nationality, mobile, email, pan_number, aadhaar_ref, address_id, relationship_manager_id, customer_since, segment_code, status, created_at, updated_at) FROM stdin;
CUST000001	PARTY001	Arjun Ramesh Menon	1978-04-12	M	Indian	9821034567	arjun.menon@email.com	AXBPM1234C	56781234	ADDR001	RM001	2015-06-01	HNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000002	PARTY002	Priya Suresh Iyer	1985-09-23	F	Indian	9845678901	priya.iyer@email.com	BQCPI5678D	12345678	ADDR002	RM001	2018-03-15	HNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000003	PARTY003	Rajesh Kumar Sharma	1965-01-30	M	Indian	9731234567	rajesh.sharma@email.com	CRDQS9012E	87654321	ADDR003	RM002	2010-11-20	UHNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000004	PARTY004	Anita Vijay Nair	1990-07-15	F	Indian	9654321098	anita.nair@email.com	DSERT3456F	23456789	ADDR004	RM002	2020-01-10	RETAIL	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000005	PARTY005	Mohammed Farhan Sheikh	1972-11-08	M	Indian	9978654321	farhan.sheikh@email.com	ETFUS7890G	34567890	ADDR005	RM003	2012-08-05	HNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000006	PARTY006	Sunita Agarwal	1958-03-22	F	Indian	9812345670	sunita.agarwal@email.com	FUGVA2345H	45678901	ADDR006	RM003	2008-02-14	UHNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000007	PARTY007	Kiran Balachandran	1983-06-17	M	Indian	9745612380	kiran.bala@email.com	GVHWB6789J	56789012	ADDR007	RM004	2019-07-22	RETAIL	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000008	PARTY008	Deepika Rajan Pillai	1970-12-05	F	Indian	9667890123	deepika.pillai@email.com	HWIXC0123K	67890123	ADDR008	RM004	2014-04-30	HNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000009	PARTY009	Suresh Chandran Varma	1955-08-19	M	Indian	9598765432	suresh.varma@email.com	IXJYD4567L	78901234	ADDR009	RM005	2005-09-01	UHNI	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000010	PARTY010	Lakshmi Narayan Patel	1995-02-28	F	Indian	9432109876	lakshmi.patel@email.com	JYKZE8901M	89012345	ADDR010	RM005	2022-06-18	RETAIL	ACTIVE	2026-04-15 14:25:38.752318	2026-04-15 14:25:38.752318
CUST000011	PARTY011	Vikram Anand Krishnan	1979-08-14	M	Indian	9876543210	vikram.krishnan@email.com	KABVK3579N	56781255	ADDR011	RM002	2016-11-10	HNI	ACTIVE	2026-05-08 14:01:09.4151	2026-05-08 14:01:09.4151
CUST000012	PARTY012	Prateek Anand Mathur	1985-06-15	M	Indian	9876543212	prateek.mathur@nseindia.com	BKPMA5512L	76543210	ADDR012	RM003	2019-03-10	HNI	ACTIVE	2026-05-08 18:41:14.197959	2026-05-08 18:41:14.197959
CUST000013	PARTY013	Sneha Anand Varma	1982-11-20	F	Indian	9876543213	sneha.varma@snehavarma.in	CLPSV7723K	86543210	ADDR013	RM001	2017-07-22	HNI	ACTIVE	2026-05-08 18:43:07.713666	2026-05-08 18:43:07.713666
CUST000014	PARTY014	Rohit Suresh Kapoor	1978-04-05	M	Indian	9876543214	rohit.kapoor@kapoorindustries.com	DKPRK8834M	96543210	ADDR014	RM004	2015-06-18	HNI	ACTIVE	2026-05-08 18:43:07.892959	2026-05-08 18:43:07.892959
\.


--
-- Data for Name: liability_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.liability_accounts (liability_id, customer_id, liability_type, principal_amount, outstanding_balance, emi_amount, start_date, maturity_date, dpd_days, npa_flag) FROM stdin;
LIAB00000001	CUST000001	HOME_LOAN	15000000.00	9800000.00	85000.00	2017-03-01	2032-03-01	0	f
LIAB00000002	CUST000003	BUSINESS_LOAN	50000000.00	22000000.00	450000.00	2019-06-01	2029-06-01	0	f
LIAB00000003	CUST000005	PERSONAL_LOAN	2000000.00	1200000.00	48000.00	2022-01-01	2026-01-01	0	f
LIAB00000004	CUST000007	AUTO_LOAN	1200000.00	780000.00	28000.00	2022-09-01	2026-09-01	0	f
LIAB00000005	CUST000008	HOME_LOAN	20000000.00	16500000.00	155000.00	2020-07-01	2040-07-01	0	f
LIAB00000006	CUST000010	PERSONAL_LOAN	500000.00	480000.00	18500.00	2023-12-01	2026-12-01	15	f
LIAB00000011	CUST000011	HOME_LOAN	5000000.00	3200000.00	42000.00	2018-04-01	2038-04-01	0	f
LIAB00000012	CUST000012	HOME_LOAN	5000000.00	3500000.00	42000.00	2020-06-01	2040-06-01	0	f
LIAB00000013	CUST000014	HOME_LOAN	10000000.00	7500000.00	95000.00	2016-01-01	2046-01-01	0	f
\.


--
-- Data for Name: transaction_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_history (txn_id, account_id, txn_date, txn_type, amount, currency, channel, counterparty_name, counterparty_account, narration, balance_after) FROM stdin;
TXN0000000001	ACC0000000001	2024-01-01	CREDIT	500000.00	INR	NEFT	Arjun Menon Consulting LLP	HDFC0098765	Monthly consulting fee	4750000.00
TXN0000000002	ACC0000000001	2024-01-05	DEBIT	120000.00	INR	NEFT	LIC of India	LIC00012345	LIC premium payment	4630000.00
TXN0000000003	ACC0000000001	2024-01-10	DEBIT	85000.00	INR	AUTO_DEBIT	HDFC Home Loan	HDFC0001234	Home loan EMI Jan-2024	4545000.00
TXN0000000004	ACC0000000001	2024-02-01	CREDIT	500000.00	INR	NEFT	Arjun Menon Consulting LLP	HDFC0098765	Monthly consulting fee	5045000.00
TXN0000000005	ACC0000000003	2024-01-03	CREDIT	185000.00	INR	NEFT	Infosys Ltd Payroll	INFY0001001	Salary Jan-2024	1060000.00
TXN0000000006	ACC0000000003	2024-01-15	DEBIT	42000.00	INR	NEFT	HDFC Bank Credit Card	HDFC0005678	Credit card payment	1018000.00
TXN0000000007	ACC0000000004	2024-01-02	CREDIT	3500000.00	INR	RTGS	Sharma Industries Pvt Ltd	ICIC0098001	Business revenue Jan	28500000.00
TXN0000000008	ACC0000000004	2024-01-08	DEBIT	1200000.00	INR	RTGS	GST Portal	GOV0000001	GST payment Q3	27300000.00
TXN0000000009	ACC0000000007	2024-01-04	CREDIT	320000.00	INR	NEFT	Sheikh Pharma Distributors	AXIS0056789	Dividend income	3420000.00
TXN0000000010	ACC0000000007	2024-01-20	CREDIT	85000.00	INR	NEFT	Unknown sender XYZ Trading	UNKN0099999	Transfer - reason unspecified	3505000.00
TXN0000000011	ACC0000000009	2024-01-01	CREDIT	2000000.00	INR	RTGS	Agarwal Estates Pvt Ltd	SBIIN001234	Rental income Jan	20000000.00
TXN0000000012	ACC0000000011	2024-01-05	CREDIT	420000.00	INR	NEFT	Kerala Govt Treasury	KGOV0001111	Director salary Jan	5820000.00
TXN0000000013	ACC0000000012	2024-01-02	CREDIT	8000000.00	INR	RTGS	Varma Group Holdings	VARA0001000	Promoter dividend	50000000.00
TXN0000000014	ACC0000000010	2024-01-03	CREDIT	65000.00	INR	NEFT	Tech Mahindra Payroll	TECHM001234	Salary Jan-2024	285000.00
TXN0000000015	ACC0000000013	2024-01-05	CREDIT	28000.00	INR	NEFT	Startup XYZ Pvt Ltd Payroll	STRT0001234	Salary Jan-2024	73000.00
TXN0000000016	ACC0000000014	2025-04-01	CREDIT	145000.00	INR	NEFT	NSE Securities India Ltd	HDFC0001122	Salary credit Apr 2025 - NSE	995000.00
TXN0000000017	ACC0000000015	2025-04-01	CREDIT	220000.00	INR	NEFT	Varma Advisory Services LLP	ICIC0098765	Business income credit Apr 2025	1470000.00
TXN0000000018	ACC0000000016	2025-04-01	CREDIT	380000.00	INR	RTGS	Kapoor Industries Pvt Ltd	AXIS0044567	Dividend payout Q4 FY2025 -- Kapoor Industries	2880000.00
\.


--
-- Name: account_master account_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_master
    ADD CONSTRAINT account_master_pkey PRIMARY KEY (account_id);


--
-- Name: customer_master customer_master_pan_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_master
    ADD CONSTRAINT customer_master_pan_number_key UNIQUE (pan_number);


--
-- Name: customer_master customer_master_party_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_master
    ADD CONSTRAINT customer_master_party_id_key UNIQUE (party_id);


--
-- Name: customer_master customer_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_master
    ADD CONSTRAINT customer_master_pkey PRIMARY KEY (customer_id);


--
-- Name: liability_accounts liability_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liability_accounts
    ADD CONSTRAINT liability_accounts_pkey PRIMARY KEY (liability_id);


--
-- Name: transaction_history transaction_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_history
    ADD CONSTRAINT transaction_history_pkey PRIMARY KEY (txn_id);


--
-- Name: account_master account_master_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_master
    ADD CONSTRAINT account_master_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer_master(customer_id);


--
-- Name: liability_accounts liability_accounts_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liability_accounts
    ADD CONSTRAINT liability_accounts_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer_master(customer_id);


--
-- Name: transaction_history transaction_history_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_history
    ADD CONSTRAINT transaction_history_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.account_master(account_id);


--
-- PostgreSQL database dump complete
--

