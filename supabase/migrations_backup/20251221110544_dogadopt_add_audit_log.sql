-- Create audit logging system for dogs table
-- Tracks all changes (INSERT, UPDATE, DELETE) for historical analysis and compliance

-- Create audit log table
CREATE TABLE dogadopt.dog_audit_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  old_data JSONB,
  new_data JSONB,
  changed_fields TEXT[],
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes for efficient querying
CREATE INDEX idx_dog_audit_log_dog_id ON dogadopt.dog_audit_log(dog_id);
CREATE INDEX idx_dog_audit_log_changed_at ON dogadopt.dog_audit_log(changed_at);
CREATE INDEX idx_dog_audit_log_operation ON dogadopt.dog_audit_log(operation);
CREATE INDEX idx_dog_audit_log_changed_by ON dogadopt.dog_audit_log(changed_by);

-- Enable RLS on audit log
ALTER TABLE dogadopt.dog_audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies for audit log
-- Admins can view all audit logs
CREATE POLICY "Admins can view all audit logs"
ON dogadopt.dog_audit_log FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Only system can insert audit logs (via trigger)
CREATE POLICY "System can insert audit logs"
ON dogadopt.dog_audit_log FOR INSERT
WITH CHECK (true);

-- Create function to audit dog changes
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  changed_fields_array TEXT[];
  old_json JSONB;
  new_json JSONB;
BEGIN
  -- Handle INSERT
  IF (TG_OP = 'INSERT') THEN
    new_json := row_to_json(NEW)::jsonb;
    
    INSERT INTO dogadopt.dog_audit_log (
      dog_id,
      operation,
      changed_by,
      new_data,
      metadata
    ) VALUES (
      NEW.id,
      'INSERT',
      auth.uid(),
      new_json,
      jsonb_build_object('table', 'dogs', 'trigger_op', TG_OP)
    );
    
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF (TG_OP = 'UPDATE') THEN
    old_json := row_to_json(OLD)::jsonb;
    new_json := row_to_json(NEW)::jsonb;
    
    -- Identify changed fields
    SELECT ARRAY_AGG(key)
    INTO changed_fields_array
    FROM jsonb_each(old_json)
    WHERE old_json->>key IS DISTINCT FROM new_json->>key;
    
    -- Only log if something actually changed
    IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
      INSERT INTO dogadopt.dog_audit_log (
        dog_id,
        operation,
        changed_by,
        old_data,
        new_data,
        changed_fields,
        metadata
      ) VALUES (
        NEW.id,
        'UPDATE',
        auth.uid(),
        old_json,
        new_json,
        changed_fields_array,
        jsonb_build_object(
          'table', 'dogs',
          'trigger_op', TG_OP,
          'changed_count', array_length(changed_fields_array, 1)
        )
      );
    END IF;
    
    RETURN NEW;
  END IF;

  -- Handle DELETE
  IF (TG_OP = 'DELETE') THEN
    old_json := row_to_json(OLD)::jsonb;
    
    INSERT INTO dogadopt.dog_audit_log (
      dog_id,
      operation,
      changed_by,
      old_data,
      metadata
    ) VALUES (
      OLD.id,
      'DELETE',
      auth.uid(),
      old_json,
      jsonb_build_object('table', 'dogs', 'trigger_op', TG_OP)
    );
    
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- Create trigger on dogs table
CREATE TRIGGER dogs_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_changes();

-- Add comments for documentation
COMMENT ON TABLE dogadopt.dog_audit_log IS 'Audit trail for all changes to dogs table. Automatically populated by trigger. Enables historical analysis and compliance reporting.';
COMMENT ON COLUMN dogadopt.dog_audit_log.operation IS 'Type of operation: INSERT (new dog added), UPDATE (dog modified), DELETE (dog removed)';
COMMENT ON COLUMN dogadopt.dog_audit_log.old_data IS 'Complete snapshot of dog data before change (NULL for INSERT)';
COMMENT ON COLUMN dogadopt.dog_audit_log.new_data IS 'Complete snapshot of dog data after change (NULL for DELETE)';
COMMENT ON COLUMN dogadopt.dog_audit_log.changed_fields IS 'Array of field names that changed (UPDATE only)';
COMMENT ON COLUMN dogadopt.dog_audit_log.changed_by IS 'User who made the change (from auth.uid()), NULL if system/unknown';
COMMENT ON COLUMN dogadopt.dog_audit_log.metadata IS 'Additional context about the change (extensible JSON)';

-- Create helpful views for common queries
CREATE VIEW dogadopt.dog_status_history AS
SELECT 
  dal.dog_id,
  d.name as dog_name,
  dal.old_data->>'status' as old_status,
  dal.new_data->>'status' as new_status,
  dal.changed_at,
  dal.changed_by
FROM dogadopt.dog_audit_log dal
LEFT JOIN dogadopt.dogs d ON d.id = dal.dog_id
WHERE dal.operation = 'UPDATE' 
  AND 'status' = ANY(dal.changed_fields)
ORDER BY dal.changed_at DESC;

COMMENT ON VIEW dogadopt.dog_status_history IS 'Convenient view showing all status changes for dogs over time';
