#!/usr/bin/env node

/**
 * Charity Number Finder
 * 
 * This script searches the Charity Commission API to find charity registration
 * numbers for rescue organizations, then updates the seed.sql file.
 * 
 * Usage: node scripts/find-charity-numbers.js
 */

import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { config } from 'dotenv';
import { readFileSync, writeFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env.local') });

const charityApiKey = process.env.CHARITY_COMMISSION_API_KEY;

if (!charityApiKey) {
  console.error('❌ Missing CHARITY_COMMISSION_API_KEY in .env file\n');
  process.exit(1);
}

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_PUBLISHABLE_KEY,
  { db: { schema: 'dogadopt' } }
);

const API_BASE = 'https://api.charitycommission.gov.uk/register/api';
const RATE_LIMIT_DELAY = 5000; // 5 seconds between requests

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Search for charity by name
 */
async function searchCharityByName(name, retries = 3) {
  const encodedName = encodeURIComponent(name);
  const url = `${API_BASE}/searchCharityName/${encodedName}`;
  
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const response = await fetch(url, {
        headers: {
          'Cache-Control': 'no-cache',
          'Ocp-Apim-Subscription-Key': charityApiKey,
        },
        timeout: 15000,
      });

      if (response.status === 404) {
        return { notFound: true };
      }

      if (response.status === 429) {
        const waitTime = Math.pow(2, attempt) * 1000;
        console.log(`     ⏳ Rate limited, waiting ${waitTime}ms...`);
        await delay(waitTime);
        continue;
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      
      if (!data || data.length === 0) {
        return { notFound: true };
      }

      // Return registered charities only
      const registeredCharities = data.filter(c => c.reg_status === 'R');
      
      if (registeredCharities.length === 0) {
        return { notFound: true, hasRemoved: true };
      }

      return {
        success: true,
        results: registeredCharities,
        charityNumber: registeredCharities[0].reg_charity_number.toString(),
        charityName: registeredCharities[0].charity_name,
      };

    } catch (error) {
      if (attempt === retries) {
        throw error;
      }
      const waitTime = Math.pow(2, attempt) * 1000;
      await delay(waitTime);
    }
  }
}

/**
 * Main execution
 */
async function main() {
  console.log('🔍 Charity Number Finder\n');
  console.log('Searching Charity Commission API for registration numbers...\n');
  
  // Get rescues without charity numbers
  const { data: rescues, error } = await supabase
    .from('rescues')
    .select('id, name')
    .is('charity_number', null)
    .order('name');
  
  if (error) {
    console.error('Failed to fetch rescues:', error);
    process.exit(1);
  }
  
  if (rescues.length === 0) {
    console.log('✓ All rescues already have charity numbers!\n');
    return;
  }
  
  console.log(`Found ${rescues.length} rescues without charity numbers\n`);
  console.log('─'.repeat(70));
  
  const results = [];
  let found = 0;
  let notFound = 0;
  
  for (const rescue of rescues) {
    console.log(`\n📍 ${rescue.name}`);
    
    try {
      const result = await searchCharityByName(rescue.name);
      
      if (result.notFound) {
        console.log(`   ⚠️  Not found in register${result.hasRemoved ? ' (removed/dissolved)' : ''}`);
        notFound++;
        results.push({
          name: rescue.name,
          charityNumber: null,
          status: 'not_found',
        });
      } else if (result.success) {
        console.log(`   ✓ Found: ${result.charityName}`);
        console.log(`   🔢 Charity #${result.charityNumber}`);
        
        if (result.results.length > 1) {
          console.log(`   ℹ️  Multiple matches found (${result.results.length}), using first`);
        }
        
        found++;
        results.push({
          name: rescue.name,
          charityNumber: result.charityNumber,
          officialName: result.charityName,
          status: 'found',
        });
      }
      
      await delay(RATE_LIMIT_DELAY);
      
    } catch (error) {
      console.error(`   ✗ Error: ${error.message}`);
      notFound++;
      results.push({
        name: rescue.name,
        charityNumber: null,
        status: 'error',
        error: error.message,
      });
    }
  }
  
  console.log('\n' + '─'.repeat(70));
  console.log(`\n📊 Summary:`);
  console.log(`  ✓ Found: ${found}`);
  console.log(`  ⚠️  Not found: ${notFound}`);
  
  // Export results to CSV
  const csvPath = join(__dirname, '..', 'charity-numbers.csv');
  const csvHeader = 'Rescue Name,Charity Number,Official Name,Status\n';
  const csvRows = results.map(r => {
    const name = `"${r.name.replace(/"/g, '""')}"`;
    const charityNumber = r.charityNumber || '';
    const officialName = r.officialName ? `"${r.officialName.replace(/"/g, '""')}"` : '';
    const status = r.status;
    return `${name},${charityNumber},${officialName},${status}`;
  }).join('\n');
  
  writeFileSync(csvPath, csvHeader + csvRows, 'utf8');
  console.log(`\n💾 Saved results to: charity-numbers.csv`);
  console.log(`   ${found} charities found, ${notFound} not found`);
  
  // Show results that need manual review
  const needsReview = results.filter(r => r.status !== 'found');
  
  if (needsReview.length > 0) {
    console.log(`\n⚠️  The following rescues need manual lookup:\n`);
    needsReview.forEach(r => {
      console.log(`  • ${r.name}`);
    });
    console.log(`\n  Search manually at: https://register-of-charities.charitycommission.gov.uk/`);
  }
  
  // Generate SQL output
  console.log(`\n📝 Generating updated seed.sql...\n`);
  
  const seedPath = join(__dirname, '..', 'supabase', 'seed.sql');
  let seedContent = readFileSync(seedPath, 'utf8');
  
  let updatedCount = 0;
  
  for (const result of results) {
    if (result.status === 'found') {
      // Find the line for this rescue and add charity number
      const escapedName = result.name.replace(/'/g, "''");
      
      // Pattern: ('Name', 'Full', 'Region', 'website'),
      // Should become: ('Name', 'Full', 'Region', 'website', 'charity_number'),
      const regex = new RegExp(
        `\\('${escapedName}'[^)]+\\),`,
        'g'
      );
      
      const match = seedContent.match(regex);
      
      if (match) {
        const oldLine = match[0];
        // Check if it already has a charity number (5th parameter)
        const params = oldLine.match(/'\w+'/g);
        
        if (params && params.length === 4) {
          // Add charity number before the closing ),
          const newLine = oldLine.replace('),', `, '${result.charityNumber}'),`);
          seedContent = seedContent.replace(oldLine, newLine);
          updatedCount++;
          console.log(`  ✓ Updated: ${result.name} → ${result.charityNumber}`);
        }
      }
    }
  }
  
  if (updatedCount > 0) {
    writeFileSync(seedPath, seedContent, 'utf8');
    console.log(`\n✅ Updated ${updatedCount} rescues in seed.sql`);
    console.log(`\nNext steps:`);
    console.log(`  1. Review the changes: git diff supabase/seed.sql`);
    console.log(`  2. Apply changes: npm run supabase:reset`);
    console.log(`  3. Collect contact data: npm run collect-contacts\n`);
  } else {
    console.log(`\n⚠️  No automatic updates possible`);
    console.log(`   Check charity-numbers.csv for found charities`);
    console.log(`   You can manually add them to seed.sql\n`);
  }
}

main().catch(console.error);
