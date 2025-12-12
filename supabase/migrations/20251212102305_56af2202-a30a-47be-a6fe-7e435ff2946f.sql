-- Expose the dogadopt schema to PostgREST API
-- Grant usage on the dogadopt schema to anon and authenticated roles
GRANT USAGE ON SCHEMA dogadopt TO anon;
GRANT USAGE ON SCHEMA dogadopt TO authenticated;

-- Grant select on all tables in dogadopt to anon (for public read access)
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO authenticated;

-- Grant all operations on dogs table to authenticated users (for admin operations)
GRANT ALL ON dogadopt.dogs TO authenticated;
GRANT ALL ON dogadopt.rescues TO authenticated;
GRANT ALL ON dogadopt.profiles TO authenticated;
GRANT SELECT ON dogadopt.user_roles TO authenticated;

-- Grant usage on sequences (for insert operations)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dogadopt TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO authenticated;

-- IMPORTANT: Add dogadopt to exposed schemas in the API
-- This needs to be done via Supabase Dashboard: Project Settings > API > Exposed Schemas
-- Add "dogadopt" to the list

NOTIFY pgrst, 'reload config';