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

ALTER TABLE IF EXISTS ONLY public.spend_aggregates DROP CONSTRAINT IF EXISTS spend_aggregates_card_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payment_behaviour DROP CONSTRAINT IF EXISTS payment_behaviour_card_id_fkey;
ALTER TABLE IF EXISTS ONLY public.card_transactions DROP CONSTRAINT IF EXISTS card_transactions_card_id_fkey;
DROP INDEX IF EXISTS public.idx_card_accounts_pan;
ALTER TABLE IF EXISTS ONLY public.spend_aggregates DROP CONSTRAINT IF EXISTS spend_aggregates_pkey;
ALTER TABLE IF EXISTS ONLY public.payment_behaviour DROP CONSTRAINT IF EXISTS payment_behaviour_pkey;
ALTER TABLE IF EXISTS ONLY public.card_transactions DROP CONSTRAINT IF EXISTS card_transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.card_accounts DROP CONSTRAINT IF EXISTS card_accounts_pkey;
DROP TABLE IF EXISTS public.spend_aggregates;
DROP TABLE IF EXISTS public.payment_behaviour;
DROP TABLE IF EXISTS public.card_transactions;
DROP TABLE IF EXISTS public.card_accounts;
DROP TYPE IF EXISTS public.payment_type_enum;
DROP TYPE IF EXISTS public.card_type_enum;
DROP TYPE IF EXISTS public.card_txn_type_enum;
DROP TYPE IF EXISTS public.card_status_enum;
--
-- Name: card_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.card_status_enum AS ENUM (
    'ACTIVE',
    'BLOCKED',
    'EXPIRED',
    'CLOSED'
);


--
-- Name: card_txn_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.card_txn_type_enum AS ENUM (
    'PURCHASE',
    'REFUND',
    'CASH_ADVANCE',
    'EMI'
);


--
-- Name: card_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.card_type_enum AS ENUM (
    'SIGNATURE',
    'PLATINUM',
    'GOLD',
    'CLASSIC',
    'BUSINESS',
    'SUPER_PREMIUM'
);


--
-- Name: payment_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payment_type_enum AS ENUM (
    'FULL',
    'MINIMUM',
    'PARTIAL',
    'NONE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: card_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_accounts (
    card_id character varying(12) NOT NULL,
    customer_id character varying(12) NOT NULL,
    card_type public.card_type_enum NOT NULL,
    credit_limit numeric(12,2) NOT NULL,
    current_balance numeric(12,2) DEFAULT 0.00,
    available_limit numeric(12,2) NOT NULL,
    min_payment_due numeric(10,2) DEFAULT 0.00,
    payment_due_date date,
    card_status public.card_status_enum DEFAULT 'ACTIVE'::public.card_status_enum,
    issue_date date NOT NULL,
    pan_number character varying(10)
);


--
-- Name: card_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.card_transactions (
    card_txn_id character varying(14) NOT NULL,
    card_id character varying(12) NOT NULL,
    txn_date date NOT NULL,
    merchant_name character varying(100) NOT NULL,
    mcc_code character varying(6) NOT NULL,
    mcc_category character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'INR'::character varying,
    city character varying(50),
    country character varying(50) DEFAULT 'India'::character varying,
    txn_type public.card_txn_type_enum NOT NULL,
    emi_flag boolean DEFAULT false
);


--
-- Name: payment_behaviour; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_behaviour (
    pay_id character varying(14) NOT NULL,
    card_id character varying(12) NOT NULL,
    statement_month character varying(7) NOT NULL,
    amount_due numeric(12,2) NOT NULL,
    amount_paid numeric(12,2) NOT NULL,
    payment_date date,
    payment_type public.payment_type_enum NOT NULL,
    days_late integer DEFAULT 0,
    dpd_flag boolean DEFAULT false
);


--
-- Name: spend_aggregates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spend_aggregates (
    agg_id character varying(14) NOT NULL,
    card_id character varying(12) NOT NULL,
    month_year character varying(7) NOT NULL,
    total_spend numeric(12,2) DEFAULT 0.00,
    travel_spend numeric(12,2) DEFAULT 0.00,
    dining_spend numeric(12,2) DEFAULT 0.00,
    retail_spend numeric(12,2) DEFAULT 0.00,
    utility_spend numeric(12,2) DEFAULT 0.00,
    emi_deductions numeric(12,2) DEFAULT 0.00,
    cash_advances numeric(12,2) DEFAULT 0.00,
    avg_txn_value numeric(10,2)
);


--
-- Data for Name: card_accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.card_accounts (card_id, customer_id, card_type, credit_limit, current_balance, available_limit, min_payment_due, payment_due_date, card_status, issue_date, pan_number) FROM stdin;
CARD00000001	CUST000001	SIGNATURE	1500000.00	285000.00	1215000.00	14250.00	2024-02-15	ACTIVE	2019-06-01	AXBPM1234C
CARD00000002	CUST000002	PLATINUM	500000.00	125000.00	375000.00	6250.00	2024-02-15	ACTIVE	2021-03-15	BQCPI5678D
CARD00000003	CUST000003	SUPER_PREMIUM	5000000.00	1850000.00	3150000.00	92500.00	2024-02-15	ACTIVE	2015-11-20	CRDQS9012E
CARD00000004	CUST000004	CLASSIC	80000.00	65000.00	15000.00	3250.00	2024-02-15	ACTIVE	2022-01-10	DSERT3456F
CARD00000005	CUST000005	BUSINESS	2000000.00	980000.00	1020000.00	49000.00	2024-02-15	ACTIVE	2018-08-05	ETFUS7890G
CARD00000006	CUST000006	SUPER_PREMIUM	5000000.00	320000.00	4680000.00	16000.00	2024-02-15	ACTIVE	2012-02-14	FUGVA2345H
CARD00000007	CUST000007	CLASSIC	60000.00	42000.00	18000.00	2100.00	2024-02-15	ACTIVE	2020-07-22	GVHWB6789J
CARD00000008	CUST000008	PLATINUM	1000000.00	285000.00	715000.00	14250.00	2024-02-15	ACTIVE	2017-04-30	HWIXC0123K
CARD00000009	CUST000009	SUPER_PREMIUM	5000000.00	180000.00	4820000.00	9000.00	2024-02-15	ACTIVE	2010-09-01	IXJYD4567L
CARD00000010	CUST000010	CLASSIC	40000.00	38500.00	1500.00	1925.00	2024-02-15	ACTIVE	2023-06-18	JYKZE8901M
CARD00000011	CUST000011	GOLD	200000.00	90000.00	110000.00	9000.00	2024-04-15	ACTIVE	2017-01-15	KABVK3579N
CARD00000012	CUST000012	GOLD	200000.00	50000.00	150000.00	5000.00	2025-05-10	ACTIVE	2019-04-01	BKPMA5512L
CARD00000013	CUST000013	PLATINUM	300000.00	78000.00	222000.00	7800.00	2025-05-12	ACTIVE	2018-01-10	CLPSV7723K
CARD00000014	CUST000014	PLATINUM	500000.00	140000.00	360000.00	14000.00	2025-05-15	ACTIVE	2016-01-10	DKPRK8834M
\.


--
-- Data for Name: card_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.card_transactions (card_txn_id, card_id, txn_date, merchant_name, mcc_code, mcc_category, amount, currency, city, country, txn_type, emi_flag) FROM stdin;
CTXN0000000001	CARD00000001	2024-01-05	Taj Hotels Mumbai	7011	Hotels & Lodging	45000.00	INR	Mumbai	India	PURCHASE	f
CTXN0000000002	CARD00000001	2024-01-08	Louis Vuitton BKC	5691	Clothing Stores	85000.00	INR	Mumbai	India	PURCHASE	f
CTXN0000000003	CARD00000001	2024-01-12	Singapore Airlines	3001	Airlines	120000.00	INR	Mumbai	India	PURCHASE	f
CTXN0000000004	CARD00000002	2024-01-04	Swiggy	5812	Restaurants	2800.00	INR	Chennai	India	PURCHASE	f
CTXN0000000005	CARD00000002	2024-01-10	Amazon India	5999	Online Retail	8500.00	INR	Chennai	India	PURCHASE	f
CTXN0000000006	CARD00000002	2024-01-18	BPCL Fuel Station	5541	Auto Fuel	4200.00	INR	Chennai	India	PURCHASE	f
CTXN0000000007	CARD00000003	2024-01-03	Bulgari Dubai	5944	Jewelry Stores	850000.00	AED	Dubai	UAE	PURCHASE	f
CTXN0000000008	CARD00000003	2024-01-09	Emirates Business Class	3003	Airlines	420000.00	INR	Delhi	India	PURCHASE	f
CTXN0000000009	CARD00000003	2024-01-15	ITC Maurya Hotel	7011	Hotels & Lodging	180000.00	INR	Delhi	India	PURCHASE	f
CTXN0000000010	CARD00000004	2024-01-02	Reliance Smart	5411	Grocery Stores	3200.00	INR	Bangalore	India	PURCHASE	f
CTXN0000000011	CARD00000004	2024-01-10	Ola Cabs	4121	Taxis	1800.00	INR	Bangalore	India	PURCHASE	f
CTXN0000000012	CARD00000004	2024-01-15	Zomato	5812	Restaurants	2100.00	INR	Bangalore	India	PURCHASE	f
CTXN0000000013	CARD00000005	2024-01-06	Amazon Business India	5999	Online Retail	185000.00	INR	Hyderabad	India	PURCHASE	f
CTXN0000000014	CARD00000005	2024-01-12	IndiGo Airlines	3001	Airlines	28000.00	INR	Hyderabad	India	PURCHASE	f
CTXN0000000015	CARD00000005	2024-01-20	Unknown Merchant - CASH	6011	Cash Advance	200000.00	INR	Hyderabad	India	CASH_ADVANCE	f
CTXN0000000016	CARD00000006	2024-01-08	Christie s Auction London	5999	Auction/Art	950000.00	GBP	London	UK	PURCHASE	f
CTXN0000000017	CARD00000006	2024-01-14	Four Seasons Geneva	7011	Hotels & Lodging	280000.00	INR	Geneva	Switzerland	PURCHASE	f
CTXN0000000018	CARD00000008	2024-01-05	Apollo Pharmacy	5912	Drug Stores	3500.00	INR	Kochi	India	PURCHASE	f
CTXN0000000019	CARD00000008	2024-01-10	Big Basket	5411	Grocery Stores	8200.00	INR	Kochi	India	PURCHASE	f
CTXN0000000020	CARD00000010	2024-01-03	D-Mart	5411	Grocery Stores	2100.00	INR	Ahmedabad	India	PURCHASE	f
\.


--
-- Data for Name: payment_behaviour; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_behaviour (pay_id, card_id, statement_month, amount_due, amount_paid, payment_date, payment_type, days_late, dpd_flag) FROM stdin;
PAYB0000000001	CARD00000001	2023-12	268000.00	268000.00	2024-01-10	FULL	0	f
PAYB0000000002	CARD00000002	2023-12	38000.00	38000.00	2024-01-12	FULL	0	f
PAYB0000000003	CARD00000003	2023-12	1650000.00	1650000.00	2024-01-08	FULL	0	f
PAYB0000000004	CARD00000004	2023-12	58000.00	2900.00	2024-01-20	MINIMUM	5	f
PAYB0000000005	CARD00000005	2023-12	850000.00	42500.00	2024-01-25	MINIMUM	10	t
PAYB0000000006	CARD00000006	2023-12	290000.00	290000.00	2024-01-05	FULL	0	f
PAYB0000000007	CARD00000007	2023-12	36000.00	10000.00	2024-01-28	PARTIAL	13	t
PAYB0000000008	CARD00000008	2023-12	260000.00	260000.00	2024-01-10	FULL	0	f
PAYB0000000009	CARD00000009	2023-12	165000.00	165000.00	2024-01-06	FULL	0	f
PAYB0000000010	CARD00000010	2023-12	35000.00	1750.00	2024-02-01	MINIMUM	17	t
PAYB0000000011	CARD00000011	2024-03	90000.00	90000.00	2024-04-14	FULL	0	f
PAYB0000000012	CARD00000011	2024-02	88000.00	88000.00	2024-03-13	FULL	0	f
PAYB0000000013	CARD00000011	2024-01	92000.00	92000.00	2024-02-14	FULL	0	f
PAYB0000000014	CARD00000012	2025-03	50000.00	50000.00	2025-04-09	FULL	0	f
PAYB0000000015	CARD00000012	2025-02	48000.00	48000.00	2025-03-09	FULL	0	f
PAYB0000000016	CARD00000012	2025-01	52000.00	52000.00	2025-02-09	FULL	0	f
PAYB0000000017	CARD00000013	2025-03	78000.00	78000.00	2025-04-11	FULL	0	f
PAYB0000000018	CARD00000013	2025-02	74000.00	74000.00	2025-03-11	FULL	0	f
PAYB0000000019	CARD00000013	2025-01	80000.00	80000.00	2025-02-11	FULL	0	f
PAYB0000000020	CARD00000014	2025-03	140000.00	140000.00	2025-04-14	FULL	0	f
PAYB0000000021	CARD00000014	2025-02	130000.00	130000.00	2025-03-14	FULL	0	f
PAYB0000000022	CARD00000014	2025-01	145000.00	145000.00	2025-02-14	FULL	0	f
\.


--
-- Data for Name: spend_aggregates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.spend_aggregates (agg_id, card_id, month_year, total_spend, travel_spend, dining_spend, retail_spend, utility_spend, emi_deductions, cash_advances, avg_txn_value) FROM stdin;
SAGG0000000001	CARD00000001	2024-01	285000.00	125000.00	18000.00	95000.00	8000.00	0.00	0.00	31666.67
SAGG0000000002	CARD00000002	2024-01	42000.00	8500.00	9500.00	12000.00	6200.00	0.00	0.00	4666.67
SAGG0000000003	CARD00000003	2024-01	1850000.00	420000.00	85000.00	980000.00	12000.00	0.00	0.00	205555.56
SAGG0000000004	CARD00000004	2024-01	65000.00	800.00	8500.00	22000.00	5500.00	0.00	0.00	4333.33
SAGG0000000005	CARD00000005	2024-01	980000.00	48000.00	22000.00	185000.00	15000.00	0.00	200000.00	81666.67
SAGG0000000006	CARD00000006	2024-01	320000.00	280000.00	12000.00	18000.00	5000.00	0.00	0.00	80000.00
SAGG0000000007	CARD00000007	2024-01	42000.00	2800.00	8500.00	18000.00	4500.00	0.00	0.00	5250.00
SAGG0000000008	CARD00000008	2024-01	285000.00	45000.00	18000.00	95000.00	22000.00	0.00	0.00	28500.00
SAGG0000000009	CARD00000009	2024-01	180000.00	85000.00	22000.00	45000.00	8000.00	0.00	0.00	30000.00
SAGG0000000010	CARD00000010	2024-01	38500.00	500.00	5200.00	12800.00	4500.00	0.00	0.00	5500.00
SAGG0000000011	CARD00000011	2024-03	90000.00	15000.00	12000.00	35000.00	8000.00	0.00	0.00	2500.00
SAGG0000000014	CARD00000012	2025-03	50000.00	8000.00	5000.00	15000.00	10000.00	0.00	0.00	2000.00
SAGG0000000015	CARD00000013	2025-03	78000.00	12000.00	8000.00	28000.00	14000.00	0.00	0.00	3200.00
SAGG0000000016	CARD00000014	2025-03	140000.00	35000.00	18000.00	45000.00	22000.00	0.00	0.00	6500.00
\.


--
-- Name: card_accounts card_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_accounts
    ADD CONSTRAINT card_accounts_pkey PRIMARY KEY (card_id);


--
-- Name: card_transactions card_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_transactions
    ADD CONSTRAINT card_transactions_pkey PRIMARY KEY (card_txn_id);


--
-- Name: payment_behaviour payment_behaviour_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_behaviour
    ADD CONSTRAINT payment_behaviour_pkey PRIMARY KEY (pay_id);


--
-- Name: spend_aggregates spend_aggregates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spend_aggregates
    ADD CONSTRAINT spend_aggregates_pkey PRIMARY KEY (agg_id);


--
-- Name: idx_card_accounts_pan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_card_accounts_pan ON public.card_accounts USING btree (pan_number);


--
-- Name: card_transactions card_transactions_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.card_transactions
    ADD CONSTRAINT card_transactions_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.card_accounts(card_id);


--
-- Name: payment_behaviour payment_behaviour_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_behaviour
    ADD CONSTRAINT payment_behaviour_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.card_accounts(card_id);


--
-- Name: spend_aggregates spend_aggregates_card_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spend_aggregates
    ADD CONSTRAINT spend_aggregates_card_id_fkey FOREIGN KEY (card_id) REFERENCES public.card_accounts(card_id);


--
-- PostgreSQL database dump complete
--

