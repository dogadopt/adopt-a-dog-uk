-- Rename tables for consistent plural naming pattern
-- This ensures related tables visually align: dogs ↔ dogs_breeds ↔ dogs_audit_logs

-- Drop dependent objects first
DROP TRIGGER IF EXISTS dog_breeds_audit_trigger ON dogadopt.dog_breeds;
DROP VIEW IF EXISTS dogadopt.dog_audit_log_resolved CASCADE;
DROP VIEW IF EXISTS dogadopt.dogs_complete CASCADE;
DROP VIEW IF EXISTS dogadopt.dogs_with_breeds CASCADE;
DROP VIEW IF EXISTS dogadopt.dogs_resolved CASCADE;

-- Rename junction table
ALTER TABLE dogadopt.dog_breeds RENAME TO dogs_breeds;

-- Rename audit table
ALTER TABLE dogadopt.dog_audit_log RENAME TO dogs_audit_logs;

-- Update indexes
ALTER INDEX IF EXISTS dogadopt.idx_dog_breeds_dog_id RENAME TO idx_dogs_breeds_dog_id;
ALTER INDEX IF EXISTS dogadopt.idx_dog_breeds_breed_id RENAME TO idx_dogs_breeds_breed_id;
ALTER INDEX IF EXISTS dogadopt.idx_dog_audit_dog_id RENAME TO idx_dogs_audit_logs_dog_id;
ALTER INDEX IF EXISTS dogadopt.idx_dog_audit_changed_at RENAME TO idx_dogs_audit_logs_changed_at;
ALTER INDEX IF EXISTS dogadopt.idx_dog_audit_operation RENAME TO idx_dogs_audit_logs_operation;
ALTER INDEX IF EXISTS dogadopt.idx_dog_audit_changed_by RENAME TO idx_dogs_audit_logs_changed_by;
ALTER INDEX IF EXISTS dogadopt.idx_dog_audit_changed_fields RENAME TO idx_dogs_audit_logs_changed_fields;

-- Recreate dogs_complete view (single comprehensive view)
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
  r.name, 
  r.id, 
  r.region, 
  r.website,
  l.name, 
  l.id, 
  l.region, 
  l.enquiry_url;

-- Recreate the resolved audit view with new name
CREATE OR REPLACE VIEW dogadopt.dogs_audit_logs_resolved AS
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

-- Recreate the audit trigger function for dogs_breeds
DROP TRIGGER IF EXISTS dogs_breeds_audit_trigger ON dogadopt.dogs_breeds;

-- Update the audit_dog_changes function to use new table name
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
        format('Dog \"%s\" created', NEW.name),
        jsonb_build_object('trigger', 'audit_dog_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB with basic fields only
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
          format('Dog \"%s\" updated (%s fields changed)', 
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
        format('Dog \"%s\" deleted', OLD.name),
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

-- Update the audit_dog_breed_changes function to use new table name
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_breed_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  v_dog_id UUID;
  v_dog_name TEXT;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    
    -- Determine which dog_id to use
    IF (TG_OP = 'DELETE') THEN
      v_dog_id := OLD.dog_id;
    ELSE
      v_dog_id := NEW.dog_id;
    END IF;
    
    -- Get dog name for summary
    SELECT name INTO v_dog_name FROM dogadopt.dogs WHERE id = v_dog_id;
    
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
      
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
        v_dog_id,
        'UPDATE',
        auth.uid(),
        old_snapshot,
        new_snapshot,
        ARRAY['breeds', 'breeds_array', 'breeds_display'],
        format('Breed added to dog \"%s\"', v_dog_name),
        jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_added')
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE (display_order changes)
    IF (TG_OP = 'UPDATE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.dog_id);
      
      -- Only log if breeds actually changed
      IF old_snapshot->>'breeds_display' IS DISTINCT FROM new_snapshot->>'breeds_display' THEN
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
          NEW.dog_id,
          'UPDATE',
          auth.uid(),
          old_snapshot,
          new_snapshot,
          ARRAY['breeds', 'breeds_array', 'breeds_display'],
          format('Breed order updated for dog \"%s\"', v_dog_name),
          jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_reordered')
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      
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
        OLD.dog_id,
        'UPDATE',
        auth.uid(),
        old_snapshot,
        new_snapshot,
        ARRAY['breeds', 'breeds_array', 'breeds_display'],
        format('Breed removed from dog \"%s\"', v_dog_name),
        jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_removed')
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_dog_breed_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Recreate triggers
DROP TRIGGER IF EXISTS dogs_audit_trigger ON dogadopt.dogs;
DROP TRIGGER IF EXISTS dogs_breeds_audit_trigger ON dogadopt.dogs_breeds;

CREATE TRIGGER dogs_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_changes();

CREATE TRIGGER dogs_breeds_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs_breeds
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_breed_changes();

-- Update grants
GRANT SELECT ON dogadopt.dogs_breeds TO anon, authenticated;
GRANT ALL ON dogadopt.dogs_breeds TO authenticated;
GRANT SELECT ON dogadopt.dogs_complete TO anon, authenticated;
GRANT SELECT ON dogadopt.dogs_audit_logs_resolved TO authenticated;

-- Update comments
COMMENT ON TABLE dogadopt.dogs_breeds IS 'Junction table linking dogs to breeds (many-to-many relationship). Supports multi-breed dogs with display ordering.';
COMMENT ON TABLE dogadopt.dogs_audit_logs IS 'Complete audit log with fully resolved dog snapshots. Enables event sourcing and time-travel queries. View dogs_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.dogs_complete IS 'Comprehensive dog view with all breeds and foreign keys fully resolved. Single source for all dog data with relationships.';
COMMENT ON VIEW dogadopt.dogs_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all dog and breed changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
