-- Remove the dog_breeds trigger that causes duplicate audit entries
-- The dogs table trigger already captures breed changes via the resolved snapshot

DROP TRIGGER IF EXISTS dog_breeds_complete_audit_trigger ON dogadopt.dog_breeds;

-- Drop the function as well since it's no longer needed
DROP FUNCTION IF EXISTS dogadopt.audit_dog_breeds_for_complete_log();

-- The comprehensive audit now only relies on the dogs table trigger
-- which captures complete resolved snapshots AFTER all changes (including breeds)
