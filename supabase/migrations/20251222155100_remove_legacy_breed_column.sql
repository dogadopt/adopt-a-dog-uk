-- Remove the legacy breed column now that we have proper many-to-many
-- The breed data is now stored in the dog_breeds junction table

-- Drop views that depend on the breed column
DROP VIEW IF EXISTS dogadopt.dogs_with_tracked_urls CASCADE;
DROP VIEW IF EXISTS dogadopt.dogs_with_breeds CASCADE;

-- Update the helper function to not update the breed column
CREATE OR REPLACE FUNCTION dogadopt.set_dog_breeds(
  p_dog_id UUID,
  p_breed_names TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt
AS $$
DECLARE
  v_breed_name TEXT;
  v_breed_id UUID;
  v_order INT;
BEGIN
  -- Delete existing breed associations
  DELETE FROM dogadopt.dog_breeds WHERE dog_id = p_dog_id;
  
  -- Insert new breed associations
  v_order := 1;
  FOREACH v_breed_name IN ARRAY p_breed_names
  LOOP
    -- Get or create breed
    SELECT id INTO v_breed_id
    FROM dogadopt.breeds
    WHERE LOWER(name) = LOWER(TRIM(v_breed_name));
    
    IF v_breed_id IS NULL THEN
      INSERT INTO dogadopt.breeds (name)
      VALUES (TRIM(v_breed_name))
      RETURNING id INTO v_breed_id;
    END IF;
    
    -- Associate breed with dog
    INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
    VALUES (p_dog_id, v_breed_id, v_order);
    
    v_order := v_order + 1;
  END LOOP;
END;
$$;

-- Drop the legacy breed column
ALTER TABLE dogadopt.dogs DROP COLUMN breed;

-- Recreate the views without the breed column
CREATE OR REPLACE VIEW dogadopt.dogs_with_breeds AS
SELECT 
  d.*,
  string_agg(b.name, ', ' ORDER BY db.display_order) AS breed,
  array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL) AS breeds_array
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dog_breeds db ON d.id = db.dog_id
LEFT JOIN dogadopt.breeds b ON db.breed_id = b.id
GROUP BY d.id;

-- Grant permissions on the view
GRANT SELECT ON dogadopt.dogs_with_breeds TO anon, authenticated;
