-- Migrate from comma-delimited breed column to many-to-many relationship
-- This migration:
-- 1. Migrates existing breed data to dog_breeds table
-- 2. Makes breed column nullable (keeping it for backward compatibility initially)
-- 3. Adds a helper view for easy querying

-- Step 1: Ensure all breed names from dogs.breed exist in breeds table
INSERT INTO dogadopt.breeds (name)
SELECT DISTINCT TRIM(breed_name)
FROM dogadopt.dogs,
     LATERAL unnest(string_to_array(breed, ',')) AS breed_name
WHERE TRIM(breed_name) != ''
  AND NOT EXISTS (
    SELECT 1 FROM dogadopt.breeds b 
    WHERE LOWER(b.name) = LOWER(TRIM(breed_name))
  );

-- Step 2: Populate dog_breeds junction table from existing breed column
INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
SELECT 
  d.id AS dog_id,
  b.id AS breed_id,
  row_number() OVER (PARTITION BY d.id ORDER BY breed_pos) AS display_order
FROM dogadopt.dogs d
CROSS JOIN LATERAL (
  SELECT 
    TRIM(breed_name) AS breed_name,
    ordinality AS breed_pos
  FROM unnest(string_to_array(d.breed, ',')) WITH ORDINALITY AS breed_name
  WHERE TRIM(breed_name) != ''
) breeds_split
JOIN dogadopt.breeds b ON LOWER(b.name) = LOWER(breeds_split.breed_name)
ON CONFLICT (dog_id, breed_id) DO NOTHING;

-- Step 3: Create a view for easy querying of dogs with their breeds
CREATE OR REPLACE VIEW dogadopt.dogs_with_breeds AS
SELECT 
  d.*,
  COALESCE(
    string_agg(b.name, ', ' ORDER BY db.display_order),
    d.breed
  ) AS breeds_display,
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    string_to_array(d.breed, ',')
  ) AS breeds_array
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dog_breeds db ON d.id = db.dog_id
LEFT JOIN dogadopt.breeds b ON db.breed_id = b.id
GROUP BY d.id;

-- Grant permissions on the view
GRANT SELECT ON dogadopt.dogs_with_breeds TO anon, authenticated;

-- Step 4: Add helper function to manage dog breeds
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
  
  -- Update the legacy breed column for backward compatibility
  UPDATE dogadopt.dogs
  SET breed = array_to_string(p_breed_names, ', ')
  WHERE id = p_dog_id;
END;
$$;

COMMENT ON FUNCTION dogadopt.set_dog_breeds IS 
'Helper function to set breeds for a dog. Manages the many-to-many relationship and updates legacy breed column.';
