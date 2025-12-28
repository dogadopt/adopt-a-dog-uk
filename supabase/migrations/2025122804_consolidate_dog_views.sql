-- Create a single comprehensive dog view
-- This replaces the previous dogs_resolved and dogs_with_breeds views

-- Drop the old views if they exist
DROP VIEW IF EXISTS dogadopt.dogs_with_breeds CASCADE;
DROP VIEW IF EXISTS dogadopt.dogs_resolved CASCADE;

-- Create a single comprehensive view that combines both functionalities
CREATE OR REPLACE VIEW dogadopt.dogs_complete AS
SELECT 
  -- Core dog fields
  d.id,
  d.name,
  d.age,
  d.size,
  d.gender,
  d.image,
  d.description,
  d.good_with_kids,
  d.good_with_dogs,
  d.good_with_cats,
  d.status,
  d.status_notes,
  d.profile_url,
  d.created_at,
  string_agg(b.name, ', ' ORDER BY db.display_order) AS breed,
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) AS breeds,
  COALESCE(
    string_agg(b.name, ', ' ORDER BY db.display_order),
    ''
  ) AS breeds_display,
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) AS breeds_array,
  
  r.name AS rescue_name,
  r.id AS rescue_id,
  r.region AS rescue_region,
  r.website AS rescue_website,
  
  l.name AS location_name,
  l.id AS location_id,
  l.region AS location_region,
  l.enquiry_url AS location_enquiry_url
  
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dog_breeds db ON d.id = db.dog_id
LEFT JOIN dogadopt.breeds b ON db.breed_id = b.id
LEFT JOIN dogadopt.rescues r ON d.rescue_id = r.id
LEFT JOIN dogadopt.locations l ON d.location_id = l.id
GROUP BY 
  d.id, 
  d.name,
  d.age,
  d.size,
  d.gender,
  d.image,
  d.description,
  d.good_with_kids,
  d.good_with_dogs,
  d.good_with_cats,
  d.status,
  d.status_notes,
  d.profile_url,
  d.created_at,
  r.name, 
  r.id, 
  r.region, 
  r.website,
  l.name, 
  l.id, 
  l.region, 
  l.enquiry_url;

-- Update the get_dog_resolved_snapshot function to use the new view
-- This function is used by the audit system to capture complete dog state
CREATE OR REPLACE FUNCTION dogadopt.get_dog_resolved_snapshot(p_dog_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(dc)::jsonb
  INTO v_snapshot
  FROM dogadopt.dogs_complete dc
  WHERE dc.id = p_dog_id;
  
  RETURN v_snapshot;
END;
$$;

-- Update grants
GRANT SELECT ON dogadopt.dogs_complete TO anon, authenticated;

-- Update comments
COMMENT ON VIEW dogadopt.dogs_complete IS 'Comprehensive dog view with all breeds and foreign keys fully resolved. Replaces dogs_with_breeds and dogs_resolved.';

