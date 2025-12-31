# Rescue Contact Details Collection

## Overview

This script collects official contact information for rescue organizations using the UK Charity Commission API. The data comes directly from the official charity register, ensuring accuracy and reliability.

## API Information

- **Source**: UK Charity Commission Register
- **Documentation**: https://api.charitycommission.gov.uk
- **Endpoint**: `/charitycontactinformation/{charity_number}/0`
- **Rate Limit**: 1 request per second (enforced by script)
- **Cost**: Free for non-commercial use

## Setup

### 1. Get Charity Commission API Key

1. Visit: https://developer.charitycommission.gov.uk/
2. Click "Sign up" and create a free account
3. Navigate to "Products" and subscribe to "Charity Commission API"
4. Go to "Profile" and copy your API key
5. Add to `.env` file:
   ```bash
   CHARITY_COMMISSION_API_KEY=your_api_key_here
   ```

### 2. Install Dependencies

```bash
npm install
```

### 3. Apply Database Migration

```bash
npm run supabase:reset
```

This adds the following fields to the `rescues` table:
- `phone` - Primary contact phone
- `email` - Primary contact email
- `address` - Full postal address
- `postcode` - UK postcode (extracted from address)
- `charity_number` - Charity registration number
- `contact_verified_at` - Timestamp of data collection
- `contact_notes` - JSON metadata about the source

## Running the Collector

```bash
npm run collect-contacts
```

### What it does:

1. Queries all rescues with a `charity_number` in the database
2. For each rescue:
   - Calls Charity Commission API
   - Retrieves official contact information
   - Extracts postcode from address
   - Saves to database with verification timestamp
3. Rate limits to 1 request/second (API requirement)
4. Retries failed requests with exponential backoff

### Expected Output:

```
🐕 UK Charity Commission Contact Collector

Found 85 rescues with charity numbers

────────────────────────────────────────────────────────────

📍 Battersea
   Charity #206394
   ✓ Contact details retrieved
     📞 020 7627 9200
     📧 info@battersea.org.uk
     📍 SW8 4AA
     🌐 www.battersea.org.uk

... (continues for each rescue)

────────────────────────────────────────────────────────────

✓ Complete! Processed 85/85 rescues
  ✓ Successfully collected: 82
  ⚠️  Skipped: 3
```

## Data Collected

The API returns official data from the Charity Commission register:

| Field | Source | Description |
|-------|--------|-------------|
| `contact_address` | API | Full postal address including postcode |
| `phone` | API | Primary contact phone number |
| `email` | API | Primary contact email address |
| `web` | API | Official website URL |
| `postcode` | Extracted | UK postcode extracted from address |

All data is automatically marked as verified with `contact_verified_at` timestamp since it comes from an official source.

## Adding Charity Numbers

Many rescues don't have charity numbers in the seed data yet. To add them:

### Option 1: Manual Lookup

1. Visit https://register-of-charities.charitycommission.gov.uk/
2. Search for the rescue organization by name
3. Copy the charity registration number
4. Add to [supabase/seed.sql](../supabase/seed.sql):

```sql
('Rescue Name', 'Full', 'Region', 'www.website.co.uk', 1234567),
                                                        ^^^^^^^^
                                                        Add charity number here
```

### Option 2: Bulk Search Script

Create a helper script to search for charity numbers:

```bash
# Search Charity Commission for missing charity numbers
node scripts/find-charity-numbers.js
```

(Script to be created - searches API by organization name)

## Verification

### Check collected data:

```sql
-- View all collected contact information
SELECT 
  name,
  charity_number,
  phone,
  email,
  postcode,
  address,
  contact_verified_at,
  contact_notes::json->>'source' as source
FROM dogadopt.rescues
WHERE phone IS NOT NULL OR email IS NOT NULL
ORDER BY contact_verified_at DESC;
```

### Rescues without charity numbers:

```sql
-- Find rescues missing charity numbers
SELECT name, region, website
FROM dogadopt.rescues
WHERE charity_number IS NULL
ORDER BY name;
```

## Troubleshooting

### Issue: "Missing CHARITY_COMMISSION_API_KEY"

**Solution:**
1. Sign up at https://developer.charitycommission.gov.uk/
2. Subscribe to the API product
3. Add your API key to `.env` file

### Issue: "404 - Charity not found"

**Possible causes:**
- Charity number is incorrect
- Organization is not a registered charity
- Organization is registered in Scotland (use Scottish register instead)

**Solution:**
- Verify charity number at https://register-of-charities.charitycommission.gov.uk/
- For Scottish charities, use: https://www.oscr.org.uk/

### Issue: "429 - Rate limited"

**Solution:**
- Script automatically retries with exponential backoff
- Ensure `RATE_LIMIT_DELAY` is set to at least 1000ms
- If persistent, wait 5 minutes and try again

### Issue: No contact details in API response

**Possible causes:**
- Charity hasn't updated their details
- Details are marked as private
- Recently registered charity

**Solution:**
- Fall back to web scraping for these specific rescues
- Contact the charity directly to update their register entry

## Benefits Over Web Scraping

✅ **Official Data**: Directly from Charity Commission register  
✅ **Always Current**: Charities required to keep register updated  
✅ **Reliable Format**: Structured JSON response  
✅ **No Parsing Errors**: No HTML/CSS changes to break  
✅ **Compliant**: Using official public API  
✅ **Faster**: Single API call vs multiple page loads  
✅ **Automatic Postcode**: Addresses always include postcodes  

## Rate Limiting

The script enforces a 1-second delay between requests to comply with API terms:

```javascript
const RATE_LIMIT_DELAY = 1000; // 1 request per second
```

For ~100 rescues, expect the script to run for approximately **2-3 minutes**.

## Future Enhancements

- [ ] Bulk charity number lookup by organization name
- [ ] Scheduled automatic re-collection (monthly)
- [ ] Integration with Scottish Charity Register (OSCR)
- [ ] Admin UI to trigger collection and view results
- [ ] Webhook notifications when contact details change
- [ ] Export contact data for CRM integration

## Support

For API issues:
- Charity Commission Developer Portal: https://developer.charitycommission.gov.uk/
- Support email: charitycommissionapi@charitycommission.gov.uk

For script issues:
- Check the logs for specific error messages
- Review the troubleshooting section above
- Create an issue in the repository
