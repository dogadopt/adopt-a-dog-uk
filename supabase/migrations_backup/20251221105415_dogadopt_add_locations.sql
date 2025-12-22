-- Add locations table to support rescue centres, foster homes, and other physical locations
-- Supports privacy controls and flexible location types

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
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add location_id to dogs table
ALTER TABLE dogadopt.dogs ADD COLUMN location_id UUID REFERENCES dogadopt.locations(id) ON DELETE SET NULL;

-- Create index for performance
CREATE INDEX idx_locations_rescue_id ON dogadopt.locations(rescue_id);
CREATE INDEX idx_dogs_location_id ON dogadopt.dogs(location_id);

-- Enable RLS on locations
ALTER TABLE dogadopt.locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations - publicly viewable
CREATE POLICY "Locations are publicly viewable"
ON dogadopt.locations FOR SELECT
USING (true);

-- RLS Policies for locations - admins can manage
CREATE POLICY "Admins can insert locations"
ON dogadopt.locations FOR INSERT
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update locations"
ON dogadopt.locations FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete locations"
ON dogadopt.locations FOR DELETE
USING (dogadopt.has_role(auth.uid(), 'admin'));

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

-- Add comments for documentation
COMMENT ON TABLE dogadopt.locations IS 'Physical locations for rescues - supports centres, foster homes, and other locations with privacy controls';
COMMENT ON COLUMN dogadopt.locations.is_public IS 'If true, show full address details. If false, show only city/region for privacy (e.g., foster homes)';
COMMENT ON COLUMN dogadopt.locations.location_type IS 'Type of location: centre (official rescue centre), foster_home (private home), office, or other';
