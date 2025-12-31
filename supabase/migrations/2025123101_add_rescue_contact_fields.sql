-- Add contact information fields to rescues table
-- Migration: 2025123101_add_rescue_contact_fields.sql

ALTER TABLE dogadopt.rescues
  ADD COLUMN IF NOT EXISTS phone VARCHAR(50),
  ADD COLUMN IF NOT EXISTS email VARCHAR(255),
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS postcode VARCHAR(20),
  ADD COLUMN IF NOT EXISTS charity_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS contact_verified_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS contact_notes TEXT;

-- Add index for postcode-based queries
CREATE INDEX IF NOT EXISTS idx_rescues_postcode 
  ON dogadopt.rescues(postcode) 
  WHERE postcode IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN dogadopt.rescues.phone IS 'Primary contact phone number';
COMMENT ON COLUMN dogadopt.rescues.email IS 'Primary contact email address';
COMMENT ON COLUMN dogadopt.rescues.address IS 'Full postal address';
COMMENT ON COLUMN dogadopt.rescues.postcode IS 'UK postcode for location-based searches';
COMMENT ON COLUMN dogadopt.rescues.charity_number IS 'UK Charity Commission registration number';
COMMENT ON COLUMN dogadopt.rescues.contact_verified_at IS 'Last time contact details were manually verified';
COMMENT ON COLUMN dogadopt.rescues.contact_notes IS 'Internal notes about contact information';

-- Update RLS policies - contact info is public read
-- No changes needed as existing SELECT policy already covers new columns
