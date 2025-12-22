-- Fix the handle_new_user trigger function to include user_roles insertion

CREATE OR REPLACE FUNCTION dogadopt.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = dogadopt
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
