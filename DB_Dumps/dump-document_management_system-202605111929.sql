--
-- PostgreSQL database dump
--

-- Dumped from database version 15.4 (Debian 15.4-2.pgdg120+1)
-- Dumped by pg_dump version 16.3

-- Started on 2026-05-11 19:29:56

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
-- TOC entry 843 (class 1247 OID 17044)
-- Name: access_level_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.access_level_enum AS ENUM (
    'PUBLIC',
    'INTERNAL',
    'RESTRICTED',
    'CONFIDENTIAL'
);


ALTER TYPE public.access_level_enum OWNER TO postgres;

--
-- TOC entry 855 (class 1247 OID 17084)
-- Name: audit_action_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.audit_action_enum AS ENUM (
    'KYC_UPDATE',
    'EDD_TRIGGER',
    'DOCUMENT_UPLOAD',
    'RISK_RECLASSIFIED',
    'PEP_FLAGGED',
    'ACCOUNT_BLOCKED',
    'ACCOUNT_UNFROZEN',
    'SAR_FILED',
    'SYSTEM_ACCESS'
);


ALTER TYPE public.audit_action_enum OWNER TO postgres;

--
-- TOC entry 840 (class 1247 OID 17029)
-- Name: doc_category_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.doc_category_enum AS ENUM (
    'IDENTITY',
    'ADDRESS_PROOF',
    'INCOME',
    'BANK_STATEMENT',
    'COMPLIANCE',
    'LEGAL',
    'PORTFOLIO'
);


ALTER TYPE public.doc_category_enum OWNER TO postgres;

--
-- TOC entry 849 (class 1247 OID 17070)
-- Name: extraction_method_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.extraction_method_enum AS ENUM (
    'AI_EXTRACTION',
    'MANUAL',
    'SYSTEM'
);


ALTER TYPE public.extraction_method_enum OWNER TO postgres;

--
-- TOC entry 852 (class 1247 OID 17078)
-- Name: extraction_method_simple_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.extraction_method_simple_enum AS ENUM (
    'AI_EXTRACTION',
    'MANUAL'
);


ALTER TYPE public.extraction_method_simple_enum OWNER TO postgres;

--
-- TOC entry 846 (class 1247 OID 17054)
-- Name: proof_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.proof_type_enum AS ENUM (
    'SALARY_SLIP',
    'ITR',
    'FORM_16',
    'CA_CERTIFICATE',
    'BUSINESS_PL',
    'RENTAL_INCOME',
    'PENSION'
);


ALTER TYPE public.proof_type_enum OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 217 (class 1259 OID 17135)
-- Name: audit_trail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_trail (
    audit_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    action_type public.audit_action_enum NOT NULL,
    action_date timestamp without time zone NOT NULL,
    performed_by character varying(50) NOT NULL,
    system_source character varying(50),
    reference_id character varying(20),
    before_state character varying(200),
    after_state character varying(200),
    ip_address character varying(45)
);


ALTER TABLE public.audit_trail OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 17122)
-- Name: bank_statements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bank_statements (
    stmt_id character varying(12) NOT NULL,
    dms_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    bank_name character varying(100) NOT NULL,
    account_number_masked character varying(20) NOT NULL,
    stmt_period_from date NOT NULL,
    stmt_period_to date NOT NULL,
    avg_monthly_credit numeric(15,2),
    avg_monthly_debit numeric(15,2),
    closing_balance numeric(15,2),
    extracted_by public.extraction_method_simple_enum DEFAULT 'AI_EXTRACTION'::public.extraction_method_simple_enum,
    notes text
);


ALTER TABLE public.bank_statements OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 17103)
-- Name: document_repository; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_repository (
    dms_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    doc_category public.doc_category_enum NOT NULL,
    doc_type character varying(50) NOT NULL,
    file_name character varying(200) NOT NULL,
    upload_date date NOT NULL,
    uploaded_by character varying(50) NOT NULL,
    file_size_kb integer,
    mime_type character varying(50),
    storage_path character varying(300),
    access_level public.access_level_enum DEFAULT 'INTERNAL'::public.access_level_enum,
    pan_number character varying(10)
);


ALTER TABLE public.document_repository OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 17111)
-- Name: income_proofs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.income_proofs (
    proof_id character varying(12) NOT NULL,
    dms_id character varying(14) NOT NULL,
    customer_id character varying(12) NOT NULL,
    proof_type public.proof_type_enum NOT NULL,
    assessment_year character varying(7),
    gross_income numeric(15,2) NOT NULL,
    net_income numeric(15,2) NOT NULL,
    employer_name character varying(100),
    filing_date date,
    extracted_by public.extraction_method_enum DEFAULT 'AI_EXTRACTION'::public.extraction_method_enum,
    extraction_confidence numeric(4,3)
);


ALTER TABLE public.income_proofs OWNER TO postgres;

--
-- TOC entry 3387 (class 0 OID 17135)
-- Dependencies: 217
-- Data for Name: audit_trail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_trail (audit_id, customer_id, action_type, action_date, performed_by, system_source, reference_id, before_state, after_state, ip_address) FROM stdin;
AUDIT00000001	CUST000005	EDD_TRIGGER	2024-01-06 10:22:15	ComplianceOfficer_01	KYC_SYSTEM	EDD00000001	risk_tier=MEDIUM	risk_tier=HIGH, edd_initiated=TRUE	10.0.1.45
AUDIT00000002	CUST000005	KYC_UPDATE	2024-01-06 10:25:00	ComplianceOfficer_01	KYC_SYSTEM	KYC000000005	kyc_status=VERIFIED	kyc_status=UNDER_REVIEW	10.0.1.45
AUDIT00000003	CUST000008	PEP_FLAGGED	2021-04-30 14:15:00	ComplianceOfficer_03	SCREEN_SYS	SCR000000008	pep_flag=FALSE	pep_flag=TRUE, cat=CAT_B	10.0.2.88
AUDIT00000004	CUST000009	KYC_UPDATE	2023-09-01 09:00:00	System_AutoFlag	KYC_SYSTEM	KYC000000009	re_kyc_status=PENDING	re_kyc_status=OVERDUE	10.0.0.1
AUDIT00000005	CUST000006	RISK_RECLASSIFIED	2024-01-18 11:30:00	ComplianceOfficer_02	RISK_ENGINE	RCLASS00000006	risk_tier=LOW	risk_tier=MEDIUM, override=TRUE	10.0.1.92
AUDIT00000006	CUST000009	EDD_TRIGGER	2023-09-01 09:05:00	System_AutoFlag	KYC_SYSTEM	EDD00000003	edd_case=NONE	edd_id=EDD00000003, status=OPEN	10.0.0.1
AUDIT00000007	CUST000003	DOCUMENT_UPLOAD	2023-10-15 16:45:00	ComplianceOfficer_02	DMS	DMS000000018	doc_count=5	doc_count=6, new=CA_CERT_FY2223	10.0.1.77
AUDIT00000008	CUST000005	DOCUMENT_UPLOAD	2024-01-06 10:30:00	ComplianceOfficer_01	DMS	DMS000000020	doc_count=8	doc_count=9, new=EXT_BANK_STMT	10.0.1.45
\.


--
-- TOC entry 3386 (class 0 OID 17122)
-- Dependencies: 216
-- Data for Name: bank_statements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bank_statements (stmt_id, dms_id, customer_id, bank_name, account_number_masked, stmt_period_from, stmt_period_to, avg_monthly_credit, avg_monthly_debit, closing_balance, extracted_by, notes) FROM stdin;
BKST00000001	DMS000000020	CUST000005	Kotak Mahindra Bank	XXXXXXXX9981	2023-07-01	2023-09-30	1850000.00	1620000.00	450000.00	MANUAL	Large cash credits in Aug. Multiple round-figure transfers. Flagged for EDD review.
\.


--
-- TOC entry 3384 (class 0 OID 17103)
-- Dependencies: 214
-- Data for Name: document_repository; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_repository (dms_id, customer_id, doc_category, doc_type, file_name, upload_date, uploaded_by, file_size_kb, mime_type, storage_path, access_level, pan_number) FROM stdin;
DMS000000001	CUST000001	IDENTITY	PAN Card	CUST000001_PAN_AXBPM1234C.pdf	2015-06-01	OnboardingAgent	120	application/pdf	cbs/cust000001/identity/	INTERNAL	AXBPM1234C
DMS000000002	CUST000001	IDENTITY	Aadhaar Card	CUST000001_AADHAAR_5678.pdf	2015-06-01	OnboardingAgent	180	application/pdf	cbs/cust000001/identity/	RESTRICTED	AXBPM1234C
DMS000000003	CUST000001	IDENTITY	Passport	CUST000001_PASSPORT_Z1234567.pdf	2019-03-02	RM001	250	application/pdf	cbs/cust000001/identity/	RESTRICTED	AXBPM1234C
DMS000000015	CUST000001	INCOME	Salary Slip - Dec 23	CUST000001_SAL_DEC2023.pdf	2024-01-15	RM001	95	application/pdf	cbs/cust000001/income/	CONFIDENTIAL	AXBPM1234C
DMS000000016	CUST000001	INCOME	ITR AY 2022-23	CUST000001_ITR_AY2223.pdf	2023-09-01	RM001	380	application/pdf	cbs/cust000001/income/	CONFIDENTIAL	AXBPM1234C
DMS000000004	CUST000002	IDENTITY	PAN Card	CUST000002_PAN_BQCPI5678D.pdf	2018-03-15	OnboardingAgent	115	application/pdf	cbs/cust000002/identity/	INTERNAL	BQCPI5678D
DMS000000005	CUST000002	IDENTITY	Aadhaar Card	CUST000002_AADHAAR_1234.pdf	2018-03-15	OnboardingAgent	175	application/pdf	cbs/cust000002/identity/	RESTRICTED	BQCPI5678D
DMS000000017	CUST000002	INCOME	Form 16 FY 2022-23	CUST000002_FORM16_FY2223.pdf	2023-06-20	System_Upload	210	application/pdf	cbs/cust000002/income/	CONFIDENTIAL	BQCPI5678D
DMS000000006	CUST000003	IDENTITY	PAN Card	CUST000003_PAN_CRDQS9012E.pdf	2010-11-20	ComplianceOfficer_02	130	application/pdf	cbs/cust000003/identity/	INTERNAL	CRDQS9012E
DMS000000007	CUST000003	IDENTITY	Passport	CUST000003_PASSPORT_A9876543.pdf	2018-07-02	RM002	280	application/pdf	cbs/cust000003/identity/	RESTRICTED	CRDQS9012E
DMS000000018	CUST000003	INCOME	CA Certificate FY23	CUST000003_CA_CERT_FY2223.pdf	2023-10-15	ComplianceOfficer_02	450	application/pdf	cbs/cust000003/income/	CONFIDENTIAL	CRDQS9012E
DMS000000008	CUST000005	IDENTITY	PAN Card	CUST000005_PAN_ETFUS7890G.pdf	2012-08-05	OnboardingAgent	118	application/pdf	cbs/cust000005/identity/	INTERNAL	ETFUS7890G
DMS000000009	CUST000005	IDENTITY	Aadhaar Card	CUST000005_AADHAAR_3456_PENDING.pdf	2012-08-05	OnboardingAgent	160	application/pdf	cbs/cust000005/identity/	RESTRICTED	ETFUS7890G
DMS000000019	CUST000005	INCOME	Business P&L FY23	CUST000005_PL_FY2223.pdf	2023-11-01	ComplianceOfficer_01	820	application/pdf	cbs/cust000005/income/	CONFIDENTIAL	ETFUS7890G
DMS000000020	CUST000005	BANK_STATEMENT	Other Bank Stmt Q3FY24	CUST000005_EXTBANK_STMT_Q3FY24.pdf	2024-01-06	ComplianceOfficer_01	650	application/pdf	cbs/cust000005/bank_stmts/	CONFIDENTIAL	ETFUS7890G
DMS000000010	CUST000006	IDENTITY	PAN Card	CUST000006_PAN_FUGVA2345H.pdf	2008-02-14	ComplianceOfficer_02	125	application/pdf	cbs/cust000006/identity/	INTERNAL	FUGVA2345H
DMS000000011	CUST000008	IDENTITY	PAN Card	CUST000008_PAN_HWIXC0123K.pdf	2014-04-30	ComplianceOfficer_03	122	application/pdf	cbs/cust000008/identity/	INTERNAL	HWIXC0123K
DMS000000012	CUST000008	IDENTITY	Driving License	CUST000008_DL_KL09DC5678.pdf	2014-04-30	ComplianceOfficer_03	200	application/pdf	cbs/cust000008/identity/	INTERNAL	HWIXC0123K
DMS000000013	CUST000009	IDENTITY	PAN Card	CUST000009_PAN_IXJYD4567L.pdf	2005-09-01	ComplianceOfficer_02	128	application/pdf	cbs/cust000009/identity/	INTERNAL	IXJYD4567L
DMS000000014	CUST000009	IDENTITY	Passport (EXPIRED)	CUST000009_PASSPORT_B2345678_EXP.pdf	2015-01-02	RM005	260	application/pdf	cbs/cust000009/identity/	RESTRICTED	IXJYD4567L
DMS000000021	CUST000011	IDENTITY	PAN Card	CUST000011_PAN_KABVK3579N.pdf	2016-11-10	OnboardingAgent	110	application/pdf	cbs/cust000011/identity/	INTERNAL	KABVK3579N
DMS000000022	CUST000011	IDENTITY	Aadhaar Card	CUST000011_AADHAAR_masked.pdf	2016-11-10	OnboardingAgent	95	application/pdf	cbs/cust000011/identity/	INTERNAL	KABVK3579N
DMS000000023	CUST000011	INCOME	ITR Filing	CUST000011_ITR_AY2023-24.pdf	2023-11-15	RM002	850	application/pdf	cbs/cust000011/income/	RESTRICTED	KABVK3579N
DMS000000024	CUST000012	IDENTITY	PAN Card	CUST000012_PAN_BKPMA5512L.pdf	2019-03-10	OnboardingAgent	112	application/pdf	cbs/cust000012/identity/	INTERNAL	BKPMA5512L
DMS000000025	CUST000012	IDENTITY	Aadhaar Card	CUST000012_AADHAAR_masked.pdf	2019-03-10	OnboardingAgent	98	application/pdf	cbs/cust000012/identity/	INTERNAL	BKPMA5512L
DMS000000026	CUST000012	INCOME	ITR Filing	CUST000012_ITR_AY2024-25.pdf	2024-11-10	RM003	760	application/pdf	cbs/cust000012/income/	RESTRICTED	BKPMA5512L
DMS000000027	CUST000013	IDENTITY	PAN Card	CUST000013_PAN_CLPSV7723K.pdf	2017-07-22	OnboardingAgent	108	application/pdf	cbs/cust000013/identity/	INTERNAL	CLPSV7723K
DMS000000028	CUST000013	IDENTITY	Aadhaar Card	CUST000013_AADHAAR_masked.pdf	2017-07-22	OnboardingAgent	92	application/pdf	cbs/cust000013/identity/	INTERNAL	CLPSV7723K
DMS000000029	CUST000013	INCOME	ITR Filing	CUST000013_ITR_AY2024-25.pdf	2024-10-25	RM001	820	application/pdf	cbs/cust000013/income/	RESTRICTED	CLPSV7723K
DMS000000030	CUST000014	IDENTITY	PAN Card	CUST000014_PAN_DKPRK8834M.pdf	2015-06-18	OnboardingAgent	115	application/pdf	cbs/cust000014/identity/	INTERNAL	DKPRK8834M
DMS000000031	CUST000014	IDENTITY	Aadhaar Card	CUST000014_AADHAAR_masked.pdf	2015-06-18	OnboardingAgent	90	application/pdf	cbs/cust000014/identity/	INTERNAL	DKPRK8834M
DMS000000032	CUST000014	INCOME	ITR Filing	CUST000014_ITR_AY2024-25.pdf	2024-11-20	RM004	980	application/pdf	cbs/cust000014/income/	RESTRICTED	DKPRK8834M
\.


--
-- TOC entry 3385 (class 0 OID 17111)
-- Dependencies: 215
-- Data for Name: income_proofs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.income_proofs (proof_id, dms_id, customer_id, proof_type, assessment_year, gross_income, net_income, employer_name, filing_date, extracted_by, extraction_confidence) FROM stdin;
INCPR0000001	DMS000000015	CUST000001	SALARY_SLIP	2023-24	6000000.00	4200000.00	Arjun Menon Consulting LLP	2024-01-15	AI_EXTRACTION	0.982
INCPR0000002	DMS000000016	CUST000001	ITR	2022-23	5800000.00	4050000.00	Arjun Menon Consulting LLP	2023-09-01	AI_EXTRACTION	0.975
INCPR0000003	DMS000000017	CUST000002	FORM_16	2022-23	2220000.00	1750000.00	Infosys Ltd	2023-06-20	AI_EXTRACTION	0.990
INCPR0000004	DMS000000018	CUST000003	CA_CERTIFICATE	2022-23	85000000.00	62000000.00	Sharma Industries Pvt Ltd	2023-10-15	MANUAL	0.990
INCPR0000005	DMS000000019	CUST000005	BUSINESS_PL	2022-23	12000000.00	8500000.00	Sheikh Pharma Distributors	2023-11-01	AI_EXTRACTION	0.888
INCPR0000006	DMS000000020	CUST000005	BUSINESS_PL	2023-24	15000000.00	10000000.00	Sheikh Pharma Distributors	2024-01-06	MANUAL	0.852
INCPR0000011	DMS000000023	CUST000011	ITR	2023-24	3500000.00	2800000.00	Krishnan Consulting Services LLP	2023-11-15	MANUAL	0.950
INCPR0000012	DMS000000026	CUST000012	ITR	2024-25	1800000.00	1320000.00	NSE Securities India Ltd	2024-11-10	MANUAL	0.970
INCPR0000013	DMS000000029	CUST000013	ITR	2024-25	2800000.00	2040000.00	Varma Advisory Services LLP	2024-10-25	MANUAL	0.960
INCPR0000014	DMS000000032	CUST000014	ITR	2024-25	5000000.00	3500000.00	Kapoor Industries Pvt Ltd	2024-11-20	MANUAL	0.950
\.


--
-- TOC entry 3239 (class 2606 OID 17141)
-- Name: audit_trail audit_trail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_trail
    ADD CONSTRAINT audit_trail_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 3237 (class 2606 OID 17129)
-- Name: bank_statements bank_statements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_statements
    ADD CONSTRAINT bank_statements_pkey PRIMARY KEY (stmt_id);


--
-- TOC entry 3232 (class 2606 OID 17110)
-- Name: document_repository document_repository_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_repository
    ADD CONSTRAINT document_repository_pkey PRIMARY KEY (dms_id);


--
-- TOC entry 3235 (class 2606 OID 17116)
-- Name: income_proofs income_proofs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income_proofs
    ADD CONSTRAINT income_proofs_pkey PRIMARY KEY (proof_id);


--
-- TOC entry 3233 (class 1259 OID 24579)
-- Name: idx_doc_repository_pan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_doc_repository_pan ON public.document_repository USING btree (pan_number);


--
-- TOC entry 3241 (class 2606 OID 17130)
-- Name: bank_statements bank_statements_dms_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bank_statements
    ADD CONSTRAINT bank_statements_dms_id_fkey FOREIGN KEY (dms_id) REFERENCES public.document_repository(dms_id);


--
-- TOC entry 3240 (class 2606 OID 17117)
-- Name: income_proofs income_proofs_dms_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income_proofs
    ADD CONSTRAINT income_proofs_dms_id_fkey FOREIGN KEY (dms_id) REFERENCES public.document_repository(dms_id);


-- Completed on 2026-05-11 19:29:57

--
-- PostgreSQL database dump complete
--

