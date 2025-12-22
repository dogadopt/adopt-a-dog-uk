-- Add adoption status tracking to dogs
-- Allows tracking whether dogs are available, reserved, adopted, etc.

-- Create adoption_status enum
CREATE TYPE dogadopt.adoption_status AS ENUM (
  'available',
  'reserved',
  'adopted',
  'on_hold',
  'fostered',
  'withdrawn'
);

-- Add status fields to dogs table
ALTER TABLE dogadopt.dogs 
  ADD COLUMN status dogadopt.adoption_status NOT NULL DEFAULT 'available',
  ADD COLUMN status_updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  ADD COLUMN status_notes TEXT;

-- Create index for filtering by status
CREATE INDEX idx_dogs_status ON dogadopt.dogs(status);

-- Create trigger to automatically update status_updated_at when status changes
CREATE OR REPLACE FUNCTION dogadopt.update_status_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.status_updated_at = now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER dogs_status_updated
  BEFORE UPDATE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.update_status_timestamp();

-- Add comments for documentation
COMMENT ON COLUMN dogadopt.dogs.status IS 'Current adoption status: available (ready for adoption), reserved (application pending), adopted (successfully adopted), on_hold (temporarily unavailable), fostered (in foster care), withdrawn (removed from adoption program)';
COMMENT ON COLUMN dogadopt.dogs.status_updated_at IS 'Timestamp of when the status was last changed. Automatically updated by trigger.';
COMMENT ON COLUMN dogadopt.dogs.status_notes IS 'Optional notes about the status change (e.g., "Adopted by Smith family", "Medical treatment until Jan 15")';
