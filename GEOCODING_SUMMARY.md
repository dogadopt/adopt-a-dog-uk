# Geocoding Summary - December 31, 2025

## Overview
Successfully geocoded missing latitude/longitude coordinates for rescues in the seed.sql file using the postcodes.io API.

## Results
- **Total rescues in database:** 155
- **Rescues with coordinates:** 111
- **Coverage:** 71.6% (up from ~36% before)
- **Rescues geocoded:** 55

## Method
1. Used the `geocode-rescues.js` script to query postcodes.io API
2. Generated CSV and SQL files with coordinates
3. Updated seed.sql with all 55 geocoded locations
4. Reset database to apply changes

## Files Generated
- `rescue-coordinates.csv` - CSV export of all geocoded rescues
- `rescue-coordinates.sql` - SQL UPDATE statements for direct application
- `GEOCODING_SUMMARY.md` - This summary document

## Sample Updates
| Rescue Name | Postcode | Latitude | Longitude |
|-------------|----------|----------|-----------|
| Dog Aid Society Scotland | EH14 4AR | 55.911235 | -3.312793 |
| Woodgreen Pets Charity | PE29 2NH | 52.29931 | -0.150593 |
| Rain Rescue | S66 1DZ | 53.40801 | -1.272467 |
| RSPCA Norwich | NR16 1EX | 52.534638 | 1.169888 |
| The Kennel Club | W1J 8AB | 51.506403 | -0.14424 |

## Remaining Work
44 rescues still lack coordinates because they:
- Don't have postcodes in the database
- Are located outside the UK (Ireland, Channel Islands, Isle of Man)
- Have incomplete address information

## Data Source
- Coordinates sourced from: [postcodes.io](https://postcodes.io)
- Free UK postcode geocoding API (no API key required)
- Accuracy: Typically accurate to postcode centroid

## Next Steps
To geocode remaining rescues:
1. Add missing postcodes to seed.sql
2. Run: `node scripts/geocode-rescues.js --csv rescue-coordinates.csv`
3. Update seed.sql with new coordinates
4. Run: `npm run supabase:reset`

For international rescues (Ireland, etc.), a different geocoding service will be needed as postcodes.io only covers UK postcodes.
