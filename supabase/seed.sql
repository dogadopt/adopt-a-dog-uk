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
  SELECT name, type, region, website,phone,email,address,postcode,charity_number,latitude,longitude FROM (VALUES
('Aireworth Dogs in Need', 'Full', 'Yorkshire & The Humber', 'www.areworthdogsinneed.co.uk', '07551 891117', 'aireworthdogsinneed@gmail.com', '4 Green Acres, Long Lee, Keighley, West Yorkshire, BD21 4WA', 'BD21 4WA', '1162052', 53.858125, -1.89117),
('Akita Rescue & Welfare Trust (UK)', 'Full', 'South East England', 'www.akitarescue.org.uk', '0345 2 602 206', 'trustees@akitarescue.org.uk', '10 Dallison Road, Hibaldstow, BRIGG, DN20 9PU', 'DN20 9PU', NULL, 53.510466, -0.51987),
('All Creatures Great & Small', 'Full', 'South Wales', 'www.allcreaturesgreatandsmall.org.uk', '01633866144', 'info@allcreatureslife.org', 'Church Farm, Church Road, Llanfrechfa, Cwmbran, NP44 8AD', 'NP44 8AD', NULL, 51.640002, -2.986172),
('All Dogs Matter', 'Full', 'London', 'www.alldogsmatter.co.uk', '02083413196', 'info@alldogsmatter.co.uk', '30 AYLMER PARADE, AYLMER ROAD, LONDON, N2 0PE', 'N2 0PE', '1132883', 51.58196, -0.158021),
('Animal Care - Lancaster Morecambe & District', 'Full', 'North West England', 'www.animalcare-lancaster.co.uk', '0152465495', 'admin@animalcare-lancaster.co.uk', 'Animal Care, Blea Tarn Road, Lancaster, Lancashire, LA2 0RD', 'LA2 0RD', NULL, 54.023852, -2.77887),
('Animal Concern Cumbria', 'Full', 'North West England', 'www.animalconcerncumbria.org', '07712330829', 'CONTACT@ANIMALCONCERNCUMBRIA.ORG', 'Animal Concern Cumbria, The Mary Irwin Centre, EGREMONT, Cumbria, CA22 2UA', 'CA22 2UA', '1161354', 54.476396, -3.566554),
('Animal Rescue Cumbria', 'Full', 'North West England', 'www.animalrescuecumbria.co.uk', '01539824293', 'admin@animalrescuecumbria.co.uk', 'Animal Rescue Cumbria, Kapellan, Grayrigg, KENDAL, LA8 9BS', 'LA8 9BS', '1153737', 54.367283, -2.661832),
('Animal Support Angels', 'Full', 'East England', 'www.animalsupportangels.com', '07752400127', 'amanda@animalsupportangels.com', '3 MALUS CLOSE, HEMEL HEMPSTEAD, HP2 4HN', 'HP2 4HN', '1182915', 51.75557, -0.445584),
('Animal Welfare Furness', 'Full', 'North West England', 'www.animals-in-need.org', '01229 811122', 'Info@animalwelfarefurness.org.uk', '122 Dalton Road, BARROW-IN-FURNESS, Cumbria, LA14 1JH', 'LA14 1JH', NULL, 54.11288, -3.224942),
('Animals in Need Northamptonshire', 'Full', 'East Midlands', 'www.animalsinneed.uk', '01933278080', 'admin@animals-in-need.org', 'PINE TREE FARM, LONDON ROAD, LITTLE IRCHESTER, WELLINGBOROUGH, NN8 2EH', 'NN8 2EH', '1068222', 52.281644, -0.678452),
('Ashbourne Animal Welfare', 'Full', 'East Midlands', 'www.ashbourneanimalwelfare.org', '01335300494', 'ashbourneanimalwelfare@yahoo.co.uk', 'THE ARK, WYASTON ROAD, ASHBOURNE, DE6 1NB', 'DE6 1NB', '1014249', 53.001247, -1.7332),
('Balto''s Dog Rescue', 'Full', 'National', 'www.baltosdogrescue.uk', '07930241473', 'info@baltosdogrescue.uk', '	Kemp House, 152 - 160 City Road, London', NULL, '1199018', NULL, NULL),
('Bath Cats and Dogs Home', 'Full', 'South West England', 'www.bcdh.org.uk', '01225 787321', 'reception@bcdh.org.uk', 'Bath Cats and Dogs Home, The Avenue, Claverton Down, Bath, BA2 7AZ', 'BA2 7AZ', NULL, 51.375925, -2.327119),
('Battersea', 'Full', 'London', 'www.battersea.org.uk', '02076279000', 'info@battersea.org.uk', 'BATTERSEA DOGS & CATS HOME, 4 BATTERSEA PARK ROAD, LONDON, SW8 4AA', 'SW8 4AA', '1185469', 51.478716, -0.14486),
('Benvardin Animal Rescue Kennels', 'Full', 'Northern Ireland', 'www.benvardinkennels.com', '07518 370478', 'benvardinkennels@gmail.com', '28 Benvardin Road,Ballymoney,BT53 8AF','BT53 8AF', NULL, 55.140357, -6.508303),
('Berwick Animal Rescue Kennels', 'Full', 'North East England', 'www.b-a-r-k.co.uk', '01289305270', 'rehome@aol.com', '43 WINDSOR CRESCENT, BERWICK-UPON-TWEED, TD15 1NT', 'TD15 1NT', '1083038', 55.777675, -2.01269),
('Birmingham Dogs Home', 'Full', 'West Midlands', 'www.birminghamdogshome.org.uk', '0121 643 5211', 'info@birminghamdogshome.org.uk', 'Birmingham Dogs Home, Catherine-de-Barnes Lane, Catherine-de-Barnes, SOLIHULL, B92 0DJ', 'B92 0DJ', '222436', 52.428979, -1.743869),
('Bleakholt Animal Sanctuary', 'Full', 'North West England', 'www.bleakholt.org', '01706822577', 'reception@bleakholt.org', 'BLEAKHOLT ANIMAL SANCTUARY, BLEAKHOLT FARM, BURY OLD ROAD, RAMSBOTTOM, BURY, BL0 0RX', 'BL0 0RX', '1110503', 53.659042, -2.29482),
('Blue Cross', 'Full', 'National', 'www.bluecross.org.uk', '03007909903', 'info@bluecross.org.uk', 'Blue Cross, Shilton Road, BURFORD, OX18 4PF', 'OX18 4PF', '224392', 51.787885, -1.61891),
('Border Collie Trust GB', 'Full', 'West Midlands', 'www.bordercollietrustgb.org.uk', '01889577058', 'info@bordercollietrustgb.org.uk', '	B C T - G B RESCUE CENTRE, NARROW LANE, HEATHWAY, COLTON, RUGELEY STAFFS, WS15 3LY', 'WS15 3LY', '1053585', 52.788363, -1.920565),
('Borders Pet Rescue', 'Full', 'Scottish Borders', 'www.borderspetrescue.org', '01896 849090', 'info@borderspetrescue.org', 'Borders Pet Rescue, Earlston, Scottish Borders, TD4 6DJ', 'TD4 6DJ', NULL, 55.634357, -2.68321),
('Boxer Welfare Scotland', 'Full', 'Aberdeen & Grampian', 'www.boxerwelfarescotland.org.uk', NULL, NULL, NULL, NULL, 'SC036719', NULL, NULL),
('Bristol Animal Rescue Centre', 'Full', 'South West England', 'www.bristolarc.org.uk', '0117 977 6043', 'reception@bristolarc.org.uk', '48 – 50 Albert Road, St Philips, Bristol, BS2 0XA', 'BS2 0XA', '205858', 51.446628, -2.576623),
('Bristol Dog Action Welfare Group', 'Full', 'South West England', 'www.dawg.org.uk', '01179695332', 'info@dawg.org.uk', '16 SHERBOURNE AVENUE, BRADLEY STOKE, BRISTOL, BS32 8BB', 'BS32 8BB', '1135539', 51.526864, -2.544006),
('Bulldog Rescue & Re-homing Trust', 'Full', 'South East England', 'www.bulldogrescue.co.uk', '08712002450', 'bulldogrescue@btinternet.com', 'P O BOX 18, MIDHURST, WEST SUSSEX, GU29 9YU', 'GU29 9YU', '1115009', 50.984869, -0.739296),
('Carla Lane Animals In Need', 'Full', 'North West England', 'www.carlalaneanimalsinneed.co.uk', '01515490959', 'animals_inneed@hotmail.co.uk', 'CARLA LANE ANIMALS IN NEED, FIR TREE ANIMAL SANCTURY, 3 SPURRIERS LANE, LIVERPOOL, L31 1BA', 'L31 1BA', '1031342', 53.510276, -2.894548),
('Causeway Coast Dog Rescue', 'Full', 'Northern Ireland', 'www.causewaycoastdogrescue.org', '07595 602702', 'info@causewaycoastdogrescue.org', 'Coleraine, Causeway Coast', NULL, 'NIC102935', NULL, NULL),
('Cheltenham Animal Shelter', 'Full', 'South West England', 'www.gawa.org.uk', '01242548776', 'gm@gawa.org.uk', 'CHELTENHAM ANIMAL SHELTER, GARDNERS LANE, CHELTENHAM, GL51 9JW', 'GL51 9JW', '1081019', 51.913039, -2.087131),
('Chilterns Dog Rescue Society', 'Full', 'East England', 'www.chilternsdogrescue.org.uk', '01296623885', 'enquiries@cdrs.org.uk', 'CHILTERNS DOG RESCUE SOCIETY, BROMLEY HEIGHTS, CHIVERY, TRING, HP23 6LD', 'HP23 6LD', '257557', 51.770405, -0.699455),
('Dog Aid Society Scotland', 'Full', 'Scotland', 'www.dogaidsociety.com', '0300 365 2500', NULL, 'Riccarton Mains Farm, 1b The Cottage, Edinburgh', 'EH14 4AR', 'SC001918', 55.911235, -3.312793),
('Dogs Trust', 'Full', 'National', 'www.dogstrust.org.uk', '02078370006', 'ContactCentre@dogstrust.org.uk', '17 WAKLEY STREET, LONDON, EC1V 7RQ', 'EC1V 7RQ', '1167663', 51.530284, -0.10238),
('Dogs Trust Ireland', 'Full', 'Ireland', 'www.dogstrust.ie', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Dumfries & Galloway Canine Rescue Centre', 'Full', 'Dumfries & Galloway', 'www.caninerescue.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Durham Dogs and Cats Home', 'Full', 'North East England', 'www.durhamdogsandcats.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Eden Animal Rescue', 'Full', 'North West England', 'www.edenanimalrescue.org.uk', '01931716114', 'admin@edenanimalrescue.org.uk', 'Moorlands Head Farm, Newbiggin, Temple Sowerby, PENRITH, CA10 1TH', 'CA10 1TH', '1117113', 54.650306, -2.565287),
('Edinburgh Dog & Cat Home', 'Full', 'Edinburgh & the Lothians', 'www.edch.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Fen Bank Greyhound Sanctuary', 'Full', 'East England', 'www.fenbankgreyhounds.co.uk', '07855690246', 'info@fenbankgreyhounds.co.uk', '15 HEWITTS MANOR, CLEETHORPES, DN35 9QT', 'DN35 9QT', '1072443', 53.542301, -0.045985),
('Ferne Animal Sanctuary', 'Full', 'South West England', 'www.ferneanimalsanctuary.org', '0146065214', 'finance@ferneanimalsanctuary.org', 'FERNE ANIMAL SANCTUARY, WAMBROOK, CHARD, TA20 3DH', 'TA20 3DH', '245671', 50.863341, -3.030792),
('Foal Farm Animal Rescue', 'Full', 'South East England', 'www.foalfarm.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Forest Dog Rescue', 'Full', 'West Midlands', 'www.forest-dog-rescue.org.uk', '01299269181', 'info@forest-dog-rescue.org.uk', 'GREEN GAP KENNELS, CLEOBURY ROAD, FAR FOREST, KIDDERMINSTER, WORCS, DY14 9DX', 'DY14 9DX', '517173', 52.37332, -2.413952),
('Forever Hounds Trust', 'Full', 'South East England', 'www.foreverhoundstrust.org', '03000125125', 'enquiries@foreverhoundstrust.org', 'Cottage Kennels, Chave Lane, Brithem Bottom, CULLOMPTON, Devon, EX15 1NE', 'EX15 1NE', '1131399', 50.894357, -3.410169),
('Freshfields Animal Rescue', 'Full', 'North West England', 'www.freshfields.org.uk', '01519311604', 'admin@freshfields.org.uk', 'FRESHFIELDS ANIMAL RESCUE, EAST LODGE FARM, EAST LANE, LIVERPOOL, L29 3EA', 'L29 3EA', '1160348', 53.517076, -2.999525),
('Friends of Akitas Trust UK', 'Full', 'East Midlands', 'www.friendsofakitas.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Gables Dogs & Cats Home', 'Full', 'South West England', 'www.gablesfarm.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Garbos German Shepherd Dog Rescue', 'Full', 'South East England', 'www.garbosgsdrescue.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('German Shepherd Rescue Elite', 'Full', 'South East England', 'www.gsrelite.co.uk', '08456006628', 'info@gsrelite.co.uk', 'Camelot Kennels, Round House, Launceston Road, Kelly Bray, CALLINGTON, Cornwall', NULL, '1150928', NULL, NULL),
('German Shepherd Rescue South', 'Full', 'South East England', 'www.german-shepherd-rescue-hampshire.org.uk', '02392221485', 'ENQUIRIES@GSRS.ORG.UK', '48 Edward Grove, Fareham, PO16 8JA', 'PO16 8JA', '1141956', 50.853032, -1.117539),
('German Shorthaired Pointer Rescue UK', 'Full', 'South Wales', 'www.gsprescue-uk.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Greenacres Rescue', 'Full', 'South Wales', 'www.greenacresrescue.org.uk', '01437781745', 'team@greenacresrescue.org.uk', 'Greenacres Rescue Ltd, Ebbs Acres Farm, Talbenny, HAVERFORDWEST, SA62 3XA', 'SA62 3XA', '1180916', 51.757149, -5.134404),
('Greyhound Gap', 'Full', 'West Midlands', 'www.greyhoundgap.org.uk', '07917422489', 'enquiries@greyhoundgap.org.uk', 'Grindle Stone Edge House, Cobmoor Road, Kidsgrove, Stoke-on-Trent, ST7 3PZ', 'ST7 3PZ', '1113207', 53.099496, -2.236645),
('Greyhound Rescue Wales', 'Full', 'Mid Wales', 'www.greyhoundrescuewales.co.uk', '0300 0123 999', 'info@greyhoundrescuewales.co.uk', 'Hillcrest, Bryncethin Road, Garnant, Ammanford, SA18 1YS', 'SA18 1YS', '1152650', 51.791847, -3.897181),
('The Greyhound Trust', 'Full', 'National', 'www.greyhoundtrust.org.uk', '02083353016', 'hello@greyhoundtrust.org.uk', 'Greyhound Trust, National Greyhound Centre, Peeks Brook Lane, Horley, Surrey, RH6 9SX', 'RH6 9SX', NULL, 51.161684, -0.134949),
('Greyhound Welfare South Wales', 'Full', 'South Wales', 'www.facebook.com/GreyhoundWelfareSouthWales', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Grovehill Animal Trust', 'Full', 'Northern Ireland', 'www.grovehillanimaltrust.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Happy Landings Animal Shelter', 'Full', 'South West England', 'www.happy-landings.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Happy Staffie Rescue', 'Full', 'West Midlands', 'www.happystaffie.co.uk', '03432896163', 'info@happystaffie.co.uk', 'Happy Staffie Rescue, Unit 3, 4 Lisle Avenue, KIDDERMINSTER, Worcestershire, DY11 7DL', 'DY11 7DL', '1132578', 52.372703, -2.258321),
('Holly Hedge Animal Sanctuary', 'Full', 'South West England', 'www.hollyhedge.org.uk', '01275474719', 'info@hollyhedge.org.uk', 'Holly Hedge Sanctuary, Wild Country Lane, Barrow Gurney, BRISTOL, BS48 3SE', 'BS48 3SE', '294606', 51.413425, -2.670533),
('Hope Rescue', 'Full', 'South Wales', 'www.hoperescue.org.uk', '01443 226 659', 'ENQUIRIES@HOPERESCUE.ORG.UK', 'Cynllan Lodge, Llanharan, PONTYCLUN, CF72 9NH', 'CF72 9NH', '1129629', 51.535489, -3.420308),
('Jerry Green Dog Rescue', 'Full', 'East Midlands', 'www.jerrygreendogs.org.uk', '01652657820', 'sue.bloomfield@jerrygreendogs.org.uk', 'Jerry Green Dog Rescue, Wressle, BRIGG, DN20 0BJ', 'DN20 0BJ', '1155042', 53.580417, -0.542352),
('Just Springers Rescue', 'Full', 'South East England', 'www.justspringersrescue.co.uk', '07849 532111', 'info@justspringersrescue.co.uk', '19 Lingfield Common Road, LINGFIELD, Surrey, RH7 6BU', 'RH7 6BU', '1135424', 51.183503, -0.02492),
('K9 Focus', 'Full', 'South West England', 'www.k9focus.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Keith''s Rescue Dogs', 'Full', 'East Midlands', 'www.keithsrescuedogs.co.uk', '01754763543', 'keithsrescuedogs@yahoo.com', '5 BRIAR CLOSE, SKEGNESS, PE25 3QB', 'PE25 3QB', '1093211', 53.141751, 0.337469),
('Labrador Lifeline Trust', 'Full', 'South East England', 'www.labrador-lifeline.com', '01256884027', 'info@labrador-lifeline.com', '6 Tottenham Close, Bramley, Tadley, RG26 5NW', 'RG26 5NW', '1076061', 51.331648, -1.056291),
('Labrador Rescue Trust', 'Full', 'South West England', 'www.labrador-rescue.com', '07791519084', 'enquiries@labrador-rescue.com', 'LESTER ALDRIDGE SOLICITORS, 31 OXFORD ROAD, BOURNEMOUTH, BH8 8EX', 'BH8 8EX', '1088198', 50.724887, -1.86521),
('Last Chance Animal Rescue', 'Full', 'South East England', 'www.lastchanceanimalrescue.co.uk', '01732 865 530', 'general@lastchanceanimalrescue.co.uk', '83 Coast Drive, Greatstone, NEW ROMNEY, Kent, TN28 8NR', 'TN28 8NR', '1002349', 50.974829, 0.964455),
('Leicester Animal Aid', 'Full', 'East Midlands', 'www.leicesteranimalaid.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Lord Whisky Sanctuary Fund', 'Full', 'South East England', 'www.lordwhisky.co.uk', '01303862622', 'lord.whisky@btinternet.com', 'THE LORD WHISKY SANCTUARY, PARK HOUSE, STELLING MINNIS, CANTERBURY, CT4 6AN', 'CT4 6AN', '283483', 51.158212, 1.069427),
('MADRA', 'Full', 'Ireland', 'www.madra.ie', NULL, NULL, NULL, NULL, '1199407', NULL, NULL),
('Manchester & District Home For Lost Dogs', 'Full', 'North West England', 'www.dogshome.net', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Margaret Green Animal Rescue', 'Full', 'South West England', 'www.margaretgreenanimalrescue.org.uk', '01929480474', 'admin@mgar.org.uk', 'Nigel Mason, ANIMAL SANCTUARY, CHURCH KNOWLE, WAREHAM, DORSET, BH20 5NQ', 'BH20 5NQ', '252594', 50.634949, -2.088331),
('Maxi''s Mates', 'Full', 'Yorkshire & The Humber', 'www.maxismates.org.uk', '07507104636', 'maxismates@gmail.com', 'Carlin Howe Farmhouse, Tocketts, GUISBOROUGH, TS14 6RG', 'TS14 6RG', '1162442', 54.550404, -1.046236),
('Mayflower Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.mayflowersanctuary.co.uk', '01302711330', 'info@mayflowersanctuary.co.uk', 'Narrow Lane, Bawtry, Doncaster, South Yorkshire, DN10 6QJ', 'DN10 6QJ', '1147324', 53.437792, -1.014318),
('The Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org', '0208 962 8000', 'info@mayhewanimalhome.org', 'MAYHEW ANIMAL HOME, TRENMAR GARDENS, LONDON, NW10 6BJ', 'NW10 6BJ', NULL, 51.531261, -0.232908),
('Mid Antrim Animal Sanctuary', 'Full', 'Northern Ireland', 'www.midantrim.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Mrs Murrays Home for Stray Dogs and Cats', 'Full', 'Aberdeen & Grampian', 'www.mrsmurrays.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('National Animal Welfare Trust', 'Full', 'National', 'www.nawt.org.uk', '02089500177', 'headoffice@nawt.org.uk', 'NATIONAL ANIMAL WELFARE TRUST, TYLERS WAY, WATFORD, WD25 8WT', 'WD25 8WT', '1090499', 51.655374, -0.345792),
('Newcastle Dog & Cat Shelter', 'Full', 'North East England', 'www.dogscatshelter.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Norfolk Greyhound Welfare', 'Full', 'East England', 'www.norfolkgreyhoundwelfare.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('North Clwyd Animal Rescue', 'Full', 'North Wales', 'www.ncar.co.uk', '01745560546', 'reception@ncar.org.uk', 'MAES GWYN, TRELOGAN, HOLYWELL, CH8 9BD', 'CH8 9BD', '515195', 53.311893, -3.324518),
('Oak Tree Animals'' Charity', 'Full', 'North West England', 'www.oaktreeanimals.org.uk', '01228560082', 'info@oaktreeanimals.org.uk', 'Oak Tree Animals Charity, Oak Tree Farm, Wetheral Shields, Wetheral, CARLISLE, CA4 8JA', 'CA4 8JA', '1169511', 54.864056, -2.838337),
('Oldies Club', 'Full', 'National', 'www.oldies.org.uk', '08445868656', 'oldies@oldies.org.uk', '49A KINROSS CLOSE, FEARNHEAD, WARRINGTON, WA2 0UT', 'WA2 0UT', '1118246', 53.421976, -2.56411),
('Preston & District RSPCA', 'Full', 'North West England', 'www.rspca-preston.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Scottish SPCA', 'Full', 'Scotland', 'www.scottishspca.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Woodgreen Pets Charity', 'Full', 'East England', 'www.woodgreen.org.uk', '03003039333', 'info@woodgreen.org.uk', 'Wood Green Animal Shelters,London Road, Godmanchester, Huntingdon, Cambridgeshire, PE29 2NH', 'PE29 2NH', '298348', 52.29931, -0.150593),
-- Additional ADCH member rescues added 2025-12-31
('Animals in Need Northants', 'Full', 'East Midlands', 'www.animalwelfarefurness.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Ashbourne & District Animal Welfare Society', 'Full', 'East Midlands', 'www.ashbourneanimalwelfare.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Band of Rescuers North Yorkshire', 'Full', 'Yorkshire & The Humber', 'www.bandofrescuers.co.uk', '07967811171', 'bandofrescuersteam@gmail.com', '43 LOWFIELD DRIVE, HAXBY, YORK, YO32 3QT', 'YO32 3QT', '1183369', 54.019797, -1.072647),
('Clare Animal Welfare CLG', 'Provisional', 'Ireland', 'www.clareanimalwelfare.ie', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Greyhound Trust - National Greyhound Centre', 'Full', 'South East England', 'www.greyhoundtrust.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Guernsey SPCA', 'Full', 'Channel Islands', 'www.gspca.org.gg', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Jersey SPCA Animals'' Shelter', 'Full', 'Channel Islands', 'www.jspca.org.je', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Manx SPCA', 'Full', 'Isle of Man', 'www.manxspca.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Mayo SPCA', 'Provisional', 'Ireland', 'www.mayospca.ie', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Pawprints Dog Rescue', 'Full', 'West Midlands', 'www.pawprintsdogrescue.org', '07415030165', 'pdrescue@hotmail.com', 'Pawprints Dunsmore Kennels, Stave Hall Farm Kennels, Fosse Way, Monks Kirby, Warwickshire, CV23 0RL', 'CV23 0RL', '1190250', 52.4451, -1.341339),
('PAWS Animal Rescue', 'Full', 'Ireland', 'www.paws.ie', '07565887332', 'hampshirepaws@outlook.com', 'CHASE FARMHOUSE, GILBERT STREET, ROPLEY, ALRESFORD, SO24 0BY', 'SO24 0BY', '1203150', 51.088451, -1.073359),
('People for Animal Care Trust (PACT)', 'Full', 'East England', 'www.pactsanctuary.org', '01362820775', 'pactsanctuary@btconnect.com', 'The Office, RIVER FARM, WOODRISING, NORWICH, Norfolk, NR9 4PJ', 'NR9 4PJ', '1154444', 52.592805, 0.932802),
('Phoenix French Bulldog Rescue', 'Full', 'East England', 'www.phoenixfrenchbulldogrescue.org', '03007727716', 'ENQUIRIES@PHOENIXFRENCHBULLDOGRESCUE.ORG', '17 WELLINGTON ROAD, SHORTSTOWN, BEDFORD, MK42 0UT', 'MK42 0UT', '1171943', 52.109991, -0.439773),
('Pro Dogs Direct', 'Full', 'South East England', 'www.prodogsdirect.org.uk', '07766021465', 'Info@ProDogsDirect.Org.Uk', '4 Cole Avenue, Aldershot, GU11 1AN', 'GU11 1AN', '1115647', 51.252058, -0.771368),
('Rain Rescue', 'Full', 'Yorkshire & The Humber', 'www.rainrescue.co.uk', '01709247777', 'info@rainrescue.co.uk', 'SUMMERFIELD LODGE, MOAT LANE, WICKERSLEY, ROTHERHAM, S66 1DZ', 'S66 1DZ', '1115089', 53.40801, -1.272467),
('Rainbow Rescue', 'Full', 'Northern Ireland', 'www.rainbowrehoming.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Raystede Centre for Animal Welfare', 'Full', 'South East England', 'www.raystede.org', '01825840252', 'info@raystede.org', 'RAYSTEDE, THE BROYLE, RINGMER, LEWES, BN8 5AJ', 'BN8 5AJ', '237696', 50.909231, 0.103918),
('Rescue Me Animal Sanctuary', 'Full', 'North West England', 'www.rescueme.org.uk', '07952017696', 'info@rescueme.org.uk', 'Bells Farm, Prescot Road, Melling, LIVERPOOL, L31 1AR', 'L31 1AR', '1157210', 53.505849, -2.901195),
('Rosie''s Trust', 'Full', 'Northern Ireland', 'www.rosiestrust.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Rottweiler Welfare Association', 'Full', 'West Midlands', 'www.rottweilerwelfare.co.uk', '07946083070', 'secretary@rottweilerwelfare.co.uk', 'PO BOX 2424, Wrexham, LL11 0PR', 'LL11 0PR', '279478', 53.048909, -3.000085),
('RSPCA', 'Full', 'National', 'www.rspca.org.uk', '01227719113', 'admin@rspca-canterbury.org.uk', 'C A D A C, Haseden Farm, Island Road, Hersden, Canterbury, CT3 4JD', 'CT3 4JD', '210743', 51.311841, 1.154045),
('RSPCA Brighton & The Heart of Sussex', 'Full', 'South East England', 'www.rspca-brighton.org.uk', '01273554218', 'info@rspcabrighton.org.uk', 'R S P C A Brighton & The Heart of Sussex, Braypool Lane, Patcham, Brighton, BN1 8ZH', 'BN1 8ZH', '206630', 50.870618, -0.158216),
('RSPCA Canterbury and District Branch', 'Full', 'South East England', 'www.rspca.org.uk/local/canterbury-and-district-branch', '01227719113', 'admin@rspca-canterbury.org.uk', 'C A D A C, Haseden Farm, Island Road, Hersden, Canterbury, CT3 4JD', 'CT3 4JD', '210743', 51.311841, 1.154045),
('RSPCA Chesterfield and North Derbyshire Branch', 'Full', 'South East', 'www.chesterfield-rspca.org.uk', '01246273358', 'info@chesterfield-rspca.org.uk', '137 SPITAL LANE, CHESTERFIELD, DERBYSHIRE, S41 0HL', 'S41 0HL', '226142', 53.227504, -1.40901),
('RSPCA Cornwall', 'Full', 'South West England', 'www.rspcacornwall.org.uk', '01637881455', 'ADMIN@RSPCACORNWALL.ORG.UK', 'RSPCA Cornwall Branch, THE VENTON CENTRE, QUOIT, ST COLUMB, CORNWALL, TR9 6JS', 'TR9 6JS', '1024808', 50.42133, -4.92287),
('RSPCA Coventry and District Branch', 'Full', 'West Midlands', 'www.rspca-coventryanddistrict.org.uk', '02476336616', 'info@rspca-coventryanddistrict.org.uk', 'RSPCA Coventry and District Branch, BROWNSHILL GREEN FARM, COUNDON WEDGE DRIVE, ALLESLEY, COVENTRY, CV5 9DQ', 'CV5 9DQ', '1208493', 52.436512, -1.552538),
('RSPCA Kent Isle of Thanet Branch', 'Full', 'South East England', 'www.rspcathanet.org.uk', '01843826179', 'info@rspcathanet.org.uk', 'R S P C A, Isle Thanet Animal Centre, Queensdown Road, Woodchurch, BIRCHINGTON, CT7 0HG', 'CT7 0HG', '209365', 51.356814, 1.346566),
('RSPCA Lancashire East Branch', 'Full', 'North West England', 'www.rspca-lancseast.org.uk', '01254231118', 'info@rspca-lancseast.org.uk', 'Nearer Holker House Farm, Enfield Road, Accrington, BB5 6NN', 'BB5 6NN', '232253', 53.771064, -2.350013),
('RSPCA Little Valley', 'Full', 'South West England', 'www.rspca-littlevalley.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('RSPCA Leeds, Wakefield & District Branch', 'Full', 'Yorkshire & The Humber', 'www.rspcaleedsandwakefield.org.uk', '01132536952', 'info@rspcaleedsandwakefield.org.uk', 'R S P C A Leeds, Wakefield & District Animal Centre, Moor Knoll Lane, East Ardsley, WAKEFIELD, WF3 2DX', 'WF3 2DX', '232223', 53.7316, -1.543017),
('RSPCA Leicester/Woodside Animal Centre', 'Full', 'East Midlands', 'www.rspcaleicester.org.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('RSPCA Llys Nini Branch', 'Full', 'South West Wales', 'www.rspca-llysnini.org.uk', '01792899460', 'admin@rspca-llysnini.org.uk', 'Llys Nini Animal Centre, Penllergaer, Swansea, SA4 9WB', 'SA4 9WB', '224337', 51.677291, -4.012386),
('RSPCA Norwich', 'Full', 'East England', 'www.rspcanorwich.org.uk', '0303 040 1565', 'woof@rspcanorwich.org', 'RSPCA Norwich, The Street, Ashwellthorpe, Norfolk, NR16 1EX', 'NR16 1EX', '1209360', 52.534638, 1.169888),
('RSPCA Radcliffe Animal Shelter Trust', 'Full', 'East Midlands', 'www.rspca-radcliffe.org.uk', '01158550222', 'info@rspca-radcliffe.org.uk', 'R S P C A, 32 Nottingham Road, Radcliffe-on-Trent, NOTTINGHAM, NG12 2DW', 'NG12 2DW', '1212852', 52.943877, -1.05181),
('RSPCA Sheffield Branch', 'Full', 'Yorkshire & The Humber', 'www.rspcasheffield.org', '01142898050', 'reception@rspcasheffield.org', '2 STADIUM WAY, ATTERCLIFFE, SHEFFIELD, S9 3HN', 'S9 3HN', '225570', 53.388145, -1.433673),
('RSPCA Southport, Ormskirk & District Branch', 'Full', 'North West England', 'www.rspcasouthport.org', '01704567624', 'info@rspcasouthport.co.uk', 'RSPCA, Animal Centre, New Cut Lane, Southport, PR8 3DW', 'PR8 3DW', '232258', 53.614018, -3.007134),
('RSPCA Sussex East and Hastings Branch', 'Full', 'East Midlands', 'www.bluebellridge.org', '01424752121', 'bluebellridge@hotmail.com', 'Bluebell Ridge, Chowns Hill, Hastings, TN35 4PA', 'TN35 4PA', '206314', 50.885145, 0.590488),
('RSPCA Warrington, Halton and St Helens Branch', 'Full', 'North West England', 'www.rspca-whs.org.uk', '01925650586', 'contact@rspca-whs.org.uk', 'R S P C A, Slutchers Lane, WARRINGTON, WA1 1NA', 'WA1 1NA', '232259', 53.385169, -2.602276),
('RSPCA Westmorland Branch', 'Full', 'North West England', 'www.rspca-westmorland.org.uk', '01539736036', 'admin@rspca-westmorland.org.uk', 'The Ruth Pedley Building, Beezon Fields, Kendal, LA9 6BL', 'LA9 6BL', '232236', 54.33271, -2.744842),
('Saints Sled Dog Rescue', 'Full', 'National', 'www.saintssleddogrescue.co.uk', '07983548370', 'info@saintssleddogrescue.co.uk', 'Mahon House, Garmondsway, FERRYHILL, County Durham, DL17 9DY', 'DL17 9DY', '1204365', 54.689618, -1.472328),
('Saving Saints Rescue UK', 'Full', 'North West England', 'www.savingsaintsrescue.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Scottish Staffordshire Bull Terrier Rescue', 'Full', 'Aberdeen & Grampian', 'www.staffierescuescotland.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Second Chance Akita Rescue', 'Full', 'West Midlands', 'www.secondchanceakitarescue.co.uk', '0330165 4660', 'admin@secondchanceakitarescue.co.uk', '42 WESLEY AVENUE, HALESOWEN, B63 2PJ', 'B63 2PJ', '1187521', 52.467615, -2.092657),
('Senior Staffy Club', 'Full', 'West Midlands', 'www.seniorstaffyclub.co.uk', '07825750551', 'admin@seniorstaffyclub.co.uk', 'C / O Unit 7 Rockhaven, Triangle Park, Triangle Way, Gloucester, GL1 1AJ', 'GL1 1AJ', '1156723', 51.861614, -2.221328),
('Society for Abandoned Animals', 'Full', 'North West England', 'www.saarescue.co.uk', '01619735318', 'office@saarescue.co.uk', 'MOSLEY ACRE FARM, STRETFORD, MANCHESTER, M32 9UP', 'M32 9UP', '245426', 53.435986, -2.309712),
('Southern Golden Retriever Rescue', 'Full', 'South England', 'www.sgrr.org.uk', '07480100344', 'admin@sgrr.org.uk', '14 Swale Road, ROCHESTER, Kent, ME2 2TT', 'ME2 2TT', '1098769', 51.39691, 0.45886),
('Spaniel Aid CIO', 'Full', 'National', 'www.spanielaid.co.uk', '07825700490', 'spanielaiduk@gmail.com', '1 BELLE BAULK, TOWCESTER, NN12 6YH', 'NN12 6YH', '1203314', 52.131642, -1.001635),
('Spirit of the Dog Rescue', 'Full', 'East England', 'www.spiritofthedog.org.uk', '07907122591', 'info@spiritofthedog.org.uk', '30 Plantation Road, Boreham, CHELMSFORD, CM3 3EA', 'CM3 3EA', '1123664', 51.759802, 0.546291),
('Sprocker Assist and Rescue', 'Full', 'National', 'www.sprockerassist.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('St Francis Dogs Home', 'Full', 'South West England', 'www.stfrancisnewquay.org.uk', '07500958520', 'mail@stfrancisnewquay.org.uk', 'St Francis Dogs Home, Trevelgue Road, Porth, Newquay, TR7 3LY', 'TR7 3LY', '1185816', 50.428109, -5.053223),
('Staffie and Stray Rescue', 'Full', 'South West England', 'www.staffieandstrayrescue.co.uk', '07963566084', 'staffiesrescue@gmail.com', 'STAFFIE AND STRAY RESCUE OFFICE, 76 Medway Road, FERNDOWN, BH22 8US', 'BH22 8US', '1163631', 50.806312, -1.868951),
('Stokenchurch Dog Rescue', 'Full', 'South East England', 'www.stokenchurchdogrescue.org.uk', '01494482695', 'admin@stokenchurchdogrescue.org.uk', 'Tower Farm, Oxford Road, Stokenchurch, HIGH WYCOMBE, HP14 3TD', 'HP14 3TD', '274589', 51.662231, -0.914545),
('Tails Animal Welfare', 'Full', 'North West England', 'www.tailsanimalwelfare.com', '07575870887', 'tailsanimalwelfare@gmail.com', '21 CROXTETH ROAD, LIVERPOOL, L8 3SE', 'L8 3SE', '1203993', 53.390025, -2.952624),
('Team Poundie', 'Full', 'North East England', 'www.teampoundie.com', '07805297340', NULL, 'Team Poundie, 8 Bagley Drive, Wellington, TELFORD, Shropshire, TF1 3NP', 'TF1 3NP', '1166962', 52.706498, -2.52908),
('Teckels Animal Sanctuaries', 'Full', 'South West England', 'www.teckelsanimalsanctuaries.co.uk', '01452740300', 'enquiries@teckelsanimalsanctuaries.co.uk', 'TECKELS, BRISTOL ROAD, WHITMINSTER, GLOUCESTER, GL2 7LU', 'GL2 7LU', '1108726', 51.776013, -2.321208),
('The Animal House Rescue', 'Full', 'West Midlands', 'www.theanimalhouserescue.co.uk', NULL, 'info@theanimalhouserescue.co.uk', 'POSTAL ADDRESS ONLY, 4 Kintore Croft, Birmingham, West Midlands, B32 4JJ', 'B32 4JJ', '1111314', 52.429327, -2.006877),
('The Cat Welfare Group', 'Full', 'South East England', 'www.thecatwelfaregroup.org', '07990064422', 'Contact@TheCatWelfareGroup.org', 'Knight Goodhead, 7 Bournemouth Road, Chandlers Ford, EASTLEIGH, Hampshire, SO53 3DA', 'SO53 3DA', '1189649', 50.981795, -1.383518),
('The Friends of Assisi Animal Sanctuary', 'Full', 'Northern Ireland', 'www.assisi-ni.org', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('The Mutts Nutts Rescue', 'Full', 'East Midlands', 'www.themuttsnuttsrescue.org', '01780654072', 'info@themuttsnuttsrescue.org', '28a Little Casterton Road, STAMFORD, PE9 1BE', 'PE9 1BE', '1176283', 52.658307, -0.49222),
('The Kennel Club', 'Full', 'London', 'www.thekennelclub.org.uk', '02075181061', 'artgallery@the-kennel-club.org.uk', 'THE KENNEL CLUB, 10 CLARGES STREET, PICCADILLY, LONDON, W1J 8AB', 'W1J 8AB', '1114823', 51.506403, -0.14424),
('Thornberry Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.thornberryanimalsanctuary.org', '01909564399', 'admin@thornberryanimalsanctuary.org', 'Thornberry Animal Sanctuary, The Stables, Todwick Road, Dinnington, SHEFFIELD, S25 3SE', 'S25 3SE', '1205404', 53.370928, -1.234412),
('Three Counties Dog Rescue', 'Full', 'East Midlands', 'www.threecountiesdogrescue.org', '01778424953', 'info@threecountiesdogrescue.org', '37 Spalding Road, BOURNE, Lincolnshire, PE10 0AU', 'PE10 0AU', '1170606', 52.771605, -0.309371),
('UK Spaniel Rescue', 'Full', 'National', 'www.ukspanielrescue.co.uk', '07935652999', 'hello@ukspanielrescue.co.uk', '4 Bush Lane, Freckleton, PRESTON, PR4 1SA', 'PR4 1SA', '1212215', 53.752267, -2.869745),
('USPCA', 'Full', 'Northern Ireland', 'www.uspca.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Wadars Animal Rescue', 'Full', 'South East England', 'www.wadars.co.uk', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
('Warrington Animal Welfare', 'Full', 'North West England', 'www.warringtonanimalwelfare.org.uk', '01925748638', 'info@warringtonanimalwelfare.org.uk', 'Slutchers lane, Bank Quay, Warrington, Cheshire, WA1 1NA', 'WA1 1NA', '1057149', 53.385169, -2.602276),
('West Yorkshire Dog Rescue', 'Full', 'Yorkshire & The Humber', 'www.westyorkshiredogrescue.co.uk', '07711617148', 'info@westyorkshiredogrescue.co.uk', 'Crow Hill Lodge, Carrs Road, Marsden, Huddersfield, West Yorkshire, HD7 6JH', 'HD7 6JH', '1132348', 53.599993, -1.921174),
('Wirral Animal Welfare Association', 'Full', 'North West England', 'www.wirralanimalwelfare.com', '01516080894', 'kstrahan13@hotmail.com', '13 Bryanston Road, Birkenhead, CH42 8PT', 'CH42 8PT', '518910', 53.372367, -3.046397),
('Woodlands Animal Sanctuary', 'Full', 'North West England', 'www.woodlandsanimalsanctuary.org.uk', '01704823293', 'info@animalsanctuary.org.uk', 'WOODLANDS FARM, SANDY LANE, HOLMESWOOD, ORMSKIRK, L40 1UE', 'L40 1UE', '1190858', 53.639754, -2.845513),
('Worcestershire Animal Rescue Shelter', 'Full', 'West Midlands', 'www.wars.org.uk', '01905831651', 'secretary@wars.org.uk', 'Worcs Animal Rescue Shelter, Hawthorn Lane, Newland, MALVERN, Worcestershire, WR13 5BD', 'WR13 5BD', '514872', 52.145169, -2.279915),
('Wythall Animal Sanctuary', 'Full', 'West Midlands', 'www.wythallanimalsanctuary.org', '01565656512', 'info@wythallanimalsanctuary.org', 'LONG VIEW, MIDDLE LANE, KINGS NORTON, BIRMINGHAM, B38 0DU', 'B38 0DU', '1137681', 52.385867, -1.904666)
  ) AS t(name, type, region, website, phone, email, address, postcode, charity_number, latitude, longitude)
)
MERGE INTO dogadopt.rescues AS target
USING temp_rescues AS source
ON target.name = source.name
WHEN MATCHED AND (
  target.type IS DISTINCT FROM source.type OR
  target.region IS DISTINCT FROM source.region OR
  target.website IS DISTINCT FROM source.website OR
  target.phone IS DISTINCT FROM source.phone OR
  target.email IS DISTINCT FROM source.email OR
  target.address IS DISTINCT FROM source.address OR
  target.postcode IS DISTINCT FROM source.postcode OR
  target.charity_number IS DISTINCT FROM source.charity_number OR
  target.latitude IS DISTINCT FROM source.latitude OR
  target.longitude IS DISTINCT FROM source.longitude
) THEN
  UPDATE SET
    type = source.type,
    region = source.region,
    website = source.website,
    phone = source.phone,
    email = source.email,
    address = source.address,
    postcode = source.postcode,
    charity_number = source.charity_number,
    latitude = source.latitude,
    longitude = source.longitude,
    coordinates_source = CASE WHEN source.latitude IS NOT NULL THEN 'postcodes.io' ELSE NULL END
WHEN NOT MATCHED THEN
  INSERT (name, type, region, website, phone, email, address, postcode, charity_number, latitude, longitude, coordinates_source)
  VALUES (source.name, source.type, source.region, source.website, source.phone, source.email, source.address, source.postcode, source.charity_number, source.latitude, source.longitude, CASE WHEN source.latitude IS NOT NULL THEN 'postcodes.io' ELSE NULL END)
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

