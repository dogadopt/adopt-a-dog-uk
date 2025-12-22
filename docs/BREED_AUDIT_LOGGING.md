# Breed Audit Logging

## Overview

Since the `breed` column was removed from the `dogs` table and breeds are now managed through the `dog_breeds` junction table, we've implemented separate audit logging for breed changes.

## Audit Tables

### 1. `dogadopt.dog_audit_log`
Tracks changes to the main `dogs` table (name, age, size, status, etc.)
- **Does NOT include breed changes** (breed column removed)

### 2. `dogadopt.dog_breeds_audit_log` (NEW)
Tracks all breed associations and changes:
- When a breed is added to a dog (INSERT)
- When a breed is removed from a dog (DELETE)
- Captures: breed name, display order, timestamp, user who made change

## Querying Breed Changes

### View All Breed History
```sql
SELECT * FROM dogadopt.dog_breed_history
ORDER BY changed_at DESC;
```

Shows:
- Dog name
- Breed name
- Operation (INSERT/DELETE)
- When it changed
- Who changed it

### View Summarized Breed Changes
```sql
SELECT * FROM dogadopt.dog_breed_changes_summary
ORDER BY changed_at DESC;
```

Shows breed changes grouped together with:
- `+Labrador, -Beagle` format (additions/removals)
- Useful for seeing "breed updated from X to Y"

### Find When a Specific Dog's Breeds Changed
```sql
SELECT 
  breed_name,
  operation,
  changed_at,
  changed_by_email
FROM dogadopt.dog_breed_history
WHERE dog_name = 'Max'
ORDER BY changed_at DESC;
```

### See All Changes for a Dog (Including Breeds)
```sql
-- Main dog changes
SELECT 
  'dog' as change_type,
  changed_at,
  operation,
  changed_fields,
  changed_by
FROM dogadopt.dog_audit_log
WHERE dog_id = 'YOUR_DOG_ID'

UNION ALL

-- Breed changes
SELECT 
  'breed' as change_type,
  changed_at,
  operation,
  ARRAY[breed_name] as changed_fields,
  changed_by
FROM dogadopt.dog_breeds_audit_log
WHERE dog_id = 'YOUR_DOG_ID'

ORDER BY changed_at DESC;
```

## How It Works

### When You Edit a Dog in Admin Panel

1. **Main dog data** changes trigger `dogadopt.audit_dog_changes()`
   - Logged to `dog_audit_log`
   
2. **Breed changes** trigger `dogadopt.audit_dog_breed_changes()`
   - `set_dog_breeds()` function deletes old breeds
   - Trigger logs each DELETE to `dog_breeds_audit_log`
   - Function inserts new breeds
   - Trigger logs each INSERT to `dog_breeds_audit_log`

### Example Audit Trail

If you change a dog's breeds from `["Labrador"]` to `["Labrador", "Golden Retriever"]`:

**dog_breeds_audit_log:**
```
dog_id    | operation | breed_name          | changed_at
----------|-----------|---------------------|------------
abc-123   | INSERT    | Golden Retriever    | 2025-12-22 15:50:00
```

Only the addition is logged (Labrador wasn't removed, so no DELETE log).

If you change from `["Beagle"]` to `["Labrador"]`:

**dog_breeds_audit_log:**
```
dog_id    | operation | breed_name | changed_at
----------|-----------|------------|------------
abc-123   | DELETE    | Beagle     | 2025-12-22 15:50:00
abc-123   | INSERT    | Labrador   | 2025-12-22 15:50:00
```

## Benefits

✅ **Complete History** - Every breed addition/removal is tracked
✅ **Who & When** - Captures user and timestamp
✅ **Query Friendly** - Views make it easy to analyze
✅ **Compliance** - Meets audit requirements
✅ **No Performance Impact** - Triggers are efficient
✅ **Separate from Dog Changes** - Breed changes don't clutter main audit log

## Permissions

- **Admins** can view audit logs (RLS policy)
- **System** can insert logs (via triggers only)
- Regular users cannot access audit tables
