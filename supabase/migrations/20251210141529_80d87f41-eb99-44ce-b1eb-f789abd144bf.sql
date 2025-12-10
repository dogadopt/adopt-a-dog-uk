-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS dogadopt.handle_new_user();

-- Create profiles table
CREATE TABLE IF NOT EXISTS dogadopt.profiles (
  id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE dogadopt.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
ON dogadopt.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
ON dogadopt.profiles FOR UPDATE
USING (auth.uid() = id);

-- Create function to handle new user signup
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

-- Create user roles enum and table
CREATE TYPE dogadopt.app_role AS ENUM ('admin', 'user');

CREATE TABLE dogadopt.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  UNIQUE (user_id, role)
);

ALTER TABLE dogadopt.user_roles ENABLE ROW LEVEL SECURITY;

-- Create security definer function to check roles
CREATE OR REPLACE FUNCTION dogadopt.has_role(_user_id UUID, _role app_role)
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

-- RLS: Users can view their own roles
CREATE POLICY "Users can view their own roles"
ON dogadopt.user_roles FOR SELECT
USING (auth.uid() = user_id);

-- RLS: Only admins can manage roles
CREATE POLICY "Admins can manage roles"
ON dogadopt.user_roles FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Add insert/update/delete policies for dogs table (admin only)
CREATE POLICY "Admins can insert dogs"
ON dogadopt.dogs FOR INSERT
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update dogs"
ON dogadopt.dogs FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete dogs"
ON dogadopt.dogs FOR DELETE
USING (dogadopt.has_role(auth.uid(), 'admin'));