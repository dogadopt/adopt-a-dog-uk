-- Comprehensive audit logging system with resolved attributes
-- Provides event sourcing capability with complete, human-readable snapshots

-- Step 1: Create view of fully resolved dog data
CREATE OR REPLACE VIEW dogadopt.dogs_resolved AS
SELECT 
  d.id,
  d.name,
  d.age,
  d.size,
  d.gender,
  d.location,
  d.image,
  d.description,
  d.good_with_kids,
  d.good_with_dogs,
  d.good_with_cats,
  d.status,
  d.status_notes,
  d.profile_url,
  d.created_at,
  
  -- Resolved breeds
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) AS breeds,
  COALESCE(
    string_agg(b.name, ', ' ORDER BY db.display_order),
    ''
  ) AS breeds_display,
  
  -- Resolved rescue information
  r.name AS rescue_name,
  r.id AS rescue_id,
  r.region AS rescue_region,
  r.website AS rescue_website,
  
  -- Resolved location information
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
  d.id, r.name, r.id, r.region, r.website,
  l.name, l.id, l.region, l.enquiry_url;

GRANT SELECT ON dogadopt.dogs_resolved TO anon, authenticated;

-- Step 2: Create comprehensive audit log table
CREATE TABLE dogadopt.dog_audit_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Complete resolved snapshots
  old_snapshot JSONB,
  new_snapshot JSONB,
  
  -- Computed change summary
  changed_fields TEXT[],
  change_summary TEXT,
  
  -- Metadata
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_dog_audit_dog_id ON dogadopt.dog_audit_log(dog_id);
CREATE INDEX idx_dog_audit_changed_at ON dogadopt.dog_audit_log(changed_at);
CREATE INDEX idx_dog_audit_operation ON dogadopt.dog_audit_log(operation);
CREATE INDEX idx_dog_audit_changed_by ON dogadopt.dog_audit_log(changed_by);
CREATE INDEX idx_dog_audit_changed_fields ON dogadopt.dog_audit_log USING GIN(changed_fields);

-- Enable RLS
ALTER TABLE dogadopt.dog_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit logs"
ON dogadopt.dog_audit_log FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert audit logs"
ON dogadopt.dog_audit_log FOR INSERT
WITH CHECK (true);

-- Step 3: Function to get resolved snapshot
CREATE OR REPLACE FUNCTION dogadopt.get_dog_resolved_snapshot(p_dog_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(dr)::jsonb
  INTO v_snapshot
  FROM dogadopt.dogs_resolved dr
  WHERE dr.id = p_dog_id;
  
  RETURN v_snapshot;
END;
$$;

-- Step 4: Comprehensive audit trigger function
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
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.dog_audit_log (
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
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.dog_audit_log (
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
      
      INSERT INTO dogadopt.dog_audit_log (
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

-- Create trigger on dogs table
CREATE TRIGGER dogs_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_changes();

-- Step 5: Create helpful views
CREATE VIEW dogadopt.dog_change_history AS
SELECT 
  dal.id,
  dal.dog_id,
  dal.new_snapshot->>'name' AS dog_name,
  dal.operation,
  dal.change_summary,
  dal.changed_fields,
  dal.changed_at,
  u.email AS changed_by_email,
  dal.old_snapshot,
  dal.new_snapshot
FROM dogadopt.dog_audit_log dal
LEFT JOIN auth.users u ON u.id = dal.changed_by
ORDER BY dal.changed_at DESC;

CREATE VIEW dogadopt.dog_timeline AS
SELECT 
  dal.dog_id,
  COALESCE(dal.new_snapshot->>'name', dal.old_snapshot->>'name') AS dog_name,
  dal.changed_at AS event_time,
  dal.operation AS event_type,
  dal.change_summary AS event_description,
  u.email AS actor,
  dal.changed_fields AS affected_fields
FROM dogadopt.dog_audit_log dal
LEFT JOIN auth.users u ON u.id = dal.changed_by
ORDER BY dal.dog_id, dal.changed_at;

CREATE VIEW dogadopt.dog_status_history AS
SELECT 
  dal.dog_id,
  dal.new_snapshot->>'name' AS dog_name,
  dal.old_snapshot->>'status' AS old_status,
  dal.new_snapshot->>'status' AS new_status,
  dal.changed_at,
  u.email AS changed_by_email
FROM dogadopt.dog_audit_log dal
LEFT JOIN auth.users u ON u.id = dal.changed_by
WHERE dal.operation = 'UPDATE' 
  AND 'status' = ANY(dal.changed_fields)
ORDER BY dal.changed_at DESC;

-- Grant permissions
GRANT SELECT ON dogadopt.dog_change_history TO authenticated;
GRANT SELECT ON dogadopt.dog_timeline TO authenticated;
GRANT SELECT ON dogadopt.dog_status_history TO authenticated;

-- Add documentation
COMMENT ON TABLE dogadopt.dog_audit_log IS 
'Complete audit log with fully resolved dog snapshots. Enables event sourcing and time-travel queries.';

COMMENT ON VIEW dogadopt.dogs_resolved IS 
'Dogs with all foreign keys resolved to human-readable values.';

COMMENT ON VIEW dogadopt.dog_change_history IS 
'Human-readable history of all dog changes with complete before/after snapshots.';

COMMENT ON VIEW dogadopt.dog_timeline IS 
'Timeline view of dog events showing what changed, when, and by whom.';

COMMENT ON VIEW dogadopt.dog_status_history IS 
'History of adoption status changes for dogs.';
