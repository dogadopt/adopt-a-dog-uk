-- Add locations table for rescue centres and foster homes
-- Add adoption status tracking to dogs

-- Create location_type enum
CREATE TYPE dogadopt.location_type AS ENUM ('centre', 'foster_home', 'office', 'other');

-- Create locations table
CREATE TABLE dogadopt.locations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  rescue_id UUID NOT NULL REFERENCES dogadopt.rescues(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location_type dogadopt.location_type NOT NULL DEFAULT 'centre',
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT NOT NULL,
  county TEXT,
  postcode TEXT,
  region TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  phone TEXT,
  email TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  enquiry_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_locations_rescue_id ON dogadopt.locations(rescue_id);

-- Enable RLS on locations
ALTER TABLE dogadopt.locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations
CREATE POLICY "Locations are publicly viewable"
ON dogadopt.locations FOR SELECT
USING (true);

CREATE POLICY "Admins can manage locations"
ON dogadopt.locations FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Add location_id to dogs table
ALTER TABLE dogadopt.dogs ADD COLUMN location_id UUID REFERENCES dogadopt.locations(id) ON DELETE SET NULL;
CREATE INDEX idx_dogs_location_id ON dogadopt.dogs(location_id);

-- Add URL tracking to dogs
ALTER TABLE dogadopt.dogs ADD COLUMN profile_url TEXT;

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

-- Migrate existing data: Create a default location for each rescue
INSERT INTO dogadopt.locations (rescue_id, name, city, region, location_type, is_public)
SELECT 
  r.id,
  r.name || ' - ' || r.region,
  COALESCE(
    CASE 
      WHEN r.region LIKE '%London%' THEN 'London'
      WHEN r.region LIKE '%Edinburgh%' THEN 'Edinburgh'
      WHEN r.region LIKE '%Cardiff%' THEN 'Cardiff'
      WHEN r.region LIKE '%Belfast%' THEN 'Belfast'
      WHEN r.region LIKE '%Birmingham%' THEN 'Birmingham'
      WHEN r.region LIKE '%Manchester%' THEN 'Manchester'
      WHEN r.region LIKE '%Leeds%' THEN 'Leeds'
      WHEN r.region LIKE '%Bristol%' THEN 'Bristol'
      ELSE SPLIT_PART(r.region, ' ', 1)
    END,
    r.region
  ),
  r.region,
  'centre',
  true
FROM dogadopt.rescues r;

-- Link existing dogs to their rescue's default location
UPDATE dogadopt.dogs d
SET location_id = (
  SELECT l.id 
  FROM dogadopt.locations l 
  WHERE l.rescue_id = d.rescue_id 
  LIMIT 1
)
WHERE d.rescue_id IS NOT NULL;

-- Grant permissions
GRANT SELECT ON dogadopt.locations TO anon, authenticated;

-- Helper function to get tracked URL
CREATE OR REPLACE FUNCTION dogadopt.get_dog_profile_url(
  _dog_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  dog_record RECORD;
  base_url TEXT;
  tracking_params TEXT;
BEGIN
  SELECT 
    d.id,
    d.profile_url,
    l.enquiry_url,
    r.website
  INTO dog_record
  FROM dogadopt.dogs d
  LEFT JOIN dogadopt.locations l ON l.id = d.location_id
  LEFT JOIN dogadopt.rescues r ON r.id = d.rescue_id
  WHERE d.id = _dog_id;

  -- Determine base URL (priority: dog profile > location enquiry > rescue website)
  IF dog_record.profile_url IS NOT NULL AND dog_record.profile_url != '' THEN
    base_url := dog_record.profile_url;
  ELSIF dog_record.enquiry_url IS NOT NULL AND dog_record.enquiry_url != '' THEN
    base_url := dog_record.enquiry_url;
  ELSIF dog_record.website IS NOT NULL AND dog_record.website != '' THEN
    base_url := dog_record.website;
  ELSE
    RETURN NULL;
  END IF;

  -- Build tracking parameters
  tracking_params := 'utm_source=dogadoptuk&utm_medium=referral&utm_campaign=dog_profile&utm_content=' || _dog_id::text;

  -- Append tracking parameters
  IF base_url LIKE '%?%' THEN
    RETURN base_url || '&' || tracking_params;
  ELSE
    RETURN base_url || '?' || tracking_params;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION dogadopt.get_dog_profile_url TO anon, authenticated;

-- Add documentation comments
COMMENT ON TABLE dogadopt.locations IS 'Physical locations for rescues - supports centres, foster homes, and other locations with privacy controls';
COMMENT ON COLUMN dogadopt.locations.is_public IS 'If true, show full address details. If false, show only city/region for privacy (e.g., foster homes)';
COMMENT ON COLUMN dogadopt.dogs.status IS 'Current adoption status: available, reserved, adopted, on_hold, fostered, or withdrawn';
COMMENT ON COLUMN dogadopt.dogs.profile_url IS 'Direct URL to this dog''s profile page on the rescue''s website';
