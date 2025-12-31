#!/usr/bin/env node

/**
 * UK Charity Commission API Contact Details Collector
 * 
 * This script collects official contact information for rescue organizations
 * using the UK Charity Commission API.
 * 
 * API Documentation: https://api.charitycommission.gov.uk
 * 
 * Features:
 * - Official data from Charity Commission register
 * - Rate limiting (5 seconds between requests)
 * - Automatic retry with exponential backoff
 * - Collects: phone, email, address, postcode, website
 * - Outputs to CSV file: rescue-contacts.csv
 * 
 * Setup:
 * 1. Get API key from: https://developer.charitycommission.gov.uk/
 * 2. Add to .env: CHARITY_COMMISSION_API_KEY=your_key
 * 
 * Usage: node scripts/collect-rescue-details.js
 */

import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { config } from 'dotenv';
import { writeFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
config({ path: join(__dirname, '..', '.env.local') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
const charityApiKey = process.env.CHARITY_COMMISSION_API_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase credentials in .env file');
  process.exit(1);
}

if (!charityApiKey) {
  console.error('❌ Missing CHARITY_COMMISSION_API_KEY in .env file');
  console.error('\nTo get an API key:');
  console.error('1. Visit: https://developer.charitycommission.gov.uk/');
  console.error('2. Sign up for a free account');
  console.error('3. Subscribe to the "Charity Commission API" product');
  console.error('4. Add CHARITY_COMMISSION_API_KEY=your_key to .env\n');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'dogadopt' }
});

// Charity Commission API configuration
const API_BASE = 'https://api.charitycommission.gov.uk/register/api';
const RATE_LIMIT_DELAY = 5000; // 5 seconds between requests

/**
 * Add delay between requests
 */
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

/**
 * Fetch contact information from Charity Commission API
 */
async function fetchCharityContactInfo(charityNumber, retries = 3) {
  const url = `${API_BASE}/charitycontactinformation/${charityNumber}/0`;
  
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
        // Rate limited - wait longer
        const waitTime = Math.pow(2, attempt) * 1000;
        console.log(`     ⏳ Rate limited, waiting ${waitTime}ms...`);
        await delay(waitTime);
        continue;
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      return {
        phone: data.phone || null,
        email: data.email || null,
        address: data.contact_address || null,
        website: data.web || null,
        success: true,
      };

    } catch (error) {
      if (attempt === retries) {
        throw error;
      }
      const waitTime = Math.pow(2, attempt) * 1000;
      console.log(`     ⚠️  Attempt ${attempt} failed, retrying in ${waitTime}ms...`);
      await delay(waitTime);
    }
  }
}

/**
 * Extract postcode from address string
 */
function extractPostcode(address) {
  if (!address) return null;
  
  // UK postcode pattern
  const postcodeMatch = address.match(/\b([A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2})\b/i);
  return postcodeMatch ? postcodeMatch[1].toUpperCase() : null;
}

/**
 * Collect details for a single rescue
 */
async function collectRescueDetails(rescue) {
  console.log(`\n📍 ${rescue.name}`);
  
  if (!rescue.charity_number) {
    console.log(`   ⚠️  No charity number - skipping`);
    return null;
  }
  
  console.log(`   Charity #${rescue.charity_number}`);
  
  try {
    const data = await fetchCharityContactInfo(rescue.charity_number);
    
    if (data.notFound) {
      console.log(`   ⚠️  Not found in Charity Commission register`);
      return null;
    }
    
    if (data.success) {
      const postcode = extractPostcode(data.address);
      
      console.log(`   ✓ Contact details retrieved`);
      if (data.phone) console.log(`     📞 ${data.phone}`);
      if (data.email) console.log(`     📧 ${data.email}`);
      if (data.address) console.log(`     📍 ${data.address}`);
      if (postcode) console.log(`     📮 ${postcode}`);
      if (data.website) console.log(`     🌐 ${data.website}`);
      
      return {
        phone: data.phone,
        email: data.email,
        address: data.address,
        postcode: postcode,
        website: data.website,
      };
    }
    
  } catch (error) {
    console.error(`   ✗ Error: ${error.message}`);
    return null;
  }
}

/**
 * Format a value for CSV output (escape quotes and wrap in quotes if needed)
 */
function formatCsvValue(value) {
  if (value === null || value === undefined) return '';
  
  const str = String(value);
  // If contains comma, quote, or newline, wrap in quotes and escape existing quotes
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`; // Fixed: added missing closing quote
  }
  return str;
}

/**
 * Main execution
 */
async function main() {
  console.log('🐕 UK Charity Commission Contact Collector\n');
  console.log('Collecting official contact information from Charity Commission API\n');
  
  // Fetch rescues with charity numbers
  const { data: rescues, error } = await supabase
    .from('rescues')
    .select('id, name, charity_number, region, website')
    .not('charity_number', 'is', null)
    .order('name');
  
  if (error) {
    console.error('Failed to fetch rescues:', error);
    process.exit(1);
  }
  
  const totalRescues = rescues.length;
  console.log(`Found ${totalRescues} rescues with charity numbers\n`);
  console.log('─'.repeat(60));
  
  const results = [];
  let processed = 0;
  let successful = 0;
  let skipped = 0;
  
  for (const rescue of rescues) {
    try {
      const details = await collectRescueDetails(rescue);
      
      if (details) {
        results.push({
          name: rescue.name,
          charity_number: rescue.charity_number,
          region: rescue.region,
          phone: details.phone,
          email: details.email,
          address: details.address,
          postcode: details.postcode,
          website: rescue.website,
          api_website: details.website,
        });
        successful++;
      } else {
        // Still include in CSV with empty contact fields
        results.push({
          name: rescue.name,
          charity_number: rescue.charity_number,
          region: rescue.region,
          phone: null,
          email: null,
          address: null,
          postcode: null,
          website: rescue.website,
          api_website: null,
        });
        skipped++;
      }
      
      processed++;
      
      // Rate limiting
      await delay(RATE_LIMIT_DELAY);
      
    } catch (error) {
      console.error(`\n✗ Error processing ${rescue.name}:`, error.message);
      results.push({
        name: rescue.name,
        charity_number: rescue.charity_number,
        region: rescue.region,
        phone: null,
        email: null,
        address: null,
        postcode: null,
        website: rescue.website,
        api_website: null,
      });
      skipped++;
    }
  }
  
  // Write results to CSV
  const csvHeader = 'Rescue Name,Charity Number,Region,Phone,Email,Address,Postcode,Website,API Website\n';
  const csvRows = results.map(r => 
    [
      formatCsvValue(r.name),
      formatCsvValue(r.charity_number),
      formatCsvValue(r.region),
      formatCsvValue(r.phone),
      formatCsvValue(r.email),
      formatCsvValue(r.address),
      formatCsvValue(r.postcode),
      formatCsvValue(r.website),
      formatCsvValue(r.api_website),
    ].join(',')
  ).join('\n');
  
  const csvContent = csvHeader + csvRows;
  const outputPath = join(__dirname, '..', 'rescue-contacts.csv');
  
  writeFileSync(outputPath, csvContent, 'utf-8');
  
  console.log('\n' + '─'.repeat(60));
  console.log(`\n✓ Complete! Processed ${processed}/${totalRescues} rescues`);
  console.log(`  ✓ Successfully collected: ${successful}`);
  console.log(`  ⚠️  Skipped: ${skipped}`);
  console.log(`\n📄 Results saved to: rescue-contacts.csv\n`);
  
  // Check for rescues without charity numbers
  const { count } = await supabase
    .from('rescues')
    .select('*', { count: 'exact', head: true })
    .is('charity_number', null);
  
  if (count > 0) {
    console.log(`⚠️  ${count} rescues have no charity number and were not included`);
    console.log(`   Update seed.sql with charity numbers to collect their data\n`);
  }
}

main().catch(console.error);
