#!/bin/bash
# Helper script to promote a user to admin role

if [ -z "$1" ]; then
    echo "Usage: ./scripts/make-admin.sh <email>"
    echo "Example: ./scripts/make-admin.sh admin@test.com"
    exit 1
fi

EMAIL="$1"

echo "Promoting $EMAIL to admin role..."

docker exec supabase_db_dog-adopt psql -U postgres -c "
UPDATE dogadopt.user_roles 
SET role = 'admin' 
WHERE user_id = (SELECT id FROM auth.users WHERE email = '$EMAIL');
"

echo "Done! $EMAIL is now an admin."
echo "Refresh your browser to see the Admin link in the header."
