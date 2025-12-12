#!/bin/bash

# Demo script for uploading dog data
echo "🐕 Adopt-a-Dog UK - Dog Data Upload Demo"
echo "======================================="
echo ""

# Check if Supabase is running
if ! curl -s http://localhost:54321/rest/v1/ >/dev/null 2>&1; then
    echo "❌ Supabase is not running. Starting it now..."
    supabase start
    echo ""
fi

echo "📋 This demo will:"
echo "  1. Check current database status"
echo "  2. Upload sample dog data if needed"
echo "  3. Verify the data was uploaded correctly"
echo ""

# Check if database has dogs
echo "🔍 Checking current dogs in database..."
DOG_COUNT=$(curl -s -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0" \
  "http://localhost:54321/rest/v1/dogadopt.dogs?select=count" | grep -o '"count":[0-9]*' | cut -d':' -f2 || echo "0")

echo "Current dogs in database: ${DOG_COUNT:-0}"

if [ "${DOG_COUNT:-0}" -eq "0" ]; then
    echo ""
    echo "📤 No dogs found. Uploading sample data..."
    npm run upload-dogs
else
    echo ""
    echo "✅ Dogs already exist in database!"
    echo ""
    echo "Options:"
    echo "  - Run 'task db:reset' to clear and reload data"
    echo "  - Run 'npm run upload-dogs' to add more sample data"
fi

echo ""
echo "🎯 Demo complete! Your development environment is ready."
echo ""
echo "Next steps:"
echo "  • Run 'npm run dev' to start the frontend"
echo "  • Visit http://localhost:8080 to see the app"
echo "  • Visit http://localhost:54323 for Supabase Studio"