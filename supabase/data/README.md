# Rescues and Locations Data

This directory contains the reference data for rescue organizations and their locations.

## Data Source

The rescues data is based on the ADCH (Association of Dogs and Cats Homes) member list, which can be found at:
https://adch.org.uk/wp-content/uploads/2025/09/Editable-Members-List-with-regions-01102025.pdf

## Files

- **rescues.csv** - CSV file containing rescue organization data
  - Columns: `name`, `type`, `region`, `website`
  - This file should be updated when the ADCH member list changes

## Updating Rescues Data

### 1. Update the CSV File

Edit `rescues.csv` to add, modify, or remove rescue organizations. The CSV format is:

```csv
name,type,region,website
Example Rescue,Full,South West England,www.example.com
```

### 2. Update the SQL Script

After editing the CSV, update the corresponding INSERT statements in:
`supabase/post-deploy/sync-rescues-locations.sql`

The script uses the temp table pattern to load data and performs an upsert operation that:
- Inserts new rescues
- Updates existing rescues only if there are actual changes
- Avoids creating unnecessary audit log entries

### 3. Test Locally

Test your changes on a local Supabase instance:

```bash
# Start local Supabase if not running
npm run supabase:start

# Run the sync script
npm run sync-rescues
```

### 4. Deploy to Production

The sync script runs automatically as part of the CI/CD pipeline when you push to the main branch. It executes after migrations in the GitHub Actions workflow.

Alternatively, you can manually sync to production:

```bash
# Set environment variables
export SUPABASE_PROJECT_REF=your-project-ref
export SUPABASE_ACCESS_TOKEN=your-access-token

# Run production sync
npm run sync-rescues:prod
```

## Data Management Strategy

### Upsert Logic

The sync script uses PostgreSQL's `INSERT ... ON CONFLICT ... DO UPDATE` pattern with a critical optimization:

```sql
ON CONFLICT (name) 
DO UPDATE SET
  type = EXCLUDED.type,
  region = EXCLUDED.region,
  website = EXCLUDED.website
WHERE 
  -- Only update if something actually changed
  dogadopt.rescues.type IS DISTINCT FROM EXCLUDED.type OR
  dogadopt.rescues.region IS DISTINCT FROM EXCLUDED.region OR
  dogadopt.rescues.website IS DISTINCT FROM EXCLUDED.website;
```

This ensures:
- ✅ New rescues are inserted
- ✅ Changed rescues are updated
- ✅ Unchanged rescues are left alone (no audit log spam)

### Audit Trail

All changes to rescues and locations are automatically tracked in:
- `dogadopt.rescues_audit_logs` - Full audit history for rescues
- `dogadopt.locations_audit_logs` - Full audit history for locations

You can view changes using the resolved views:
```sql
SELECT * FROM dogadopt.rescues_audit_logs_resolved 
ORDER BY changed_at DESC 
LIMIT 20;
```

### Default Locations

The sync script automatically creates a default location for any rescue that doesn't have one. This ensures:
- Every rescue has at least one location entry
- The location is based on the rescue's region
- Existing locations are never modified

## Maintenance Notes

### When to Update

Update the rescues data when:
1. The ADCH publishes a new member list
2. A rescue organization changes their details
3. A new rescue joins ADCH
4. A rescue leaves ADCH (mark as inactive rather than delete)

### Best Practices

1. **Always test locally first** - Use `npm run sync-rescues` before deploying
2. **Review audit logs** - Check what changed after running the sync
3. **Backup before major changes** - Export the current data before large updates
4. **Document changes** - Add notes in commit messages about what was updated
5. **Verify websites** - Ensure all website URLs are correct and accessible

## Troubleshooting

### Local Sync Issues

**Problem:** "Cannot connect to Docker container"
```bash
# Solution: Ensure Supabase is running
npm run supabase:start
docker ps | grep supabase
```

**Problem:** "psql command not found"
```bash
# Solution: Check Docker container name
docker ps --filter "name=supabase_db"
# Update script if container name differs
```

### Production Sync Issues

**Problem:** "Invalid project reference"
```bash
# Solution: Verify environment variables
echo $SUPABASE_PROJECT_REF
echo $SUPABASE_ACCESS_TOKEN

# Get correct values from Supabase Dashboard
# Settings > General > Reference ID
# https://supabase.com/dashboard/account/tokens
```

**Problem:** "Permission denied"
```bash
# Solution: Ensure access token has correct permissions
# Regenerate token with full project access
```

## Schema Reference

### Rescues Table

```sql
CREATE TABLE dogadopt.rescues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'Full',
  region TEXT NOT NULL,
  website TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### Locations Table

```sql
CREATE TABLE dogadopt.locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rescue_id UUID REFERENCES dogadopt.rescues(id),
  name TEXT NOT NULL,
  location_type dogadopt.location_type DEFAULT 'centre',
  city TEXT NOT NULL,
  region TEXT,
  -- ... additional address fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

## Future Enhancements

Potential improvements to consider:
1. **CSV Parser** - Auto-read CSV file instead of manual SQL statements
2. **Web Scraper** - Automatically fetch latest ADCH member list
3. **Admin UI** - Web interface for managing rescues data
4. **Validation** - Pre-deployment checks for data quality
5. **Notifications** - Alert on significant changes
