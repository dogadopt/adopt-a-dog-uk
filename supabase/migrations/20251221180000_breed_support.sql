-- Comprehensive breed support with multi-breed capability
-- Migrates from text breed column to many-to-many relationship

-- Create breeds reference table
CREATE TABLE dogadopt.breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create junction table for dog-breed many-to-many relationship
CREATE TABLE dogadopt.dog_breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL REFERENCES dogadopt.dogs(id) ON DELETE CASCADE,
  breed_id UUID NOT NULL REFERENCES dogadopt.breeds(id) ON DELETE RESTRICT,
  display_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(dog_id, breed_id)
);

-- Create indexes
CREATE INDEX idx_dog_breeds_dog_id ON dogadopt.dog_breeds(dog_id);
CREATE INDEX idx_dog_breeds_breed_id ON dogadopt.dog_breeds(breed_id);

-- Enable RLS on new tables
ALTER TABLE dogadopt.breeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dog_breeds ENABLE ROW LEVEL SECURITY;

-- RLS Policies for breeds
CREATE POLICY "Breeds are publicly viewable" 
ON dogadopt.breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage breeds"
ON dogadopt.breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dog_breeds
CREATE POLICY "Dog breeds are publicly viewable" 
ON dogadopt.dog_breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage dog breeds"
ON dogadopt.dog_breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Insert standard dog breeds
INSERT INTO dogadopt.breeds (name) VALUES
  ('Affenpinscher'), ('Afghan Hound'), ('Airedale Terrier'), ('Akita'),
  ('Alaskan Malamute'), ('American Bulldog'), ('American Staffordshire Terrier'),
  ('Australian Cattle Dog'), ('Australian Shepherd'), ('Basenji'), ('Basset Hound'),
  ('Beagle'), ('Bearded Collie'), ('Bedlington Terrier'), ('Belgian Malinois'),
  ('Bernese Mountain Dog'), ('Bichon Frise'), ('Bloodhound'), ('Border Collie'),
  ('Border Terrier'), ('Borzoi'), ('Boston Terrier'), ('Boxer'), ('Brittany'),
  ('Bull Terrier'), ('Bulldog'), ('Bullmastiff'), ('Cairn Terrier'), ('Cane Corso'),
  ('Cardigan Welsh Corgi'), ('Cavalier King Charles Spaniel'), ('Chesapeake Bay Retriever'),
  ('Chihuahua'), ('Chinese Crested'), ('Chinese Shar-Pei'), ('Chow Chow'),
  ('Cocker Spaniel'), ('Collie'), ('Dachshund'), ('Dalmatian'), ('Doberman Pinscher'),
  ('English Cocker Spaniel'), ('English Setter'), ('English Springer Spaniel'),
  ('English Toy Spaniel'), ('Flat-Coated Retriever'), ('Fox Terrier (Smooth)'),
  ('Fox Terrier (Wire)'), ('French Bulldog'), ('German Pinscher'), ('German Shepherd'),
  ('German Shorthaired Pointer'), ('German Wirehaired Pointer'), ('Giant Schnauzer'),
  ('Golden Retriever'), ('Gordon Setter'), ('Great Dane'), ('Great Pyrenees'),
  ('Greyhound'), ('Havanese'), ('Ibizan Hound'), ('Irish Setter'), ('Irish Terrier'),
  ('Irish Water Spaniel'), ('Irish Wolfhound'), ('Italian Greyhound'),
  ('Jack Russell Terrier'), ('Japanese Chin'), ('Keeshond'), ('Kerry Blue Terrier'),
  ('Labrador Retriever'), ('Lakeland Terrier'), ('Lhasa Apso'), ('Maltese'),
  ('Manchester Terrier'), ('Mastiff'), ('Miniature Pinscher'), ('Miniature Schnauzer'),
  ('Mixed Breed'), ('Newfoundland'), ('Norfolk Terrier'), ('Norwegian Elkhound'),
  ('Norwich Terrier'), ('Old English Sheepdog'), ('Papillon'), ('Pekingese'),
  ('Pembroke Welsh Corgi'), ('Pointer'), ('Pomeranian'), ('Poodle (Miniature)'),
  ('Poodle (Standard)'), ('Poodle (Toy)'), ('Portuguese Water Dog'), ('Pug'),
  ('Puli'), ('Rhodesian Ridgeback'), ('Rottweiler'), ('Saint Bernard'), ('Saluki'),
  ('Samoyed'), ('Schipperke'), ('Scottish Deerhound'), ('Scottish Terrier'),
  ('Sealyham Terrier'), ('Shetland Sheepdog'), ('Shiba Inu'), ('Shih Tzu'),
  ('Siberian Husky'), ('Silky Terrier'), ('Skye Terrier'),
  ('Soft Coated Wheaten Terrier'), ('Staffordshire Bull Terrier'), ('Standard Schnauzer'),
  ('Tibetan Terrier'), ('Vizsla'), ('Weimaraner'), ('Welsh Springer Spaniel'),
  ('Welsh Terrier'), ('West Highland White Terrier'), ('Whippet'),
  ('Wire Fox Terrier'), ('Yorkshire Terrier'),
  -- Common cross-breeds
  ('Cockapoo'), ('Labradoodle'), ('Goldendoodle'), ('Cavapoo'), ('Puggle'),
  ('Yorkipoo'), ('Maltipoo'), ('Schnoodle'), ('Pomsky'), ('Aussiedoodle'),
  ('Bernedoodle'), ('Sheepadoodle')
ON CONFLICT (name) DO NOTHING;

-- Migrate existing breed data from text column
-- Insert any breeds that don't exist yet
INSERT INTO dogadopt.breeds (name)
SELECT DISTINCT TRIM(breed_name)
FROM dogadopt.dogs,
     LATERAL unnest(string_to_array(breed, ',')) AS breed_name
WHERE TRIM(breed_name) != ''
  AND NOT EXISTS (
    SELECT 1 FROM dogadopt.breeds b 
    WHERE LOWER(b.name) = LOWER(TRIM(breed_name))
  );

-- Create relationships for existing dogs
INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
SELECT 
  d.id AS dog_id,
  b.id AS breed_id,
  row_number() OVER (PARTITION BY d.id ORDER BY breed_pos) AS display_order
FROM dogadopt.dogs d
CROSS JOIN LATERAL (
  SELECT 
    TRIM(breed_name) AS breed_name,
    ordinality AS breed_pos
  FROM unnest(string_to_array(d.breed, ',')) WITH ORDINALITY AS breed_name
  WHERE TRIM(breed_name) != ''
) breeds_split
JOIN dogadopt.breeds b ON LOWER(b.name) = LOWER(breeds_split.breed_name)
ON CONFLICT (dog_id, breed_id) DO NOTHING;

-- Drop the old breed column
ALTER TABLE dogadopt.dogs DROP COLUMN breed;

-- Create view for easy querying of dogs with breeds
CREATE OR REPLACE VIEW dogadopt.dogs_with_breeds AS
SELECT 
  d.*,
  string_agg(b.name, ', ' ORDER BY db.display_order) AS breed,
  array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL) AS breeds_array
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dog_breeds db ON d.id = db.dog_id
LEFT JOIN dogadopt.breeds b ON db.breed_id = b.id
GROUP BY d.id;

-- Grant permissions
GRANT SELECT ON dogadopt.breeds TO anon, authenticated;
GRANT SELECT ON dogadopt.dog_breeds TO anon, authenticated;
GRANT SELECT ON dogadopt.dogs_with_breeds TO anon, authenticated;

-- Helper function to manage dog breeds
CREATE OR REPLACE FUNCTION dogadopt.set_dog_breeds(
  p_dog_id UUID,
  p_breed_names TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt
AS $$
DECLARE
  v_breed_name TEXT;
  v_breed_id UUID;
  v_order INT;
BEGIN
  -- Delete existing breed associations
  DELETE FROM dogadopt.dog_breeds WHERE dog_id = p_dog_id;
  
  -- Insert new breed associations
  v_order := 1;
  FOREACH v_breed_name IN ARRAY p_breed_names
  LOOP
    -- Get or create breed
    SELECT id INTO v_breed_id
    FROM dogadopt.breeds
    WHERE LOWER(name) = LOWER(TRIM(v_breed_name));
    
    IF v_breed_id IS NULL THEN
      INSERT INTO dogadopt.breeds (name)
      VALUES (TRIM(v_breed_name))
      RETURNING id INTO v_breed_id;
    END IF;
    
    -- Associate breed with dog
    INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
    VALUES (p_dog_id, v_breed_id, v_order);
    
    v_order := v_order + 1;
  END LOOP;
END;
$$;

COMMENT ON FUNCTION dogadopt.set_dog_breeds IS 'Helper function to set breeds for a dog. Manages the many-to-many relationship.';
COMMENT ON TABLE dogadopt.breeds IS 'Reference table of dog breeds';
COMMENT ON TABLE dogadopt.dog_breeds IS 'Junction table linking dogs to breeds (supports multi-breed dogs)';
