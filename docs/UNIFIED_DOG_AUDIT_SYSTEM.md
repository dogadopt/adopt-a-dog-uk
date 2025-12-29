# Unified Dog Audit System

## Overview

The unified dog audit system provides comprehensive audit logging for all changes to dog records and their associated breeds. The system captures complete before/after snapshots of all changes, enabling event sourcing, time-travel queries, and detailed change tracking.

## Architecture

### Core Components

1. **Single Audit Log Table**: `dogadopt.dogs_audit_logs`
   - Captures all changes from both `dogs` and `dogs_breeds` tables
   - Stores complete resolved snapshots including foreign key relationships
   - Supports INSERT, UPDATE, and DELETE operations

2. **Unified Data View**: `dogadopt.dogs_complete`
   - Single comprehensive view for all dog data
   - Provides complete dog data with breeds and relationships resolved
   - Used by audit system to capture complete state

3. **Resolved Audit View**: `dogadopt.dogs_audit_logs_resolved`
   - Single comprehensive view for all audit queries
   - Human-readable audit log with all foreign keys resolved
   - Shows before/after states for all fields
   - Includes metadata about change source and type
   - Replaces multiple specialized views with one unified interface

### Audit Triggers

1. **`dogs_audit_trigger`**: Captures changes from the `dogs` table
   - Fires AFTER INSERT, UPDATE, DELETE
   - Uses OLD and NEW record state for accurate before/after tracking
   - Enriches with resolved data from `dogs_complete` view

2. **`dog_breeds_audit_trigger`**: Captures changes from the `dog_breeds` table
   - Fires AFTER INSERT, UPDATE, DELETE
   - Tracks breed additions, removals, and reordering
   - Links changes back to the parent dog record

## Database Schema

### dogs_audit_logs Table

```sql
CREATE TABLE dogadopt.dogs_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dog_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id),
  
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
```

### Available Views

**`dogs_audit_logs_resolved`**: Single comprehensive audit log view with all fields resolved

Fields include:
- **Audit Info**: audit_id, dog_id, operation, changed_at, changed_by, changed_by_email, changed_by_name
- **Dog Info**: dog_name, dog_age, dog_size, dog_gender
- **Status Tracking**: old_status, new_status
- **Breed Tracking**: old_breeds, new_breeds
- **Location Info**: rescue_name, location_name
- **Change Details**: changed_fields (array), change_summary
- **Complete Snapshots**: old_snapshot (JSONB), new_snapshot (JSONB)
- **Metadata**: metadata (JSONB), source_table, sub_operation, created_at

This single view replaces multiple specialized views and provides all necessary audit information for:
- Status change tracking
- Breed modification history
- Complete change timelines
- Detailed field-level changes

## Usage Examples

### Query All Changes for a Dog

```sql
SELECT *
FROM dogadopt.dogs_audit_logs_resolved
WHERE dog_name = 'Bella'
ORDER BY changed_at;
```

### Find All Status Changes

```sql
SELECT dog_name, old_status, new_status, changed_at
FROM dogadopt.dogs_audit_logs_resolved
WHERE old_status IS DISTINCT FROM new_status
ORDER BY changed_at DESC;
```

### Track Breed Modifications

```sql
SELECT dog_name, old_breeds, new_breeds, sub_operation, changed_at
FROM dogadopt.dogs_audit_logs_resolved
WHERE old_breeds IS DISTINCT FROM new_breeds
ORDER BY changed_at;
```

### View Complete Timeline for a Dog

```sql
SELECT changed_at, operation, change_summary, changed_fields, sub_operation
FROM dogadopt.dogs_audit_logs_resolved
WHERE dog_name = 'Luna'
ORDER BY changed_at;
```

### Filter by Source Table

```sql
-- Show only changes originating from the dogs table
SELECT dog_name, operation, change_summary, changed_at
FROM dogadopt.dogs_audit_logs_resolved
WHERE source_table = 'dogs'
ORDER BY changed_at DESC;

-- Show only breed-related changes
SELECT dog_name, old_breeds, new_breeds, sub_operation
FROM dogadopt.dogs_audit_logs_resolved
WHERE source_table = 'dogs_breeds'
ORDER BY changed_at DESC;
```

### Reconstruct Dog State at a Point in Time

```sql
-- Get the most recent snapshot before a specific date
SELECT old_snapshot
FROM dogadopt.dog_audit_log
WHERE dog_id = 'some-uuid'
  AND changed_at <= '2025-01-01'
ORDER BY changed_at DESC
LIMIT 1;
```

## Change Types Captured

### From `dogs` Table
- Dog creation (INSERT)
- Property changes (UPDATE): name, age, size, gender, status, description, image, etc.
- Dog deletion (DELETE)
- Status changes with notes
- Profile URL updates

### From `dog_breeds` Table
- Breed addition (INSERT) - captured as UPDATE with sub_operation 'breed_added'
- Breed reordering (UPDATE) - captured as UPDATE with sub_operation 'breed_reordered'
- Breed removal (DELETE) - captured as UPDATE with sub_operation 'breed_removed'

## Snapshot Structure

Each audit entry includes complete snapshots with:

```json
{
  "id": "uuid",
  "name": "Dog Name",
  "age": "Adult",
  "size": "Medium",
  "gender": "Female",
  "status": "available",
  "status_notes": null,
  "breeds": ["Breed 1", "Breed 2"],
  "breeds_display": "Breed 1, Breed 2",
  "breeds_array": ["Breed 1", "Breed 2"],
  "rescue_name": "Rescue Name",
  "rescue_id": "uuid",
  "rescue_region": "Region",
  "location_name": "Location Name",
  "location_id": "uuid",
  "location_region": "Region",
  "image": "url",
  "description": "text",
  "profile_url": "url",
  "good_with_kids": true,
  "good_with_dogs": true,
  "good_with_cats": false,
  "created_at": "timestamp"
}
```

## Implementation Details

### Audit Trigger Behavior

1. **INSERT**: Creates audit entry with new_snapshot only
2. **UPDATE**: 
   - Compares OLD and NEW record states
   - Merges with resolved view data
   - Only logs if fields actually changed
   - Includes array of changed field names
3. **DELETE**: Creates audit entry with old_snapshot only

### Exception Handling

All audit triggers include exception handling to prevent blocking database operations if audit logging fails. Errors are logged as warnings but don't prevent the original operation from completing.

### Performance Considerations

- Indexes on `dog_id`, `changed_at`, `operation`, and `changed_fields`
- GIN index on `changed_fields` array for efficient filtering
- Views use LEFT JOINs to handle missing related data gracefully

## Permissions

- **Public/Anon**: No access to audit logs
- **Authenticated**: Read-only access to all audit views
- **Admin**: Full read access to audit logs
- **System**: Can insert audit logs (via triggers)

## Migrations

The audit system is implemented across multiple migrations:

1. `2025122803_dogadopt_dogs_and_breeds.sql`: Initial audit setup
2. `2025122804_consolidate_dog_views.sql`: Unified `dogs_complete` view
3. `2025122805_unified_dog_audit.sql`: Breed audit trigger and resolved view
4. `2025122806_fix_dog_audit_trigger.sql`: Fixed snapshot capture for proper before/after tracking

## Testing

Use the provided test scripts to verify the audit system:

```bash
# Basic audit test
./test-audit.sh

# Comprehensive verification
./verify-audit.sh
```

## Future Enhancements

- Event replay capabilities
- Audit log cleanup/archival policies
- Real-time audit event streaming
- Audit analytics dashboard
- Point-in-time dog state reconstruction API
