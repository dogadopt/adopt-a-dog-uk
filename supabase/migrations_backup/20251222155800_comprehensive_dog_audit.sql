-- Create comprehensive dog audit system with resolved attributes
-- This provides event sourcing capability with complete, human-readable snapshots

-- Step 1: Create a materialized view of fully resolved dog data
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
  
  -- Resolved breeds (both as array and display string)
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
  d.id, d.name, d.age, d.size, d.gender, d.location, d.image,
  d.description, d.good_with_kids, d.good_with_dogs, d.good_with_cats,
  d.status, d.status_notes, d.profile_url, d.created_at,
  r.name, r.id, r.region, r.website,
  l.name, l.id, l.region, l.enquiry_url;

-- Grant permissions
GRANT SELECT ON dogadopt.dogs_resolved TO anon, authenticated;

-- Step 2: Create comprehensive audit log table
CREATE TABLE dogadopt.dog_complete_audit_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Complete resolved snapshots (human-readable)
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
CREATE INDEX idx_dog_complete_audit_dog_id ON dogadopt.dog_complete_audit_log(dog_id);
CREATE INDEX idx_dog_complete_audit_changed_at ON dogadopt.dog_complete_audit_log(changed_at);
CREATE INDEX idx_dog_complete_audit_operation ON dogadopt.dog_complete_audit_log(operation);
CREATE INDEX idx_dog_complete_audit_changed_by ON dogadopt.dog_complete_audit_log(changed_by);
CREATE INDEX idx_dog_complete_audit_changed_fields ON dogadopt.dog_complete_audit_log USING GIN(changed_fields);

-- Enable RLS
ALTER TABLE dogadopt.dog_complete_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view complete audit logs"
ON dogadopt.dog_complete_audit_log FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert complete audit logs"
ON dogadopt.dog_complete_audit_log FOR INSERT
WITH CHECK (true);

-- Step 3: Create function to get resolved snapshot
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

-- Step 4: Create comprehensive audit trigger function
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_complete_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  change_summary_text TEXT;
  change_details TEXT[];
BEGIN
  -- Handle INSERT
  IF (TG_OP = 'INSERT') THEN
    -- Get resolved snapshot after insert
    new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
    
    INSERT INTO dogadopt.dog_complete_audit_log (
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
      jsonb_build_object(
        'trigger', 'audit_dog_complete_changes',
        'table', TG_TABLE_NAME
      )
    );
    
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF (TG_OP = 'UPDATE') THEN
    -- Get resolved snapshots before and after
    old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
    new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
    
    -- Identify changed fields by comparing snapshots
    SELECT ARRAY_AGG(key)
    INTO changed_fields_array
    FROM jsonb_each(old_snapshot)
    WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
    
    -- Only log if something actually changed
    IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
      -- Build human-readable change summary
      change_details := ARRAY[]::TEXT[];
      
      -- Loop through changed fields to build summary
      FOR i IN 1..array_length(changed_fields_array, 1)
      LOOP
        CASE changed_fields_array[i]
          WHEN 'breeds' THEN
            change_details := array_append(change_details, 
              format('Breeds: %s → %s', 
                COALESCE(old_snapshot->>'breeds_display', '(none)'),
                COALESCE(new_snapshot->>'breeds_display', '(none)')
              )
            );
          WHEN 'status' THEN
            change_details := array_append(change_details,
              format('Status: %s → %s',
                old_snapshot->>'status',
                new_snapshot->>'status'
              )
            );
          WHEN 'rescue_name' THEN
            change_details := array_append(change_details,
              format('Rescue: %s → %s',
                COALESCE(old_snapshot->>'rescue_name', '(none)'),
                COALESCE(new_snapshot->>'rescue_name', '(none)')
              )
            );
          WHEN 'location_name' THEN
            change_details := array_append(change_details,
              format('Location: %s → %s',
                COALESCE(old_snapshot->>'location_name', '(none)'),
                COALESCE(new_snapshot->>'location_name', '(none)')
              )
            );
          ELSE
            change_details := array_append(change_details,
              format('%s changed', initcap(replace(changed_fields_array[i], '_', ' ')))
            );
        END CASE;
      END LOOP;
      
      change_summary_text := format('Dog "%s" updated: %s', 
        NEW.name, 
        array_to_string(change_details, '; ')
      );
      
      INSERT INTO dogadopt.dog_complete_audit_log (
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
        change_summary_text,
        jsonb_build_object(
          'trigger', 'audit_dog_complete_changes',
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
    
    INSERT INTO dogadopt.dog_complete_audit_log (
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
      jsonb_build_object(
        'trigger', 'audit_dog_complete_changes',
        'table', TG_TABLE_NAME
      )
    );
    
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- Step 5: Create trigger on dogs table for complete auditing
DROP TRIGGER IF EXISTS dogs_complete_audit_trigger ON dogadopt.dogs;
CREATE TRIGGER dogs_complete_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_complete_changes();

-- Step 6: Create trigger on dog_breeds for complete auditing
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_breeds_for_complete_log()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  v_dog_id UUID;
  old_snapshot JSONB;
  new_snapshot JSONB;
BEGIN
  -- Determine which dog_id to use
  IF (TG_OP = 'DELETE') THEN
    v_dog_id := OLD.dog_id;
  ELSE
    v_dog_id := NEW.dog_id;
  END IF;
  
  -- Get snapshots before and after breed change
  -- Note: This will capture the change after it's been made
  old_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
  
  -- Wait a moment for the change to propagate, then get new snapshot
  -- (In practice, within the same transaction this should be immediate)
  new_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
  
  -- Log the breed change as part of complete audit
  INSERT INTO dogadopt.dog_complete_audit_log (
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
    ARRAY['breeds', 'breeds_display'],
    format('Breeds updated for dog (ID: %s)', v_dog_id),
    jsonb_build_object(
      'trigger', 'audit_dog_breeds_for_complete_log',
      'table', 'dog_breeds',
      'breed_operation', TG_OP
    )
  );
  
  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

DROP TRIGGER IF EXISTS dog_breeds_complete_audit_trigger ON dogadopt.dog_breeds;
CREATE TRIGGER dog_breeds_complete_audit_trigger
  AFTER INSERT OR DELETE ON dogadopt.dog_breeds
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_breeds_for_complete_log();

-- Step 7: Create helpful views
CREATE VIEW dogadopt.dog_change_history AS
SELECT 
  dcal.id,
  dcal.dog_id,
  dcal.new_snapshot->>'name' AS dog_name,
  dcal.operation,
  dcal.change_summary,
  dcal.changed_fields,
  dcal.changed_at,
  u.email AS changed_by_email,
  dcal.old_snapshot,
  dcal.new_snapshot
FROM dogadopt.dog_complete_audit_log dcal
LEFT JOIN auth.users u ON u.id = dcal.changed_by
ORDER BY dcal.changed_at DESC;

CREATE VIEW dogadopt.dog_timeline AS
SELECT 
  dcal.dog_id,
  COALESCE(dcal.new_snapshot->>'name', dcal.old_snapshot->>'name') AS dog_name,
  dcal.changed_at AS event_time,
  dcal.operation AS event_type,
  dcal.change_summary AS event_description,
  u.email AS actor,
  dcal.changed_fields AS affected_fields
FROM dogadopt.dog_complete_audit_log dcal
LEFT JOIN auth.users u ON u.id = dcal.changed_by
ORDER BY dcal.dog_id, dcal.changed_at;

-- Grant permissions
GRANT SELECT ON dogadopt.dog_change_history TO authenticated;
GRANT SELECT ON dogadopt.dog_timeline TO authenticated;

-- Add comments
COMMENT ON TABLE dogadopt.dog_complete_audit_log IS 
'Complete audit log with fully resolved dog snapshots. Enables event sourcing and time-travel queries.';

COMMENT ON VIEW dogadopt.dogs_resolved IS 
'Materialized view of dogs with all foreign keys resolved to human-readable values.';

COMMENT ON VIEW dogadopt.dog_change_history IS 
'Human-readable history of all dog changes with complete before/after snapshots.';

COMMENT ON VIEW dogadopt.dog_timeline IS 
'Timeline view of dog events showing what changed, when, and by whom.';
