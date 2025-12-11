-- Create the dogadopt schema
CREATE SCHEMA IF NOT EXISTS dogadopt;

-- Create the enum in dogadopt schema
CREATE TYPE dogadopt.app_role AS ENUM ('admin', 'user');

-- Create profiles table in dogadopt schema
CREATE TABLE dogadopt.profiles (
  id uuid NOT NULL PRIMARY KEY,
  email text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE dogadopt.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile" ON dogadopt.profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON dogadopt.profiles
FOR UPDATE USING (auth.uid() = id);

-- Create user_roles table in dogadopt schema
CREATE TABLE dogadopt.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role dogadopt.app_role NOT NULL,
  UNIQUE (user_id, role)
);

ALTER TABLE dogadopt.user_roles ENABLE ROW LEVEL SECURITY;

-- Create has_role function in dogadopt schema
CREATE OR REPLACE FUNCTION dogadopt.has_role(_user_id uuid, _role dogadopt.app_role)
RETURNS boolean
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

CREATE POLICY "Users can view their own roles" ON dogadopt.user_roles
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage roles" ON dogadopt.user_roles
FOR ALL USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Create rescues table in dogadopt schema
CREATE TABLE dogadopt.rescues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL DEFAULT 'Full',
  region text NOT NULL,
  website text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE dogadopt.rescues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Rescues are publicly viewable" ON dogadopt.rescues
FOR SELECT USING (true);

-- Create dogs table in dogadopt schema
CREATE TABLE dogadopt.dogs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  breed text NOT NULL,
  age text NOT NULL,
  size text NOT NULL,
  gender text NOT NULL,
  description text NOT NULL,
  image text NOT NULL,
  location text NOT NULL,
  rescue text NOT NULL,
  rescue_id uuid REFERENCES dogadopt.rescues(id),
  good_with_dogs boolean NOT NULL DEFAULT false,
  good_with_cats boolean NOT NULL DEFAULT false,
  good_with_kids boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE dogadopt.dogs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Dogs are publicly viewable" ON dogadopt.dogs
FOR SELECT USING (true);

CREATE POLICY "Admins can insert dogs" ON dogadopt.dogs
FOR INSERT WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update dogs" ON dogadopt.dogs
FOR UPDATE USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete dogs" ON dogadopt.dogs
FOR DELETE USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Create handle_new_user function for dogadopt schema
CREATE OR REPLACE FUNCTION dogadopt.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt
AS $$
BEGIN
  INSERT INTO dogadopt.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

-- Drop old trigger if exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION dogadopt.handle_new_user();

-- Migrate existing data from public schema to dogadopt schema
INSERT INTO dogadopt.profiles (id, email, created_at)
SELECT id, email, created_at FROM public.profiles
ON CONFLICT (id) DO NOTHING;

INSERT INTO dogadopt.user_roles (id, user_id, role)
SELECT id, user_id, role::text::dogadopt.app_role FROM public.user_roles
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO dogadopt.rescues (id, name, type, region, website, created_at)
SELECT id, name, type, region, website, created_at FROM public.rescues
ON CONFLICT (id) DO NOTHING;

INSERT INTO dogadopt.dogs (id, name, breed, age, size, gender, description, image, location, rescue, rescue_id, good_with_dogs, good_with_cats, good_with_kids, created_at)
SELECT id, name, breed, age, size, gender, description, image, location, rescue, rescue_id, good_with_dogs, good_with_cats, good_with_kids, created_at FROM public.dogs
ON CONFLICT (id) DO NOTHING;

-- Grant usage on dogadopt schema to authenticated and anon roles
GRANT USAGE ON SCHEMA dogadopt TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA dogadopt TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dogadopt TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA dogadopt TO authenticated;