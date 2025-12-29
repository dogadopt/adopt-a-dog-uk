# Comprehensive Dog Audit System

## Overview

A complete event sourcing system that captures **fully resolved** dog state with all IDs resolved to human-readable values. This provides a complete audit trail with snapshots that can be understood without joining multiple tables.

## Key Components

### 1. `dogadopt.dogs_resolved` View
A comprehensive view that resolves all foreign keys:

```sql
SELECT * FROM dogadopt.dogs_resolved WHERE id = 'YOUR_DOG_ID';
```

**Returns:**
- All dog attributes (name, age, size, gender, etc.)
- **Resolved breeds**: Both as array `['Labrador', 'Golden Retriever']` and display string `'Labrador, Golden Retriever'`
- **Resolved rescue**: Name, ID, region, website
- **Resolved location**: Name, ID, region, enquiry URL

### 2. `dogadopt.dog_complete_audit_log` Table
Stores complete snapshots with human-readable data:

- `old_snapshot` - Complete state BEFORE change (JSONB)
- `new_snapshot` - Complete state AFTER change (JSONB)
- `changed_fields` - Array of what changed
- `change_summary` - Human-readable description (e.g., "Breeds: Beagle → Labrador, Golden Retriever")
- `changed_by` - Who made the change
- `changed_at` - When it happened

### 3. Helper Views

#### `dog_change_history`
Complete change history with before/after snapshots:
```sql
SELECT * FROM dogadopt.dog_change_history 
WHERE dog_name = 'Max' 
ORDER BY changed_at DESC;
```

#### `dog_timeline`
Event timeline showing all changes:
```sql
SELECT * FROM dogadopt.dog_timeline 
WHERE dog_id = 'YOUR_DOG_ID'
ORDER BY event_time;
```

## Usage Examples

###1: See Complete Change History for a Dog
```sql
SELECT 
  changed_at,
  operation,
  change_summary,
  changed_by_email,
  changed_fields
FROM dogadopt.dog_change_history
WHERE dog_name = 'Max'
ORDER BY changed_at DESC;
```

### Example 2: See What a Dog Looked Like at a Specific Time (Time Travel)
```sql
-- Get the most recent snapshot before a specific date
SELECT 
  new_snapshot->>'name' AS name,
  new_snapshot->>'breeds_display' AS breeds,
  new_snapshot->>'status' AS status,
  new_snapshot->>'rescue_name' AS rescue,
  new_snapshot->>'location_name' AS location,
  changed_at
FROM dogadopt.dog_complete_audit_log
WHERE dog_id = 'YOUR_DOG_ID'
  AND changed_at <= '2025-12-01'::timestamp
ORDER BY changed_at DESC
LIMIT 1;
```

### Example 3: Track Breed Changes Over Time
```sql
SELECT 
  changed_at,
  old_snapshot->>'breeds_display' AS old_breeds,
  new_snapshot->>'breeds_display' AS new_breeds,
  changed_by_email
FROM dogadopt.dog_change_history
WHERE dog_name = 'Max'
  AND 'breeds' = ANY(changed_fields)
ORDER BY changed_at;
```

### Example 4: See All Dogs That Changed Status Today
```sql
SELECT 
  dog_name,
  old_snapshot->>'status' AS old_status,
  new_snapshot->>'status' AS new_status,
  changed_at,
  changed_by_email
FROM dogadopt.dog_change_history
WHERE changed_at::date = CURRENT_DATE
  AND 'status' = ANY(changed_fields)
ORDER BY changed_at DESC;
```

### Example 5: Audit Report - Who Changed What
```sql
SELECT 
  changed_by_email,
  COUNT(*) AS total_changes,
  COUNT(DISTINCT dog_id) AS dogs_affected,
  array_agg(DISTINCT operation) AS operations
FROM dogadopt.dog_complete_audit_log
WHERE changed_at >= NOW() - INTERVAL '7 days'
GROUP BY changed_by_email
ORDER BY total_changes DESC;
```

### Example 6: Rebuild Dog State at Any Point in Time
```sql
-- Get complete state of all dogs as they were on 2025-12-01
WITH latest_snapshots AS (
  SELECT DISTINCT ON (dog_id)
    dog_id,
    new_snapshot,
    changed_at
  FROM dogadopt.dog_complete_audit_log
  WHERE changed_at <= '2025-12-01'::timestamp
    AND operation != 'DELETE'
  ORDER BY dog_id, changed_at DESC
)
SELECT 
  new_snapshot->>'name' AS name,
  new_snapshot->>'breeds_display' AS breeds,
  new_snapshot->>'status' AS status,
  new_snapshot->>'rescue_name' AS rescue
FROM latest_snapshots
ORDER BY new_snapshot->>'name';
```

## What Gets Audited

### Automatic Triggers

1. **Dogs Table Changes**
   - INSERT: Full snapshot logged
   - UPDATE: Before/after snapshots, changed fields identified
   - DELETE: Final snapshot logged

2. **Breed Changes** (dog_breeds table)
   - When breeds added/removed
   - Automatically captures updated dog state
   - Change summary shows breed additions/removals

### Change Summary Examples

```
"Dog 'Max' created"
"Dog 'Max' updated: Breeds: Beagle → Labrador, Golden Retriever"
"Dog 'Max' updated: Status: available → adopted"
"Dog 'Max' updated: Rescue: Dogs Trust → RSPCA; Location: London → Manchester"
"Dog 'Max' deleted"
```

## Benefits

✅ **Complete Snapshots** - No need to join tables to understand changes
✅ **Human Readable** - All IDs resolved to names
✅ **Event Sourcing** - Can rebuild state at any point in time
✅ **Audit Compliance** - Who, what, when, why for all changes
✅ **Time Travel Queries** - See historical state
✅ **Change Analytics** - Understand patterns and trends
✅ **Debugging** - Track down when/how data changed
✅ **Accountability** - Know who made each change

## Performance Considerations

- Snapshots stored as JSONB (efficient, indexed)
- Triggers run AFTER changes (doesn't block operations)
- Old audit logs can be archived periodically
- Views are optimized for common queries

## Architecture

```
┌─────────────┐
│    dogs     │──┐
└─────────────┘  │
                 │  Triggers on changes
┌─────────────┐  │
│ dog_breeds  │──┤
└─────────────┘  │
                 ▼
        ┌──────────────────────┐
        │ dogs_resolved VIEW   │ ◄── Resolves all IDs
        └──────────────────────┘
                 │
                 │ Snapshot captured
                 ▼
     ┌───────────────────────────┐
     │ dog_complete_audit_log    │
     │  - old_snapshot (JSONB)   │
     │  - new_snapshot (JSONB)   │
     │  - changed_fields         │
     │  - change_summary         │
     └───────────────────────────┘
                 │
                 │ Queried via views
                 ▼
        ┌──────────────────┐
        │  dog_timeline    │ ◄── Human-readable events
        │  dog_change_history │
        └──────────────────┘
```

## Comparison with Previous Audit Systems

### Old System
- ❌ Separate audit tables for dogs and breeds
- ❌ IDs not resolved (need joins to understand)
- ❌ Incomplete snapshots
- ❌ Hard to query historical state

### New System
- ✅ Single comprehensive audit log
- ✅ All IDs resolved in snapshots
- ✅ Complete before/after state
- ✅ Easy time-travel queries
- ✅ Human-readable change summaries
- ✅ Event sourcing capable

## Migration Note

This system **replaces** the previous:
- `dog_audit_log` (raw dog table changes)
- `dog_breeds_audit_log` (breed association changes)

Both are still present for backwards compatibility, but **`dog_complete_audit_log` is the primary audit trail** going forward.
