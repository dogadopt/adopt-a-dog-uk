-- Configure PostgREST API access
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO authenticated;

-- Grant all operations on main tables to authenticated users (for admin operations)
GRANT ALL ON dogadopt.dogs TO authenticated;
GRANT ALL ON dogadopt.rescues TO authenticated;
GRANT ALL ON dogadopt.profiles TO authenticated;
GRANT SELECT ON dogadopt.user_roles TO authenticated;

-- Grant usage on sequences (for insert operations)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dogadopt TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO authenticated;

-- Notify PostgREST to reload configuration
NOTIFY pgrst, 'reload config';