-- Seed file for LOCAL DEVELOPMENT ONLY
-- This file is ONLY run by `supabase db reset` in local development
-- It will NOT be applied to production databases

-- HOW TO CREATE AN ADMIN USER:
-- 
-- 1. Sign up at /auth with any email/password (e.g., admin@test.com / admin123)
-- 2. Run this SQL to promote yourself to admin:
--    
--    UPDATE dogadopt.user_roles 
--    SET role = 'admin' 
--    WHERE user_id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');
--
-- Or run this Docker command:
--    docker exec supabase_db_dog-adopt psql -U postgres -c "UPDATE dogadopt.user_roles SET role = 'admin' WHERE user_id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');"

-- Sample data will be loaded from other seed files if they exist
