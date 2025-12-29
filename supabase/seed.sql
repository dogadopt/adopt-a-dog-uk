-- Seed file for LOCAL DEVELOPMENT ONLY
-- This file is ONLY run by `supabase db reset` in local development
-- It will NOT be applied to production databases

-- HOW TO CREATE AN ADMIN USER:
-- 
-- 1. Sign up at /auth with any email/password (e.g., admin@test.com / admin123)
-- 2. Run this SQL to promote yourself to admin:
--    
--    UPDATE dogadopt.user_roles 
--    SET role = 'admin' 
--    WHERE user_id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');
--
-- Or run this Docker command:
--    docker exec supabase_db_dog-adopt psql -U postgres -c "UPDATE dogadopt.user_roles SET role = 'admin' WHERE user_id = (SELECT id FROM auth.users WHERE email = 'YOUR_EMAIL@example.com');"

-- Sample dogs for demonstration
-- First, insert dogs
WITH inserted_dogs AS (
  INSERT INTO dogadopt.dogs (name, age, size, gender, rescue_id, image, good_with_kids, good_with_dogs, good_with_cats, description) VALUES
  ('Bella', 'Adult', 'Large', 'Female',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Battersea'), 
   'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800', 
   true, true, false, 'Bella is a gentle giant with a heart of gold. She loves long walks in the park and cuddles on the sofa.'),

  ('Max', 'Young', 'Large', 'Male',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Dogs Trust'), 
   'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=800', 
   true, true, false, 'Max is an intelligent and loyal companion. He''s great with training and loves to learn new tricks.'),

  ('Daisy', 'Senior', 'Medium', 'Female',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Bristol Animal Rescue Centre'), 
   'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800', 
   true, true, true, 'Daisy is a sweet senior girl looking for a quiet home. She enjoys gentle walks and sunny spots.'),

  ('Charlie', 'Puppy', 'Small', 'Male',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Birmingham Dogs Home'), 
   'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800', 
   true, true, false, 'Charlie is a bundle of energy! This playful pup needs an active family who can keep up with him.'),

  ('Luna', 'Adult', 'Medium', 'Female',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Hope Rescue'), 
   'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=800', 
   true, false, false, 'Luna is a loving staffie who adores humans. She would thrive as the only pet in a devoted home.'),

  ('Oscar', 'Young', 'Medium', 'Male',
   (SELECT id FROM dogadopt.rescues WHERE name = 'Scottish SPCA'), 
   'https://images.unsplash.com/photo-1503256207526-0d5d80fa2f47?w=800', 
   true, true, true, 'Oscar is incredibly smart and needs mental stimulation. Perfect for an active family who loves the outdoors.')
  RETURNING id, name
)
-- Then, link dogs to breeds
INSERT INTO dogadopt.dogs_breeds (dog_id, breed_id, display_order)
SELECT 
  d.id,
  b.id,
  1
FROM inserted_dogs d
CROSS JOIN dogadopt.breeds b
WHERE (d.name = 'Bella' AND b.name = 'Labrador Retriever')
   OR (d.name = 'Max' AND b.name = 'German Shepherd')
   OR (d.name = 'Daisy' AND b.name = 'Cocker Spaniel')
   OR (d.name = 'Charlie' AND b.name = 'Jack Russell Terrier')
   OR (d.name = 'Luna' AND b.name = 'Staffordshire Bull Terrier')
   OR (d.name = 'Oscar' AND b.name = 'Border Collie');

