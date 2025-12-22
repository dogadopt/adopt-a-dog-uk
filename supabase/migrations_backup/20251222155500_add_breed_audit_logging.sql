-- Add audit logging for breed changes in dog_breeds junction table
-- Since breed is no longer a column on dogs table, we need separate tracking

-- Create audit log table for breed changes
CREATE TABLE dogadopt.dog_breeds_audit_log (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL REFERENCES dogadopt.dogs(id) ON DELETE CASCADE,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'DELETE')),
  breed_id UUID REFERENCES dogadopt.breeds(id) ON DELETE SET NULL,
  breed_name TEXT NOT NULL,
  display_order INTEGER,
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes for efficient querying
CREATE INDEX idx_dog_breeds_audit_log_dog_id ON dogadopt.dog_breeds_audit_log(dog_id);
CREATE INDEX idx_dog_breeds_audit_log_changed_at ON dogadopt.dog_breeds_audit_log(changed_at);
CREATE INDEX idx_dog_breeds_audit_log_breed_id ON dogadopt.dog_breeds_audit_log(breed_id);

-- Enable RLS on breed audit log
ALTER TABLE dogadopt.dog_breeds_audit_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Admins can view breed audit logs"
ON dogadopt.dog_breeds_audit_log FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert breed audit logs"
ON dogadopt.dog_breeds_audit_log FOR INSERT
WITH CHECK (true);

-- Create function to audit dog breed changes
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_breed_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  v_breed_name TEXT;
BEGIN
  -- Get breed name for logging
  IF (TG_OP = 'INSERT') THEN
    SELECT name INTO v_breed_name
    FROM dogadopt.breeds
    WHERE id = NEW.breed_id;
    
    INSERT INTO dogadopt.dog_breeds_audit_log (
      dog_id,
      operation,
      breed_id,
      breed_name,
      display_order,
      changed_by,
      metadata
    ) VALUES (
      NEW.dog_id,
      'INSERT',
      NEW.breed_id,
      v_breed_name,
      NEW.display_order,
      auth.uid(),
      jsonb_build_object('table', 'dog_breeds', 'action', 'breed_added')
    );
    
    RETURN NEW;
  END IF;

  IF (TG_OP = 'DELETE') THEN
    SELECT name INTO v_breed_name
    FROM dogadopt.breeds
    WHERE id = OLD.breed_id;
    
    INSERT INTO dogadopt.dog_breeds_audit_log (
      dog_id,
      operation,
      breed_id,
      breed_name,
      display_order,
      changed_by,
      metadata
    ) VALUES (
      OLD.dog_id,
      'DELETE',
      OLD.breed_id,
      v_breed_name,
      OLD.display_order,
      auth.uid(),
      jsonb_build_object('table', 'dog_breeds', 'action', 'breed_removed')
    );
    
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- Create trigger on dog_breeds table
CREATE TRIGGER dog_breeds_audit_trigger
  AFTER INSERT OR DELETE ON dogadopt.dog_breeds
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_breed_changes();

-- Create helpful view for breed change history
CREATE VIEW dogadopt.dog_breed_history AS
SELECT 
  dbal.dog_id,
  d.name as dog_name,
  dbal.breed_name,
  dbal.operation,
  dbal.changed_at,
  u.email as changed_by_email,
  dbal.metadata
FROM dogadopt.dog_breeds_audit_log dbal
LEFT JOIN dogadopt.dogs d ON d.id = dbal.dog_id
LEFT JOIN auth.users u ON u.id = dbal.changed_by
ORDER BY dbal.changed_at DESC;

-- Grant permissions
GRANT SELECT ON dogadopt.dog_breed_history TO authenticated;

-- Create comprehensive breed change summary view
CREATE VIEW dogadopt.dog_breed_changes_summary AS
WITH breed_changes AS (
  SELECT 
    dog_id,
    changed_at,
    changed_by,
    string_agg(
      CASE 
        WHEN operation = 'INSERT' THEN '+' || breed_name
        WHEN operation = 'DELETE' THEN '-' || breed_name
      END,
      ', '
      ORDER BY changed_at
    ) as change_description
  FROM dogadopt.dog_breeds_audit_log
  GROUP BY dog_id, changed_at, changed_by
)
SELECT 
  bc.dog_id,
  d.name as dog_name,
  bc.change_description,
  bc.changed_at,
  u.email as changed_by_email
FROM breed_changes bc
LEFT JOIN dogadopt.dogs d ON d.id = bc.dog_id
LEFT JOIN auth.users u ON u.id = bc.changed_by
ORDER BY bc.changed_at DESC;

GRANT SELECT ON dogadopt.dog_breed_changes_summary TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE dogadopt.dog_breeds_audit_log IS 'Audit trail for breed associations. Tracks when breeds are added or removed from dogs.';
COMMENT ON VIEW dogadopt.dog_breed_history IS 'Historical view of all breed changes per dog';
COMMENT ON VIEW dogadopt.dog_breed_changes_summary IS 'Summarized view of breed changes showing additions (+) and removals (-) together';
