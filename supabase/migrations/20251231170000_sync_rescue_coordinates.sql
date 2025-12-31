-- Sync rescue coordinates from geocoding
-- This migration updates all rescue records with their geocoded coordinates
-- Data source: postcodes.io API via geocode-rescues.js script
-- Date: 2025-12-31

-- Update rescue records with geocoded coordinates
-- Using MERGE to safely update existing records without creating duplicates

WITH temp_rescue_updates AS (
  SELECT name, latitude, longitude FROM (VALUES
    ('Dog Aid Society Scotland', 55.911235, -3.312793),
    ('Woodgreen Pets Charity', 52.29931, -0.150593),
    ('Band of Rescuers North Yorkshire', 54.019797, -1.072647),
    ('Pawprints Dog Rescue', 52.4451, -1.341339),
    ('PAWS Animal Rescue', 51.088451, -1.073359),
    ('People for Animal Care Trust (PACT)', 52.592805, 0.932802),
    ('Phoenix French Bulldog Rescue', 52.109991, -0.439773),
    ('Pro Dogs Direct', 51.252058, -0.771368),
    ('Rain Rescue', 53.40801, -1.272467),
    ('Raystede Centre for Animal Welfare', 50.909231, 0.103918),
    ('Rescue Me Animal Sanctuary', 53.505849, -2.901195),
    ('Rottweiler Welfare Association', 53.048909, -3.000085),
    ('RSPCA', 51.311841, 1.154045),
    ('RSPCA Brighton & The Heart of Sussex', 50.870618, -0.158216),
    ('RSPCA Canterbury and District Branch', 51.311841, 1.154045),
    ('RSPCA Chesterfield and North Derbyshire Branch', 53.227504, -1.40901),
    ('RSPCA Cornwall', 50.42133, -4.92287),
    ('RSPCA Coventry and District Branch', 52.436512, -1.552538),
    ('RSPCA Kent Isle of Thanet Branch', 51.356814, 1.346566),
    ('RSPCA Lancashire East Branch', 53.771064, -2.350013),
    ('RSPCA Leeds, Wakefield & District Branch', 53.7316, -1.543017),
    ('RSPCA Llys Nini Branch', 51.677291, -4.012386),
    ('RSPCA Norwich', 52.534638, 1.169888),
    ('RSPCA Radcliffe Animal Shelter Trust', 52.943877, -1.05181),
    ('RSPCA Sheffield Branch', 53.388145, -1.433673),
    ('RSPCA Southport, Ormskirk & District Branch', 53.614018, -3.007134),
    ('RSPCA Sussex East and Hastings Branch', 50.885145, 0.590488),
    ('RSPCA Warrington, Halton and St Helens Branch', 53.385169, -2.602276),
    ('RSPCA Westmorland Branch', 54.33271, -2.744842),
    ('Saints Sled Dog Rescue', 54.689618, -1.472328),
    ('Second Chance Akita Rescue', 52.467615, -2.092657),
    ('Senior Staffy Club', 51.861614, -2.221328),
    ('Society for Abandoned Animals', 53.435986, -2.309712),
    ('Southern Golden Retriever Rescue', 51.39691, 0.45886),
    ('Spaniel Aid CIO', 52.131642, -1.001635),
    ('Spirit of the Dog Rescue', 51.759802, 0.546291),
    ('St Francis Dogs Home', 50.428109, -5.053223),
    ('Staffie and Stray Rescue', 50.806312, -1.868951),
    ('Stokenchurch Dog Rescue', 51.662231, -0.914545),
    ('Tails Animal Welfare', 53.390025, -2.952624),
    ('Team Poundie', 52.706498, -2.52908),
    ('Teckels Animal Sanctuaries', 51.776013, -2.321208),
    ('The Animal House Rescue', 52.429327, -2.006877),
    ('The Cat Welfare Group', 50.981795, -1.383518),
    ('The Mutts Nutts Rescue', 52.658307, -0.49222),
    ('The Kennel Club', 51.506403, -0.14424),
    ('Thornberry Animal Sanctuary', 53.370928, -1.234412),
    ('Three Counties Dog Rescue', 52.771605, -0.309371),
    ('UK Spaniel Rescue', 53.752267, -2.869745),
    ('Warrington Animal Welfare', 53.385169, -2.602276),
    ('West Yorkshire Dog Rescue', 53.599993, -1.921174),
    ('Wirral Animal Welfare Association', 53.372367, -3.046397),
    ('Woodlands Animal Sanctuary', 53.639754, -2.845513),
    ('Worcestershire Animal Rescue Shelter', 52.145169, -2.279915),
    ('Wythall Animal Sanctuary', 52.385867, -1.904666)
  ) AS t(name, latitude, longitude)
)
UPDATE dogadopt.rescues AS target
SET 
  latitude = source.latitude,
  longitude = source.longitude,
  coordinates_updated_at = now(),
  coordinates_source = 'postcodes.io'
FROM temp_rescue_updates AS source
WHERE target.name = source.name
  AND (target.latitude IS NULL OR target.longitude IS NULL);

-- Log summary of updates
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE 'Updated % rescue(s) with geocoded coordinates', updated_count;
END $$;
