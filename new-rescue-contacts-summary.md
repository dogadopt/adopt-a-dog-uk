# New ADCH Member Rescues - Contact Details Collection Summary

**Date:** 2025-12-31  
**Total Rescues Processed:** 29  
**Successfully Collected:** 18  
**Skipped (No Charity Number):** 11

## Summary

This report contains contact details collected from the UK Charity Commission API for rescues added to the seed.sql file under "Additional ADCH member rescues added 2025-12-31".

### Rescues with Contact Details Collected (18)

| Rescue Name | Phone | Email | Region |
|-------------|-------|-------|--------|
| Band of Rescuers North Yorkshire | 07967811171 | bandofrescuersteam@gmail.com | Yorkshire & The Humber |
| Pawprints Dog Rescue | 07415030165 | pdrescue@hotmail.com | West Midlands |
| PAWS Animal Rescue | 07565887332 | hampshirepaws@outlook.com | Ireland |
| People for Animal Care Trust (PACT) | 01362820775 | pactsanctuary@btconnect.com | East England |
| Phoenix French Bulldog Rescue | 03007727716 | ENQUIRIES@PHOENIXFRENCHBULLDOGRESCUE.ORG | East England |
| Pro Dogs Direct | 07766 021 465 | Info@ProDogsDirect.Org.Uk | South East England |
| Rain Rescue | 01709247777 | info@rainrescue.co.uk | Yorkshire & The Humber |
| Raystede Centre for Animal Welfare | 01825840252 | info@raystede.org | South East England |
| Rescue Me Animal Sanctuary | 07952017696 | info@rescueme.org.uk | North West England |
| Rottweiler Welfare Association | 07946083070 | secretary@rottweilerwelfare.co.uk | West Midlands |
| RSPCA Brighton & The Heart of Sussex | 01273554218 | info@rspcabrighton.org.uk | South East England |
| RSPCA Canterbury and District Branch | 01227719113 | admin@rspca-canterbury.org.uk | South East England |
| RSPCA Chesterfield and North Derbyshire Branch | 01246273358 | info@chesterfield-rspca.org.uk | South East |
| RSPCA Cornwall | 01637881455 | ADMIN@RSPCACORNWALL.ORG.UK | South West England |
| RSPCA Coventry and District Branch | 02476336616 | info@rspca-coventryanddistrict.org.uk | West Midlands |
| RSPCA Kent Isle of Thanet Branch | 01843826179 | info@rspcathanet.org.uk | South East England |
| RSPCA Lancashire East Branch | 01254231118 | info@rspca-lancseast.org.uk | North West England |
| RSPCA (main) | 01227719113 | admin@rspca-canterbury.org.uk | National |

### Rescues Without Charity Numbers (11)

These rescues could not be queried via the Charity Commission API:

- Animals in Need Northants
- Ashbourne & District Animal Welfare Society
- Clare Animal Welfare CLG
- Greyhound Trust - National Greyhound Centre
- Guernsey SPCA
- Jersey SPCA Animals' Shelter
- Manx SPCA
- Mayo SPCA
- Rainbow Rescue
- Rosie's Trust
- RSPCA Little Valley

## Files Generated

- **new-rescue-contacts.csv** - Full CSV with both database values and API-collected values
- **new-rescue-contacts-summary.md** - This summary document

## Next Steps

The collected contact details can be used to:
1. Update the seed.sql file with phone, email, address, and postcode information
2. Create a migration to populate these fields in the database
3. Enhance rescue profiles on the website with official contact information

## Notes

- All data collected from the official UK Charity Commission API
- Contact details are current as of collection date
- Some rescues (Channel Islands, Isle of Man, Ireland) may not be in the UK Charity Commission register
- Rate limiting of 5 seconds between API calls was applied to respect API usage policies
