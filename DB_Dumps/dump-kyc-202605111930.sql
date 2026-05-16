--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 16.3

-- Started on 2026-05-11 19:30:05

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
-- TOC entry 856 (class 1247 OID 16710)
-- Name: doc_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.doc_status_enum AS ENUM (
    'VALID',
    'EXPIRED',
    'PENDING_VERIFICATION',
    'REJECTED'
);


ALTER TYPE public.doc_status_enum OWNER TO postgres;

--
-- TOC entry 853 (class 1247 OID 16692)
-- Name: doc_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.doc_type_enum AS ENUM (
    'PAN',
    'AADHAAR',
    'PASSPORT',
    'VOTER_ID',
    'DRIVING_LICENSE',
    'UTILITY_BILL',
    'RENT_AGREEMENT',
    'BANK_STMT'
);


ALTER TYPE public.doc_type_enum OWNER TO postgres;

--
-- TOC entry 880 (class 1247 OID 16790)
-- Name: edd_outcome_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.edd_outcome_enum AS ENUM (
    'CLEARED',
    'SUSPICIOUS_ACTIVITY_REPORT',
    'RELATIONSHIP_EXITED',
    'PENDING'
);


ALTER TYPE public.edd_outcome_enum OWNER TO postgres;

--
-- TOC entry 877 (class 1247 OID 16778)
-- Name: edd_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.edd_status_enum AS ENUM (
    'OPEN',
    'IN_PROGRESS',
    'CLOSED_CLEARED',
    'CLOSED_ESCALATED',
    'PENDING_DOCS'
);


ALTER TYPE public.edd_status_enum OWNER TO postgres;

--
-- TOC entry 844 (class 1247 OID 16662)
-- Name: kyc_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.kyc_status_enum AS ENUM (
    'VERIFIED',
    'PENDING',
    'EXPIRED',
    'REJECTED',
    'UNDER_REVIEW'
);


ALTER TYPE public.kyc_status_enum OWNER TO postgres;

--
-- TOC entry 847 (class 1247 OID 16674)
-- Name: kyc_tier_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.kyc_tier_enum AS ENUM (
    'STANDARD',
    'ENHANCED',
    'SIMPLIFIED'
);


ALTER TYPE public.kyc_tier_enum OWNER TO postgres;

--
-- TOC entry 841 (class 1247 OID 16652)
-- Name: kyc_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.kyc_type_enum AS ENUM (
    'FULL_KYC',
    'E_KYC',
    'VIDEO_KYC',
    'IN_PERSON'
);


ALTER TYPE public.kyc_type_enum OWNER TO postgres;

--
-- TOC entry 865 (class 1247 OID 16740)
-- Name: pep_category_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pep_category_enum AS ENUM (
    'CAT_A',
    'CAT_B',
    'CAT_C',
    'NONE'
);


ALTER TYPE public.pep_category_enum OWNER TO postgres;

--
-- TOC entry 871 (class 1247 OID 16759)
-- Name: risk_tier_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.risk_tier_enum AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'VERY_HIGH'
);


ALTER TYPE public.risk_tier_enum OWNER TO postgres;

--
-- TOC entry 862 (class 1247 OID 16731)
-- Name: screen_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.screen_type_enum AS ENUM (
    'INITIAL',
    'PERIODIC',
    'TRIGGERED',
    'RE_SCREEN'
);


ALTER TYPE public.screen_type_enum OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 218 (class 1259 OID 16799)
-- Name: edd_cases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.edd_cases (
    edd_id character varying(12) NOT NULL,
    customer_id character varying(12) NOT NULL,
    trigger_reason character varying(200) NOT NULL,
    open_date date NOT NULL,
    case_status public.edd_status_enum NOT NULL,
    assigned_to character varying(50),
    findings_summary text,
    source_of_wealth_verified boolean DEFAULT false,
    escalation_flag boolean DEFAULT false,
    close_date date,
    outcome public.edd_outcome_enum DEFAULT 'PENDING'::public.edd_outcome_enum
);


ALTER TABLE public.edd_cases OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16719)
-- Name: identity_documents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.identity_documents (
    doc_id character varying(14) NOT NULL,
    kyc_id character varying(12) NOT NULL,
    doc_type public.doc_type_enum NOT NULL,
    doc_number character varying(30) NOT NULL,
    issuing_authority character varying(100),
    issue_date date,
    expiry_date date,
    doc_status public.doc_status_enum DEFAULT 'VALID'::public.doc_status_enum,
    dms_ref character varying(14)
);


ALTER TABLE public.identity_documents OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 16681)
-- Name: kyc_master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kyc_master (
    kyc_id character varying(12) NOT NULL,
    customer_id character varying(12) NOT NULL,
    kyc_type public.kyc_type_enum NOT NULL,
    kyc_status public.kyc_status_enum NOT NULL,
    kyc_tier public.kyc_tier_enum DEFAULT 'STANDARD'::public.kyc_tier_enum,
    verification_method character varying(50),
    verified_date date NOT NULL,
    expiry_date date,
    re_kyc_due date,
    verified_by character varying(50),
    notes text,
    pan_number character varying(10)
);


ALTER TABLE public.kyc_master OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16749)
-- Name: pep_screening; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pep_screening (
    screen_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    screen_date date NOT NULL,
    screen_type public.screen_type_enum NOT NULL,
    pep_flag boolean DEFAULT false,
    pep_category public.pep_category_enum DEFAULT 'NONE'::public.pep_category_enum,
    sanctions_list character varying(100),
    sanctions_hit character varying(200),
    adverse_media_hit text,
    screened_by character varying(50) NOT NULL,
    next_review date
);


ALTER TABLE public.pep_screening OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16767)
-- Name: risk_classification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.risk_classification (
    risk_class_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    risk_tier public.risk_tier_enum NOT NULL,
    risk_score numeric(5,2) NOT NULL,
    classification_date date NOT NULL,
    classification_basis text,
    override_flag boolean DEFAULT false,
    override_reason character varying(200),
    reviewed_by character varying(50)
);


ALTER TABLE public.risk_classification OWNER TO postgres;

--
-- TOC entry 3414 (class 0 OID 16799)
-- Dependencies: 218
-- Data for Name: edd_cases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.edd_cases (edd_id, customer_id, trigger_reason, open_date, case_status, assigned_to, findings_summary, source_of_wealth_verified, escalation_flag, close_date, outcome) FROM stdin;
EDD00000001	CUST000005	Large cash deposits >10L in 3 months. Unknown counterparty transactions.	2024-01-06	IN_PROGRESS	ComplianceOfficer_01	Cash deposits traced to wholesale market collections. Partially verified. 1 transaction still unexplained.	f	t	\N	PENDING
EDD00000002	CUST000008	PEP Category B. Senior government official. Mandatory EDD.	2021-04-30	CLOSED_CLEARED	ComplianceOfficer_03	Source of wealth - salary + ancestral property. All documents verified. Annual re-screening scheduled.	t	f	2021-09-15	CLEARED
EDD00000003	CUST000009	Complex corporate structure. Multiple beneficial owners. Re-KYC overdue.	2023-09-01	OPEN	ComplianceOfficer_02	UBO structure shared. Pending verification of 3 offshore entities. Re-KYC overdue since Sep 2023.	f	t	\N	PENDING
EDD00000004	CUST000006	UHNI client with multiple property transactions. Re-KYC overdue.	2024-01-18	PENDING_DOCS	ComplianceOfficer_02	Property sale proceeds verified for 2 of 4 transactions. Awaiting CA certificate for balance.	f	f	\N	PENDING
\.


--
-- TOC entry 3411 (class 0 OID 16719)
-- Dependencies: 215
-- Data for Name: identity_documents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.identity_documents (doc_id, kyc_id, doc_type, doc_number, issuing_authority, issue_date, expiry_date, doc_status, dms_ref) FROM stdin;
DOC000000001	KYC000000001	PAN	AXBPM1234C	Income Tax Dept	2005-01-01	9999-12-31	VALID	DMS000000001
DOC000000002	KYC000000001	AADHAAR	5678****1234	UIDAI	2012-06-01	9999-12-31	VALID	DMS000000002
DOC000000003	KYC000000001	PASSPORT	Z1234567	MEA India	2019-03-01	2029-03-01	VALID	DMS000000003
DOC000000004	KYC000000002	PAN	BQCPI5678D	Income Tax Dept	2010-05-01	9999-12-31	VALID	DMS000000004
DOC000000005	KYC000000002	AADHAAR	1234****5678	UIDAI	2015-09-01	9999-12-31	VALID	DMS000000005
DOC000000006	KYC000000003	PAN	CRDQS9012E	Income Tax Dept	1998-01-01	9999-12-31	VALID	DMS000000006
DOC000000007	KYC000000003	PASSPORT	A9876543	MEA India	2018-07-01	2028-07-01	VALID	DMS000000007
DOC000000008	KYC000000005	PAN	ETFUS7890G	Income Tax Dept	2003-01-01	9999-12-31	VALID	DMS000000008
DOC000000009	KYC000000005	AADHAAR	3456****7890	UIDAI	2014-04-01	9999-12-31	PENDING_VERIFICATION	DMS000000009
DOC000000010	KYC000000006	PAN	FUGVA2345H	Income Tax Dept	1995-01-01	9999-12-31	VALID	DMS000000010
DOC000000011	KYC000000008	PAN	HWIXC0123K	Income Tax Dept	2008-01-01	9999-12-31	VALID	DMS000000011
DOC000000012	KYC000000008	DRIVING_LICENSE	KL09 DC5678	Kerala RTO	2016-08-01	2036-08-01	VALID	DMS000000012
DOC000000013	KYC000000009	PAN	IXJYD4567L	Income Tax Dept	1992-01-01	9999-12-31	VALID	DMS000000013
DOC000000014	KYC000000009	PASSPORT	B2345678	MEA India	2015-01-01	2025-01-01	EXPIRED	DMS000000014
DOC000000015	KYC000000011	PAN	KABVK3579N	Income Tax Dept	2005-03-15	9999-12-31	VALID	DMS000000021
DOC000000016	KYC000000011	AADHAAR	56781255	UIDAI	2012-01-01	9999-12-31	VALID	DMS000000022
DOC000000017	KYC000000012	PAN	BKPMA5512L	Income Tax Dept	2008-07-20	9999-12-31	VALID	DMS000000024
DOC000000018	KYC000000012	AADHAAR	76543210	UIDAI	2013-05-10	9999-12-31	VALID	DMS000000025
DOC000000019	KYC000000013	PAN	CLPSV7723K	Income Tax Dept	2006-08-15	9999-12-31	VALID	DMS000000027
DOC000000020	KYC000000013	AADHAAR	86543210	UIDAI	2014-02-28	9999-12-31	VALID	DMS000000028
DOC000000021	KYC000000014	PAN	DKPRK8834M	Income Tax Dept	2003-11-10	9999-12-31	VALID	DMS000000030
DOC000000022	KYC000000014	AADHAAR	96543210	UIDAI	2011-09-20	9999-12-31	VALID	DMS000000031
\.


--
-- TOC entry 3410 (class 0 OID 16681)
-- Dependencies: 214
-- Data for Name: kyc_master; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.kyc_master (kyc_id, customer_id, kyc_type, kyc_status, kyc_tier, verification_method, verified_date, expiry_date, re_kyc_due, verified_by, notes, pan_number) FROM stdin;
KYC000000001	CUST000001	IN_PERSON	VERIFIED	STANDARD	DOCUMENT	2021-06-01	2026-06-01	2026-06-01	ComplianceOfficer_01	\N	AXBPM1234C
KYC000000002	CUST000002	E_KYC	VERIFIED	STANDARD	AADHAAR_OTP	2022-03-15	2027-03-15	2027-03-15	System_Auto	\N	BQCPI5678D
KYC000000003	CUST000003	IN_PERSON	VERIFIED	ENHANCED	BIOMETRIC	2020-11-20	2025-11-20	2024-11-20	ComplianceOfficer_02	UHNI client - enhanced monitoring active	CRDQS9012E
KYC000000004	CUST000004	E_KYC	VERIFIED	STANDARD	AADHAAR_OTP	2023-01-10	2028-01-10	2028-01-10	System_Auto	\N	DSERT3456F
KYC000000005	CUST000005	IN_PERSON	UNDER_REVIEW	ENHANCED	DOCUMENT	2022-08-05	\N	2024-08-05	ComplianceOfficer_01	Large cash deposits flagged. EDD initiated.	ETFUS7890G
KYC000000006	CUST000006	IN_PERSON	VERIFIED	ENHANCED	BIOMETRIC	2019-02-14	2024-02-14	2024-02-14	ComplianceOfficer_02	UHNI. Multiple property assets. Re-KYC overdue.	FUGVA2345H
KYC000000007	CUST000007	VIDEO_KYC	VERIFIED	STANDARD	VIDEO_CALL	2022-07-22	2027-07-22	2027-07-22	System_Video	\N	GVHWB6789J
KYC000000008	CUST000008	IN_PERSON	VERIFIED	ENHANCED	DOCUMENT	2021-04-30	2026-04-30	2026-04-30	ComplianceOfficer_03	Government official - PEP Category B	HWIXC0123K
KYC000000009	CUST000009	IN_PERSON	VERIFIED	ENHANCED	BIOMETRIC	2018-09-01	2023-09-01	2023-09-01	ComplianceOfficer_02	Re-KYC OVERDUE. Complex corporate structure.	IXJYD4567L
KYC000000010	CUST000010	E_KYC	VERIFIED	STANDARD	AADHAAR_OTP	2023-06-18	2028-06-18	2028-06-18	System_Auto	\N	JYKZE8901M
KYC000000011	CUST000011	IN_PERSON	VERIFIED	STANDARD	DOCUMENT	2016-11-10	2026-11-10	2026-11-10	ComplianceOfficer_01	KYC verified at branch. HNI segment. MODERATE risk. Clean profile.	KABVK3579N
KYC000000012	CUST000012	IN_PERSON	VERIFIED	STANDARD	DOCUMENT	2019-03-10	2029-03-10	2027-03-10	ComplianceOfficer_01	NSE employee -- SEBI PFUTP Regulations 2003. All equity investments in NSE-listed securities prohibited. Portfolio limited to Debt/Gold/Govt Bonds. Employer pre-clearance certificate on file.	BKPMA5512L
KYC000000013	CUST000013	IN_PERSON	VERIFIED	STANDARD	DOCUMENT	2017-07-22	2027-07-22	2027-07-22	ComplianceOfficer_02	Long-standing HNI client. Conservative investor. KYC current. Suitability review in progress following client request to upgrade risk appetite.	CLPSV7723K
KYC000000014	CUST000014	IN_PERSON	VERIFIED	STANDARD	DOCUMENT	2015-06-18	2025-06-18	2027-06-18	ComplianceOfficer_01	Aggressive HNI investor. Business owner. KYC current. Suffered heavy portfolio losses in FY2022-23. Risk reclassification in progress following client request to shift conservative.	DKPRK8834M
\.


--
-- TOC entry 3412 (class 0 OID 16749)
-- Dependencies: 216
-- Data for Name: pep_screening; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pep_screening (screen_id, customer_id, screen_date, screen_type, pep_flag, pep_category, sanctions_list, sanctions_hit, adverse_media_hit, screened_by, next_review) FROM stdin;
SCR000000001	CUST000001	2021-06-01	INITIAL	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2022-06-01
SCR000000002	CUST000002	2022-03-15	INITIAL	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2023-03-15
SCR000000003	CUST000003	2020-11-20	INITIAL	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2021-11-20
SCR000000004	CUST000003	2024-01-20	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	ComplianceOfficer_02	2025-01-20
SCR000000005	CUST000005	2024-01-06	TRIGGERED	f	NONE	OFAC,UN,SEBI	None	Mention in local news re: business dispute	ComplianceOfficer_01	2024-07-06
SCR000000006	CUST000006	2019-02-14	INITIAL	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2020-02-14
SCR000000007	CUST000006	2024-01-18	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	ComplianceOfficer_02	2025-01-18
SCR000000008	CUST000008	2021-04-30	INITIAL	t	CAT_B	OFAC,UN,SEBI	None	None	ComplianceOfficer_03	2022-04-30
SCR000000009	CUST000008	2024-01-25	PERIODIC	t	CAT_B	OFAC,UN,SEBI	None	None	ComplianceOfficer_03	2025-01-25
SCR000000010	CUST000009	2018-09-01	INITIAL	f	NONE	OFAC,UN,SEBI	None	Indirect mention in regulatory probe 2017	ComplianceOfficer_02	2019-09-01
SCR000000011	CUST000011	2024-01-15	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2025-01-15
SCR000000012	CUST000012	2024-09-15	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2025-09-15
SCR000000013	CUST000013	2025-01-20	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2026-01-20
SCR000000014	CUST000014	2024-12-05	PERIODIC	f	NONE	OFAC,UN,SEBI	None	None	AutoScreen_v2	2025-12-05
\.


--
-- TOC entry 3413 (class 0 OID 16767)
-- Dependencies: 217
-- Data for Name: risk_classification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_classification (risk_class_id, customer_id, risk_tier, risk_score, classification_date, classification_basis, override_flag, override_reason, reviewed_by) FROM stdin;
RCLASS00000001	CUST000001	LOW	22.50	2024-01-10	Stable income, regular transactions, no adverse flags	f	\N	ComplianceOfficer_01
RCLASS00000002	CUST000002	LOW	18.00	2024-02-15	Salaried professional, clean history, standard KYC	f	\N	ComplianceOfficer_01
RCLASS00000003	CUST000003	MEDIUM	55.00	2024-01-20	UHNI business owner, large transactions, offshore interest	f	\N	ComplianceOfficer_02
RCLASS00000004	CUST000004	LOW	12.00	2024-03-01	Retail salaried, low value transactions, standard profile	f	\N	ComplianceOfficer_02
RCLASS00000005	CUST000005	HIGH	78.50	2024-01-06	Large unexplained cash deposits, business dispute mention	f	\N	ComplianceOfficer_01
RCLASS00000006	CUST000006	MEDIUM	48.00	2024-01-18	UHNI real estate, multiple entities, re-KYC overdue	t	Manually upgraded from LOW pending re-KYC	ComplianceOfficer_02
RCLASS00000007	CUST000007	LOW	15.00	2024-02-10	Retail salaried, video KYC, low value account	f	\N	ComplianceOfficer_03
RCLASS00000008	CUST000008	HIGH	72.00	2024-01-25	PEP Cat-B, government official, enhanced monitoring required	f	\N	ComplianceOfficer_03
RCLASS00000009	CUST000009	VERY_HIGH	88.00	2024-01-08	UHNI promoter, complex structure, re-KYC overdue, old probe	f	\N	ComplianceOfficer_02
RCLASS00000010	CUST000010	LOW	10.00	2024-03-05	New retail customer, low value, standard profile	f	\N	ComplianceOfficer_03
RCLASS00000011	CUST000011	LOW	20.00	2024-01-15	Verified KYC, no PEP, no adverse media, no EDD cases, MODERATE risk appetite, stable income.	f	\N	ComplianceOfficer_01
RCLASS00000012	CUST000012	LOW	15.00	2024-09-15	Verified KYC, no PEP, no adverse media, CONSERVATIVE risk appetite. Compliance restriction (SEBI PFUTP) actively managed. Stable salaried income.	f	\N	ComplianceOfficer_01
RCLASS00000013	CUST000013	LOW	18.00	2025-01-20	Verified KYC, no PEP, no adverse media. CONSERVATIVE risk appetite on record. Stable business income. Suitability re-assessment pending client's request to upgrade to aggressive strategy.	f	\N	ComplianceOfficer_02
RCLASS00000014	CUST000014	MEDIUM	55.00	2024-12-05	AGGRESSIVE risk appetite on record. Concentrated mid/small-cap equity exposure. FY2022-23 heavy losses: -18.3% (Dec-22), -14.5% (Mar-23). Behavioural risk elevated post-drawdown. Risk reclassification pending.	f	\N	ComplianceOfficer_01
\.


--
-- TOC entry 3266 (class 2606 OID 16808)
-- Name: edd_cases edd_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edd_cases
    ADD CONSTRAINT edd_cases_pkey PRIMARY KEY (edd_id);


--
-- TOC entry 3258 (class 2606 OID 16724)
-- Name: identity_documents identity_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_documents
    ADD CONSTRAINT identity_documents_pkey PRIMARY KEY (doc_id);


--
-- TOC entry 3254 (class 2606 OID 16690)
-- Name: kyc_master kyc_master_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kyc_master
    ADD CONSTRAINT kyc_master_customer_id_key UNIQUE (customer_id);


--
-- TOC entry 3256 (class 2606 OID 16688)
-- Name: kyc_master kyc_master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kyc_master
    ADD CONSTRAINT kyc_master_pkey PRIMARY KEY (kyc_id);


--
-- TOC entry 3260 (class 2606 OID 16757)
-- Name: pep_screening pep_screening_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pep_screening
    ADD CONSTRAINT pep_screening_pkey PRIMARY KEY (screen_id);


--
-- TOC entry 3262 (class 2606 OID 16776)
-- Name: risk_classification risk_classification_customer_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_classification
    ADD CONSTRAINT risk_classification_customer_id_key UNIQUE (customer_id);


--
-- TOC entry 3264 (class 2606 OID 16774)
-- Name: risk_classification risk_classification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_classification
    ADD CONSTRAINT risk_classification_pkey PRIMARY KEY (risk_class_id);


--
-- TOC entry 3252 (class 1259 OID 24577)
-- Name: idx_kyc_master_pan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_kyc_master_pan ON public.kyc_master USING btree (pan_number);


--
-- TOC entry 3267 (class 2606 OID 16725)
-- Name: identity_documents identity_documents_kyc_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.identity_documents
    ADD CONSTRAINT identity_documents_kyc_id_fkey FOREIGN KEY (kyc_id) REFERENCES public.kyc_master(kyc_id);


-- Completed on 2026-05-11 19:30:05

--
-- PostgreSQL database dump complete
--

