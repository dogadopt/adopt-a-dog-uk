#!/bin/bash
# Test audit logging for rescues and locations
set -e  # Exit on error
set -o pipefail  # Exit on pipe failures

echo "=== Testing Rescue and Location Audit System ==="
echo

# Function to escape single quotes for SQL
escape_sql() {
  echo "$1" | sed "s/'/''/g"
}

# Test Rescues Audit
echo "1. Get a sample rescue name or create one:"
if RESCUE_NAME=$(docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT name FROM dogadopt.rescues LIMIT 1;" 2>/dev/null | xargs); then
  if [ -z "$RESCUE_NAME" ]; then
    echo "No rescues found, creating test rescue..."
    docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "INSERT INTO dogadopt.rescues (name, type, region, website) VALUES ('Test Initial Rescue', 'Full', 'Test Region', 'www.test.com') RETURNING name;" 2>/dev/null
    RESCUE_NAME="Test Initial Rescue"
  fi
else
  echo "Error: Could not connect to database"
  exit 1
fi

# Escape the rescue name for SQL
RESCUE_NAME_ESCAPED=$(escape_sql "$RESCUE_NAME")
echo "Testing with rescue: $RESCUE_NAME"
echo

echo "2. Current audit log count for $RESCUE_NAME:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.rescues_audit_logs WHERE rescue_id = (SELECT id FROM dogadopt.rescues WHERE name = '$RESCUE_NAME_ESCAPED');"

echo "3. Updating $RESCUE_NAME website..."
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "UPDATE dogadopt.rescues SET website = 'www.updated-rescue-website.com' WHERE name = '$RESCUE_NAME_ESCAPED';"

echo "4. Audit log count after update:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.rescues_audit_logs WHERE rescue_id = (SELECT id FROM dogadopt.rescues WHERE name = '$RESCUE_NAME_ESCAPED');"

echo "5. View audit log for $RESCUE_NAME:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT rescue_name, operation, old_website, new_website, change_summary FROM dogadopt.rescues_audit_logs_resolved WHERE rescue_name = '$RESCUE_NAME_ESCAPED' ORDER BY changed_at DESC LIMIT 5;"

echo
echo "=== Testing Location Audit ==="
echo

echo "6. Get a sample location name or create one:"
if LOCATION_NAME=$(docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT name FROM dogadopt.locations LIMIT 1;" 2>/dev/null | xargs); then
  if [ -z "$LOCATION_NAME" ]; then
    echo "No locations found, creating test location..."
    # Get the rescue_id from our test rescue
    if RESCUE_ID=$(docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT id FROM dogadopt.rescues WHERE name = '$RESCUE_NAME_ESCAPED';" 2>/dev/null | xargs); then
      if [ -z "$RESCUE_ID" ]; then
        echo "Error: Could not find rescue_id for '$RESCUE_NAME'"
        exit 1
      fi
      docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "INSERT INTO dogadopt.locations (rescue_id, name, city, location_type) VALUES ('$RESCUE_ID', 'Test Initial Location', 'Test City', 'centre') RETURNING name;" 2>/dev/null
      LOCATION_NAME="Test Initial Location"
    else
      echo "Error: Could not query rescue_id"
      exit 1
    fi
  fi
else
  echo "Error: Could not connect to database"
  exit 1
fi

# Escape the location name for SQL
LOCATION_NAME_ESCAPED=$(escape_sql "$LOCATION_NAME")
echo "Testing with location: $LOCATION_NAME"
echo

echo "7. Current audit log count for $LOCATION_NAME:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.locations_audit_logs WHERE location_id = (SELECT id FROM dogadopt.locations WHERE name = '$LOCATION_NAME_ESCAPED');"

echo "8. Updating $LOCATION_NAME city..."
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "UPDATE dogadopt.locations SET city = 'Updated City' WHERE name = '$LOCATION_NAME_ESCAPED';"

echo "9. Audit log count after update:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.locations_audit_logs WHERE location_id = (SELECT id FROM dogadopt.locations WHERE name = '$LOCATION_NAME_ESCAPED');"

echo "10. View audit log for $LOCATION_NAME:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT location_name, operation, old_city, new_city, change_summary FROM dogadopt.locations_audit_logs_resolved WHERE location_name = '$LOCATION_NAME_ESCAPED' ORDER BY changed_at DESC LIMIT 5;"

echo
echo "11. Create a new rescue to test INSERT audit:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "INSERT INTO dogadopt.rescues (name, type, region, website) VALUES ('Test Rescue Audit', 'Full', 'Test Region', 'www.test-audit.com');"

echo "12. View audit log for new rescue:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT rescue_name, operation, change_summary FROM dogadopt.rescues_audit_logs_resolved WHERE rescue_name = 'Test Rescue Audit' ORDER BY changed_at DESC;"

echo
echo "13. Create a new location to test INSERT audit:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "INSERT INTO dogadopt.locations (rescue_id, name, city, location_type) VALUES ((SELECT id FROM dogadopt.rescues WHERE name = 'Test Rescue Audit'), 'Test Location Audit', 'Test City', 'centre');"

echo "14. View audit log for new location:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT location_name, operation, rescue_name, change_summary FROM dogadopt.locations_audit_logs_resolved WHERE location_name = 'Test Location Audit' ORDER BY changed_at DESC;"

echo
echo "15. Test location_type change:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "UPDATE dogadopt.locations SET location_type = 'foster_home' WHERE name = 'Test Location Audit';"

echo "16. View location_type change in audit log:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT location_name, old_location_type, new_location_type, changed_fields FROM dogadopt.locations_audit_logs_resolved WHERE location_name = 'Test Location Audit' AND old_location_type IS DISTINCT FROM new_location_type ORDER BY changed_at DESC;"

echo
echo "=== Cleanup Test Data ==="
echo "17. Delete test rescue (will cascade to location):"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "DELETE FROM dogadopt.rescues WHERE name = 'Test Rescue Audit';"

echo "18. View DELETE audit logs:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT rescue_name, operation, change_summary FROM dogadopt.rescues_audit_logs_resolved WHERE rescue_name = 'Test Rescue Audit' ORDER BY changed_at DESC;"

echo
echo "=== Test Complete ==="
