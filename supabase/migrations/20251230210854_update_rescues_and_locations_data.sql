-- Update rescue and location data from dogadopt.github.io
-- Source: https://github.com/dogadopt/dogadopt.github.io/blob/main/rescues.json
-- Generated: 2025-12-30T21:08:54.867Z

-- IMPORTANT: This migration replaces ALL rescue and location data
-- This is safe for initial setup, but if there are existing dogs,
-- their rescue_id references will become invalid.

-- First, clear existing data (keeping audit logs)
-- Note: locations can be safely deleted (has ON DELETE SET NULL for dogs.location_id)
DELETE FROM dogadopt.locations;

-- Temporarily disable the foreign key constraint on dogs.rescue_id to allow deletion
-- This is safe because we're replacing all rescues immediately after
ALTER TABLE dogadopt.dogs DROP CONSTRAINT IF EXISTS dogs_rescue_id_fkey;
DELETE FROM dogadopt.rescues;

-- Re-enable the foreign key constraint
-- Note: We use ON DELETE RESTRICT to prevent accidental rescue deletion in the future
ALTER TABLE dogadopt.dogs 
ADD CONSTRAINT dogs_rescue_id_fkey 
FOREIGN KEY (rescue_id) 
REFERENCES dogadopt.rescues(id) 
ON DELETE RESTRICT;

-- Insert rescues with location data

-- Hope Rescue (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Hope Rescue', 'Full', 'Wales', 'https://www.hoperescue.org.uk/');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Hope Rescue', 'Wales', 'Wales', 51.5683353, -3.4233855, 'https://www.hoperescue.org.uk//Listing/Category/rehoming', 'centre', true
FROM dogadopt.rescues WHERE name = 'Hope Rescue';


-- Dogs Trust Ballymena (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Ballymena', 'Full', 'Northern Ireland', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Ballymena', 'Northern Ireland', 'Northern Ireland', 54.89434429019429, -6.319846642329437, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=BA', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Ballymena';


-- Dogs Trust Basildon (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Basildon', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Basildon', 'England', 'England', 51.59382415776215, 0.4979160552076976, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=ESS', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Basildon';


-- Dogs Trust Bridgend (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Bridgend', 'Full', 'Wales', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Bridgend', 'Wales', 'Wales', 51.5229559, -3.6170128, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=BRI', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Bridgend';


-- Dogs Trust Canterbury (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Canterbury', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Canterbury', 'England', 'England', 51.3311581182853, 1.0665529975239958, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=CANT', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Canterbury';


-- Dogs Trust Cardiff (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Cardiff', 'Full', 'Wales', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Cardiff', 'Wales', 'Wales', 51.472538, -3.154653, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=CWL', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Cardiff';


-- Dogs Trust Cumbria (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Cumbria', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Cumbria', 'England', 'England', 54.74007052390364, -2.7114944087079116, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=PEN', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Cumbria';


-- Dogs Trust Darlington (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Darlington', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Darlington', 'England', 'England', 54.5581299172093, -1.4736975243362862, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=DAR', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Darlington';


-- Dogs Trust Evesham (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Evesham', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Evesham', 'England', 'England', 52.06706403840139, -1.8976944576712451, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=EVE', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Evesham';


-- Dogs Trust Glasgow (Scotland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Glasgow', 'Full', 'Scotland', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Glasgow', 'Scotland', 'Scotland', 55.840651544802014, -4.123991099999999, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=GLA', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Glasgow';


-- Dogs Trust Harefield West London (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Harefield West London', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Harefield West London', 'England', 'England', 51.58115710585518, -0.4695443288356228, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=HAR', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Harefield West London';


-- Dogs Trust Ilfracombe (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Ilfracombe', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Ilfracombe', 'England', 'England', 51.15411866097572, -4.141980209875649, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=ILF', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Ilfracombe';


-- Dogs Trust Kenilworth (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Kenilworth', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Kenilworth', 'England', 'England', 52.34946443522804, -1.6536649865068689, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=KEN', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Kenilworth';


-- Dogs Trust Leeds (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Leeds', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Leeds', 'England', 'England', 53.85209030832631, -1.3785319974301473, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=LE', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Leeds';


-- Dogs Trust Loughborough (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Loughborough', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Loughborough', 'England', 'England', 52.80450426390624, -1.0661442389218843, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=LOU', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Loughborough';


-- Dogs Trust Manchester (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Manchester', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Manchester', 'England', 'England', 53.45396606709549, -2.1325908604906076, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=MAN', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Manchester';


-- Dogs Trust Liverpool (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Liverpool', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Liverpool', 'England', 'England', 53.41506807594241, -2.8171201543426223, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=LIV', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Liverpool';


-- Dogs Trust Newbury (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Newbury', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Newbury', 'England', 'England', 51.385223780970776, -1.4075837638901438, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=NEW', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Newbury';


-- Dogs Trust Salisbury (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Salisbury', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Salisbury', 'England', 'England', 51.16843780090715, -1.704198755595371, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=SAL', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Salisbury';


-- Dogs Trust Shoreham (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Shoreham', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Shoreham', 'England', 'England', 50.83024886674935, -0.28747925310432965, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=SHO', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Shoreham';


-- Dogs Trust Shrewsbury (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Shrewsbury', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Shrewsbury', 'England', 'England', 52.74248069986932, -2.6524257134931317, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=ROD', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Shrewsbury';


-- Dogs Trust Snetterton (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Snetterton', 'Full', 'England', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Snetterton', 'England', 'England', 52.49184420632689, 0.9548198132728437, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=SNET', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Snetterton';


-- Dogs Trust West Calder (Scotland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust West Calder', 'Full', 'Scotland', 'https://www.dogstrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust West Calder', 'Scotland', 'Scotland', 55.838242264410994, -3.561866283266499, 'https://www.dogstrust.org.uk/rehoming/dogs?centres=WC', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust West Calder';


-- All Creatures Great and Small (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('All Creatures Great and Small', 'Full', 'Wales', 'https://www.allcreaturesgreatandsmall.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'All Creatures Great and Small', 'Wales', 'Wales', 51.64143515501649, -2.9833928370567944, 'https://www.allcreaturesgreatandsmall.org.uk/rehoming/rehome-a-dog', 'centre', true
FROM dogadopt.rescues WHERE name = 'All Creatures Great and Small';


-- Blue Cross Devon (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Devon', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Devon', 'England', 'England', 50.69718793016154, -3.520393002629656, 'https://www.bluecross.org.uk/rehome/dog?Location=Devon:%20Exeter%20rehoming,%20advice%20and%20behaviour%20unit', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Devon';


-- Blue Cross Hampshire (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Hampshire', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Hampshire', 'England', 'England', 50.94122669302236, -1.2981374121965266, 'https://www.bluecross.org.uk/rehome/dog?Location=Hampshire:%20Southampton%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Hampshire';


-- Blue Cross Hertfordshire (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Hertfordshire', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Hertfordshire', 'England', 'England', 51.84419194100218, -0.3203479267950048, 'https://www.bluecross.org.uk/rehome/dog?Location=Hertfordshire%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Hertfordshire';


-- Blue Cross South Wales (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross South Wales', 'Full', 'Wales', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross South Wales', 'Wales', 'Wales', 51.584123441801914, -2.9780051901218263, 'https://www.bluecross.org.uk/rehome/dog?Location=South%20Wales:%20Newport%20rehoming,%20advice%20and%20behaviour%20unit', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross South Wales';


-- Blue Cross Oxfordshire (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Oxfordshire', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Oxfordshire', 'England', 'England', 51.78816443788282, -1.6185645699904763, 'https://www.bluecross.org.uk/rehome/dog?Location=Oxfordshire:%20Burford%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Oxfordshire';


-- Blue Cross South Yorkshire (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross South Yorkshire', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross South Yorkshire', 'England', 'England', 53.34596518213209, -1.4944702718186182, 'https://www.bluecross.org.uk/rehome/dog?Location=South%20Yorkshire:%20Sheffield%20rehoming,%20advice%20and%20behaviour%20unit', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross South Yorkshire';


-- Blue Cross Suffolk (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Suffolk', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Suffolk', 'England', 'England', 52.025919652569634, 1.142073512074519, 'https://www.bluecross.org.uk/rehome/dog?Location=Suffolk%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Suffolk';


-- Blue Cross West Midlands (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross West Midlands', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross West Midlands', 'England', 'England', 52.374296291332236, -2.0546579417654325, 'https://www.bluecross.org.uk/rehome/dog?Location=West%20Midlands:%20Bromsgrove%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross West Midlands';


-- Blue Cross Yorkshire (England)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Blue Cross Yorkshire', 'Full', 'England', 'https://www.bluecross.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Blue Cross Yorkshire', 'England', 'England', 54.194765936991736, -1.4029836269867608, 'https://www.bluecross.org.uk/rehome/dog?Location=Yorkshire:%20Thirsk%20rehoming%20centre', 'centre', true
FROM dogadopt.rescues WHERE name = 'Blue Cross Yorkshire';


-- RSPCA Newport (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('RSPCA Newport', 'Full', 'Wales', 'https://www.rspca.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'RSPCA Newport', 'Wales', 'Wales', 51.587741, -2.998343, NULL, 'centre', true
FROM dogadopt.rescues WHERE name = 'RSPCA Newport';


-- Greyhound Welfare and Rescue Newport (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Greyhound Welfare and Rescue Newport', 'Full', 'Wales', 'https://swwgreyhounds.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Greyhound Welfare and Rescue Newport', 'Wales', 'Wales', 51.582104, -3.01743, 'https://swwgreyhounds.org.uk/homing', 'centre', true
FROM dogadopt.rescues WHERE name = 'Greyhound Welfare and Rescue Newport';


-- Porthcawl Animal Welfare Society (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Porthcawl Animal Welfare Society', 'Full', 'Wales', 'https://pawsporthcawl.wixsite.com/paws');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Porthcawl Animal Welfare Society', 'Wales', 'Wales', 51.484406, -3.703249, 'https://pawsporthcawl.wixsite.com/paws/dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Porthcawl Animal Welfare Society';


-- German Shepherd Rescue & Rehome West Glamorgan (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('German Shepherd Rescue & Rehome West Glamorgan', 'Full', 'Wales', 'https://www.gsd2000.com');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'German Shepherd Rescue & Rehome West Glamorgan', 'Wales', 'Wales', 51.61922, -3.945828, 'https://www.gsd2000.com/dogs-for-adoption', 'centre', true
FROM dogadopt.rescues WHERE name = 'German Shepherd Rescue & Rehome West Glamorgan';


-- Greyhound Trust – West Wales (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Greyhound Trust – West Wales', 'Full', 'Wales', 'https://www.greyhoundtrust.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Greyhound Trust – West Wales', 'Wales', 'Wales', 51.678073, -4.712498, 'https://www.greyhoundtrust.org.uk/home-a-greyhound?siteid=68', 'centre', true
FROM dogadopt.rescues WHERE name = 'Greyhound Trust – West Wales';


-- Greyhound Rescue Wales – Hillcrest Centre (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Greyhound Rescue Wales – Hillcrest Centre', 'Full', 'Wales', 'https://greyhoundrescueWales.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Greyhound Rescue Wales – Hillcrest Centre', 'Wales', 'Wales', 51.713755, -3.342751, 'https://greyhoundrescueWales.co.uk/adopt', 'centre', true
FROM dogadopt.rescues WHERE name = 'Greyhound Rescue Wales – Hillcrest Centre';


-- Greenacres Rescue Pembrokeshire (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Greenacres Rescue Pembrokeshire', 'Full', 'Wales', 'https://www.greenacresrescue.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Greenacres Rescue Pembrokeshire', 'Wales', 'Wales', 51.82693, -4.975693, 'https://www.greenacresrescue.org.uk/find-a-pet/dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Greenacres Rescue Pembrokeshire';


-- Freshfields Animal Rescue – Wales (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Freshfields Animal Rescue – Wales', 'Full', 'Wales', 'https://www.freshfields.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Freshfields Animal Rescue – Wales', 'Wales', 'Wales', 53.293873, -3.051279, 'https://www.freshfields.org.uk/freshfields-residents', 'centre', true
FROM dogadopt.rescues WHERE name = 'Freshfields Animal Rescue – Wales';


-- RSPCA – Bryn-y-Maen (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('RSPCA – Bryn-y-Maen', 'Full', 'Wales', 'https://www.rspca.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'RSPCA – Bryn-y-Maen', 'Wales', 'Wales', 53.274754, -3.818303, NULL, 'centre', true
FROM dogadopt.rescues WHERE name = 'RSPCA – Bryn-y-Maen';


-- North Clwyd Animal Rescue (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('North Clwyd Animal Rescue', 'Full', 'Wales', 'https://www.ncar.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'North Clwyd Animal Rescue', 'Wales', 'Wales', 53.176625, -3.142241, 'https://www.ncar.org.uk/animal_categories/dogs/', 'centre', true
FROM dogadopt.rescues WHERE name = 'North Clwyd Animal Rescue';


-- Rottweiler Welfare Wrexham (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Rottweiler Welfare Wrexham', 'Full', 'Wales', 'https://www.rottweilerwelfare.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Rottweiler Welfare Wrexham', 'Wales', 'Wales', 53.050184, -3.001923, 'https://www.rottweilerwelfare.co.uk/our-dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Rottweiler Welfare Wrexham';


-- Cardiff Dogs Home (Wales)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Cardiff Dogs Home', 'Full', 'Wales', 'https://www.cardiffdogshome.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Cardiff Dogs Home', 'Wales', 'Wales', 51.488585, -3.169084, 'https://www.cardiffdogshome.co.uk/give-a-dog-a-home/dogs-available-for-rehoming', 'centre', true
FROM dogadopt.rescues WHERE name = 'Cardiff Dogs Home';


-- Benvardin Animal Rescue Kennels (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Benvardin Animal Rescue Kennels', 'Full', 'Northern Ireland', 'https://benvardinkennels.com');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Benvardin Animal Rescue Kennels', 'Northern Ireland', 'Northern Ireland', 55.1423832946954, -6.5083271272516035, 'https://benvardinkennels.com/', 'centre', true
FROM dogadopt.rescues WHERE name = 'Benvardin Animal Rescue Kennels';


-- Causeway Coast Dog Rescue (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Causeway Coast Dog Rescue', 'Full', 'Northern Ireland', 'https://causewaycoastdogrescue.org');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Causeway Coast Dog Rescue', 'Northern Ireland', 'Northern Ireland', 55.13260582557945, -6.6658603369137195, 'https://causewaycoastdogrescue.org/dogs-for-rehoming', 'centre', true
FROM dogadopt.rescues WHERE name = 'Causeway Coast Dog Rescue';


-- Clare Animal Welfare CLG (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Clare Animal Welfare CLG', 'Full', 'Ireland', 'https://www.clareanimalwelfare.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Clare Animal Welfare CLG', 'Ireland', 'Ireland', 52.8474208530384, -8.988752072490978, 'https://www.clareanimalwelfare.ie/our-dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Clare Animal Welfare CLG';


-- PAWS Animal Rescue (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('PAWS Animal Rescue', 'Full', 'Ireland', 'https://www.paws.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'PAWS Animal Rescue', 'Ireland', 'Ireland', 52.51086657687802, -7.4587952536375575, 'https://www.paws.ie/adopt-a-dog', 'centre', true
FROM dogadopt.rescues WHERE name = 'PAWS Animal Rescue';


-- Galway SPCA (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Galway SPCA', 'Full', 'Ireland', 'https://www.gspca.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Galway SPCA', 'Ireland', 'Ireland', 53.14440139972886, -8.2677861959272, 'https://www.gspca.ie/rehoming/dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Galway SPCA';


-- Dogs Trust Ireland (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Dogs Trust Ireland', 'Full', 'Ireland', 'https://www.dogstrust.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Dogs Trust Ireland', 'Ireland', 'Ireland', 53.4141094466885, -6.319405314133566, 'https://www.dogstrust.ie/rehoming/dogs?county=All', 'centre', true
FROM dogadopt.rescues WHERE name = 'Dogs Trust Ireland';


-- MADRA Rescue (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('MADRA Rescue', 'Full', 'Ireland', 'https://www.madra.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'MADRA Rescue', 'Ireland', 'Ireland', 53.33276569667293, -9.55779431797975, 'https://www.madra.ie/dog-profiles', 'centre', true
FROM dogadopt.rescues WHERE name = 'MADRA Rescue';


-- Mayo SPCA (Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Mayo SPCA', 'Full', 'Ireland', 'https://mayospca.ie');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Mayo SPCA', 'Ireland', 'Ireland', 53.74964886887303, -8.800114390686645, 'https://mayospca.ie/category/dogs/', 'centre', true
FROM dogadopt.rescues WHERE name = 'Mayo SPCA';


-- Rainbow Rehoming Centre (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Rainbow Rehoming Centre', 'Full', 'Northern Ireland', 'https://www.rainbowrehoming.com');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Rainbow Rehoming Centre', 'Northern Ireland', 'Northern Ireland', 55.032873762967874, -7.165914319726115, 'https://www.rainbowrehoming.com/rehome/dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'Rainbow Rehoming Centre';


-- Grovehill Animal Trust (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Grovehill Animal Trust', 'Full', 'Northern Ireland', 'https://grovehillanimaltrust.org');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Grovehill Animal Trust - Location 1', 'Northern Ireland', 'Northern Ireland', 54.60724252744901, -7.3045544503179, 'https://grovehillanimaltrust.orgrehoming/dog-rehoming-process/', 'centre', true
FROM dogadopt.rescues WHERE name = 'Grovehill Animal Trust';

INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Grovehill Animal Trust - Location 2', 'Northern Ireland', 'Northern Ireland', 54.60724252744901, -7.3045544503179, 'https://grovehillanimaltrust.orgrehoming/dog-rehoming-process/', 'centre', true
FROM dogadopt.rescues WHERE name = 'Grovehill Animal Trust';


-- USPCA (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('USPCA', 'Full', 'Northern Ireland', 'https://www.uspca.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'USPCA', 'Northern Ireland', 'Northern Ireland', 54.20142797056085, -6.343896749747796, 'https://www.uspca.co.uk/animals-available-for-rehoming', 'centre', true
FROM dogadopt.rescues WHERE name = 'USPCA';


-- Mid Antrim Animal Sanctuary (Northern Ireland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Mid Antrim Animal Sanctuary', 'Full', 'Northern Ireland', 'https://www.assisi-ni.org');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Mid Antrim Animal Sanctuary', 'Northern Ireland', 'Northern Ireland', 54.62641683950719, -5.677465333766653, 'https://www.assisi-ni.org/adopt', 'centre', true
FROM dogadopt.rescues WHERE name = 'Mid Antrim Animal Sanctuary';


-- ManxSCPA (Isle of Man)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('ManxSCPA', 'Full', 'Isle of Man', 'https://www.manxspca.com');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'ManxSCPA', 'Isle of Man', 'Isle of Man', 54.17015230120721, -4.617847273748266, 'https://www.manxspca.com/pet_taxonomy/dogs', 'centre', true
FROM dogadopt.rescues WHERE name = 'ManxSCPA';


-- Boxer Welfare Scotland (Scotland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Boxer Welfare Scotland', 'Full', 'Scotland', 'https://www.boxerwelfarescotland.org.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Boxer Welfare Scotland', 'Scotland', 'Scotland', 57.436291, -1.82941, NULL, 'centre', true
FROM dogadopt.rescues WHERE name = 'Boxer Welfare Scotland';


-- Airdale Terrier Club of Scotland (Scotland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Airdale Terrier Club of Scotland', 'Full', 'Scotland', 'https://www.airedale-terrier-club-of-scotland.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Airdale Terrier Club of Scotland', 'Scotland', 'Scotland', 55.833511, -4.426281, NULL, 'centre', true
FROM dogadopt.rescues WHERE name = 'Airdale Terrier Club of Scotland';


-- Scottish Staffordshire Bull Terrier Rescue (Scotland)
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
  ('Scottish Staffordshire Bull Terrier Rescue', 'Full', 'Scotland', 'https://staffierescuescotland.co.uk');
INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)
SELECT id, 'Scottish Staffordshire Bull Terrier Rescue', 'Scotland', 'Scotland', 55.833511, -4.426281, NULL, 'centre', true
FROM dogadopt.rescues WHERE name = 'Scottish Staffordshire Bull Terrier Rescue';


-- Migration complete!
-- Total rescues inserted: 61
-- Total locations inserted: 62
-- WARNING: Existing dog records will need their rescue_id updated to match new rescue IDs
