#!/usr/bin/env node

/**
 * Geocode Rescues Script
 * 
 * Fetches latitude/longitude coordinates for rescues based on their postcodes
 * using the free postcodes.io API (no API key required).
 * 
 * Usage:
 *   node scripts/geocode-rescues.js [--dry-run] [--force] [--csv <filename>]
 * 
 * Options:
 *   --dry-run  Show what would be updated without making changes
 *   --force    Re-geocode rescues that already have coordinates
 *   --csv      Output results to CSV file (e.g., --csv rescue-coordinates.csv)
 */

import { createClient } from '@supabase/supabase-js';
import { writeFileSync } from 'fs';
import { join } from 'path';

const SUPABASE_URL = process.env.SUPABASE_URL || 'http://127.0.0.1:54321';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const forceUpdate = args.includes('--force');
const csvIndex = args.indexOf('--csv');
const csvFilename = csvIndex !== -1 && args[csvIndex + 1] ? args[csvIndex + 1] : null;

// Initialize Supabase client
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  db: {
    schema: 'dogadopt'
  }
});

/**
 * Geocode a UK postcode using the free postcodes.io API
 */
async function geocodePostcode(postcode) {
  if (!postcode) return null;
  
  // Clean postcode (remove spaces, uppercase)
  const cleanPostcode = postcode.replace(/\s+/g, '').toUpperCase();
  
  try {
    const response = await fetch(`https://api.postcodes.io/postcodes/${cleanPostcode}`);
    
    if (!response.ok) {
      if (response.status === 404) {
        console.warn(`  ⚠️  Postcode not found: ${postcode}`);
        return null;
      }
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const data = await response.json();
    
    if (data.status === 200 && data.result) {
      return {
        latitude: data.result.latitude,
        longitude: data.result.longitude,
        postcode: data.result.postcode // normalized postcode
      };
    }
    
    return null;
  } catch (error) {
    console.error(`  ❌ Error geocoding ${postcode}:`, error.message);
    return null;
  }
}

/**
 * Add delay between API calls to be respectful
 */
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  console.log('🗺️  Geocoding Rescues\n');
  console.log(`Mode: ${isDryRun ? 'DRY RUN (no changes)' : 'LIVE'}`);
  console.log(`Force update: ${forceUpdate ? 'YES' : 'NO'}`);
  console.log(`CSV output: ${csvFilename || 'NO'}\n`);
  
  // Fetch rescues that need geocoding
  let query = supabase
    .from('rescues')
    .select('id, name, postcode, latitude, longitude')
    .not('postcode', 'is', null);
  
  if (!forceUpdate) {
    query = query.is('latitude', null);
  }
  
  const { data: rescues, error } = await query;
  
  if (error) {
    console.error('❌ Error fetching rescues:', error.message);
    process.exit(1);
  }
  
  if (!rescues || rescues.length === 0) {
    console.log('✅ No rescues need geocoding!');
    return;
  }
  
  console.log(`Found ${rescues.length} rescue(s) to geocode:\n`);
  
  let successCount = 0;
  let failCount = 0;
  let skippedCount = 0;
  const csvRows = [];
  
  for (const rescue of rescues) {
    console.log(`📍 ${rescue.name}`);
    console.log(`   Postcode: ${rescue.postcode}`);
    
    if (rescue.latitude && !forceUpdate) {
      console.log('   ⏭️  Already has coordinates (use --force to update)');
      skippedCount++;
      continue;
    }
    
    const result = await geocodePostcode(rescue.postcode);
    
    if (result) {
      console.log(`   ✓ Coordinates: ${result.latitude}, ${result.longitude}`);
      
      // Add to CSV output
      if (csvFilename) {
        csvRows.push({
          id: rescue.id,
          name: rescue.name,
          postcode: result.postcode,
          latitude: result.latitude,
          longitude: result.longitude
        });
      }
      
      if (!isDryRun && !csvFilename) {
        const { error: updateError } = await supabase
          .from('rescues')
          .update({
            latitude: result.latitude,
            longitude: result.longitude,
            coordinates_updated_at: new Date().toISOString(),
            coordinates_source: 'postcodes.io'
          })
          .eq('id', rescue.id);
        
        if (updateError) {
          console.error(`   ❌ Update failed:`, updateError.message);
          failCount++;
        } else {
          console.log('   💾 Saved to database');
          successCount++;
        }
      } else {
        console.log(`   ${csvFilename ? '📝 Added to CSV' : '[Would save to database]'}`);
        successCount++;
      }
    } else {
      failCount++;
    }
    
    console.log('');
    
    // Be nice to the API - wait 200ms between requests
    await delay(200);
  }
  
  console.log('\n' + '='.repeat(50));
  console.log('📊 Summary:');
  console.log(`   ✅ Successful: ${successCount}`);
  console.log(`   ❌ Failed: ${failCount}`);
  if (skippedCount > 0) {
    console.log(`   ⏭️  Skipped: ${skippedCount}`);
  }
  console.log('='.repeat(50));
  
  // Write CSV file if requested
  if (csvFilename && csvRows.length > 0) {
    const csvContent = [
      'id,name,postcode,latitude,longitude',
      ...csvRows.map(row => 
        `${row.id},"${row.name.replace(/"/g, '""')}","${row.postcode}",${row.latitude},${row.longitude}`
      )
    ].join('\n');
    
    const csvPath = join(process.cwd(), csvFilename);
    writeFileSync(csvPath, csvContent, 'utf8');
    console.log(`\n📄 CSV file saved: ${csvPath}`);
    console.log(`   ${csvRows.length} row(s) written`);
    
    // Also generate SQL UPDATE statements
    const sqlFilename = csvFilename.replace('.csv', '.sql');
    const sqlStatements = csvRows.map(row => 
      `UPDATE dogadopt.rescues SET latitude = ${row.latitude}, longitude = ${row.longitude}, coordinates_source = 'postcodes.io' WHERE id = '${row.id}'; -- ${row.name}`
    ).join('\n');
    
    const sqlPath = join(process.cwd(), sqlFilename);
    writeFileSync(sqlPath, sqlStatements, 'utf8');
    console.log(`\n📝 SQL file saved: ${sqlPath}`);
    console.log(`   Ready to copy into seed.sql`);
  }
  
  if (isDryRun) {
    console.log('\n💡 Run without --dry-run to apply changes');
  }
  
  if (csvFilename && !isDryRun) {
    console.log('\n💡 Note: CSV mode does not update the database directly');
    console.log('   Use the generated SQL file or run without --csv to update');
  }
}

main().catch(console.error);
