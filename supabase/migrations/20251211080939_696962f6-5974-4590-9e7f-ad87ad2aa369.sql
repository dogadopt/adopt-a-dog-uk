-- Insert profile if missing
INSERT INTO public.profiles (id, email)
VALUES ('5d5992bd-b8ff-4401-b67b-79cb3be21136', 'griff182uk@googlemail.com')
ON CONFLICT (id) DO NOTHING;

-- Add admin role
INSERT INTO public.user_roles (user_id, role)
VALUES ('5d5992bd-b8ff-4401-b67b-79cb3be21136', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;