#!/usr/bin/env node

/**
 * Generate SQL migration from rescues.json
 * Maps rescue data from dogadopt.github.io format to our database schema
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Read the JSON data
const rescuesData = JSON.parse(fs.readFileSync('/tmp/rescues.json', 'utf8'));

console.log('Processing rescue data...');
console.log(`Total entries: ${rescuesData.length}`);

// Group by rescue name to handle duplicates
const rescueGroups = {};
rescuesData.forEach(entry => {
  const name = entry.rescue_name;
  if (!rescueGroups[name]) {
    rescueGroups[name] = [];
  }
  rescueGroups[name].push(entry);
});

console.log(`Unique rescues: ${Object.keys(rescueGroups).length}`);

// Function to escape SQL strings
function escapeSql(str) {
  if (!str) return null;
  return str.replace(/'/g, "''");
}

// Function to determine region from country
function determineRegion(country, rescueName) {
  const regionMap = {
    'England': 'England',
    'Wales': 'Wales',
    'Scotland': 'Scotland',
    'Northern Ireland': 'Northern Ireland',
    'Ireland': 'Ireland',
    'Isle of Man': 'Isle of Man'
  };
  return regionMap[country] || country;
}

// Function to build website URL
function buildWebsiteUrl(entry) {
  if (!entry.website) return null;
  
  let url = entry.website;
  // Ensure protocol
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://' + url;
  }
  
  // Remove trailing slash to avoid double slashes when appending paths
  url = url.replace(/\/+$/, '');
  
  return url;
}

// Function to build full URL with path
function buildFullUrl(baseUrl, path) {
  if (!baseUrl) return null;
  if (!path) return null;
  
  // Ensure path starts with exactly one slash
  if (!path.startsWith('/')) {
    path = '/' + path;
  }
  path = path.replace(/^\/+/, '/');
  
  return baseUrl + path;
}

// Generate SQL
let migrationSql = `-- Update rescue and location data from dogadopt.github.io
-- Source: https://github.com/dogadopt/dogadopt.github.io/blob/main/rescues.json
-- Generated: ${new Date().toISOString()}

-- IMPORTANT: This migration replaces ALL rescue and location data
-- This is safe for initial setup, but if there are existing dogs,
-- their rescue_id references will become invalid.

-- First, clear existing data (keeping audit logs)
-- Note: locations can be safely deleted (has ON DELETE SET NULL for dogs.location_id)
DELETE FROM dogadopt.locations;

-- Temporarily disable the foreign key constraint on dogs.rescue_id to allow deletion
-- This is safe because we're replacing all rescues immediately after
ALTER TABLE dogadopt.dogs DROP CONSTRAINT IF EXISTS dogs_rescue_id_fkey;
DELETE FROM dogadopt.rescues;

-- Re-enable the foreign key constraint
-- Note: We use ON DELETE RESTRICT to prevent accidental rescue deletion in the future
ALTER TABLE dogadopt.dogs 
ADD CONSTRAINT dogs_rescue_id_fkey 
FOREIGN KEY (rescue_id) 
REFERENCES dogadopt.rescues(id) 
ON DELETE RESTRICT;

-- Insert rescues with location data
`;

Object.entries(rescueGroups).forEach(([rescueName, locations]) => {
  const firstLocation = locations[0];
  const websiteUrl = buildWebsiteUrl(firstLocation);
  const region = determineRegion(firstLocation.country, rescueName);
  
  // Insert rescue
  migrationSql += `\n-- ${rescueName} (${region})\n`;
  migrationSql += `INSERT INTO dogadopt.rescues (name, type, region, website) VALUES\n`;
  migrationSql += `  ('${escapeSql(rescueName)}', 'Full', '${escapeSql(region)}', ${websiteUrl ? `'${escapeSql(websiteUrl)}'` : 'NULL'});\n`;
  
  // Insert locations for this rescue
  locations.forEach((loc, idx) => {
    const locationName = locations.length > 1 
      ? `${rescueName} - Location ${idx + 1}` 
      : rescueName;
    
    const city = loc.country || 'Unknown';
    const baseUrl = buildWebsiteUrl(firstLocation);
    const websiteDogsUrl = loc.website_dogs ? buildFullUrl(baseUrl, loc.website_dogs) : null;
    
    migrationSql += `INSERT INTO dogadopt.locations (rescue_id, name, city, region, latitude, longitude, enquiry_url, location_type, is_public)\n`;
    migrationSql += `SELECT id, '${escapeSql(locationName)}', '${escapeSql(city)}', '${escapeSql(region)}', `;
    migrationSql += loc.lat ? `${parseFloat(loc.lat)}` : 'NULL';
    migrationSql += ', ';
    migrationSql += loc.lng ? `${parseFloat(loc.lng)}` : 'NULL';
    migrationSql += ', ';
    migrationSql += websiteDogsUrl ? `'${escapeSql(websiteDogsUrl)}'` : 'NULL';
    migrationSql += `, 'centre', true\n`;
    migrationSql += `FROM dogadopt.rescues WHERE name = '${escapeSql(rescueName)}';\n\n`;
  });
});

// Add completion notes
migrationSql += `\n-- Migration complete!`;
migrationSql += `\n-- Total rescues inserted: ${Object.keys(rescueGroups).length}`;
migrationSql += `\n-- Total locations inserted: ${rescuesData.length}`;
migrationSql += `\n-- Note: All audit logs preserved, changes tracked in audit system\n`;

// Write the migration file
const timestamp = new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14);
const migrationPath = path.join(__dirname, '..', 'supabase', 'migrations', `${timestamp}_update_rescues_and_locations_data.sql`);

fs.writeFileSync(migrationPath, migrationSql);

console.log(`\nMigration file created: ${migrationPath}`);
console.log(`Total rescues to insert: ${Object.keys(rescueGroups).length}`);
console.log(`Total locations to insert: ${rescuesData.length}`);
