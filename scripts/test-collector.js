#!/usr/bin/env node

/**
 * Test script to verify the Charity Commission API collector works
 * Usage: node scripts/test-collector.js
 */

import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch';
import { config } from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

config({ path: join(__dirname, '..', '.env') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_PUBLISHABLE_KEY;
const charityApiKey = process.env.CHARITY_COMMISSION_API_KEY;

if (!charityApiKey) {
  console.error('❌ Missing CHARITY_COMMISSION_API_KEY in .env file');
  console.error('\nGet your API key from: https://developer.charitycommission.gov.uk/\n');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  db: { schema: 'dogadopt' }
});

const API_BASE = 'https://api.charitycommission.gov.uk/register/api';

async function testSingleRescue() {
  console.log('🧪 Testing Charity Commission API collector...\n');
  
  // Get first rescue with a charity number
  const { data: rescues, error } = await supabase
    .from('rescues')
    .select('id, name, charity_number')
    .not('charity_number', 'is', null)
    .limit(1);
  
  if (error || !rescues || rescues.length === 0) {
    console.error('❌ No rescues with charity numbers found');
    console.error('Add charity numbers to seed.sql first\n');
    return;
  }
  
  const rescue = rescues[0];
  console.log(`Testing with: ${rescue.name}`);
  console.log(`Charity Number: ${rescue.charity_number}\n`);
  
  const url = `${API_BASE}/charitycontactinformation/${rescue.charity_number}/0`;
  console.log(`API Endpoint: ${url}\n`);
  
  try {
    console.log('Making API request...');
    const response = await fetch(url, {
      headers: {
        'Cache-Control': 'no-cache',
        'Ocp-Apim-Subscription-Key': charityApiKey,
      },
    });
    
    console.log(`Response Status: ${response.status} ${response.statusText}\n`);
    
    if (!response.ok) {
      if (response.status === 404) {
        console.log('❌ Charity not found in register');
        console.log('   Check the charity number is correct\n');
      } else if (response.status === 401) {
        console.log('❌ Authentication failed');
        console.log('   Check your API key is correct\n');
      } else {
        console.log(`❌ API error: ${response.status}`);
      }
      return;
    }
    
    const data = await response.json();
    
    console.log('✅ API Response received!\n');
    console.log('📋 Contact Information:');
    console.log('═'.repeat(60));
    console.log(`📞 Phone:    ${data.phone || 'Not provided'}`);
    console.log(`📧 Email:    ${data.email || 'Not provided'}`);
    console.log(`🌐 Website:  ${data.web || 'Not provided'}`);
    console.log(`📍 Address:  ${data.contact_address || 'Not provided'}`);
    console.log('═'.repeat(60));
    
    // Extract postcode
    if (data.contact_address) {
      const postcodeMatch = data.contact_address.match(/\b([A-Z]{1,2}\d{1,2}[A-Z]?\s?\d[A-Z]{2})\b/i);
      if (postcodeMatch) {
        console.log(`\n📬 Extracted Postcode: ${postcodeMatch[1].toUpperCase()}`);
      }
    }
    
    console.log('\n✅ Test completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('  1. Ensure all rescues have charity numbers in seed.sql');
    console.log('  2. Run: npm run collect-contacts');
    console.log('  3. Check database for collected data\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    
    if (error.code === 'ENOTFOUND') {
      console.error('\n   Check your internet connection\n');
    }
  }
}

testSingleRescue().catch(console.error);
