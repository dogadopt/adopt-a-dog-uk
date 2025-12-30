# Rescue Coordinate Update

## Overview
This migration adds GPS coordinates to existing rescue locations and adds new rescue centers from the dogadopt.github.io repository.

## What It Does

### 1. Updates Existing Rescues (9)
Adds latitude and longitude coordinates to these existing rescues:
- Hope Rescue
- Freshfields Animal Rescue
- North Clwyd Animal Rescue
- Benvardin Animal Rescue Kennels
- Causeway Coast Dog Rescue
- Dogs Trust Ireland
- Grovehill Animal Trust
- Mid Antrim Animal Sanctuary
- Boxer Welfare Scotland

### 2. Adds New Rescue Centers (53)
Adds specific rescue centers that weren't in the database, including:
- 22 Dogs Trust centers (Ballymena, Basildon, Bridgend, Canterbury, Cardiff, etc.)
- 11 Blue Cross centers (Devon, Hampshire, Hertfordshire, Oxfordshire, etc.)
- Various other rescue centers across UK and Ireland

**Result:** Database will contain 157 total rescues (104 existing + 53 new)

## Files

- **Migration:** `supabase/migrations/20251230212837_add_rescue_coordinates.sql`
- **Generator Script:** `scripts/add-rescue-coordinates.js`
- **Matching Report:** `RESCUE_MATCHING_REPORT.md`

## How to Regenerate

If the source data changes:

```bash
# Download latest data
curl -s https://raw.githubusercontent.com/dogadopt/dogadopt.github.io/main/rescues.json -o /tmp/rescues.json

# Regenerate migration
node scripts/add-rescue-coordinates.js
```

## Source Data
https://github.com/dogadopt/dogadopt.github.io/blob/main/rescues.json

## Notes

- All 104 existing rescues are preserved
- Only updates coordinates where they don't already exist (won't overwrite)
- New rescues are added as Full type with proper regions and websites
- All changes tracked in audit system
- Source data contains "Airdale Terrier Club of Scotland" (note spelling) - kept as-is from source
