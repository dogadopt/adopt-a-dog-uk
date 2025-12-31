#!/usr/bin/env node

/**
 * Collect missing contact details for all rescues with charity numbers
 */

import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { config } from 'dotenv';
import { writeFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env.local') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
const charityApiKey = process.env.CHARITY_COMMISSION_API_KEY;

if (!supabaseUrl || !supabaseKey || !charityApiKey) {
  console.error('❌ Missing credentials in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'dogadopt' }
});

const API_BASE = 'https://api.charitycommission.gov.uk/register/api';
const RATE_LIMIT_DELAY = 5000;

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

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

      if (response.status === 404) return { notFound: true };
      if (response.status === 429) {
        const waitTime = Math.pow(2, attempt) * 1000;
        console.log(`     ⏳ Rate limited, waiting ${waitTime}ms...`);
        await delay(waitTime);
        continue;
      }
      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      const data = await response.json();
      return {
        phone: data.phone || null,
        email: data.email || null,
        address: data.contact_address || null,
        website: data.web || null,
        success: true,
      };
    } catch (error) {
      if (attempt === retries) throw error;
      await delay(Math.pow(2, attempt) * 1000);
    }
  }
}

function extractPostcode(address) {
  if (!address) return null;
  const match = address.match(/\b([A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2})\b/i);
  return match ? match[1].toUpperCase() : null;
}

function formatCsvValue(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

async function main() {
  console.log('🐕 Collecting missing contact details for rescues with charity numbers\n');
  
  const { data: rescues, error } = await supabase
    .from('rescues')
    .select('id, name, charity_number, region, website, phone, email')
    .not('charity_number', 'is', null)
    .or('phone.is.null,email.is.null')
    .order('name');
  
  if (error) {
    console.error('Failed to fetch rescues:', error);
    process.exit(1);
  }
  
  console.log(`Found ${rescues.length} rescues with charity numbers but missing contacts\n`);
  console.log('─'.repeat(60));
  
  const results = [];
  let successful = 0;
  
  for (const rescue of rescues) {
    console.log(`\n📍 ${rescue.name}`);
    console.log(`   Charity #${rescue.charity_number}`);
    
    try {
      const data = await fetchCharityContactInfo(rescue.charity_number);
      
      if (data.notFound) {
        console.log(`   ⚠️  Not found in register`);
        results.push({ rescue, phone: null, email: null, address: null, postcode: null });
      } else if (data.success) {
        const postcode = extractPostcode(data.address);
        console.log(`   ✓ Contact details retrieved`);
        if (data.phone) console.log(`     📞 ${data.phone}`);
        if (data.email) console.log(`     📧 ${data.email}`);
        if (data.address) console.log(`     📍 ${data.address}`);
        if (postcode) console.log(`     📮 ${postcode}`);
        
        results.push({
          rescue,
          phone: data.phone,
          email: data.email,
          address: data.address,
          postcode: postcode,
        });
        successful++;
      }
      
      await delay(RATE_LIMIT_DELAY);
    } catch (error) {
      console.error(`   ✗ Error: ${error.message}`);
      results.push({ rescue, phone: null, email: null, address: null, postcode: null });
    }
  }
  
  // Write CSV
  const csvHeader = 'Rescue Name,Charity Number,Region,DB Phone,DB Email,API Phone,API Email,API Address,API Postcode\n';
  const csvRows = results.map(r => [
    formatCsvValue(r.rescue.name),
    formatCsvValue(r.rescue.charity_number),
    formatCsvValue(r.rescue.region),
    formatCsvValue(r.rescue.phone),
    formatCsvValue(r.rescue.email),
    formatCsvValue(r.phone),
    formatCsvValue(r.email),
    formatCsvValue(r.address),
    formatCsvValue(r.postcode),
  ].join(',')).join('\n');
  
  const csvContent = csvHeader + csvRows;
  const outputPath = join(__dirname, '..', 'missing-rescue-contacts.csv');
  writeFileSync(outputPath, csvContent, 'utf-8');
  
  console.log('\n' + '─'.repeat(60));
  console.log(`\n✓ Complete! Processed ${rescues.length} rescues`);
  console.log(`  ✓ Successfully collected: ${successful}`);
  console.log(`\n📄 Results saved to: missing-rescue-contacts.csv\n`);
}

main().catch(console.error);
