-- Add flexible birth date fields to dogs table
-- Allows storing birth date with varying levels of precision (year only, year+month, or full date)

-- Add birth date columns
ALTER TABLE dogadopt.dogs 
  ADD COLUMN birth_year INTEGER,
  ADD COLUMN birth_month INTEGER,
  ADD COLUMN birth_day INTEGER;

-- Add constraints for valid date ranges
ALTER TABLE dogadopt.dogs
  ADD CONSTRAINT check_birth_year_range 
    -- Allow current year + 1 to handle dogs born in December when data is entered in January
    CHECK (birth_year IS NULL OR (birth_year >= 1900 AND birth_year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1)),
  ADD CONSTRAINT check_birth_month_range 
    CHECK (birth_month IS NULL OR (birth_month >= 1 AND birth_month <= 12)),
  ADD CONSTRAINT check_birth_day_range 
    CHECK (birth_day IS NULL OR (birth_day >= 1 AND birth_day <= 31)),
  ADD CONSTRAINT check_birth_month_requires_year
    CHECK (birth_month IS NULL OR birth_year IS NOT NULL),
  ADD CONSTRAINT check_birth_day_requires_month
    CHECK (birth_day IS NULL OR (birth_month IS NOT NULL AND birth_year IS NOT NULL));

-- Add comment explaining the birth date fields
COMMENT ON COLUMN dogadopt.dogs.birth_year IS 'Birth year (required if any birth date information is provided)';
COMMENT ON COLUMN dogadopt.dogs.birth_month IS 'Birth month (1-12, requires birth_year)';
COMMENT ON COLUMN dogadopt.dogs.birth_day IS 'Birth day (1-31, requires birth_year and birth_month)';

-- Function to calculate age category from birth date
-- Returns: 'Puppy' (≤6 months), 'Young' (6mo-2yr), 'Adult' (2-8yr), 'Senior' (8+yr)
CREATE OR REPLACE FUNCTION dogadopt.calculate_age_category(
  p_birth_year INTEGER,
  p_birth_month INTEGER DEFAULT NULL,
  p_birth_day INTEGER DEFAULT NULL
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_birth_date DATE;
  v_age_interval INTERVAL;
  v_age_years NUMERIC;
  v_age_months NUMERIC;
BEGIN
  -- If no birth year provided, return NULL
  IF p_birth_year IS NULL THEN
    RETURN NULL;
  END IF;
  
  -- Construct birth date with available precision
  -- Use middle of year/month if not specified for more accurate age calculation
  IF p_birth_month IS NULL THEN
    -- Year only - use July 1st as midpoint
    v_birth_date := make_date(p_birth_year, 7, 1);
  ELSIF p_birth_day IS NULL THEN
    -- Year and month - use 15th as midpoint
    v_birth_date := make_date(p_birth_year, p_birth_month, 15);
  ELSE
    -- Full date available
    BEGIN
      v_birth_date := make_date(p_birth_year, p_birth_month, p_birth_day);
    EXCEPTION WHEN OTHERS THEN
      -- Invalid date (e.g., Feb 31), return NULL
      RETURN NULL;
    END;
  END IF;
  
  -- Calculate age once and extract components
  v_age_interval := age(CURRENT_DATE, v_birth_date);
  v_age_years := EXTRACT(YEAR FROM v_age_interval);
  v_age_months := v_age_years * 12 + EXTRACT(MONTH FROM v_age_interval);
  
  -- Categorize based on age
  IF v_age_months <= 6 THEN
    RETURN 'Puppy';
  ELSIF v_age_months <= 24 THEN  -- 2 years
    RETURN 'Young';
  ELSIF v_age_years <= 8 THEN
    RETURN 'Adult';
  ELSE
    RETURN 'Senior';
  END IF;
END;
$$;

COMMENT ON FUNCTION dogadopt.calculate_age_category IS 'Calculate age category from birth date. Returns Puppy (≤6mo), Young (6mo-2yr), Adult (2-8yr), or Senior (8+yr)';

-- Function to get the effective age category (computed from birth date or stored value)
CREATE OR REPLACE FUNCTION dogadopt.get_effective_age_category(
  p_dog_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_dog RECORD;
  v_computed_age TEXT;
BEGIN
  SELECT birth_year, birth_month, birth_day, age
  INTO v_dog
  FROM dogadopt.dogs
  WHERE id = p_dog_id;
  
  -- If birth date is available, compute age category
  IF v_dog.birth_year IS NOT NULL THEN
    v_computed_age := dogadopt.calculate_age_category(
      v_dog.birth_year,
      v_dog.birth_month,
      v_dog.birth_day
    );
    
    IF v_computed_age IS NOT NULL THEN
      RETURN v_computed_age;
    END IF;
  END IF;
  
  -- Fall back to manually entered age
  RETURN v_dog.age;
END;
$$;

COMMENT ON FUNCTION dogadopt.get_effective_age_category IS 'Get effective age category - computed from birth date if available, otherwise use stored age value';

-- Update the dogs_complete view to include birth date fields and computed age
DROP VIEW IF EXISTS dogadopt.dogs_complete;

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
  
  -- Birth date fields
  d.birth_year,
  d.birth_month,
  d.birth_day,
  
  -- Computed age category (from birth date if available, otherwise stored age)
  COALESCE(
    dogadopt.calculate_age_category(d.birth_year, d.birth_month, d.birth_day),
    d.age
  ) AS computed_age,
  
  -- Breed information (multiple formats for convenience)
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
  
  -- Rescue information
  r.name AS rescue_name,
  r.id AS rescue_id,
  r.region AS rescue_region,
  r.website AS rescue_website,
  
  -- Location information
  l.name AS location_name,
  l.id AS location_id,
  l.region AS location_region,
  l.enquiry_url AS location_enquiry_url
  
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dogs_breeds db ON d.id = db.dog_id
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
  d.birth_year,
  d.birth_month,
  d.birth_day,
  r.name, 
  r.id, 
  r.region, 
  r.website,
  l.name, 
  l.id, 
  l.region, 
  l.enquiry_url;

COMMENT ON VIEW dogadopt.dogs_complete IS 'Comprehensive dog view with all breeds, foreign keys, and computed age category from birth date';

-- Update get_dog_resolved_snapshot to include birth date fields
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

-- Update audit trigger to include birth date fields in snapshot
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_dog_record JSONB;
  new_dog_record JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        new_snapshot,
        change_summary,
        metadata
      ) VALUES (
        NEW.id,
        'INSERT',
        auth.uid(),
        new_snapshot,
        format('Dog "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_dog_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB with all fields including birth date
      old_dog_record := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'age', OLD.age,
        'size', OLD.size,
        'gender', OLD.gender,
        'image', OLD.image,
        'description', OLD.description,
        'good_with_kids', OLD.good_with_kids,
        'good_with_dogs', OLD.good_with_dogs,
        'good_with_cats', OLD.good_with_cats,
        'status', OLD.status,
        'status_notes', OLD.status_notes,
        'profile_url', OLD.profile_url,
        'rescue_id', OLD.rescue_id,
        'location_id', OLD.location_id,
        'birth_year', OLD.birth_year,
        'birth_month', OLD.birth_month,
        'birth_day', OLD.birth_day,
        'created_at', OLD.created_at
      );
      
      new_dog_record := jsonb_build_object(
        'id', NEW.id,
        'name', NEW.name,
        'age', NEW.age,
        'size', NEW.size,
        'gender', NEW.gender,
        'image', NEW.image,
        'description', NEW.description,
        'good_with_kids', NEW.good_with_kids,
        'good_with_dogs', NEW.good_with_dogs,
        'good_with_cats', NEW.good_with_cats,
        'status', NEW.status,
        'status_notes', NEW.status_notes,
        'profile_url', NEW.profile_url,
        'rescue_id', NEW.rescue_id,
        'location_id', NEW.location_id,
        'birth_year', NEW.birth_year,
        'birth_month', NEW.birth_month,
        'birth_day', NEW.birth_day,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots (with breeds, rescue, location)
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      -- Merge the dog-specific changes with the resolved data
      -- Use the old_dog_record for fields that changed in the dogs table
      old_snapshot := old_snapshot || old_dog_record;
      new_snapshot := new_snapshot || new_dog_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.dogs_audit_logs (
          dog_id,
          operation,
          changed_by,
          old_snapshot,
          new_snapshot,
          changed_fields,
          change_summary,
          metadata
        ) VALUES (
          NEW.id,
          'UPDATE',
          auth.uid(),
          old_snapshot,
          new_snapshot,
          changed_fields_array,
          format('Dog "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_dog_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        old_snapshot,
        change_summary,
        metadata
      ) VALUES (
        OLD.id,
        'DELETE',
        auth.uid(),
        old_snapshot,
        format('Dog "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_dog_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_dog_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION dogadopt.calculate_age_category TO anon, authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_effective_age_category TO anon, authenticated;
