-- Remove email field from profiles table
-- Email should only exist in auth.users (managed by Supabase Auth)
-- This prevents data duplication and reduces security/privacy risks

-- Drop the email column
ALTER TABLE dogadopt.profiles DROP COLUMN IF EXISTS email;

-- Update the trigger function to not insert email
CREATE OR REPLACE FUNCTION dogadopt.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = dogadopt
AS $$
BEGIN
  INSERT INTO dogadopt.profiles (id)
  VALUES (new.id);
  RETURN new;
END;
$$;

-- Add comment explaining profiles table purpose
COMMENT ON TABLE dogadopt.profiles IS 'Public user profile data. Email and auth info stored in auth.users. Use this for displayable user data like username, avatar, preferences, etc.';
