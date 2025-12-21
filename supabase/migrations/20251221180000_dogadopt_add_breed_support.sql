-- Migration to add comprehensive breed support with multi-breed capability
-- This migration allows dogs to have multiple breeds (for cross-breeds)

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

-- Create index for faster lookups
CREATE INDEX idx_dog_breeds_dog_id ON dogadopt.dog_breeds(dog_id);
CREATE INDEX idx_dog_breeds_breed_id ON dogadopt.dog_breeds(breed_id);

-- Enable RLS on new tables
ALTER TABLE dogadopt.breeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dog_breeds ENABLE ROW LEVEL SECURITY;

-- RLS Policies for breeds (publicly viewable)
CREATE POLICY "Breeds are publicly viewable" 
ON dogadopt.breeds 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage breeds"
ON dogadopt.breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dog_breeds (publicly viewable)
CREATE POLICY "Dog breeds are publicly viewable" 
ON dogadopt.dog_breeds 
FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage dog breeds"
ON dogadopt.dog_breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Insert all standard dog breeds
INSERT INTO dogadopt.breeds (name) VALUES
  ('Affenpinscher'),
  ('Afghan Hound'),
  ('Airedale Terrier'),
  ('Akbash'),
  ('Akita'),
  ('Alaskan Klee Kai'),
  ('Alaskan Malamute'),
  ('American Bulldog'),
  ('American Bully'),
  ('American Eskimo Dog'),
  ('American Foxhound'),
  ('American Hairless Terrier'),
  ('American Pit Bull Terrier'),
  ('American Staffordshire Terrier'),
  ('American Water Spaniel'),
  ('Anatolian Shepherd Dog'),
  ('Appenzeller Sennenhund'),
  ('Australian Cattle Dog'),
  ('Australian Kelpie'),
  ('Australian Shepherd'),
  ('Australian Terrier'),
  ('Azawakh'),
  ('Barbet'),
  ('Basenji'),
  ('Basset Bleu de Gascogne'),
  ('Basset Fauve de Bretagne'),
  ('Basset Hound'),
  ('Bavarian Mountain Hound'),
  ('Beagle'),
  ('Bearded Collie'),
  ('Beauceron'),
  ('Bedlington Terrier'),
  ('Belgian Malinois'),
  ('Belgian Sheepdog'),
  ('Belgian Tervuren'),
  ('Bergamasco Sheepdog'),
  ('Berger Picard'),
  ('Bernese Mountain Dog'),
  ('Bichon Frise'),
  ('Black and Tan Coonhound'),
  ('Black Russian Terrier'),
  ('Bloodhound'),
  ('Blue Lacy'),
  ('Bluetick Coonhound'),
  ('Boerboel'),
  ('Bolognese'),
  ('Border Collie'),
  ('Border Terrier'),
  ('Borzoi'),
  ('Boston Terrier'),
  ('Bouvier des Flandres'),
  ('Boxer'),
  ('Boykin Spaniel'),
  ('Bracco Italiano'),
  ('Briard'),
  ('Brittany'),
  ('Brussels Griffon'),
  ('Bull Terrier'),
  ('Bulldog'),
  ('Bullmastiff'),
  ('Cairn Terrier'),
  ('Canaan Dog'),
  ('Cane Corso'),
  ('Cardigan Welsh Corgi'),
  ('Carolina Dog'),
  ('Catahoula Leopard Dog'),
  ('Caucasian Shepherd Dog'),
  ('Cavalier King Charles Spaniel'),
  ('Central Asian Shepherd Dog'),
  ('Cesky Terrier'),
  ('Chesapeake Bay Retriever'),
  ('Chihuahua'),
  ('Chinese Crested'),
  ('Chinese Shar-Pei'),
  ('Chinook'),
  ('Chow Chow'),
  ('Cirneco dell''Etna'),
  ('Clumber Spaniel'),
  ('Cocker Spaniel'),
  ('Collie'),
  ('Coton de Tulear'),
  ('Curly-Coated Retriever'),
  ('Dachshund'),
  ('Dalmatian'),
  ('Dandie Dinmont Terrier'),
  ('Doberman Pinscher'),
  ('Dogo Argentino'),
  ('Dogue de Bordeaux'),
  ('Dutch Shepherd'),
  ('English Cocker Spaniel'),
  ('English Foxhound'),
  ('English Setter'),
  ('English Springer Spaniel'),
  ('English Toy Spaniel'),
  ('Entlebucher Mountain Dog'),
  ('Estrela Mountain Dog'),
  ('Eurasier'),
  ('Field Spaniel'),
  ('Finnish Lapphund'),
  ('Finnish Spitz'),
  ('Flat-Coated Retriever'),
  ('Fox Terrier (Smooth)'),
  ('Fox Terrier (Wire)'),
  ('French Bulldog'),
  ('German Pinscher'),
  ('German Shepherd'),
  ('German Shorthaired Pointer'),
  ('German Spitz'),
  ('German Wirehaired Pointer'),
  ('Giant Schnauzer'),
  ('Glen of Imaal Terrier'),
  ('Golden Retriever'),
  ('Gordon Setter'),
  ('Grand Basset Griffon Vendéen'),
  ('Great Dane'),
  ('Great Pyrenees'),
  ('Greater Swiss Mountain Dog'),
  ('Greyhound'),
  ('Hamiltonstovare'),
  ('Harrier'),
  ('Havanese'),
  ('Hovawart'),
  ('Ibizan Hound'),
  ('Icelandic Sheepdog'),
  ('Irish Red and White Setter'),
  ('Irish Setter'),
  ('Irish Terrier'),
  ('Irish Water Spaniel'),
  ('Irish Wolfhound'),
  ('Italian Greyhound'),
  ('Jack Russell Terrier'),
  ('Japanese Chin'),
  ('Japanese Spitz'),
  ('Jindo'),
  ('Kai Ken'),
  ('Karelian Bear Dog'),
  ('Keeshond'),
  ('Kerry Blue Terrier'),
  ('Komondor'),
  ('Kooikerhondje'),
  ('Korean Jindo'),
  ('Kuvasz'),
  ('Labrador Retriever'),
  ('Lagotto Romagnolo'),
  ('Lakeland Terrier'),
  ('Lancashire Heeler'),
  ('Leonberger'),
  ('Lhasa Apso'),
  ('Lowchen'),
  ('Maltese'),
  ('Manchester Terrier'),
  ('Mastiff'),
  ('Miniature American Shepherd'),
  ('Miniature Bull Terrier'),
  ('Miniature Pinscher'),
  ('Miniature Schnauzer'),
  ('Mixed Breed'),
  ('Neapolitan Mastiff'),
  ('Newfoundland'),
  ('Norfolk Terrier'),
  ('Norwegian Buhund'),
  ('Norwegian Elkhound'),
  ('Norwegian Lundehund'),
  ('Norwich Terrier'),
  ('Nova Scotia Duck Tolling Retriever'),
  ('Old English Sheepdog'),
  ('Otterhound'),
  ('Papillon'),
  ('Parson Russell Terrier'),
  ('Pekingese'),
  ('Pembroke Welsh Corgi'),
  ('Peruvian Inca Orchid'),
  ('Petit Basset Griffon Vendéen'),
  ('Pharaoh Hound'),
  ('Plott Hound'),
  ('Pointer'),
  ('Polish Lowland Sheepdog'),
  ('Pomeranian'),
  ('Poodle (Miniature)'),
  ('Poodle (Standard)'),
  ('Poodle (Toy)'),
  ('Portuguese Podengo Pequeno'),
  ('Portuguese Water Dog'),
  ('Pug'),
  ('Puli'),
  ('Pumi'),
  ('Pyrenean Mastiff'),
  ('Pyrenean Shepherd'),
  ('Rat Terrier'),
  ('Redbone Coonhound'),
  ('Rhodesian Ridgeback'),
  ('Rottweiler'),
  ('Russian Toy'),
  ('Saint Bernard'),
  ('Saluki'),
  ('Samoyed'),
  ('Schipperke'),
  ('Scottish Deerhound'),
  ('Scottish Terrier'),
  ('Sealyham Terrier'),
  ('Shetland Sheepdog'),
  ('Shiba Inu'),
  ('Shih Tzu'),
  ('Siberian Husky'),
  ('Silky Terrier'),
  ('Skye Terrier'),
  ('Sloughi'),
  ('Small Munsterlander'),
  ('Soft Coated Wheaten Terrier'),
  ('Spanish Mastiff'),
  ('Spanish Water Dog'),
  ('Spinone Italiano'),
  ('Staffordshire Bull Terrier'),
  ('Standard Schnauzer'),
  ('Sussex Spaniel'),
  ('Swedish Vallhund'),
  ('Tibetan Mastiff'),
  ('Tibetan Spaniel'),
  ('Tibetan Terrier'),
  ('Toy Fox Terrier'),
  ('Treeing Walker Coonhound'),
  ('Vizsla'),
  ('Weimaraner'),
  ('Welsh Springer Spaniel'),
  ('Welsh Terrier'),
  ('West Highland White Terrier'),
  ('Whippet'),
  ('Wire Fox Terrier'),
  ('Wirehaired Pointing Griffon'),
  ('Wirehaired Vizsla'),
  ('Xoloitzcuintli'),
  ('Yorkshire Terrier'),
  -- Common cross-breeds
  ('Cockapoo'),
  ('Labradoodle'),
  ('Goldendoodle'),
  ('Cavapoo'),
  ('Puggle'),
  ('Yorkipoo'),
  ('Maltipoo'),
  ('Schnoodle'),
  ('Pomsky'),
  ('Shorkie'),
  ('Morkie'),
  ('Chorkie'),
  ('Aussiedoodle'),
  ('Bernedoodle'),
  ('Sheepadoodle'),
  -- Terrier Mix for existing data
  ('Terrier Mix')
ON CONFLICT (name) DO NOTHING;

-- Migrate existing breed data to new structure
-- First, insert any breeds from dogs table that don't exist yet
INSERT INTO dogadopt.breeds (name)
SELECT DISTINCT breed 
FROM dogadopt.dogs 
WHERE breed NOT IN (SELECT name FROM dogadopt.breeds)
ON CONFLICT (name) DO NOTHING;

-- Create relationships for existing dogs
INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
SELECT d.id, b.id, 1
FROM dogadopt.dogs d
JOIN dogadopt.breeds b ON d.breed = b.name;

-- Grant permissions
GRANT SELECT ON dogadopt.breeds TO anon, authenticated;
GRANT SELECT ON dogadopt.dog_breeds TO anon, authenticated;
