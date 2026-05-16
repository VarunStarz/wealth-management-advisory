--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 16.3

-- Started on 2026-05-11 19:29:45

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
-- TOC entry 843 (class 1247 OID 16542)
-- Name: experience_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.experience_enum AS ENUM (
    'NOVICE',
    'INTERMEDIATE',
    'EXPERIENCED',
    'EXPERT'
);


ALTER TYPE public.experience_enum OWNER TO postgres;

--
-- TOC entry 861 (class 1247 OID 16610)
-- Name: goal_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.goal_type_enum AS ENUM (
    'WEALTH_GROWTH',
    'RETIREMENT',
    'EDUCATION',
    'TAX_SAVING',
    'INCOME_GENERATION',
    'ESTATE_PLANNING'
);


ALTER TYPE public.goal_type_enum OWNER TO postgres;

--
-- TOC entry 849 (class 1247 OID 16562)
-- Name: interaction_channel_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.interaction_channel_enum AS ENUM (
    'IN_PERSON',
    'PHONE',
    'EMAIL',
    'VIDEO',
    'PORTAL'
);


ALTER TYPE public.interaction_channel_enum OWNER TO postgres;

--
-- TOC entry 852 (class 1247 OID 16574)
-- Name: interaction_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.interaction_type_enum AS ENUM (
    'REVIEW',
    'COMPLAINT',
    'INQUIRY',
    'ONBOARDING',
    'EDD_DISCUSSION',
    'AD_HOC'
);


ALTER TYPE public.interaction_type_enum OWNER TO postgres;

--
-- TOC entry 867 (class 1247 OID 16632)
-- Name: liquidity_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.liquidity_enum AS ENUM (
    'HIGH',
    'MEDIUM',
    'LOW'
);


ALTER TYPE public.liquidity_enum OWNER TO postgres;

--
-- TOC entry 846 (class 1247 OID 16552)
-- Name: risk_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.risk_enum AS ENUM (
    'CONSERVATIVE',
    'MODERATE',
    'AGGRESSIVE',
    'VERY_AGGRESSIVE'
);


ALTER TYPE public.risk_enum OWNER TO postgres;

--
-- TOC entry 840 (class 1247 OID 16530)
-- Name: segment_enum_crm; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.segment_enum_crm AS ENUM (
    'RETAIL',
    'HNI',
    'UHNI',
    'NRI',
    'CORP'
);


ALTER TYPE public.segment_enum_crm OWNER TO postgres;

--
-- TOC entry 864 (class 1247 OID 16624)
-- Name: time_horizon_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.time_horizon_enum AS ENUM (
    'SHORT',
    'MEDIUM',
    'LONG'
);


ALTER TYPE public.time_horizon_enum OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 216 (class 1259 OID 16639)
-- Name: client_preferences; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.client_preferences OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16587)
-- Name: client_profile; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.client_profile OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16596)
-- Name: interaction_log; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.interaction_log OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 32792)
-- Name: recommendation_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recommendation_log (
    rec_id character varying(40) NOT NULL,
    customer_id character varying(20) NOT NULL,
    rm_id character varying(20),
    recommendation_date timestamp without time zone DEFAULT now(),
    investable_amount_inr numeric(15,2),
    risk_tier_used character varying(20),
    recommended_funds jsonb,
    allocation_summary text,
    pipeline_run_id character varying(50)
);


ALTER TABLE public.recommendation_log OWNER TO postgres;

--
-- TOC entry 3396 (class 0 OID 16639)
-- Dependencies: 216
-- Data for Name: client_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- TOC entry 3394 (class 0 OID 16587)
-- Dependencies: 214
-- Data for Name: client_profile; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- TOC entry 3395 (class 0 OID 16596)
-- Dependencies: 215
-- Data for Name: interaction_log; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- TOC entry 3397 (class 0 OID 32792)
-- Dependencies: 217
-- Data for Name: recommendation_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recommendation_log (rec_id, customer_id, rm_id, recommendation_date, investable_amount_inr, risk_tier_used, recommended_funds, allocation_summary, pipeline_run_id) FROM stdin;
REC20260510CUST000011	CUST000011	RM002	2026-05-10 14:37:27.618906	2000000.00	MEDIUM	[{"amc": "Mirae Asset MF", "name": "Mirae Asset Large Cap Fund - Direct Plan - Growth", "fund_id": "FUND018", "category": "Large Cap Fund", "rationale": "With a 3yr CAGR of 12.11% and a max drawdown of -15.85%, this Large Cap fund serves as a stable equity core for a MEDIUM risk portfolio. It provides measured growth exposure within the 35% equity allocation while avoiding the higher volatility of mid or small cap funds.", "asset_class": "EQUITY", "cagr_1yr_pct": 3.4, "cagr_3yr_pct": 12.11, "volatility_pct": 12.87, "composite_score": 54.1, "max_drawdown_pct": -15.85, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Offering a 3yr CAGR of 7.69% and a negligible max drawdown of -0.45%, this Short Duration fund is ideal for the 20% debt allocation. It ensures strong liquidity and capital protection as a stabilizing anchor for a MEDIUM risk tier portfolio.", "asset_class": "DEBT", "cagr_1yr_pct": 6.19, "cagr_3yr_pct": 7.69, "volatility_pct": 0.88, "composite_score": 75.1, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Delivering an impressive 3yr CAGR of 22.08% with a controlled max drawdown of -10.78%, this Multi Asset fund efficiently fulfills the 15% hybrid bucket. It offers excellent risk-adjusted returns and dynamic diversification suitable for a balanced growth profile.", "asset_class": "HYBRID", "cagr_1yr_pct": 21.82, "cagr_3yr_pct": 22.08, "volatility_pct": 9.76, "composite_score": 86.2, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Providing a robust 3yr CAGR of 33.32% alongside a max drawdown of -22.28%, this Gold ETF optimally fills the 15% gold allocation. Since existing holdings already include Sovereign Gold Bonds, this ETF offers complementary liquid gold exposure for inflation hedging.", "asset_class": "GOLD", "cagr_1yr_pct": 53.55, "cagr_3yr_pct": 33.32, "volatility_pct": 18.12, "composite_score": 75, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "EPFO / Government of India", "name": "Employee Provident Fund (EPF)", "fund_id": "FUND008", "category": "Provident Fund", "rationale": "A guaranteed static return of 8.25% with zero drawdown makes this Provident Fund the perfect vehicle for the 15% safe bucket. It guarantees absolute capital protection, serving as a risk-free anchor in line with a balanced growth strategy.", "asset_class": "SAFE", "cagr_1yr_pct": 8.25, "cagr_3yr_pct": 8.25, "volatility_pct": 0, "composite_score": 69, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}]	35% equity / 15% hybrid / 20% debt / 15% gold / 15% safe	
REC20260510CUST000001	CUST000001	RM001	2026-05-10 16:13:20.119041	15000000.00	MEDIUM	[{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "With a stellar 3yr CAGR of 24.83% and a composite score of 76.65, this fund is the top choice for the core equity allocation, providing aggressive growth exposure suitable for a MEDIUM risk profile.", "asset_class": "EQUITY", "cagr_1yr_pct": 15.4, "cagr_3yr_pct": 24.83, "volatility_pct": 14.84, "composite_score": 76.65, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.30,00,000", "suggested_allocation_pct": 20}, {"amc": "Mirae Asset MF", "name": "Mirae Asset Large Cap Fund - Direct Plan - Growth", "fund_id": "FUND018", "category": "Large Cap Fund", "rationale": "A 3yr CAGR of 12.11% with a contained drawdown of -15.85% makes this a stable anchor for the equity portion of the portfolio, balancing the higher volatility of the mid-cap allocation.", "asset_class": "EQUITY", "cagr_1yr_pct": 3.4, "cagr_3yr_pct": 12.11, "volatility_pct": 12.87, "composite_score": 62.58, "max_drawdown_pct": -15.85, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Top-ranked in its category with a score of 75.11. Offers stable returns (3yr CAGR 7.69%) with extremely low volatility, serving as the primary debt anchor for liquidity and stability.", "asset_class": "DEBT", "cagr_1yr_pct": 6.19, "cagr_3yr_pct": 7.69, "volatility_pct": 0.88, "composite_score": 75.11, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.30,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "The highest-scoring fund overall (86.12), delivering excellent risk-adjusted returns (3yr CAGR 22.08%, max drawdown -10.78%). Provides diversification across asset classes in a single scheme.", "asset_class": "HYBRID", "cagr_1yr_pct": 21.82, "cagr_3yr_pct": 22.08, "volatility_pct": 9.76, "composite_score": 86.12, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "Reserve Bank of India", "name": "Sovereign Gold Bond (SGB) - Current Series", "fund_id": "FUND020", "category": "Sovereign Gold Bond", "rationale": "Provides exposure to gold prices plus a sovereign-guaranteed 2.5% annual coupon, making it the most efficient vehicle for gold allocation. It acts as a hedge against inflation and equity market volatility.", "asset_class": "GOLD", "cagr_1yr_pct": 2.5, "cagr_3yr_pct": 2.5, "volatility_pct": 0, "composite_score": 82.5, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "EPFO / Government of India", "name": "Employee Provident Fund (EPF)", "fund_id": "FUND008", "category": "Provident Fund", "rationale": "Offers a guaranteed, tax-efficient return of 8.25% with zero market risk. This serves as the foundational safe-harbor allocation in the portfolio, ensuring capital preservation.", "asset_class": "SAFE", "cagr_1yr_pct": 8.25, "cagr_3yr_pct": 8.25, "volatility_pct": 0, "composite_score": 87.75, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}]	35% EQUITY / 20% DEBT / 15% HYBRID / 15% GOLD / 15% SAFE	
\.


--
-- TOC entry 3247 (class 2606 OID 16644)
-- Name: client_preferences client_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_preferences
    ADD CONSTRAINT client_preferences_pkey PRIMARY KEY (pref_id);


--
-- TOC entry 3240 (class 2606 OID 16595)
-- Name: client_profile client_profile_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_profile
    ADD CONSTRAINT client_profile_customer_id_key UNIQUE (customer_id);


--
-- TOC entry 3242 (class 2606 OID 16593)
-- Name: client_profile client_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_profile
    ADD CONSTRAINT client_profile_pkey PRIMARY KEY (client_id);


--
-- TOC entry 3245 (class 2606 OID 16603)
-- Name: interaction_log interaction_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interaction_log
    ADD CONSTRAINT interaction_log_pkey PRIMARY KEY (interaction_id);


--
-- TOC entry 3249 (class 2606 OID 32799)
-- Name: recommendation_log recommendation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recommendation_log
    ADD CONSTRAINT recommendation_log_pkey PRIMARY KEY (rec_id);


--
-- TOC entry 3243 (class 1259 OID 24576)
-- Name: idx_client_profile_pan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_client_profile_pan ON public.client_profile USING btree (pan_number);


--
-- TOC entry 3251 (class 2606 OID 16645)
-- Name: client_preferences client_preferences_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.client_preferences
    ADD CONSTRAINT client_preferences_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client_profile(client_id);


--
-- TOC entry 3250 (class 2606 OID 16604)
-- Name: interaction_log interaction_log_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interaction_log
    ADD CONSTRAINT interaction_log_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.client_profile(client_id);


-- Completed on 2026-05-11 19:29:46

--
-- PostgreSQL database dump complete
--

