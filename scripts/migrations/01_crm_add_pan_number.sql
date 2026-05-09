-- Migration 01: Add pan_number to crm.client_profile
-- Run against the CRM database.
--
-- Why: client_profile is currently linked to CBS via customer_id,
-- which is unrealistic — a real CRM would not store the CBS internal ID.
-- Adding pan_number allows identity resolution to use PAN as the
-- cross-system linkage key, matching how banks actually operate.

ALTER TABLE client_profile
    ADD COLUMN IF NOT EXISTS pan_number VARCHAR(10);

CREATE INDEX IF NOT EXISTS idx_client_profile_pan
    ON client_profile (pan_number);
