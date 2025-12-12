-- Create the dogadopt schema
CREATE SCHEMA IF NOT EXISTS dogadopt;

-- Grant usage on dogadopt schema
GRANT USAGE ON SCHEMA dogadopt TO anon, authenticated;

-- Create rescues table first (referenced by dogs)
CREATE TABLE dogadopt.rescues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'Full',
  region TEXT NOT NULL,
  website TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create dogs table
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

-- Create user roles enum and related tables
CREATE TYPE dogadopt.app_role AS ENUM ('admin', 'user');

CREATE TABLE dogadopt.profiles (
  id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

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

-- Create security definer function to check roles
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

-- RLS Policies for rescues (publicly viewable)
CREATE POLICY "Rescues are publicly viewable" 
ON dogadopt.rescues 
FOR SELECT 
USING (true);

-- RLS Policies for dogs
CREATE POLICY "Dogs are publicly viewable" 
ON dogadopt.dogs 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert dogs"
ON dogadopt.dogs FOR INSERT
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update dogs"
ON dogadopt.dogs FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'));

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
SECURITY DEFINER SET search_path = dogadopt
AS $$
BEGIN
  INSERT INTO dogadopt.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

-- Trigger to create profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION dogadopt.handle_new_user();