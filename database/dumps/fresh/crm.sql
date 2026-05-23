--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 15.4 (Debian 15.4-2.pgdg120+1)

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
ALTER TABLE IF EXISTS ONLY public.recommendation_log DROP CONSTRAINT IF EXISTS recommendation_log_pkey;
ALTER TABLE IF EXISTS ONLY public.interaction_log DROP CONSTRAINT IF EXISTS interaction_log_pkey;
ALTER TABLE IF EXISTS ONLY public.client_profile DROP CONSTRAINT IF EXISTS client_profile_pkey;
ALTER TABLE IF EXISTS ONLY public.client_profile DROP CONSTRAINT IF EXISTS client_profile_customer_id_key;
ALTER TABLE IF EXISTS ONLY public.client_preferences DROP CONSTRAINT IF EXISTS client_preferences_pkey;
DROP TABLE IF EXISTS public.recommendation_log;
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
-- Name: recommendation_log; Type: TABLE; Schema: public; Owner: -
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
-- Data for Name: recommendation_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recommendation_log (rec_id, customer_id, rm_id, recommendation_date, investable_amount_inr, risk_tier_used, recommended_funds, allocation_summary, pipeline_run_id) FROM stdin;
REC20260510CUST000011	CUST000011	RM002	2026-05-10 14:37:27.618906	2000000.00	MEDIUM	[{"amc": "Mirae Asset MF", "name": "Mirae Asset Large Cap Fund - Direct Plan - Growth", "fund_id": "FUND018", "category": "Large Cap Fund", "rationale": "With a 3yr CAGR of 12.11% and a max drawdown of -15.85%, this Large Cap fund serves as a stable equity core for a MEDIUM risk portfolio. It provides measured growth exposure within the 35% equity allocation while avoiding the higher volatility of mid or small cap funds.", "asset_class": "EQUITY", "cagr_1yr_pct": 3.4, "cagr_3yr_pct": 12.11, "volatility_pct": 12.87, "composite_score": 54.1, "max_drawdown_pct": -15.85, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Offering a 3yr CAGR of 7.69% and a negligible max drawdown of -0.45%, this Short Duration fund is ideal for the 20% debt allocation. It ensures strong liquidity and capital protection as a stabilizing anchor for a MEDIUM risk tier portfolio.", "asset_class": "DEBT", "cagr_1yr_pct": 6.19, "cagr_3yr_pct": 7.69, "volatility_pct": 0.88, "composite_score": 75.1, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Delivering an impressive 3yr CAGR of 22.08% with a controlled max drawdown of -10.78%, this Multi Asset fund efficiently fulfills the 15% hybrid bucket. It offers excellent risk-adjusted returns and dynamic diversification suitable for a balanced growth profile.", "asset_class": "HYBRID", "cagr_1yr_pct": 21.82, "cagr_3yr_pct": 22.08, "volatility_pct": 9.76, "composite_score": 86.2, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Providing a robust 3yr CAGR of 33.32% alongside a max drawdown of -22.28%, this Gold ETF optimally fills the 15% gold allocation. Since existing holdings already include Sovereign Gold Bonds, this ETF offers complementary liquid gold exposure for inflation hedging.", "asset_class": "GOLD", "cagr_1yr_pct": 53.55, "cagr_3yr_pct": 33.32, "volatility_pct": 18.12, "composite_score": 75, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "EPFO / Government of India", "name": "Employee Provident Fund (EPF)", "fund_id": "FUND008", "category": "Provident Fund", "rationale": "A guaranteed static return of 8.25% with zero drawdown makes this Provident Fund the perfect vehicle for the 15% safe bucket. It guarantees absolute capital protection, serving as a risk-free anchor in line with a balanced growth strategy.", "asset_class": "SAFE", "cagr_1yr_pct": 8.25, "cagr_3yr_pct": 8.25, "volatility_pct": 0, "composite_score": 69, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}]	35% equity / 15% hybrid / 20% debt / 15% gold / 15% safe	
REC20260510CUST000001	CUST000001	RM001	2026-05-10 16:13:20.119041	15000000.00	MEDIUM	[{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "With a stellar 3yr CAGR of 24.83% and a composite score of 76.65, this fund is the top choice for the core equity allocation, providing aggressive growth exposure suitable for a MEDIUM risk profile.", "asset_class": "EQUITY", "cagr_1yr_pct": 15.4, "cagr_3yr_pct": 24.83, "volatility_pct": 14.84, "composite_score": 76.65, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.30,00,000", "suggested_allocation_pct": 20}, {"amc": "Mirae Asset MF", "name": "Mirae Asset Large Cap Fund - Direct Plan - Growth", "fund_id": "FUND018", "category": "Large Cap Fund", "rationale": "A 3yr CAGR of 12.11% with a contained drawdown of -15.85% makes this a stable anchor for the equity portion of the portfolio, balancing the higher volatility of the mid-cap allocation.", "asset_class": "EQUITY", "cagr_1yr_pct": 3.4, "cagr_3yr_pct": 12.11, "volatility_pct": 12.87, "composite_score": 62.58, "max_drawdown_pct": -15.85, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Top-ranked in its category with a score of 75.11. Offers stable returns (3yr CAGR 7.69%) with extremely low volatility, serving as the primary debt anchor for liquidity and stability.", "asset_class": "DEBT", "cagr_1yr_pct": 6.19, "cagr_3yr_pct": 7.69, "volatility_pct": 0.88, "composite_score": 75.11, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.30,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "The highest-scoring fund overall (86.12), delivering excellent risk-adjusted returns (3yr CAGR 22.08%, max drawdown -10.78%). Provides diversification across asset classes in a single scheme.", "asset_class": "HYBRID", "cagr_1yr_pct": 21.82, "cagr_3yr_pct": 22.08, "volatility_pct": 9.76, "composite_score": 86.12, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "Reserve Bank of India", "name": "Sovereign Gold Bond (SGB) - Current Series", "fund_id": "FUND020", "category": "Sovereign Gold Bond", "rationale": "Provides exposure to gold prices plus a sovereign-guaranteed 2.5% annual coupon, making it the most efficient vehicle for gold allocation. It acts as a hedge against inflation and equity market volatility.", "asset_class": "GOLD", "cagr_1yr_pct": 2.5, "cagr_3yr_pct": 2.5, "volatility_pct": 0, "composite_score": 82.5, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}, {"amc": "EPFO / Government of India", "name": "Employee Provident Fund (EPF)", "fund_id": "FUND008", "category": "Provident Fund", "rationale": "Offers a guaranteed, tax-efficient return of 8.25% with zero market risk. This serves as the foundational safe-harbor allocation in the portfolio, ensuring capital preservation.", "asset_class": "SAFE", "cagr_1yr_pct": 8.25, "cagr_3yr_pct": 8.25, "volatility_pct": 0, "composite_score": 87.75, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.22,50,000", "suggested_allocation_pct": 15}]	35% EQUITY / 20% DEBT / 15% HYBRID / 15% GOLD / 15% SAFE	
REC20260513CUST000011	CUST000011	RM002	2026-05-13 16:58:24.553132	2000000.00	MEDIUM	[{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "With a stellar 3yr CAGR of 23.46% and a composite score of 75.63, this fund is the top-ranked equity choice. It adds mid-cap diversification to your existing large-cap-heavy portfolio, aligning with a MEDIUM risk growth strategy.", "asset_class": "EQUITY", "cagr_1yr_pct": 8.6, "cagr_3yr_pct": 23.46, "volatility_pct": 14.93, "composite_score": 75.63, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Top-ranked in its category with a 7.62% 3yr CAGR and extremely low drawdown (-0.45%). This provides a stable debt anchor for portfolio liquidity and capital preservation, fitting the core debt allocation.", "asset_class": "DEBT", "cagr_1yr_pct": 6.1, "cagr_3yr_pct": 7.62, "volatility_pct": 0.88, "composite_score": 71.95, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "The highest-scoring hybrid fund (81.99) with an impressive 21.37% 3yr CAGR. Its multi-asset approach provides a balanced risk-reward profile, acting as a volatility buffer between pure equity and debt.", "asset_class": "HYBRID", "cagr_1yr_pct": 17.91, "cagr_3yr_pct": 21.37, "volatility_pct": 9.8, "composite_score": 81.99, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "HDFC AMC", "name": "HDFC Gold ETF - Growth Option", "fund_id": "FUND021", "category": "Gold ETF", "rationale": "Chosen for its high liquidity and strong performance (33.91% 3yr CAGR). This ETF complements your existing SGB holding, providing an excellent hedge against market volatility for the gold allocation.", "asset_class": "GOLD", "cagr_1yr_pct": 61.09, "cagr_3yr_pct": 33.91, "volatility_pct": 18.46, "composite_score": 81.44, "max_drawdown_pct": -22.27, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "EPFO / Government of India", "name": "Employee Provident Fund (EPF)", "fund_id": "FUND008", "category": "Provident Fund", "rationale": "Offers a guaranteed, tax-efficient return of 8.25% with zero market risk. This serves as the mandatory stable anchor in a balanced portfolio, ensuring capital protection for this allocation slice.", "asset_class": "SAFE", "cagr_1yr_pct": 8.25, "cagr_3yr_pct": 8.25, "volatility_pct": 0, "composite_score": 71.75, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}]	35% EQUITY / 20% DEBT / 15% HYBRID / 15% GOLD / 15% SAFE	
REC20260514CUST000011	CUST000011	RM002	2026-05-14 15:28:40.201418	2000000.00	HIGH	[{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "With an impressive 3yr CAGR of 23.46% and a contained max drawdown of -16.76%, this fund provides excellent growth potential. It is selected as the top-ranking equity pick to drive aggressive wealth accumulation for a HIGH risk portfolio.", "asset_class": "EQUITY", "cagr_1yr_pct": 8.6, "cagr_3yr_pct": 23.46, "volatility_pct": 14.93, "composite_score": 75.66, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "PPFAS MF", "name": "Parag Parikh Flexi Cap Fund - Direct Plan - Growth", "fund_id": "FUND023", "category": "Flexi Cap Fund", "rationale": "Delivering a steady 16.5% 3yr CAGR and strong downside protection (-10.98% max drawdown), this serves as a high-quality diversifier. It is included as a second equity slot to safely fulfill the expanded 75% equity mandate.", "asset_class": "EQUITY", "cagr_1yr_pct": 0.99, "cagr_3yr_pct": 16.5, "volatility_pct": 9.79, "composite_score": 73.27, "max_drawdown_pct": -10.98, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "HDFC AMC", "name": "HDFC ELSS Tax Saver - Growth Option - Direct Plan", "fund_id": "FUND028", "category": "ELSS Tax Saver", "rationale": "Offering a 16.99% 3yr CAGR and a moderate -14.81% drawdown, this fund adds substantial growth while providing Section 80C tax benefits. It ensures the HIGH tier portfolio remains tax-efficient.", "asset_class": "EQUITY", "cagr_1yr_pct": -3.88, "cagr_3yr_pct": 16.99, "volatility_pct": 12.2, "composite_score": 69.02, "max_drawdown_pct": -14.81, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "Motilal Oswal MF", "name": "Motilal Oswal Nasdaq 100 Fund of Fund - Direct Plan Growth", "fund_id": "FUND030", "category": "International FoF", "rationale": "An exceptional 3yr CAGR of 44.64% combined with global tech exposure makes this an ideal high-growth satellite. It precisely fits the 10% international allocation for essential geographical diversification.", "asset_class": "INTERNATIONAL", "cagr_1yr_pct": 84.98, "cagr_3yr_pct": 44.64, "volatility_pct": 20.74, "composite_score": 75.8, "max_drawdown_pct": -26.21, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "With a strong 33.88% 3yr CAGR, this ETF efficiently captures underlying gold price appreciation. It serves as a liquid hedge against equity volatility in the 10% metals bucket.", "asset_class": "GOLD", "cagr_1yr_pct": 60.84, "cagr_3yr_pct": 33.88, "volatility_pct": 18.14, "composite_score": 75.31, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Achieving a 21.37% 3yr CAGR with a low -10.78% drawdown, this fund scores highest among hybrid options. Selected for the 5% hybrid slot to act as a growth-oriented volatility buffer.", "asset_class": "HYBRID", "cagr_1yr_pct": 17.91, "cagr_3yr_pct": 21.37, "volatility_pct": 9.8, "composite_score": 85.34, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.1,00,000", "suggested_allocation_pct": 5}]	75% Equity, 10% International, 10% Gold, 5% Hybrid (adjusted from standard HIGH matrix due to unavailable Safe/Debt instruments)	
REC20260517CUST000011	CUST000011	RM002	2026-05-17 07:19:43.872734	2000000.00	HIGH	[{"amc": "Nippon India MF", "name": "Nippon India Growth Fund (Mid Cap) - Direct Plan Growth", "fund_id": "FUND025", "category": "Mid Cap Fund", "rationale": "With a robust 25.24% 3yr CAGR and a manageable max drawdown of -19.87%, this fund offers strong growth potential for a high-risk portfolio. It is chosen for its superior risk-adjusted returns in the mid-cap space.", "asset_class": "EQUITY", "cagr_1yr_pct": 10.06, "cagr_3yr_pct": 25.24, "volatility_pct": 16.47, "composite_score": 82, "max_drawdown_pct": -19.87, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "Nippon India MF", "name": "Nippon India Small Cap Fund - Direct Plan Growth Plan - Growth Option", "fund_id": "FUND027", "category": "Small Cap Fund", "rationale": "A 3yr CAGR of 21.04% with a max drawdown of -24.21% makes this an excellent choice for aggressive growth. It is selected to provide high-growth exposure in the small-cap bucket.", "asset_class": "EQUITY", "cagr_1yr_pct": 6.9, "cagr_3yr_pct": 21.04, "volatility_pct": 16.3, "composite_score": 74.5, "max_drawdown_pct": -24.21, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "Mirae Asset MF", "name": "Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth", "fund_id": "FUND031", "category": "International FoF", "rationale": "Exceptional 55.52% 3yr CAGR provides aggressive international growth. Chosen for its high return potential within the international allocation, despite higher volatility.", "asset_class": "INTERNATIONAL", "cagr_1yr_pct": 44.34, "cagr_3yr_pct": 55.52, "volatility_pct": 24.75, "composite_score": 95, "max_drawdown_pct": -30.31, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "A strong 21.58% 3yr CAGR with a low max drawdown of -10.78% offers a great balance of growth and stability. Included as a volatility buffer in this aggressive portfolio.", "asset_class": "HYBRID", "cagr_1yr_pct": 17.96, "cagr_3yr_pct": 21.58, "volatility_pct": 9.82, "composite_score": 85, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.1,00,000", "suggested_allocation_pct": 5}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "With an impressive 35.69% 3yr CAGR, this Gold ETF provides excellent returns for the metals portion of the portfolio, acting as a hedge against inflation.", "asset_class": "GOLD", "cagr_1yr_pct": 68.81, "cagr_3yr_pct": 35.69, "volatility_pct": 18.46, "composite_score": 91.8, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Reserve Bank of India", "name": "Sovereign Gold Bond (SGB) - Current Series", "fund_id": "FUND020", "category": "Sovereign Gold Bond", "rationale": "Provides a stable anchor with a guaranteed 2.5% return on top of gold price appreciation. A mandatory safe anchor for a high-risk portfolio.", "asset_class": "GOLD", "cagr_1yr_pct": 2.5, "cagr_3yr_pct": 2.5, "volatility_pct": 0, "composite_score": 75, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"amc": "HDFC AMC", "name": "HDFC Balanced Advantage Fund - Growth Plan - Direct Plan", "fund_id": "FUND015", "category": "Balanced Advantage Fund", "rationale": "Offers a steady 15.17% 3yr CAGR and a low max drawdown of -10.18%. This provides liquidity and a defensive buffer to the portfolio.", "asset_class": "HYBRID", "cagr_1yr_pct": -0.54, "cagr_3yr_pct": 15.17, "volatility_pct": 9.67, "composite_score": 72.8, "max_drawdown_pct": -10.18, "suggested_amount_inr": "Rs.1,00,000", "suggested_allocation_pct": 5}]	50% equity / 10% international / 5% hybrid / 10% gold / 20% safe / 5% debt	e10b415e-3849-4321-90a6-583805842e44
REC20260517CUST000001	CUST000001	RM001	2026-05-17 09:28:19.533699	1000000.00	MEDIUM	[{"option_id": 1, "option_name": "Growth Tilt", "allocation_summary": "50% Equity / 20% Debt / 15% Hybrid / 15% Gold", "strategy_description": "Emphasises high-growth potential through a significant allocation to equity, complemented by hybrid and gold funds for diversification.", "recommended_instruments": [{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Top-rated in its class, offering aggressive growth with a 23.42% 3-year CAGR, suitable for the high-equity allocation of this strategy.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.42, "composite_score": 75.63, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 50}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Provides a stable debt anchor with a 7.53% 3-year CAGR and minimal drawdown, balancing the equity risk.", "asset_class": "DEBT", "cagr_3yr_pct": 7.53, "composite_score": 74.79, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "A high-performing hybrid fund with a 21.58% 3-year CAGR, adding diversification across asset classes.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.58, "composite_score": 85.49, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.1,50,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Serves as an effective hedge against inflation and market volatility, with a strong 35.69% 3-year CAGR reflecting recent gold performance.", "asset_class": "GOLD", "cagr_3yr_pct": 35.69, "composite_score": 75.95, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.1,50,000", "suggested_allocation_pct": 15}]}, {"option_id": 2, "option_name": "Balanced", "allocation_summary": "35% Equity / 35% Debt / 15% Hybrid / 15% Gold", "strategy_description": "A well-diversified portfolio that balances growth and stability through a mix of equity, debt, and hybrid instruments.", "recommended_instruments": [{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Provides a solid growth engine for the portfolio with its impressive 23.42% 3-year CAGR.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.42, "composite_score": 75.63, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.3,50,000", "suggested_allocation_pct": 35}, {"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Offers stability and steady returns with a 7.53% 3-year CAGR and very low volatility, forming the core of the debt allocation.", "asset_class": "DEBT", "cagr_3yr_pct": 7.53, "composite_score": 74.79, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.3,50,000", "suggested_allocation_pct": 35}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Enhances diversification with its multi-asset approach and strong 21.58% 3-year CAGR.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.58, "composite_score": 85.49, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.1,50,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Acts as a hedge against economic uncertainty, with a significant 35.69% 3-year CAGR.", "asset_class": "GOLD", "cagr_3yr_pct": 35.69, "composite_score": 75.95, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.1,50,000", "suggested_allocation_pct": 15}]}, {"option_id": 3, "option_name": "Income and Stability", "allocation_summary": "45% Debt / 20% Equity / 20% Hybrid / 15% Gold", "strategy_description": "Focuses on generating regular income and preserving capital with a higher allocation to debt instruments, while still participating in some equity growth.", "recommended_instruments": [{"amc": "Axis AMC", "name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "The cornerstone of this income-focused strategy, this fund provides steady returns (7.53% 3-year CAGR) and capital protection.", "asset_class": "DEBT", "cagr_3yr_pct": 7.53, "composite_score": 74.79, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.4,50,000", "suggested_allocation_pct": 45}, {"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Provides a growth kicker to the portfolio with its strong 23.42% 3-year CAGR, even with a smaller allocation.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.42, "composite_score": 75.63, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Offers a blend of asset classes for diversification and has demonstrated a strong 21.58% 3-year CAGR.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.58, "composite_score": 85.49, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 20}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Provides a hedge against inflation, a key consideration for an income-focused portfolio, with a 35.69% 3-year CAGR.", "asset_class": "GOLD", "cagr_3yr_pct": 35.69, "composite_score": 75.95, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.1,50,000", "suggested_allocation_pct": 15}]}]	Growth Tilt, Balanced, Income and Stability	
REC20260517CUST000013	CUST000013	RM001	2026-05-17 09:57:47.509759	800000.00	NO_RISK	[{"option_id": 1, "option_name": "Government Schemes", "allocation_summary": "68% safe / 32% debt", "strategy_description": "A highly safe portfolio focused on sovereign-guaranteed schemes and liquid debt funds for capital preservation and stable income.", "recommended_instruments": [{"amc": "India Post / Government of India", "name": "National Savings Certificate (NSC) VIII Issue", "fund_id": "FUND005", "category": "Government Savings Scheme", "rationale": "Offers a high, fixed, sovereign-guaranteed return of 7.7% with zero volatility, serving as the core of this safety-first portfolio.", "asset_class": "SAFE", "cagr_1yr_pct": 7.7, "cagr_3yr_pct": 7.7, "volatility_pct": 0, "composite_score": 67.9, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.5,44,000", "suggested_allocation_pct": 68}, {"amc": "HDFC AMC", "name": "HDFC Liquid Fund - Growth Option - Direct Plan", "fund_id": "FUND002", "category": "Liquid Fund", "rationale": "As the top-scoring debt fund, it provides high liquidity and superior risk-adjusted returns (3-year CAGR of 6.95%) with minimal drawdown, ideal for the portfolio's liquidity component.", "asset_class": "DEBT", "cagr_1yr_pct": 6.27, "cagr_3yr_pct": 6.95, "volatility_pct": 0.16, "composite_score": 73.9, "max_drawdown_pct": -0.01, "suggested_amount_inr": "Rs.2,56,000", "suggested_allocation_pct": 32}]}, {"option_id": 2, "option_name": "Fixed Deposit Ladder", "allocation_summary": "100% safe", "strategy_description": "A portfolio maximizing safety and predictable returns through a ladder of high-quality bank fixed deposits. Note: The GOLD allocation was omitted as no eligible gold instruments were available in the NO_RISK universe.", "recommended_instruments": [{"amc": "HDFC Bank", "name": "HDFC Bank Fixed Deposit (1-3 Year)", "fund_id": "FUND007", "category": "Bank Fixed Deposit", "rationale": "Provides a predictable, guaranteed return of 7.25% from a top-tier private bank, forming the first rung of the FD ladder.", "asset_class": "SAFE", "cagr_1yr_pct": 7.25, "cagr_3yr_pct": 7.25, "volatility_pct": 0, "composite_score": 67, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 50}, {"amc": "State Bank of India", "name": "SBI Fixed Deposit (1-3 Year)", "fund_id": "FUND006", "category": "Bank Fixed Deposit", "rationale": "With a guaranteed return of 7.1% from India's largest public sector bank, this instrument adds immense safety and diversification to the FD ladder.", "asset_class": "SAFE", "cagr_1yr_pct": 7.1, "cagr_3yr_pct": 7.1, "volatility_pct": 0, "composite_score": 66.7, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 50}]}]	Government Schemes, Fixed Deposit Ladder	f91a5323-455b-4393-9118-fac548625619
REC20260519CUST000011	CUST000011	RM002	2026-05-19 13:49:10.112247	2000000.00	MEDIUM	[{"option_id": 1, "option_name": "Growth Tilt", "allocation_summary": "50% Equity / 15% Hybrid / 15% Gold / 10% Debt / 10% Safe", "strategy_description": "High allocation to equity to prioritise growth, balanced with a diversified mix of other asset classes.", "recommended_instruments": [{"name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Top-performing equity fund with a 23.38% 3yr CAGR, driving the portfolio's growth objective despite a higher drawdown of -16.76%.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.38, "composite_score": 88.5, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"name": "Mirae Asset Large Cap Fund - Direct Plan - Growth", "fund_id": "FUND018", "category": "Large Cap Fund", "rationale": "Provides stability to the equity portion with a solid 11.12% 3yr CAGR and a contained drawdown of -15.85%.", "asset_class": "EQUITY", "cagr_3yr_pct": 11.12, "composite_score": 60.7, "max_drawdown_pct": -15.85, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Excellent risk-adjusted returns with a 21.49% 3yr CAGR and a low drawdown of -10.78%, serving as a strong anchor.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.49, "composite_score": 89.9, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Offers a hedge against inflation and market volatility, with an exceptional 36.19% 3yr CAGR, albeit with higher drawdown risk of -22.28%.", "asset_class": "GOLD", "cagr_3yr_pct": 36.19, "composite_score": 87.1, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Serves as the 'SAFE' component, providing stability and liquidity with a 7.44% 3yr CAGR and near-zero drawdown of -0.45%.", "asset_class": "SAFE", "cagr_3yr_pct": 7.44, "composite_score": 88.6, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"name": "Kotak Corporate Bond Fund - Direct Plan - Growth Option", "fund_id": "FUND011", "category": "Corporate Bond Fund", "rationale": "Adds a stable debt component with a 7.13% 3yr CAGR and minimal drawdown of -0.63%, complementing the high-growth assets.", "asset_class": "DEBT", "cagr_3yr_pct": 7.13, "composite_score": 85.3, "max_drawdown_pct": -0.63, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}]}, {"option_id": 2, "option_name": "Balanced", "allocation_summary": "35% Equity / 20% Debt / 15% Hybrid / 15% Gold / 15% Safe", "strategy_description": "A well-diversified portfolio balancing growth in equities with the stability of debt and gold.", "recommended_instruments": [{"name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Top-performing equity fund with a 23.38% 3yr CAGR, driving the portfolio's growth objective despite a higher drawdown of -16.76%.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.38, "composite_score": 88.5, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"name": "Kotak Corporate Bond Fund - Direct Plan - Growth Option", "fund_id": "FUND011", "category": "Corporate Bond Fund", "rationale": "Forms the core of the debt allocation, providing steady returns (7.13% 3yr CAGR) and very low volatility (drawdown -0.63%).", "asset_class": "DEBT", "cagr_3yr_pct": 7.13, "composite_score": 85.3, "max_drawdown_pct": -0.63, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Excellent risk-adjusted returns with a 21.49% 3yr CAGR and a low drawdown of -10.78%, serving as a strong anchor.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.49, "composite_score": 89.9, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Offers a hedge against inflation and market volatility, with an exceptional 36.19% 3yr CAGR, albeit with higher drawdown risk of -22.28%.", "asset_class": "GOLD", "cagr_3yr_pct": 36.19, "composite_score": 87.1, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Serves as the 'SAFE' component, providing stability and liquidity with a 7.44% 3yr CAGR and near-zero drawdown of -0.45%.", "asset_class": "SAFE", "cagr_3yr_pct": 7.44, "composite_score": 88.6, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}]}, {"option_id": 3, "option_name": "Income + Stability", "allocation_summary": "35% Debt / 20% Equity / 20% Hybrid / 15% Safe / 10% Gold", "strategy_description": "A conservative approach focusing on generating income through debt, with a smaller allocation to equity for potential upside.", "recommended_instruments": [{"name": "Kotak Corporate Bond Fund - Direct Plan - Growth Option", "fund_id": "FUND011", "category": "Corporate Bond Fund", "rationale": "Forms the core of the debt allocation, providing steady returns (7.13% 3yr CAGR) and very low volatility (drawdown -0.63%).", "asset_class": "DEBT", "cagr_3yr_pct": 7.13, "composite_score": 85.3, "max_drawdown_pct": -0.63, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Provides a growth kicker to the portfolio with its strong 23.38% 3yr CAGR.", "asset_class": "EQUITY", "cagr_3yr_pct": 23.38, "composite_score": 88.5, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Excellent risk-adjusted returns with a 21.49% 3yr CAGR and a low drawdown of -10.78%, adding a balanced growth component.", "asset_class": "HYBRID", "cagr_3yr_pct": 21.49, "composite_score": 89.9, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"name": "Axis Short Duration Fund - Direct Plan - Growth Option", "fund_id": "FUND009", "category": "Short Duration Fund", "rationale": "Enhances portfolio stability with a 7.44% 3yr CAGR and minimal drawdown of -0.45%, acting as a liquidity buffer.", "asset_class": "SAFE", "cagr_3yr_pct": 7.44, "composite_score": 88.6, "max_drawdown_pct": -0.45, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "A small allocation provides a hedge against inflation, with an exceptional 36.19% 3yr CAGR.", "asset_class": "GOLD", "cagr_3yr_pct": 36.19, "composite_score": 87.1, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}]}]	Growth Tilt, Balanced, Income + Stability	
REC20260520CUST000011	CUST000011	RM002	2026-05-20 14:16:00.29434	2000000.00	HIGH	[{"algorithm": "SHARPE_OPTIMISED", "option_id": 1, "option_name": "Sharpe Maximiser", "allocation_summary": "40% international / 30% equity / 15% gold / 10% hybrid / 5% safe", "strategy_description": "Data-driven allocation maximising risk-adjusted return across eligible asset classes, weighted by each class's Sharpe proxy, then constrained to the client's risk tier.", "projected_gain_3yr_inr": "Rs.21,74,000", "portfolio_sharpe_approx": 1.65, "recommended_instruments": [{"amc": "Mirae Asset MF", "name": "Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth", "fund_id": "FUND031", "category": "International FoF", "rationale": "Top-ranked International fund with exceptional 51.83% 3-year CAGR, driving the portfolio's growth component despite higher volatility.", "asset_class": "INTERNATIONAL", "cagr_1yr_pct": 44.41, "cagr_3yr_pct": 51.83, "volatility_pct": 24.71, "composite_score": 93.36, "max_drawdown_pct": -30.31, "suggested_amount_inr": "Rs.8,00,000", "suggested_allocation_pct": 40}, {"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "High-performing Mid Cap fund with a strong 23.72% 3-year CAGR and a solid composite score, adding domestic equity growth.", "asset_class": "EQUITY", "cagr_1yr_pct": 6.85, "cagr_3yr_pct": 23.72, "volatility_pct": 14.94, "composite_score": 90.1, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.6,00,000", "suggested_allocation_pct": 30}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Best-in-class Gold ETF with a remarkable 36.5% 3-year CAGR, providing a strong hedge against inflation and market volatility.", "asset_class": "GOLD", "cagr_1yr_pct": 67.05, "cagr_3yr_pct": 36.5, "volatility_pct": 18.47, "composite_score": 96.65, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Top-scoring hybrid fund offering excellent risk-adjusted returns (21.6% 3-year CAGR) and stability.", "asset_class": "HYBRID", "cagr_1yr_pct": 17.43, "cagr_3yr_pct": 21.6, "volatility_pct": 9.83, "composite_score": 98.41, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "India Post / Government of India", "name": "National Savings Certificate (NSC) VIII Issue", "fund_id": "FUND005", "category": "Government Savings Scheme", "rationale": "Sovereign-guaranteed instrument providing capital safety and a competitive fixed return of 7.7%.", "asset_class": "SAFE", "cagr_1yr_pct": 7.7, "cagr_3yr_pct": 7.7, "volatility_pct": 0, "composite_score": 83.9, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.1,00,000", "suggested_allocation_pct": 5}], "projected_corpus_3yr_inr": "Rs.41,74,000", "expected_portfolio_return_pct": 28.9, "expected_portfolio_max_drawdown_pct": -17.57}, {"algorithm": "TEMPLATE_DRIVEN", "option_id": 2, "option_name": "Growth Maximiser", "allocation_summary": "65% equity / 15% international / 10% gold / 10% safe", "strategy_description": "Maximum equity and international exposure for aggressive capital appreciation, following a 65% Equity, 15% International, 10% Gold, 10% Safe allocation.", "projected_gain_3yr_inr": "Rs.20,58,000", "portfolio_sharpe_approx": 1.41, "recommended_instruments": [{"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "Top-scoring Mid Cap fund with a strong 23.72% 3-year CAGR, forming the core of the domestic equity allocation.", "asset_class": "EQUITY", "cagr_1yr_pct": 6.85, "cagr_3yr_pct": 23.72, "volatility_pct": 14.94, "composite_score": 90.1, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.7,00,000", "suggested_allocation_pct": 35}, {"amc": "Nippon India MF", "name": "Nippon India Growth Fund (Mid Cap) - Direct Plan Growth", "fund_id": "FUND025", "category": "Mid Cap Fund", "rationale": "Second-highest scoring Mid Cap fund with a stellar 25.68% 3-year CAGR to complement the primary equity holding and avoid concentration.", "asset_class": "EQUITY", "cagr_1yr_pct": 9.34, "cagr_3yr_pct": 25.68, "volatility_pct": 16.5, "composite_score": 87.97, "max_drawdown_pct": -19.87, "suggested_amount_inr": "Rs.6,00,000", "suggested_allocation_pct": 30}, {"amc": "Mirae Asset MF", "name": "Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth", "fund_id": "FUND031", "category": "International FoF", "rationale": "Provides aggressive international growth with a 51.83% 3-year CAGR, targeting top global tech companies.", "asset_class": "INTERNATIONAL", "cagr_1yr_pct": 44.41, "cagr_3yr_pct": 51.83, "volatility_pct": 24.71, "composite_score": 93.36, "max_drawdown_pct": -30.31, "suggested_amount_inr": "Rs.3,00,000", "suggested_allocation_pct": 15}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Best-in-class Gold ETF provides a powerful hedge with a 36.5% 3-year CAGR.", "asset_class": "GOLD", "cagr_1yr_pct": 67.05, "cagr_3yr_pct": 36.5, "volatility_pct": 18.47, "composite_score": 96.65, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "India Post / Government of India", "name": "National Savings Certificate (NSC) VIII Issue", "fund_id": "FUND005", "category": "Government Savings Scheme", "rationale": "Offers a risk-free foundation with a guaranteed 7.7% return, ensuring capital protection for this portion of the portfolio.", "asset_class": "SAFE", "cagr_1yr_pct": 7.7, "cagr_3yr_pct": 7.7, "volatility_pct": 0, "composite_score": 83.9, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}], "projected_corpus_3yr_inr": "Rs.40,58,000", "expected_portfolio_return_pct": 27.28, "expected_portfolio_max_drawdown_pct": -19.38}, {"algorithm": "TEMPLATE_DRIVEN", "option_id": 3, "option_name": "Tax + Growth", "allocation_summary": "30% equity / 25% safe / 10% international / 10% gold / 5% hybrid", "strategy_description": "A balanced portfolio combining tax savings via ELSS and PPF with equity growth. Follows a 30% ELSS, 25% Safe (PPF), 20% Equity, 10% International, 10% Gold, 5% Hybrid allocation.", "projected_gain_3yr_inr": "Rs.15,39,000", "portfolio_sharpe_approx": 1.5, "recommended_instruments": [{"amc": "DSP MF", "name": "DSP ELSS Tax Saver Fund - Direct Plan - Growth", "fund_id": "FUND029", "category": "ELSS Tax Saver", "rationale": "Top-ranked ELSS fund with a 17.74% 3-year CAGR, providing tax benefits under Section 80C alongside equity growth.", "asset_class": "EQUITY", "cagr_1yr_pct": -2.23, "cagr_3yr_pct": 17.74, "volatility_pct": 13.88, "composite_score": 84.18, "max_drawdown_pct": -16.16, "suggested_amount_inr": "Rs.6,00,000", "suggested_allocation_pct": 30}, {"amc": "Government of India", "name": "Public Provident Fund (PPF)", "fund_id": "FUND003", "category": "Government Savings Scheme", "rationale": "Provides a tax-free, sovereign-guaranteed return of 7.1%, forming the stable, tax-efficient core of this portfolio.", "asset_class": "SAFE", "cagr_1yr_pct": 7.1, "cagr_3yr_pct": 7.1, "volatility_pct": 0, "composite_score": 82.6, "max_drawdown_pct": 0, "suggested_amount_inr": "Rs.5,00,000", "suggested_allocation_pct": 25}, {"amc": "HDFC AMC", "name": "HDFC Mid Cap Opportunities Fund - Growth Option - Direct Plan", "fund_id": "FUND019", "category": "Mid Cap Fund", "rationale": "High-performing Mid Cap fund with a 23.72% 3-year CAGR to drive additional domestic equity growth.", "asset_class": "EQUITY", "cagr_1yr_pct": 6.85, "cagr_3yr_pct": 23.72, "volatility_pct": 14.94, "composite_score": 90.1, "max_drawdown_pct": -16.76, "suggested_amount_inr": "Rs.4,00,000", "suggested_allocation_pct": 20}, {"amc": "Mirae Asset MF", "name": "Mirae Asset NYSE FANG+ ETF Fund of Fund - Direct Plan Growth", "fund_id": "FUND031", "category": "International FoF", "rationale": "Offers aggressive international growth with a 51.83% 3-year CAGR, diversifying the equity allocation globally.", "asset_class": "INTERNATIONAL", "cagr_1yr_pct": 44.41, "cagr_3yr_pct": 51.83, "volatility_pct": 24.71, "composite_score": 93.36, "max_drawdown_pct": -30.31, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Nippon India MF", "name": "Nippon India ETF Gold BeES", "fund_id": "FUND022", "category": "Gold ETF", "rationale": "Top-tier Gold ETF providing a hedge against inflation and market risk with a strong 36.5% 3-year CAGR.", "asset_class": "GOLD", "cagr_1yr_pct": 67.05, "cagr_3yr_pct": 36.5, "volatility_pct": 18.47, "composite_score": 96.65, "max_drawdown_pct": -22.28, "suggested_amount_inr": "Rs.2,00,000", "suggested_allocation_pct": 10}, {"amc": "Nippon India MF", "name": "Nippon India Multi Asset Allocation Fund - Direct Plan - Growth Option", "fund_id": "FUND017", "category": "Multi Asset Fund", "rationale": "Adds stability and diversification with its excellent risk-adjusted return of 21.6% (3-year CAGR) and low drawdown.", "asset_class": "HYBRID", "cagr_1yr_pct": 17.43, "cagr_3yr_pct": 21.6, "volatility_pct": 9.83, "composite_score": 98.41, "max_drawdown_pct": -10.78, "suggested_amount_inr": "Rs.1,00,000", "suggested_allocation_pct": 5}], "projected_corpus_3yr_inr": "Rs.35,39,000", "expected_portfolio_return_pct": 20.89, "expected_portfolio_max_drawdown_pct": -13.9}]	Sharpe Maximiser, Growth Maximiser, Tax + Growth	
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
-- Name: recommendation_log recommendation_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation_log
    ADD CONSTRAINT recommendation_log_pkey PRIMARY KEY (rec_id);


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

