-- Add rescue_since_date field to dogs table
-- This is an optional date field that tracks when the dog was taken into the rescue

-- Add the rescue_since_date column to the dogs table
ALTER TABLE dogadopt.dogs 
  ADD COLUMN rescue_since_date DATE;

-- Add comment explaining the field
COMMENT ON COLUMN dogadopt.dogs.rescue_since_date IS 'Date the dog was taken into the rescue (optional)';

-- Drop and recreate the dogs_complete view to include rescue_since_date
DROP VIEW IF EXISTS dogadopt.dogs_complete CASCADE;
CREATE VIEW dogadopt.dogs_complete AS
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
  
  -- Rescue since date
  d.rescue_since_date,
  
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
  d.rescue_since_date,
  r.name, 
  r.id, 
  r.region, 
  r.website,
  l.name, 
  l.id, 
  l.region, 
  l.enquiry_url;

COMMENT ON VIEW dogadopt.dogs_complete IS 'Comprehensive dog view with all breeds, foreign keys, computed age category from birth date, and rescue since date';

-- Update audit trigger to include rescue_since_date in snapshot
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
      -- Convert OLD and NEW to JSONB with all fields including birth date and rescue_since_date
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
        'rescue_since_date', OLD.rescue_since_date,
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
        'rescue_since_date', NEW.rescue_since_date,
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

-- Drop and recreate the dogs_audit_logs_resolved view to include rescue_since_date tracking
DROP VIEW IF EXISTS dogadopt.dogs_audit_logs_resolved CASCADE;
CREATE VIEW dogadopt.dogs_audit_logs_resolved AS
SELECT 
  dal.id AS audit_id,
  dal.dog_id,
  dal.operation,
  dal.changed_at,
  dal.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Dog information from snapshot
  COALESCE(dal.new_snapshot->>'name', dal.old_snapshot->>'name') AS dog_name,
  COALESCE(dal.new_snapshot->>'age', dal.old_snapshot->>'age') AS dog_age,
  COALESCE(dal.new_snapshot->>'size', dal.old_snapshot->>'size') AS dog_size,
  COALESCE(dal.new_snapshot->>'gender', dal.old_snapshot->>'gender') AS dog_gender,
  
  -- Status tracking
  dal.old_snapshot->>'status' AS old_status,
  dal.new_snapshot->>'status' AS new_status,
  
  -- Breed tracking
  dal.old_snapshot->>'breeds_display' AS old_breeds,
  dal.new_snapshot->>'breeds_display' AS new_breeds,
  
  -- Rescue since date tracking
  dal.old_snapshot->>'rescue_since_date' AS old_rescue_since_date,
  dal.new_snapshot->>'rescue_since_date' AS new_rescue_since_date,
  
  -- Rescue and location
  COALESCE(dal.new_snapshot->>'rescue_name', dal.old_snapshot->>'rescue_name') AS rescue_name,
  COALESCE(dal.new_snapshot->>'location_name', dal.old_snapshot->>'location_name') AS location_name,
  
  -- Change details
  dal.changed_fields,
  dal.change_summary,
  
  -- Full snapshots for detailed analysis
  dal.old_snapshot,
  dal.new_snapshot,
  
  -- Metadata
  dal.metadata,
  dal.metadata->>'table' AS source_table,
  dal.metadata->>'sub_operation' AS sub_operation,
  
  dal.created_at
FROM dogadopt.dogs_audit_logs dal
LEFT JOIN auth.users u ON u.id = dal.changed_by
ORDER BY dal.changed_at DESC;

COMMENT ON VIEW dogadopt.dogs_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all dog and breed changes with human-readable fields. Includes complete before/after snapshots, rescue since date tracking, and metadata about the source of changes.';
