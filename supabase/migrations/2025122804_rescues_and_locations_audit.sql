-- Rescues and Locations Audit - Comprehensive audit logging for rescues and locations
-- Similar to dog audit system, captures complete snapshots of all changes

-- ========================================
-- RESCUES AUDIT SYSTEM
-- ========================================

-- Create rescues audit log table
CREATE TABLE dogadopt.rescues_audit_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  rescue_id UUID NOT NULL,
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

-- Create indexes for rescues_audit_logs
CREATE INDEX idx_rescues_audit_logs_rescue_id ON dogadopt.rescues_audit_logs(rescue_id);
CREATE INDEX idx_rescues_audit_logs_changed_at ON dogadopt.rescues_audit_logs(changed_at);
CREATE INDEX idx_rescues_audit_logs_operation ON dogadopt.rescues_audit_logs(operation);
CREATE INDEX idx_rescues_audit_logs_changed_by ON dogadopt.rescues_audit_logs(changed_by);
CREATE INDEX idx_rescues_audit_logs_changed_fields ON dogadopt.rescues_audit_logs USING GIN(changed_fields);

-- Enable RLS on rescues_audit_logs
ALTER TABLE dogadopt.rescues_audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rescues_audit_logs
CREATE POLICY "Admins can view rescue audit logs"
ON dogadopt.rescues_audit_logs FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert rescue audit logs"
ON dogadopt.rescues_audit_logs FOR INSERT
WITH CHECK (true);

-- Function to get complete resolved snapshot of a rescue
CREATE OR REPLACE FUNCTION dogadopt.get_rescue_resolved_snapshot(p_rescue_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(r)::jsonb
  INTO v_snapshot
  FROM dogadopt.rescues r
  WHERE r.id = p_rescue_id;
  
  RETURN v_snapshot;
END;
$$;

-- Audit trigger function for rescues table
-- Captures complete before/after snapshots with proper state handling
CREATE OR REPLACE FUNCTION dogadopt.audit_rescue_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_rescue_record JSONB;
  new_rescue_record JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_rescue_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.rescues_audit_logs (
        rescue_id,
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
        format('Rescue "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_rescue_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB
      old_rescue_record := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'type', OLD.type,
        'region', OLD.region,
        'website', OLD.website,
        'created_at', OLD.created_at
      );
      
      new_rescue_record := jsonb_build_object(
        'id', NEW.id,
        'name', NEW.name,
        'type', NEW.type,
        'region', NEW.region,
        'website', NEW.website,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots
      old_snapshot := dogadopt.get_rescue_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_rescue_resolved_snapshot(NEW.id);
      
      -- Merge the rescue-specific changes
      old_snapshot := old_snapshot || old_rescue_record;
      new_snapshot := new_snapshot || new_rescue_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.rescues_audit_logs (
          rescue_id,
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
          format('Rescue "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_rescue_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      -- Build snapshot from OLD record since the record is already deleted
      old_snapshot := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'type', OLD.type,
        'region', OLD.region,
        'website', OLD.website,
        'created_at', OLD.created_at
      );
      
      INSERT INTO dogadopt.rescues_audit_logs (
        rescue_id,
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
        format('Rescue "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_rescue_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_rescue_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Create trigger for rescues
CREATE TRIGGER rescues_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.rescues
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_rescue_changes();

-- Create comprehensive resolved audit log view for rescues
CREATE OR REPLACE VIEW dogadopt.rescues_audit_logs_resolved AS
SELECT 
  ral.id AS audit_id,
  ral.rescue_id,
  ral.operation,
  ral.changed_at,
  ral.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Rescue information from snapshot
  COALESCE(ral.new_snapshot->>'name', ral.old_snapshot->>'name') AS rescue_name,
  COALESCE(ral.new_snapshot->>'type', ral.old_snapshot->>'type') AS rescue_type,
  COALESCE(ral.new_snapshot->>'region', ral.old_snapshot->>'region') AS rescue_region,
  
  -- Field tracking
  ral.old_snapshot->>'name' AS old_name,
  ral.new_snapshot->>'name' AS new_name,
  ral.old_snapshot->>'type' AS old_type,
  ral.new_snapshot->>'type' AS new_type,
  ral.old_snapshot->>'region' AS old_region,
  ral.new_snapshot->>'region' AS new_region,
  ral.old_snapshot->>'website' AS old_website,
  ral.new_snapshot->>'website' AS new_website,
  
  -- Change details
  ral.changed_fields,
  ral.change_summary,
  
  -- Full snapshots for detailed analysis
  ral.old_snapshot,
  ral.new_snapshot,
  
  -- Metadata
  ral.metadata,
  ral.metadata->>'table' AS source_table,
  
  ral.created_at
FROM dogadopt.rescues_audit_logs ral
LEFT JOIN auth.users u ON u.id = ral.changed_by
ORDER BY ral.changed_at DESC;

-- ========================================
-- LOCATIONS AUDIT SYSTEM
-- ========================================

-- Create locations audit log table
CREATE TABLE dogadopt.locations_audit_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  location_id UUID NOT NULL,
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

-- Create indexes for locations_audit_logs
CREATE INDEX idx_locations_audit_logs_location_id ON dogadopt.locations_audit_logs(location_id);
CREATE INDEX idx_locations_audit_logs_changed_at ON dogadopt.locations_audit_logs(changed_at);
CREATE INDEX idx_locations_audit_logs_operation ON dogadopt.locations_audit_logs(operation);
CREATE INDEX idx_locations_audit_logs_changed_by ON dogadopt.locations_audit_logs(changed_by);
CREATE INDEX idx_locations_audit_logs_changed_fields ON dogadopt.locations_audit_logs USING GIN(changed_fields);

-- Enable RLS on locations_audit_logs
ALTER TABLE dogadopt.locations_audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations_audit_logs
CREATE POLICY "Admins can view location audit logs"
ON dogadopt.locations_audit_logs FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert location audit logs"
ON dogadopt.locations_audit_logs FOR INSERT
WITH CHECK (true);

-- Create view with rescue information joined
CREATE OR REPLACE VIEW dogadopt.locations_complete AS
SELECT 
  l.id,
  l.rescue_id,
  l.name,
  l.location_type,
  l.address_line1,
  l.address_line2,
  l.city,
  l.county,
  l.postcode,
  l.region,
  l.latitude,
  l.longitude,
  l.phone,
  l.email,
  l.is_public,
  l.enquiry_url,
  l.created_at,
  
  -- Rescue information
  r.name AS rescue_name,
  r.type AS rescue_type,
  r.region AS rescue_region,
  r.website AS rescue_website
  
FROM dogadopt.locations l
LEFT JOIN dogadopt.rescues r ON l.rescue_id = r.id;

-- Function to get complete resolved snapshot of a location
CREATE OR REPLACE FUNCTION dogadopt.get_location_resolved_snapshot(p_location_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(lc)::jsonb
  INTO v_snapshot
  FROM dogadopt.locations_complete lc
  WHERE lc.id = p_location_id;
  
  RETURN v_snapshot;
END;
$$;

-- Audit trigger function for locations table
-- Captures complete before/after snapshots with proper state handling
CREATE OR REPLACE FUNCTION dogadopt.audit_location_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_location_record JSONB;
  new_location_record JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_location_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.locations_audit_logs (
        location_id,
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
        format('Location "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_location_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB
      old_location_record := jsonb_build_object(
        'id', OLD.id,
        'rescue_id', OLD.rescue_id,
        'name', OLD.name,
        'location_type', OLD.location_type,
        'address_line1', OLD.address_line1,
        'address_line2', OLD.address_line2,
        'city', OLD.city,
        'county', OLD.county,
        'postcode', OLD.postcode,
        'region', OLD.region,
        'latitude', OLD.latitude,
        'longitude', OLD.longitude,
        'phone', OLD.phone,
        'email', OLD.email,
        'is_public', OLD.is_public,
        'enquiry_url', OLD.enquiry_url,
        'created_at', OLD.created_at
      );
      
      new_location_record := jsonb_build_object(
        'id', NEW.id,
        'rescue_id', NEW.rescue_id,
        'name', NEW.name,
        'location_type', NEW.location_type,
        'address_line1', NEW.address_line1,
        'address_line2', NEW.address_line2,
        'city', NEW.city,
        'county', NEW.county,
        'postcode', NEW.postcode,
        'region', NEW.region,
        'latitude', NEW.latitude,
        'longitude', NEW.longitude,
        'phone', NEW.phone,
        'email', NEW.email,
        'is_public', NEW.is_public,
        'enquiry_url', NEW.enquiry_url,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots (with rescue info)
      old_snapshot := dogadopt.get_location_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_location_resolved_snapshot(NEW.id);
      
      -- Merge the location-specific changes with the resolved data
      old_snapshot := old_snapshot || old_location_record;
      new_snapshot := new_snapshot || new_location_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.locations_audit_logs (
          location_id,
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
          format('Location "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_location_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      -- Build snapshot from OLD record since the record is already deleted
      -- Note: Cannot get rescue info via join since location is already deleted
      old_snapshot := jsonb_build_object(
        'id', OLD.id,
        'rescue_id', OLD.rescue_id,
        'name', OLD.name,
        'location_type', OLD.location_type,
        'address_line1', OLD.address_line1,
        'address_line2', OLD.address_line2,
        'city', OLD.city,
        'county', OLD.county,
        'postcode', OLD.postcode,
        'region', OLD.region,
        'latitude', OLD.latitude,
        'longitude', OLD.longitude,
        'phone', OLD.phone,
        'email', OLD.email,
        'is_public', OLD.is_public,
        'enquiry_url', OLD.enquiry_url,
        'created_at', OLD.created_at
      );
      
      INSERT INTO dogadopt.locations_audit_logs (
        location_id,
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
        format('Location "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_location_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_location_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Create trigger for locations
CREATE TRIGGER locations_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.locations
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_location_changes();

-- Create comprehensive resolved audit log view for locations
CREATE OR REPLACE VIEW dogadopt.locations_audit_logs_resolved AS
SELECT 
  lal.id AS audit_id,
  lal.location_id,
  lal.operation,
  lal.changed_at,
  lal.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Location information from snapshot
  COALESCE(lal.new_snapshot->>'name', lal.old_snapshot->>'name') AS location_name,
  COALESCE(lal.new_snapshot->>'location_type', lal.old_snapshot->>'location_type') AS location_type,
  COALESCE(lal.new_snapshot->>'city', lal.old_snapshot->>'city') AS city,
  COALESCE(lal.new_snapshot->>'region', lal.old_snapshot->>'region') AS region,
  
  -- Rescue information
  COALESCE(lal.new_snapshot->>'rescue_name', lal.old_snapshot->>'rescue_name') AS rescue_name,
  
  -- Field tracking for key changes
  lal.old_snapshot->>'name' AS old_name,
  lal.new_snapshot->>'name' AS new_name,
  lal.old_snapshot->>'location_type' AS old_location_type,
  lal.new_snapshot->>'location_type' AS new_location_type,
  lal.old_snapshot->>'city' AS old_city,
  lal.new_snapshot->>'city' AS new_city,
  lal.old_snapshot->>'region' AS old_region,
  lal.new_snapshot->>'region' AS new_region,
  lal.old_snapshot->>'is_public' AS old_is_public,
  lal.new_snapshot->>'is_public' AS new_is_public,
  
  -- Change details
  lal.changed_fields,
  lal.change_summary,
  
  -- Full snapshots for detailed analysis
  lal.old_snapshot,
  lal.new_snapshot,
  
  -- Metadata
  lal.metadata,
  lal.metadata->>'table' AS source_table,
  
  lal.created_at
FROM dogadopt.locations_audit_logs lal
LEFT JOIN auth.users u ON u.id = lal.changed_by
ORDER BY lal.changed_at DESC;

-- Grant permissions for rescues audit
GRANT SELECT ON dogadopt.rescues_audit_logs_resolved TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_rescue_resolved_snapshot TO authenticated;

-- Grant permissions for locations audit
GRANT SELECT ON dogadopt.locations_complete TO anon, authenticated;
GRANT SELECT ON dogadopt.locations_audit_logs_resolved TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_location_resolved_snapshot TO authenticated;

-- Add documentation
COMMENT ON TABLE dogadopt.rescues_audit_logs IS 'Complete audit log with fully resolved rescue snapshots. Enables event sourcing and time-travel queries. View rescues_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.rescues_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all rescue changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
COMMENT ON FUNCTION dogadopt.audit_rescue_changes IS 'Audit trigger for rescues table. Captures complete snapshots including OLD/NEW record state for proper before/after tracking.';

COMMENT ON TABLE dogadopt.locations_audit_logs IS 'Complete audit log with fully resolved location snapshots including rescue information. Enables event sourcing and time-travel queries. View locations_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.locations_complete IS 'Comprehensive location view with rescue information fully resolved. Single source for all location data with relationships.';
COMMENT ON VIEW dogadopt.locations_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all location changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
COMMENT ON FUNCTION dogadopt.audit_location_changes IS 'Audit trigger for locations table. Captures complete snapshots including OLD/NEW record state for proper before/after tracking.';
