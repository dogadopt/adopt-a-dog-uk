-- Rescues and Locations
-- Rescue organizations, physical locations (centres, foster homes), and related data

-- Create rescues table
CREATE TABLE dogadopt.rescues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'Full',
  region TEXT NOT NULL,
  website TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on rescues
ALTER TABLE dogadopt.rescues ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rescues (publicly viewable, admins can manage)
CREATE POLICY "Rescues are publicly viewable" 
ON dogadopt.rescues FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage rescues"
ON dogadopt.rescues FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Insert ADCH member rescue organizations
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
('Aireworth Dogs in Need', 'Full', 'Yorkshire & The Humber', 'www.areworthdogsinneed.co.uk'),
('Akita Rescue & Welfare Trust (UK)', 'Full', 'South East England', 'www.akitarescue.org.uk'),
('All Creatures Great & Small', 'Full', 'South Wales', 'www.allcreaturesgreatandsmall.org.uk'),
('All Dogs Matter', 'Full', 'London', 'www.alldogsmatter.co.uk'),
('Animal Care - Lancaster, Morecambe & District', 'Full', 'North West England', 'www.animalcare-lancaster.co.uk'),
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
('Greyhound Trust', 'Full', 'South East England', 'www.greyhoundtrust.org.uk'),
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
('Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org'),
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
('SSPCA', 'Full', 'Scotland', 'www.scottishspca.org'),
('Staffie Smiles', 'Full', 'West Midlands', 'www.staffiesmiles.com'),
('The Greyhound Trust', 'Full', 'National', 'www.greyhoundtrust.org.uk'),
('The Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org'),
('The Surrey Border Collie & Sheepdog Welfare Society', 'Full', 'South East England', 'www.bordercolliewelfare.org'),
('Underheugh Animal Sanctuary', 'Full', 'North East England', 'www.underheugh.co.uk'),
('Viva Rescue', 'Full', 'West Midlands', 'www.vivarescue.org.uk'),
('West London Dog Rescue', 'Full', 'London', 'www.wldr.org'),
('Westmorland Animal Sanctuary', 'Full', 'North West England', 'www.westmorlandanimalsanctuary.org.uk'),
('Wild at Heart Foundation', 'Full', 'National', 'www.wildatheartfoundation.org'),
('Woodgreen, The Animals Charity', 'Full', 'East England', 'www.woodgreen.org.uk'),
('Yorkshire Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.yorkshireanimalsanctuary.co.uk'),
('Yorkshire Coast Dog Rescue', 'Full', 'Yorkshire & The Humber', 'www.yorkshirecoastdogrescue.co.uk');

-- Create location_type enum
CREATE TYPE dogadopt.location_type AS ENUM ('centre', 'foster_home', 'office', 'other');

-- Create locations table
CREATE TABLE dogadopt.locations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  rescue_id UUID NOT NULL REFERENCES dogadopt.rescues(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location_type dogadopt.location_type NOT NULL DEFAULT 'centre',
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT NOT NULL,
  county TEXT,
  postcode TEXT,
  region TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  phone TEXT,
  email TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  enquiry_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_locations_rescue_id ON dogadopt.locations(rescue_id);

-- Enable RLS on locations
ALTER TABLE dogadopt.locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations
CREATE POLICY "Locations are publicly viewable"
ON dogadopt.locations FOR SELECT
USING (true);

CREATE POLICY "Admins can manage locations"
ON dogadopt.locations FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- Create a default location for each rescue
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
FROM dogadopt.rescues r;

-- Grant permissions
GRANT SELECT ON dogadopt.rescues TO anon, authenticated;
GRANT ALL ON dogadopt.rescues TO authenticated;
GRANT SELECT ON dogadopt.locations TO anon, authenticated;

-- Add documentation comments
COMMENT ON TABLE dogadopt.locations IS 'Physical locations for rescues - supports centres, foster homes, and other locations with privacy controls';
COMMENT ON COLUMN dogadopt.locations.is_public IS 'If true, show full address details. If false, show only city/region for privacy (e.g., foster homes)';
