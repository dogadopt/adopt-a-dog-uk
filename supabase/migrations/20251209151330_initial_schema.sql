-- Initial schema with rescues, dogs, profiles, and user roles
-- Includes RLS policies, storage setup, and API permissions

-- Create the dogadopt schema
CREATE SCHEMA IF NOT EXISTS dogadopt;

-- Grant usage on dogadopt schema
GRANT USAGE ON SCHEMA dogadopt TO anon, authenticated;

-- Create user roles enum
CREATE TYPE dogadopt.app_role AS ENUM ('admin', 'user');

-- Create rescues table
CREATE TABLE dogadopt.rescues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'Full',
  region TEXT NOT NULL,
  website TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create dogs table (breed column will be migrated to relationship later)
CREATE TABLE dogadopt.dogs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  breed TEXT NOT NULL,
  age TEXT NOT NULL,
  size TEXT NOT NULL CHECK (size IN ('Small', 'Medium', 'Large')),
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
  location TEXT NOT NULL,
  rescue TEXT NOT NULL,
  rescue_id UUID REFERENCES dogadopt.rescues(id),
  image TEXT NOT NULL,
  good_with_kids BOOLEAN NOT NULL DEFAULT false,
  good_with_dogs BOOLEAN NOT NULL DEFAULT false,
  good_with_cats BOOLEAN NOT NULL DEFAULT false,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

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
ALTER TABLE dogadopt.rescues ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dogs ENABLE ROW LEVEL SECURITY;
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

-- RLS Policies for rescues (publicly viewable, admins can manage)
CREATE POLICY "Rescues are publicly viewable" 
ON dogadopt.rescues FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage rescues"
ON dogadopt.rescues FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dogs (publicly viewable, admins can manage)
CREATE POLICY "Dogs are publicly viewable" 
ON dogadopt.dogs FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert dogs"
ON dogadopt.dogs FOR INSERT
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update dogs"
ON dogadopt.dogs FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'))
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete dogs"
ON dogadopt.dogs FOR DELETE
USING (dogadopt.has_role(auth.uid(), 'admin'));

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
GRANT ALL ON dogadopt.dogs TO authenticated;
GRANT ALL ON dogadopt.rescues TO authenticated;
GRANT ALL ON dogadopt.profiles TO authenticated;
GRANT SELECT ON dogadopt.user_roles TO authenticated;

-- Grant usage on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA dogadopt TO authenticated;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA dogadopt GRANT SELECT ON TABLES TO authenticated;

-- Create storage bucket for dog adoption images
INSERT INTO storage.buckets (id, name, public)
VALUES ('dog-adopt-images', 'dog-adopt-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public read access for dog images"
ON storage.objects FOR SELECT
USING (bucket_id = 'dog-adopt-images');

CREATE POLICY "Authenticated users can upload dog images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update dog images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete dog images"
ON storage.objects FOR DELETE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

-- Notify PostgREST to reload configuration
NOTIFY pgrst, 'reload config';
