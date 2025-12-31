-- Add latitude and longitude coordinates to rescues table
-- Migration: 2025123102_add_rescue_coordinates.sql

-- Grant service_role access to dogadopt schema (if not already granted)
GRANT USAGE ON SCHEMA dogadopt TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA dogadopt TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA dogadopt TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA dogadopt TO service_role;

ALTER TABLE dogadopt.rescues
  ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
  ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8),
  ADD COLUMN IF NOT EXISTS coordinates_updated_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS coordinates_source TEXT;

-- Create spatial index for distance-based queries
CREATE INDEX IF NOT EXISTS idx_rescues_coordinates 
  ON dogadopt.rescues(latitude, longitude) 
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN dogadopt.rescues.latitude IS 'Latitude coordinate (WGS84)';
COMMENT ON COLUMN dogadopt.rescues.longitude IS 'Longitude coordinate (WGS84)';
COMMENT ON COLUMN dogadopt.rescues.coordinates_updated_at IS 'Last time coordinates were geocoded';
COMMENT ON COLUMN dogadopt.rescues.coordinates_source IS 'Source of geocoding (e.g., "postcodes.io", "google", "manual")';

-- Function to calculate distance between two coordinates (in km)
-- Useful for "find rescues near me" features
CREATE OR REPLACE FUNCTION dogadopt.calculate_distance(
  lat1 DECIMAL,
  lon1 DECIMAL,
  lat2 DECIMAL,
  lon2 DECIMAL
)
RETURNS DECIMAL
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  earth_radius CONSTANT DECIMAL := 6371; -- Earth's radius in km
  dlat DECIMAL;
  dlon DECIMAL;
  a DECIMAL;
  c DECIMAL;
BEGIN
  -- Haversine formula
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  a := sin(dlat/2) * sin(dlat/2) + 
       cos(radians(lat1)) * cos(radians(lat2)) * 
       sin(dlon/2) * sin(dlon/2);
  
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  
  RETURN earth_radius * c;
END;
$$;

COMMENT ON FUNCTION dogadopt.calculate_distance IS 'Calculate great circle distance between two coordinates in kilometers using Haversine formula';
