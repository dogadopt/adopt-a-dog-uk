-- Create dogs table
CREATE TABLE public.dogs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  breed TEXT NOT NULL,
  age TEXT NOT NULL,
  size TEXT NOT NULL CHECK (size IN ('Small', 'Medium', 'Large')),
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
  location TEXT NOT NULL,
  rescue TEXT NOT NULL,
  image TEXT NOT NULL,
  good_with_kids BOOLEAN NOT NULL DEFAULT false,
  good_with_dogs BOOLEAN NOT NULL DEFAULT false,
  good_with_cats BOOLEAN NOT NULL DEFAULT false,
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.dogs ENABLE ROW LEVEL SECURITY;

-- Dogs are publicly viewable (adopt don't shop - we want everyone to see them)
CREATE POLICY "Dogs are publicly viewable" 
ON public.dogs 
FOR SELECT 
USING (true);

-- Insert sample dogs
INSERT INTO public.dogs (name, breed, age, size, gender, location, rescue, image, good_with_kids, good_with_dogs, good_with_cats, description) VALUES
('Bella', 'Labrador Retriever', 'Adult', 'Large', 'Female', 'London', 'Battersea Dogs Home', 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800', true, true, false, 'Bella is a gentle giant with a heart of gold. She loves long walks in the park and cuddles on the sofa.'),
('Max', 'German Shepherd', 'Young', 'Large', 'Male', 'Manchester', 'Dogs Trust Manchester', 'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=800', true, true, false, 'Max is an intelligent and loyal companion. He''s great with training and loves to learn new tricks.'),
('Daisy', 'Cocker Spaniel', 'Senior', 'Medium', 'Female', 'Bristol', 'Bristol Animal Rescue', 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800', true, true, true, 'Daisy is a sweet senior girl looking for a quiet home. She enjoys gentle walks and sunny spots.'),
('Charlie', 'Jack Russell Terrier', 'Puppy', 'Small', 'Male', 'Birmingham', 'Birmingham Dogs Home', 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800', true, true, false, 'Charlie is a bundle of energy! This playful pup needs an active family who can keep up with him.'),
('Luna', 'Staffordshire Bull Terrier', 'Adult', 'Medium', 'Female', 'Leeds', 'Leeds Dog Rescue', 'https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=800', true, false, false, 'Luna is a loving staffie who adores humans. She would thrive as the only pet in a devoted home.'),
('Oscar', 'Border Collie', 'Young', 'Medium', 'Male', 'Edinburgh', 'Scottish SPCA', 'https://images.unsplash.com/photo-1503256207526-0d5d80fa2f47?w=800', true, true, true, 'Oscar is incredibly smart and needs mental stimulation. Perfect for an active family who loves the outdoors.');