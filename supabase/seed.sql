-- Seed file for reference data and development samples
-- This file can be run with `supabase db reset` or `supabase db seed`
-- It is safe to run multiple times as it uses UPSERT logic

-- ========================================
-- RESCUES AND LOCATIONS REFERENCE DATA
-- ========================================
-- This section syncs rescue organization data from ADCH (Association of Dogs and Cats Homes)
-- Data source: https://adch.org.uk/wp-content/uploads/2025/09/Editable-Members-List-with-regions-01102025.pdf
-- Only updates records when there are actual differences to minimize audit log noise

-- Merge rescues: Insert new, update changed, and delete removed ones
-- Using CTE to ensure data is available in the same transaction
WITH temp_rescues AS (
  SELECT name, type, region, website FROM (VALUES
('Aireworth Dogs in Need', 'Full', 'Yorkshire & The Humber', 'www.areworthdogsinneed.co.uk'),
('Akita Rescue & Welfare Trust (UK)', 'Full', 'South East England', 'www.akitarescue.org.uk'),
('All Creatures Great & Small', 'Full', 'South Wales', 'www.allcreaturesgreatandsmall.org.uk'),
('All Dogs Matter', 'Full', 'London', 'www.alldogsmatter.co.uk'),
('Animal Care - Lancaster Morecambe & District', 'Full', 'North West England', 'www.animalcare-lancaster.co.uk'),
('Animal Concern Cumbria', 'Full', 'North West England', 'www.animalconcerncumbria.org'),
('Animal Rescue Cumbria', 'Full', 'North West England', 'www.animalrescuecumbria.co.uk'),
('Animal Support Angels', 'Full', 'East England', 'www.animalsupportangels.com'),
('Animal Welfare Furness', 'Full', 'North West England', 'www.animals-in-need.org'),
('Animals in Need Northants', 'Full', 'East Midlands', 'www.animalsinneed.uk'),
('Ashbourne Animal Welfare', 'Full', 'East Midlands', 'www.ashbourneanimalwelfare.org'),
('Balto''s Dog Rescue', 'Full', 'National', 'www.baltosdogrescue.uk'),
('Bath Cats and Dogs Home', 'Full', 'South West England', 'www.bcdh.org.uk'),
('Battersea', 'Full', 'London', 'www.battersea.org.uk'),
('Benvardin Animal Rescue Kennels', 'Full', 'Northern Ireland', 'www.benvardinkennels.com'),
('Berwick Animal Rescue Kennels', 'Full', 'North East England', 'www.b-a-r-k.co.uk'),
('Birmingham Dogs Home', 'Full', 'West Midlands', 'www.birminghamdogshome.org.uk'),
('Bleakholt Animal Sanctuary', 'Full', 'North West England', 'www.bleakholt.org'),
('Blue Cross', 'Full', 'National', 'www.bluecross.org.uk'),
('Border Collie Trust GB', 'Full', 'West Midlands', 'www.bordercollietrust.org.uk'),
('Borders Pet Rescue', 'Full', 'Scottish Borders', 'www.borderspetrescue.org'),
('Boxer Welfare Scotland', 'Full', 'Aberdeen & Grampian', 'www.boxerwelfarescotland.org.uk'),
('Bristol Animal Rescue Centre', 'Full', 'South West England', 'www.bristolarc.org.uk'),
('Bristol Dog Action Welfare Group', 'Full', 'South West England', 'www.dawg.org.uk'),
('Bulldog Rescue & Re-homing Trust', 'Full', 'South East England', 'www.bulldogrescue.co.uk'),
('Carla Lane Animals In Need', 'Full', 'North West England', 'www.carlalaneanimalsinneed.co.uk'),
('Causeway Coast Dog Rescue', 'Full', 'Northern Ireland', 'www.causewaycoastdogrescue.org'),
('Cheltenham Animal Shelter', 'Full', 'South West England', 'www.gawa.org.uk'),
('Chilterns Dog Rescue Society', 'Full', 'East England', 'www.chilternsdogrescue.org.uk'),
('Dog Aid Society Scotland', 'Full', 'Scotland', 'www.dogaidsociety.com'),
('Dogs Trust', 'Full', 'National', 'www.dogstrust.org.uk'),
('Dogs Trust Ireland', 'Full', 'Ireland', 'www.dogstrust.ie'),
('Dumfries & Galloway Canine Rescue Centre', 'Full', 'Dumfries & Galloway', 'www.caninerescue.co.uk'),
('Durham Dogs and Cats Home', 'Full', 'North East England', 'www.durhamdogsandcats.uk'),
('Eden Animal Rescue', 'Full', 'North West England', 'www.edenanimalrescue.org.uk'),
('Edinburgh Dog & Cat Home', 'Full', 'Edinburgh & the Lothians', 'www.edch.org.uk'),
('Fen Bank Greyhound Sanctuary', 'Full', 'East England', 'www.fenbankgreyhounds.co.uk'),
('Ferne Animal Sanctuary', 'Full', 'South West England', 'www.ferneanimalsanctuary.org'),
('Foal Farm Animal Rescue', 'Full', 'South East England', 'www.foalfarm.org.uk'),
('Forest Dog Rescue', 'Full', 'West Midlands', 'www.forest-dog-rescue.org.uk'),
('Forever Hounds Trust', 'Full', 'South East England', 'www.foreverhoundstrust.org'),
('Freshfields Animal Rescue', 'Full', 'North West England', 'www.freshfields.org.uk'),
('Friends of Akitas Trust UK', 'Full', 'East Midlands', 'www.friendsofakitas.co.uk'),
('Gables Dogs & Cats Home', 'Full', 'South West England', 'www.gablesfarm.org.uk'),
('Garbos German Shepherd Dog Rescue', 'Full', 'South East England', 'www.garbosgsdrescue.co.uk'),
('German Shepherd Rescue Elite', 'Full', 'South East England', 'www.gsrelite.co.uk'),
('German Shepherd Rescue South', 'Full', 'South East England', 'www.german-shepherd-rescue-hampshire.org.uk'),
('German Shorthaired Pointer Rescue UK', 'Full', 'South Wales', 'www.gsprescue-uk.org.uk'),
('Greenacres Rescue', 'Full', 'South Wales', 'www.greenacresrescue.org.uk'),
('Greyhound Gap', 'Full', 'West Midlands', 'www.greyhoundgap.org.uk'),
('Greyhound Rescue Wales', 'Full', 'Mid Wales', 'www.greyhoundrescuewales.co.uk'),
('The Greyhound Trust', 'Full', 'National', 'www.greyhoundtrust.org.uk'),
('Greyhound Welfare South Wales', 'Full', 'South Wales', 'www.facebook.com/GreyhoundWelfareSouthWales'),
('Grovehill Animal Trust', 'Full', 'Northern Ireland', 'www.grovehillanimaltrust.org'),
('Happy Landings Animal Shelter', 'Full', 'South West England', 'www.happy-landings.org.uk'),
('Happy Staffie Rescue', 'Full', 'West Midlands', 'www.happystaffie.co.uk'),
('Holly Hedge Animal Sanctuary', 'Full', 'South West England', 'www.hollyhedge.org.uk'),
('Hope Rescue', 'Full', 'South Wales', 'www.hoperescue.org.uk'),
('Jerry Green Dog Rescue', 'Full', 'East Midlands', 'www.jerrygreendogs.org.uk'),
('Just Springers Rescue', 'Full', 'South East England', 'www.justspringersrescue.co.uk'),
('K9 Focus', 'Full', 'South West England', 'www.k9focus.co.uk'),
('Keith''s Rescue Dogs', 'Full', 'East Midlands', 'www.keithsrescuedogs.co.uk'),
('Labrador Lifeline Trust', 'Full', 'South East England', 'www.labrador-lifeline.com'),
('Labrador Rescue Trust', 'Full', 'South West England', 'www.labrador-rescue.com'),
('Last Chance Animal Rescue', 'Full', 'South East England', 'www.lastchanceanimalrescue.co.uk'),
('Leicester Animal Aid', 'Full', 'East Midlands', 'www.leicesteranimalaid.org.uk'),
('Lord Whisky Sanctuary Fund', 'Full', 'South East England', 'www.lordwhisky.co.uk'),
('MADRA', 'Full', 'Ireland', 'www.madra.ie'),
('Manchester & District Home For Lost Dogs', 'Full', 'North West England', 'www.dogshome.net'),
('Margaret Green Animal Rescue', 'Full', 'South West England', 'www.margaretgreenanimalrescue.org.uk'),
('Maxi''s Mates', 'Full', 'Yorkshire & The Humber', 'www.maxismates.org.uk'),
('Mayflower Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.mayflowersanctuary.co.uk'),
('The Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org'),
('Mid Antrim Animal Sanctuary', 'Full', 'Northern Ireland', 'www.midantrim.org'),
('Mrs Murrays Home for Stray Dogs and Cats', 'Full', 'Aberdeen & Grampian', 'www.mrsmurrays.co.uk'),
('National Animal Welfare Trust', 'Full', 'National', 'www.nawt.org.uk'),
('Newcastle Dog & Cat Shelter', 'Full', 'North East England', 'www.dogscatshelter.co.uk'),
('Norfolk Greyhound Welfare', 'Full', 'East England', 'www.norfolkgreyhoundwelfare.co.uk'),
('North Clwyd Animal Rescue', 'Full', 'North Wales', 'www.ncar.co.uk'),
('North Lincolnshire Greyhound Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.nlgs.org.uk'),
('Oak Tree Animals'' Charity', 'Full', 'South West England', 'www.oaktreeanimals.org.uk'),
('Old Windsor Safari Park', 'Full', 'South East England', 'www.windsorgreatpark.co.uk'),
('Oldies Club', 'Full', 'National', 'www.oldies.org.uk'),
('Paws Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.pawsanimalsanctuary.co.uk'),
('Pennine Pen Animal Rescue', 'Full', 'Yorkshire & The Humber', 'www.penninepen.org.uk'),
('Pointer Rescue Service', 'Full', 'National', 'www.pointer-rescue.co.uk'),
('Preston & District RSPCA', 'Full', 'North West England', 'www.rspca-preston.org.uk'),
('Redwings Horse Sanctuary', 'Full', 'East England', 'www.redwings.org.uk'),
('Retired Greyhound Trust', 'Full', 'South East England', 'www.retiredgreyhounds.co.uk'),
('Rochdale Dog Rescue', 'Full', 'North West England', 'www.rochdaledog.rescue.org.uk'),
('Scottish SPCA', 'Full', 'Scotland', 'www.scottishspca.org'),
('Scruples & Wellies Animal Rescue', 'Full', 'South West England', 'www.scruplesandwellies.org'),
('Setter Rescue Scotland', 'Full', 'Scotland', 'www.setterrescuescotland.co.uk'),
('Severn Edge Vets Charity', 'Full', 'West Midlands', 'www.severnedgevets.co.uk'),
('Shropshire Cat Rescue', 'Full', 'West Midlands', 'www.shropshirecatrescue.org.uk'),
('Staffie Smiles', 'Full', 'West Midlands', 'www.staffiesmiles.com'),
('The Surrey Border Collie & Sheepdog Welfare Society', 'Full', 'South East England', 'www.bordercolliewelfare.org'),
('Underheugh Animal Sanctuary', 'Full', 'North East England', 'www.underheugh.co.uk'),
('Viva Rescue', 'Full', 'West Midlands', 'www.vivarescue.org.uk'),
('West London Dog Rescue', 'Full', 'London', 'www.wldr.org'),
('Westmorland Animal Sanctuary', 'Full', 'North West England', 'www.westmorlandanimalsanctuary.org.uk'),
('Wild at Heart Foundation', 'Full', 'National', 'www.wildatheartfoundation.org'),
('Woodgreen The Animals Charity', 'Full', 'East England', 'www.woodgreen.org.uk'),
('Yorkshire Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.yorkshireanimalsanctuary.co.uk'),
('Yorkshire Coast Dog Rescue', 'Full', 'Yorkshire & The Humber', 'www.yorkshirecoastdogrescue.co.uk')
  ) AS t(name, type, region, website)
)
MERGE INTO dogadopt.rescues AS target
USING temp_rescues AS source
ON target.name = source.name
WHEN MATCHED AND (
  target.type IS DISTINCT FROM source.type OR
  target.region IS DISTINCT FROM source.region OR
  target.website IS DISTINCT FROM source.website
) THEN
  UPDATE SET
    type = source.type,
    region = source.region,
    website = source.website
WHEN NOT MATCHED THEN
  INSERT (name, type, region, website)
  VALUES (source.name, source.type, source.region, source.website)
WHEN NOT MATCHED BY SOURCE THEN
  DELETE;

-- Sync default locations for rescues that don't have any locations yet
INSERT INTO dogadopt.locations (rescue_id, name, city, region, location_type, is_public)
SELECT 
  r.id,
  r.name || ' - ' || r.region,
  COALESCE(
    CASE 
      WHEN r.region LIKE '%London%' THEN 'London'
      WHEN r.region LIKE '%Edinburgh%' THEN 'Edinburgh'
      WHEN r.region LIKE '%Cardiff%' THEN 'Cardiff'
      WHEN r.region LIKE '%Belfast%' THEN 'Belfast'
      WHEN r.region LIKE '%Birmingham%' THEN 'Birmingham'
      WHEN r.region LIKE '%Manchester%' THEN 'Manchester'
      WHEN r.region LIKE '%Leeds%' THEN 'Leeds'
      WHEN r.region LIKE '%Bristol%' THEN 'Bristol'
      ELSE SPLIT_PART(r.region, ' ', 1)
    END,
    r.region
  ),
  r.region,
  'centre',
  true
FROM dogadopt.rescues r
WHERE NOT EXISTS (
  SELECT 1 
  FROM dogadopt.locations l 
  WHERE l.rescue_id = r.id
);

-- ========================================
-- DEVELOPMENT SAMPLE DATA
-- ========================================
-- Only insert sample dogs in local development environment
-- Production deployments should skip this section

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

DO $$
BEGIN
  -- Only insert sample dogs if this is a local development environment
  -- Check if we're running locally by looking for the default anon key
  IF current_setting('app.settings.jwt_secret', true) = 'super-secret-jwt-token-with-at-least-32-characters-long' THEN
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
    
    RAISE NOTICE 'Sample dogs inserted for development environment';
  ELSE
    RAISE NOTICE 'Skipping sample dogs - not in development environment';
  END IF;
END $$;

