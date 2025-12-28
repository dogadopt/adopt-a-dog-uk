#!/bin/bash
# Test audit logging

echo "=== Testing Dog Audit System ==="
echo

echo "1. Current audit log count for Bella:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.dogs_audit_logs WHERE dog_id = (SELECT id FROM dogadopt.dogs WHERE name = 'Bella');"

echo "2. Updating Bella's status to 'adopted'..."
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "UPDATE dogadopt.dogs SET status = 'adopted' WHERE name = 'Bella';"

echo "3. Audit log count after update:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM dogadopt.dogs_audit_logs WHERE dog_id = (SELECT id FROM dogadopt.dogs WHERE name = 'Bella');"

echo "4. View audit log for Bella:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT dog_name, operation, old_status, new_status, change_summary FROM dogadopt.dogs_audit_logs_resolved WHERE dog_name = 'Bella' ORDER BY changed_at;"

echo
echo "5. Adding a new breed to Max..."
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "INSERT INTO dogadopt.dogs_breeds (dog_id, breed_id, display_order) SELECT (SELECT id FROM dogadopt.dogs WHERE name = 'Max'), (SELECT id FROM dogadopt.breeds WHERE name = 'Mixed Breed'), 2;"

echo "6. View breed changes for Max:"
docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "SELECT dog_name, old_breeds, new_breeds, change_summary FROM dogadopt.dogs_audit_logs_resolved WHERE dog_name = 'Max' AND old_breeds IS DISTINCT FROM new_breeds ORDER BY changed_at;"

echo
echo "=== Test Complete ==="
