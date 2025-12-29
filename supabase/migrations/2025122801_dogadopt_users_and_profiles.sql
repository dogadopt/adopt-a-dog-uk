-- Users and Profiles
-- User roles, profiles, authentication setup, and RLS policies for user management

-- Create the dogadopt schema
CREATE SCHEMA IF NOT EXISTS dogadopt;

-- Grant usage on dogadopt schema
GRANT USAGE ON SCHEMA dogadopt TO anon, authenticated;

-- Create user roles enum
CREATE TYPE dogadopt.app_role AS ENUM ('admin', 'user');

-- Create profiles table (without email - managed by auth.users)
CREATE TABLE dogadopt.profiles (
  id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

COMMENT ON TABLE dogadopt.profiles IS 'Public user profile data. Email and auth info stored in auth.users.';

-- Create user roles table
CREATE TABLE dogadopt.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role dogadopt.app_role NOT NULL,
  UNIQUE (user_id, role)
);

-- Enable RLS on all tables
ALTER TABLE dogadopt.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.user_roles ENABLE ROW LEVEL SECURITY;

-- Security definer function to check roles
CREATE OR REPLACE FUNCTION dogadopt.has_role(_user_id UUID, _role dogadopt.app_role)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = dogadopt
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM dogadopt.user_roles
    WHERE user_id = _user_id
      AND role = _role
  )
$$;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile"
ON dogadopt.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON dogadopt.profiles FOR UPDATE
USING (auth.uid() = id);

-- RLS Policies for user_roles
CREATE POLICY "Users can view their own roles"
ON dogadopt.user_roles FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage roles"
ON dogadopt.user_roles FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION dogadopt.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = dogadopt
AS $$
BEGIN
  -- Create profile for new user
  INSERT INTO dogadopt.profiles (id)
  VALUES (new.id);
  
  -- Grant default 'user' role to new user
  INSERT INTO dogadopt.user_roles (user_id, role)
  VALUES (new.id, 'user');
  
  RETURN new;
END;
$$;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION dogadopt.handle_new_user();

-- Configure PostgREST API access
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO authenticated;

-- Grant all operations to authenticated users (for admin operations)
GRANT ALL ON dogadopt.profiles TO authenticated;
GRANT SELECT ON dogadopt.user_roles TO authenticated;

-- Grant usage on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dogadopt TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO authenticated;

-- Notify PostgREST to reload configuration
NOTIFY pgrst, 'reload config';
