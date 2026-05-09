-- Migration 02: Add pan_number to kyc.kyc_master
-- Run against the KYC database.
--
-- Why: kyc_master is currently linked to CBS via customer_id,
-- which is unrealistic — a KYC system would use PAN/Aadhaar as its
-- primary identity anchor, not an internal bank customer ID.
-- Adding pan_number allows the identity resolution layer to match
-- KYC records using PAN, independent of the CBS customer_id.

ALTER TABLE kyc_master
    ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10);

CREATE INDEX IF NOT EXISTS idx_kyc_master_pan
    ON kyc_master (pan_number);
