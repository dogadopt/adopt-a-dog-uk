-- Fix comprehensive audit trigger - add error handling and simpler logic

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
BEGIN
  BEGIN  -- Add exception handling
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
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
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
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
          format('Dog "%s" updated', NEW.name),
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

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_dog_complete_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS dogs_complete_audit_trigger ON dogadopt.dogs;
CREATE TRIGGER dogs_complete_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_complete_changes();
