#!/usr/bin/env node

import { createClient } from '@supabase/supabase-js';

// Configuration
const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'http://localhost:54321';
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY || 
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

// Create Supabase client with dogadopt schema
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  db: {
    schema: 'dogadopt'
  }
});

// Sample dog data
const sampleDogs = [
  {
    id: crypto.randomUUID(),
    name: 'Buddy',
    breed: 'Golden Retriever',
    age: 'Adult',
    size: 'Large',
    gender: 'Male',
    location: 'London',
    rescue_id: null, // Will be set after rescues are created
    image: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400',
    description: 'Buddy is a friendly golden retriever who loves playing fetch and long walks in the park.',
    good_with_kids: true,
    good_with_dogs: true,
    good_with_cats: false
  },
  {
    id: crypto.randomUUID(),
    name: 'Luna',
    breed: 'Border Collie',
    age: 'Young',
    size: 'Medium',
    gender: 'Female',
    location: 'Manchester',
    rescue_id: null,
    image: 'https://images.unsplash.com/photo-1551717743-49959800b1f6?w=400',
    description: 'Luna is an intelligent and energetic border collie who needs an active family.',
    good_with_kids: true,
    good_with_dogs: true,
    good_with_cats: true
  },
  {
    id: crypto.randomUUID(),
    name: 'Max',
    breed: 'German Shepherd',
    age: 'Adult',
    size: 'Large',
    gender: 'Male',
    location: 'Birmingham',
    rescue_id: null,
    image: 'https://images.unsplash.com/photo-1589941013453-ec89f33b5e95?w=400',
    description: 'Max is a loyal and protective german shepherd who bonds deeply with his family.',
    good_with_kids: true,
    good_with_dogs: false,
    good_with_cats: false
  },
  {
    id: crypto.randomUUID(),
    name: 'Bella',
    breed: 'Labrador Mix',
    age: 'Puppy',
    size: 'Large',
    gender: 'Female',
    location: 'Bristol',
    rescue_id: null,
    image: 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400',
    description: 'Bella is a sweet labrador mix puppy who loves everyone she meets.',
    good_with_kids: true,
    good_with_dogs: true,
    good_with_cats: true
  },
  {
    id: crypto.randomUUID(),
    name: 'Charlie',
    breed: 'Beagle',
    age: 'Adult',
    size: 'Medium',
    gender: 'Male',
    location: 'Leeds',
    rescue_id: null,
    image: 'https://images.unsplash.com/photo-1544717297-fa95b6ee9643?w=400',
    description: 'Charlie is a curious beagle who loves to explore and follow interesting scents.',
    good_with_kids: true,
    good_with_dogs: true,
    good_with_cats: false
  }
];

// Sample rescue organizations
const sampleRescues = [
  {
    id: crypto.randomUUID(),
    name: 'Battersea Dogs Home',
    location: 'London',
    contact_email: 'info@battersea.org.uk',
    phone: '+44 20 7622 3626',
    website: 'https://www.battersea.org.uk'
  },
  {
    id: crypto.randomUUID(),
    name: 'Dogs Trust Manchester',
    location: 'Manchester',
    contact_email: 'manchester@dogstrust.org.uk',
    phone: '+44 161 945 8200',
    website: 'https://www.dogstrust.org.uk'
  },
  {
    id: crypto.randomUUID(),
    name: 'RSPCA Birmingham',
    location: 'Birmingham',
    contact_email: 'birmingham@rspca.org.uk',
    phone: '+44 121 643 5144',
    website: 'https://www.rspca.org.uk'
  },
  {
    id: crypto.randomUUID(),
    name: 'Bristol Animal Rescue',
    location: 'Bristol',
    contact_email: 'info@bristolanimalrescue.org.uk',
    phone: '+44 117 958 9661',
    website: 'https://www.bristolanimalrescue.org.uk'
  },
  {
    id: crypto.randomUUID(),
    name: 'German Shepherd Rescue',
    location: 'Leeds',
    contact_email: 'info@gsrescue.org.uk',
    phone: '+44 113 245 9876',
    website: 'https://www.gsrescue.org.uk'
  }
];

async function uploadData() {
  try {
    console.log('🐕 Starting dog data upload...');

    // Check if we're using local Supabase
    const isLocal = SUPABASE_URL.includes('localhost');
    console.log(`📡 Connecting to ${isLocal ? 'local' : 'remote'} Supabase...`);

    // Get existing rescues instead of creating new ones
    console.log('🏢 Getting existing rescue organizations...');
    const { data: rescues, error: rescueError } = await supabase
      .from('rescues')
      .select('*')
      .limit(10);

    if (rescueError) {
      console.error('❌ Error fetching rescues:', rescueError);
      return;
    }

    if (!rescues || rescues.length === 0) {
      console.error('❌ No rescues found. Please run migrations first.');
      return;
    }

    console.log(`✅ Found ${rescues.length} rescue organizations`);

    // Assign rescue IDs to dogs
    const dogsWithRescues = sampleDogs.map((dog, index) => {
      const rescue = rescues[index % rescues.length];
      return {
        ...dog,
        rescue_id: rescue.id
      };
    });

    // Upload dogs to dogadopt schema
    console.log('🐕 Uploading dogs...');
    const { data: dogs, error: dogError } = await supabase
      .from('dogs')
      .upsert(dogsWithRescues, { onConflict: 'id' })
      .select();

    if (dogError) {
      console.error('❌ Error uploading dogs:', dogError);
      return;
    }

    console.log(`✅ Uploaded ${dogs.length} dogs`);

    // Verify the data
    const { data: allDogs, error: verifyError } = await supabase
      .from('dogs')
      .select('*')
      .limit(10);

    if (verifyError) {
      console.error('❌ Error verifying data:', verifyError);
      return;
    }

    console.log('\n🎉 Upload complete!');
    console.log(`📊 Total dogs in database: ${allDogs.length}`);
    console.log('\n📋 Sample dogs uploaded:');
    allDogs.slice(0, 3).forEach(dog => {
      console.log(`  • ${dog.name} (${dog.breed}) - ${dog.location}`);
    });

  } catch (error) {
    console.error('💥 Unexpected error:', error);
  }
}

// Check if database exists and run upload
uploadData();