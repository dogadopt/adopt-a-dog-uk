#!/bin/bash
# Verify rescue and location data after migration
# This script queries the database to confirm the migration was successful

set -e

echo "🔍 Verifying Rescue and Location Data Migration"
echo "=============================================="
echo ""

# Check if we're running in a container or need to connect to local Supabase
if [ -f ".env.local" ]; then
    source .env.local
fi

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-54322}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
DB_PASS="${DB_PASS:-postgres}"

# Function to run SQL query
run_query() {
    docker exec supabase_db_dog-adopt psql -U postgres -d postgres -c "$1" 2>/dev/null || \
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$1"
}

echo "📊 Checking rescue count..."
RESCUE_COUNT=$(run_query "SELECT COUNT(*) FROM dogadopt.rescues;" | grep -oP '\d+' | head -1)
echo "   Rescues found: $RESCUE_COUNT"
if [ "$RESCUE_COUNT" = "61" ]; then
    echo "   ✅ Expected count (61)"
else
    echo "   ⚠️  Expected 61 rescues, found $RESCUE_COUNT"
fi
echo ""

echo "📍 Checking location count..."
LOCATION_COUNT=$(run_query "SELECT COUNT(*) FROM dogadopt.locations;" | grep -oP '\d+' | head -1)
echo "   Locations found: $LOCATION_COUNT"
if [ "$LOCATION_COUNT" = "62" ]; then
    echo "   ✅ Expected count (62)"
else
    echo "   ⚠️  Expected 62 locations, found $LOCATION_COUNT"
fi
echo ""

echo "🌍 Checking regional distribution..."
run_query "
SELECT region, COUNT(*) as count 
FROM dogadopt.rescues 
GROUP BY region 
ORDER BY count DESC;
"
echo ""

echo "🔗 Checking rescues with websites..."
RESCUE_WITH_WEBSITES=$(run_query "SELECT COUNT(*) FROM dogadopt.rescues WHERE website IS NOT NULL;" | grep -oP '\d+' | head -1)
echo "   Rescues with websites: $RESCUE_WITH_WEBSITES / $RESCUE_COUNT"
echo ""

echo "📍 Checking locations with coordinates..."
LOCATIONS_WITH_COORDS=$(run_query "SELECT COUNT(*) FROM dogadopt.locations WHERE latitude IS NOT NULL AND longitude IS NOT NULL;" | grep -oP '\d+' | head -1)
echo "   Locations with coordinates: $LOCATIONS_WITH_COORDS / $LOCATION_COUNT"
echo ""

echo "✨ Sample rescues:"
run_query "
SELECT name, region, website 
FROM dogadopt.rescues 
ORDER BY name 
LIMIT 5;
"
echo ""

echo "=============================================="
echo "✅ Verification complete!"
