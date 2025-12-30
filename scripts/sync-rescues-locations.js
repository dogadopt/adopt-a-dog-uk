#!/usr/bin/env node

/**
 * Post-Deploy Script: Sync Rescues and Locations
 * 
 * This script synchronizes rescue and location data from the CSV source file
 * to the Supabase database. It only updates records when there are actual 
 * differences to minimize audit log noise.
 * 
 * Usage:
 *   npm run sync-rescues              # Sync to local Supabase
 *   npm run sync-rescues:prod         # Sync to production Supabase
 * 
 * Environment Variables (for production):
 *   SUPABASE_PROJECT_REF - Your Supabase project reference ID
 *   SUPABASE_ACCESS_TOKEN - Your Supabase access token
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { spawn } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Determine if running in production mode
const isProduction = process.argv.includes('--production') || process.argv.includes('--prod');

// Paths
const SQL_FILE = join(__dirname, '..', 'supabase', 'post-deploy', 'sync-rescues-locations.sql');

async function runCommand(command, args, env = {}) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      stdio: 'inherit',
      env: { ...process.env, ...env },
      shell: true
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed with exit code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

async function syncLocal() {
  console.log('🔄 Syncing rescues and locations to LOCAL Supabase...\n');
  
  try {
    // Execute SQL file against local Supabase
    await runCommand('docker', [
      'exec',
      '-i',
      'supabase_db_dog-adopt',
      'psql',
      '-U', 'postgres',
      '-f', '-'
    ], {});
    
    // Read and pipe the SQL file
    const sql = readFileSync(SQL_FILE, 'utf8');
    const proc = spawn('docker', [
      'exec',
      '-i',
      'supabase_db_dog-adopt',
      'psql',
      '-U', 'postgres'
    ], {
      stdio: ['pipe', 'inherit', 'inherit']
    });
    
    proc.stdin.write(sql);
    proc.stdin.end();
    
    await new Promise((resolve, reject) => {
      proc.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`psql command failed with exit code ${code}`));
        }
      });
    });
    
    console.log('\n✅ Local sync completed successfully!');
  } catch (error) {
    console.error('\n❌ Local sync failed:', error.message);
    process.exit(1);
  }
}

async function syncProduction() {
  console.log('🔄 Syncing rescues and locations to PRODUCTION Supabase...\n');
  
  // Check required environment variables
  const projectRef = process.env.SUPABASE_PROJECT_REF;
  const accessToken = process.env.SUPABASE_ACCESS_TOKEN;
  
  if (!projectRef || !accessToken) {
    console.error('❌ Missing required environment variables:');
    if (!projectRef) console.error('  - SUPABASE_PROJECT_REF');
    if (!accessToken) console.error('  - SUPABASE_ACCESS_TOKEN');
    console.error('\nPlease set these variables before running the production sync.');
    process.exit(1);
  }
  
  try {
    // Link to Supabase project
    console.log('Linking to Supabase project...');
    await runCommand('supabase', ['link', '--project-ref', projectRef], {
      SUPABASE_ACCESS_TOKEN: accessToken
    });
    
    // Execute SQL file via Supabase CLI
    console.log('Executing sync script...');
    await runCommand('supabase', ['db', 'execute', '--file', SQL_FILE], {
      SUPABASE_ACCESS_TOKEN: accessToken
    });
    
    console.log('\n✅ Production sync completed successfully!');
  } catch (error) {
    console.error('\n❌ Production sync failed:', error.message);
    console.error('\nTroubleshooting:');
    console.error('  1. Verify SUPABASE_ACCESS_TOKEN is valid');
    console.error('  2. Verify SUPABASE_PROJECT_REF matches your project');
    console.error('  3. Check that Supabase CLI is installed (npm install -g supabase)');
    process.exit(1);
  }
}

async function main() {
  console.log('═══════════════════════════════════════════════════');
  console.log('  Rescues & Locations Data Sync');
  console.log('═══════════════════════════════════════════════════\n');
  
  if (isProduction) {
    await syncProduction();
  } else {
    await syncLocal();
  }
  
  console.log('\n📋 Next steps:');
  console.log('  - Verify the changes in your database');
  console.log('  - Check the audit logs for any updates');
  console.log('  - Test the application to ensure data is correct');
  console.log('\n═══════════════════════════════════════════════════\n');
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
