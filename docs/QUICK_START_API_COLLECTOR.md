# Quick Start Guide: Charity Commission API Collector

## Step 1: Get Your API Key

1. Visit: https://developer.charitycommission.gov.uk/
2. Sign up for a free account (takes 2 minutes)
3. Subscribe to the "Charity Commission API" product
4. Copy your API key from your profile
5. Add to your `.env` file:
   ```bash
   CHARITY_COMMISSION_API_KEY=your_key_here
   ```

## Step 2: Test the API

```bash
node scripts/test-collector.js
```

Expected output:
```
✅ API Response received!

📋 Contact Information:
════════════════════════════════════════════════════════════
📞 Phone:    020 7627 9200
📧 Email:    info@battersea.org.uk
🌐 Website:  www.battersea.org.uk
📍 Address:  4 Battersea Park Road, London, SW8 4AA
════════════════════════════════════════════════════════════

📬 Extracted Postcode: SW8 4AA

✅ Test completed successfully!
```

## Step 3: Run Full Collection

```bash
npm run collect-contacts
```

This will:
- Process all rescues that have charity numbers
- Take ~2-3 minutes for ~100 rescues
- Save official contact data to database
- Automatically mark as verified

## Step 4: Verify Results

```bash
# Connect to your local Supabase
supabase db connect
```

```sql
-- View collected data
SELECT 
  name,
  charity_number,
  phone,
  email,
  postcode,
  LEFT(address, 50) as address_preview,
  contact_verified_at
FROM dogadopt.rescues
WHERE phone IS NOT NULL
ORDER BY name
LIMIT 10;
```

## Adding Missing Charity Numbers

Some rescues don't have charity numbers yet. To add them:

### Quick Lookup

1. Visit: https://register-of-charities.charitycommission.gov.uk/
2. Search for the rescue name
3. Copy the charity number
4. Update `supabase/seed.sql`:

```sql
-- Before:
('Rescue Name', 'Full', 'Region', 'www.website.co.uk'),

-- After:  
('Rescue Name', 'Full', 'Region', 'www.website.co.uk', '1234567'),
                                                        ^^^^^^^^^^^
                                                        Add charity number in quotes
```

5. Reset database:
```bash
npm run supabase:reset
```

6. Run collector again:
```bash
npm run collect-contacts
```

## Troubleshooting

### "Missing CHARITY_COMMISSION_API_KEY"

→ Follow Step 1 above to get your API key

### "404 - Charity not found"

→ Verify the charity number at: https://register-of-charities.charitycommission.gov.uk/

### "401 - Authentication failed"

→ Check your API key is correct in `.env` file

### Script runs but no data collected

→ Make sure rescues have charity numbers in `seed.sql`

Check which rescues need charity numbers:
```sql
SELECT name, website
FROM dogadopt.rescues
WHERE charity_number IS NULL
ORDER BY name;
```

## What Data You'll Get

From the Charity Commission API:
- ✅ **Official phone number**
- ✅ **Official email address**  
- ✅ **Full postal address** (with postcode)
- ✅ **Official website URL**
- ✅ **Last updated** timestamp

All data is verified and current (charities must keep their register up-to-date).

## Need Help?

- API Documentation: https://api.charitycommission.gov.uk
- Support: charitycommissionapi@charitycommission.gov.uk
- Full docs: [RESCUE_CONTACT_COLLECTION.md](RESCUE_CONTACT_COLLECTION.md)
