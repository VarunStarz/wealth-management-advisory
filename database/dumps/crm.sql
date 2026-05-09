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

ALTER TABLE IF EXISTS ONLY public.interaction_log DROP CONSTRAINT IF EXISTS interaction_log_client_id_fkey;
ALTER TABLE IF EXISTS ONLY public.client_preferences DROP CONSTRAINT IF EXISTS client_preferences_client_id_fkey;
DROP INDEX IF EXISTS public.idx_client_profile_pan;
ALTER TABLE IF EXISTS ONLY public.interaction_log DROP CONSTRAINT IF EXISTS interaction_log_pkey;
ALTER TABLE IF EXISTS ONLY public.client_profile DROP CONSTRAINT IF EXISTS client_profile_pkey;
ALTER TABLE IF EXISTS ONLY public.client_profile DROP CONSTRAINT IF EXISTS client_profile_customer_id_key;
ALTER TABLE IF EXISTS ONLY public.client_preferences DROP CONSTRAINT IF EXISTS client_preferences_pkey;
DROP TABLE IF EXISTS public.interaction_log;
DROP TABLE IF EXISTS public.client_profile;
DROP TABLE IF EXISTS public.client_preferences;
DROP TYPE IF EXISTS public.time_horizon_enum;
DROP TYPE IF EXISTS public.segment_enum_crm;
DROP TYPE IF EXISTS public.risk_enum;
DROP TYPE IF EXISTS public.liquidity_enum;
DROP TYPE IF EXISTS public.interaction_type_enum;
DROP TYPE IF EXISTS public.interaction_channel_enum;
DROP TYPE IF EXISTS public.goal_type_enum;
DROP TYPE IF EXISTS public.experience_enum;
--
-- Name: experience_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.experience_enum AS ENUM (
    'NOVICE',
    'INTERMEDIATE',
    'EXPERIENCED',
    'EXPERT'
);


--
-- Name: goal_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.goal_type_enum AS ENUM (
    'WEALTH_GROWTH',
    'RETIREMENT',
    'EDUCATION',
    'TAX_SAVING',
    'INCOME_GENERATION',
    'ESTATE_PLANNING'
);


--
-- Name: interaction_channel_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.interaction_channel_enum AS ENUM (
    'IN_PERSON',
    'PHONE',
    'EMAIL',
    'VIDEO',
    'PORTAL'
);


--
-- Name: interaction_type_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.interaction_type_enum AS ENUM (
    'REVIEW',
    'COMPLAINT',
    'INQUIRY',
    'ONBOARDING',
    'EDD_DISCUSSION',
    'AD_HOC'
);


--
-- Name: liquidity_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.liquidity_enum AS ENUM (
    'HIGH',
    'MEDIUM',
    'LOW'
);


--
-- Name: risk_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.risk_enum AS ENUM (
    'CONSERVATIVE',
    'MODERATE',
    'AGGRESSIVE',
    'VERY_AGGRESSIVE'
);


--
-- Name: segment_enum_crm; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.segment_enum_crm AS ENUM (
    'RETAIL',
    'HNI',
    'UHNI',
    'NRI',
    'CORP'
);


--
-- Name: time_horizon_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.time_horizon_enum AS ENUM (
    'SHORT',
    'MEDIUM',
    'LONG'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: client_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_preferences (
    pref_id character varying(12) NOT NULL,
    client_id character varying(12) NOT NULL,
    goal_type public.goal_type_enum NOT NULL,
    time_horizon public.time_horizon_enum NOT NULL,
    liquidity_need public.liquidity_enum NOT NULL,
    excluded_sectors character varying(200),
    esg_preference boolean DEFAULT false,
    last_updated date
);


--
-- Name: client_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_profile (
    client_id character varying(12) NOT NULL,
    customer_id character varying(12) NOT NULL,
    segment public.segment_enum_crm NOT NULL,
    sub_segment character varying(50),
    rm_id character varying(10) NOT NULL,
    onboarding_date date NOT NULL,
    investment_experience public.experience_enum NOT NULL,
    risk_appetite_stated public.risk_enum NOT NULL,
    preferred_language character varying(20) DEFAULT 'English'::character varying,
    referral_source character varying(100),
    aum_band character varying(30),
    last_review_date date,
    next_review_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    pan_number character varying(10)
);


--
-- Name: interaction_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.interaction_log (
    interaction_id character varying(14) NOT NULL,
    client_id character varying(12) NOT NULL,
    interaction_date date NOT NULL,
    channel public.interaction_channel_enum NOT NULL,
    type public.interaction_type_enum NOT NULL,
    summary text,
    sentiment_score numeric(3,2),
    follow_up_flag boolean DEFAULT false,
    created_by character varying(10)
);


--
-- Data for Name: client_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.client_preferences (pref_id, client_id, goal_type, time_horizon, liquidity_need, excluded_sectors, esg_preference, last_updated) FROM stdin;
PREF00000001	CLI000001	WEALTH_GROWTH	LONG	LOW	Tobacco,Gambling	f	2024-01-10
PREF00000002	CLI000002	WEALTH_GROWTH	MEDIUM	MEDIUM	\N	t	2024-02-15
PREF00000003	CLI000003	ESTATE_PLANNING	LONG	LOW	\N	f	2024-01-20
PREF00000004	CLI000004	TAX_SAVING	MEDIUM	HIGH	\N	f	2024-03-01
PREF00000005	CLI000005	INCOME_GENERATION	MEDIUM	MEDIUM	Alcohol	f	2024-01-05
PREF00000006	CLI000006	ESTATE_PLANNING	LONG	LOW	\N	f	2024-01-18
PREF00000007	CLI000007	TAX_SAVING	SHORT	HIGH	\N	f	2024-02-10
PREF00000008	CLI000008	RETIREMENT	LONG	LOW	\N	f	2024-01-25
PREF00000009	CLI000009	ESTATE_PLANNING	LONG	LOW	\N	f	2024-01-08
PREF00000010	CLI000010	WEALTH_GROWTH	MEDIUM	HIGH	\N	t	2024-03-05
PREF00000011	CLI000011	WEALTH_GROWTH	LONG	LOW	\N	f	2023-04-01
PREF00000012	CLI000012	INCOME_GENERATION	LONG	MEDIUM	EQUITY - SEBI PFUTP Insider Trading Prevention (NSE Employee)	f	2024-09-15
PREF00000013	CLI000013	WEALTH_GROWTH	LONG	LOW	\N	t	2025-01-20
PREF00000014	CLI000014	WEALTH_GROWTH	LONG	LOW	\N	f	2024-12-05
\.


--
-- Data for Name: client_profile; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.client_profile (client_id, customer_id, segment, sub_segment, rm_id, onboarding_date, investment_experience, risk_appetite_stated, preferred_language, referral_source, aum_band, last_review_date, next_review_date, created_at, pan_number) FROM stdin;
CLI000001	CUST000001	HNI	Senior Professional	RM001	2015-06-01	EXPERIENCED	MODERATE	English	Direct walk-in	1Cr-5Cr	2024-01-10	2025-01-10	2026-04-15 14:28:20.738049	AXBPM1234C
CLI000002	CUST000002	HNI	Tech Professional	RM001	2018-03-15	INTERMEDIATE	MODERATE	English	Employee referral	50L-1Cr	2024-02-15	2025-02-15	2026-04-15 14:28:20.738049	BQCPI5678D
CLI000003	CUST000003	UHNI	Business Owner	RM002	2010-11-20	EXPERT	AGGRESSIVE	Hindi	Partner bank referral	10Cr+	2024-01-20	2025-01-20	2026-04-15 14:28:20.738049	CRDQS9012E
CLI000004	CUST000004	RETAIL	Salaried	RM002	2020-01-10	NOVICE	CONSERVATIVE	English	Digital onboarding	<10L	2024-03-01	2025-03-01	2026-04-15 14:28:20.738049	DSERT3456F
CLI000005	CUST000005	HNI	Business Owner	RM003	2012-08-05	EXPERIENCED	AGGRESSIVE	English	CA referral	1Cr-5Cr	2024-01-05	2025-01-05	2026-04-15 14:28:20.738049	ETFUS7890G
CLI000006	CUST000006	UHNI	Real Estate	RM003	2008-02-14	EXPERT	AGGRESSIVE	Hindi	Private banking migration	50Cr+	2024-01-18	2025-01-18	2026-04-15 14:28:20.738049	FUGVA2345H
CLI000007	CUST000007	RETAIL	Salaried	RM004	2019-07-22	NOVICE	CONSERVATIVE	Tamil	Digital onboarding	<10L	2024-02-10	2025-02-10	2026-04-15 14:28:20.738049	GVHWB6789J
CLI000008	CUST000008	HNI	Government Official	RM004	2014-04-30	INTERMEDIATE	MODERATE	Malayalam	Internal referral	5Cr-10Cr	2024-01-25	2025-01-25	2026-04-15 14:28:20.738049	HWIXC0123K
CLI000009	CUST000009	UHNI	Promoter/HUF	RM005	2005-09-01	EXPERT	VERY_AGGRESSIVE	English	Legacy relationship	100Cr+	2024-01-08	2025-01-08	2026-04-15 14:28:20.738049	IXJYD4567L
CLI000010	CUST000010	RETAIL	Fresher/Salaried	RM005	2022-06-18	NOVICE	CONSERVATIVE	Gujarati	App referral	<10L	2024-03-05	2025-03-05	2026-04-15 14:28:20.738049	JYKZE8901M
CLI000011	CUST000011	HNI	Senior Consultant	RM002	2016-11-10	EXPERIENCED	MODERATE	English	Referral - existing client	50L-1Cr	2023-04-01	2024-04-01	2026-05-08 14:01:09.456288	KABVK3579N
CLI000012	CUST000012	HNI	NSE Senior Analyst	RM003	2019-03-10	EXPERIENCED	CONSERVATIVE	English	Direct - Walk-in	50L-1Cr	2024-09-15	2025-09-15	2026-05-08 18:42:17.753214	BKPMA5512L
CLI000013	CUST000013	HNI	Boutique Consulting Owner	RM001	2017-07-22	EXPERIENCED	CONSERVATIVE	English	Referral - existing client	1Cr-5Cr	2025-01-20	2026-01-20	2026-05-08 18:43:07.743387	CLPSV7723K
CLI000014	CUST000014	HNI	Business Owner - Manufacturing	RM004	2015-06-18	EXPERT	AGGRESSIVE	English	Referral - HNI network	1Cr-5Cr	2024-12-05	2025-12-05	2026-05-08 18:43:07.918142	DKPRK8834M
\.


--
-- Data for Name: interaction_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.interaction_log (interaction_id, client_id, interaction_date, channel, type, summary, sentiment_score, follow_up_flag, created_by) FROM stdin;
INT0000000001	CLI000001	2024-01-10	IN_PERSON	REVIEW	Annual portfolio review. Client satisfied with returns. Discussed rebalancing toward debt.	0.85	f	RM001
INT0000000002	CLI000002	2024-02-15	PHONE	REVIEW	Quarterly check-in. Client asked about SIP increase options.	0.78	t	RM001
INT0000000003	CLI000003	2024-01-20	IN_PERSON	REVIEW	UHNI annual review. Client requested offshore investment options. PEP screening discussion initiated.	0.72	t	RM002
INT0000000004	CLI000005	2024-01-05	IN_PERSON	EDD_DISCUSSION	EDD triggered due to large cash deposits. Client provided source of funds documentation.	0.60	t	RM003
INT0000000005	CLI000006	2024-01-18	IN_PERSON	REVIEW	UHNI semi-annual review. Multiple property transactions noted. Requested updated wealth statement.	0.80	t	RM003
INT0000000006	CLI000008	2024-01-25	IN_PERSON	REVIEW	Annual review. Client is a senior govt official. Enhanced monitoring discussion. PEP category noted.	0.65	t	RM004
INT0000000007	CLI000009	2024-01-08	IN_PERSON	REVIEW	UHNI review. Complex corporate structure. Multiple entities. Beneficial ownership clarification needed.	0.70	t	RM005
INT0000000008	CLI000004	2024-03-01	PORTAL	INQUIRY	Customer inquired about SIP. Basic product information provided.	0.90	f	RM002
INT0000000009	CLI000010	2024-03-05	PHONE	ONBOARDING	New client call. Account setup queries addressed.	0.88	f	RM005
INT0000000010	CLI000001	2023-07-15	EMAIL	AD_HOC	Client flagged an unknown debit. Investigated and resolved. Fraudulent transaction reversed.	0.50	f	RM001
INT0000000011	CLI000011	2024-03-15	IN_PERSON	REVIEW	Annual portfolio review. Client comfortable with diversified allocation across equity, bonds, gold, and FD. No concerns raised. Discussion on performance against benchmark deferred to next meeting.	0.85	f	RM002
INT0000000012	CLI000012	2024-09-15	IN_PERSON	REVIEW	Compliance review. Prateek confirmed continued employment at NSE. Per SEBI PFUTP Regulations 2003, equity investments in NSE-listed securities are prohibited. Portfolio restricted to Debt MFs, Sovereign Gold Bonds, and Government Securities. Compliance restriction confirmed active. Client satisfied with INCOME strategy performance.	0.78	f	RM003
INT0000000013	CLI000013	2025-01-20	IN_PERSON	REVIEW	Annual review. Sneha's conservative portfolio is performing well -- positive alpha across 6 consecutive quarters. However, client has EXPLICITLY REQUESTED a shift to aggressive growth strategy. States she has a 10-year horizon and is willing to accept higher volatility for higher returns. Current on-record risk appetite is CONSERVATIVE. Formal suitability re-assessment required before any rebalancing. RM to initiate behavioural risk profiling questionnaire.	0.88	t	RM001
INT0000000014	CLI000014	2024-12-05	IN_PERSON	REVIEW	Annual review following FY2022-23 portfolio losses. Rohit suffered -18.3% in Dec 2022 and -14.5% in Mar 2023 due to aggressive mid/small-cap positioning. Portfolio has partially recovered (+8.4%, +7.2%, +6.8%) but cumulative loss still not fully recovered. Client has FORMALLY REQUESTED a shift to conservative allocation citing emotional distress and reduced risk tolerance post-drawdown. On-record risk appetite remains AGGRESSIVE -- formal reclassification required before any rebalancing can proceed. RM to initiate revised risk profiling.	0.45	t	RM004
\.


--
-- Name: client_preferences client_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_preferences
    ADD CONSTRAINT client_preferences_pkey PRIMARY KEY (pref_id);


--
-- Name: client_profile client_profile_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_profile
    ADD CONSTRAINT client_profile_customer_id_key UNIQUE (customer_id);


--
-- Name: client_profile client_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_profile
    ADD CONSTRAINT client_profile_pkey PRIMARY KEY (client_id);


--
-- Name: interaction_log interaction_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interaction_log
    ADD CONSTRAINT interaction_log_pkey PRIMARY KEY (interaction_id);


--
-- Name: idx_client_profile_pan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_profile_pan ON public.client_profile USING btree (pan_number);


--
-- Name: client_preferences client_preferences_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_preferences
    ADD CONSTRAINT client_preferences_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client_profile(client_id);


--
-- Name: interaction_log interaction_log_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.interaction_log
    ADD CONSTRAINT interaction_log_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client_profile(client_id);


--
-- PostgreSQL database dump complete
--

