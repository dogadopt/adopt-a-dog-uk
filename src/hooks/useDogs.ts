import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import type { Dog } from '@/types/dog';
import { DEFAULT_DOG_IMAGE } from '@/lib/constants';

// Helper function to calculate age category from birth date
// Returns: 'Puppy' (≤6 months), 'Young' (6mo-2yr), 'Adult' (2-8yr), 'Senior' (8+yr)
function calculateAgeCategory(
  birthYear: number | null, 
  birthMonth: number | null = null, 
  birthDay: number | null = null
): string | null {
  if (!birthYear) return null;
  
  try {
    // Construct birth date with available precision
    // Use middle of year/month if not specified for more accurate age calculation
    let birthDate: Date;
    if (!birthMonth) {
      // Year only - use July 1st as midpoint
      birthDate = new Date(birthYear, 6, 1);
    } else if (!birthDay) {
      // Year and month - use 15th as midpoint
      birthDate = new Date(birthYear, birthMonth - 1, 15);
    } else {
      // Full date available
      birthDate = new Date(birthYear, birthMonth - 1, birthDay);
    }
    
    // Check for invalid date
    if (isNaN(birthDate.getTime())) return null;
    
    const now = new Date();
    
    // Calculate age more accurately by considering all date components
    let ageInMonths = (now.getFullYear() - birthDate.getFullYear()) * 12;
    ageInMonths += now.getMonth() - birthDate.getMonth();
    
    // Adjust if we haven't reached the birth day in the current month
    if (now.getDate() < birthDate.getDate()) {
      ageInMonths--;
    }
    
    const ageInYears = ageInMonths / 12;
    
    // Categorize based on age
    if (ageInMonths <= 6) {
      return 'Puppy';
    } else if (ageInMonths <= 24) {  // 2 years
      return 'Young';
    } else if (ageInMonths <= 96) {  // 8 years
      return 'Adult';
    } else {
      return 'Senior';
    }
  } catch (error) {
    return null;
  }
}

interface DogRow {
  id: string;
  name: string;
  age: string;
  size: string;
  gender: string;
  location_id: string | null;
  rescue_id: string | null;
  image: string | null;
  profile_url: string | null;
  description: string;
  good_with_kids: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
  birth_year: number | null;
  birth_month: number | null;
  birth_day: number | null;
  created_at: string;
  rescues: {
    id: string;
    name: string;
    region: string;
    website: string | null;
  } | null;
  dogs_breeds: Array<{
    breeds: {
      id: string;
      name: string;
    };
    display_order: number;
  }>;
}

export const useDogs = () => {
  return useQuery({
    queryKey: ['dogs'],
    queryFn: async (): Promise<Dog[]> => {
      const { data, error } = await (supabase as any)
        .from('dogs')
        .select(`
          *,
          rescues(id, name, region, website),
          dogs_breeds(display_order, breed_id, breeds(id, name))
        `)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return (data as unknown as DogRow[]).map((dog) => {
        // Get breeds from many-to-many relationship
        const breeds = dog.dogs_breeds
          ?.sort((a, b) => a.display_order - b.display_order)
          .map((db) => db.breeds.name) || [];

        // Calculate computed age if birth date is available
        const computedAge = calculateAgeCategory(dog.birth_year, dog.birth_month, dog.birth_day);

        return {
          id: dog.id,
          name: dog.name,
          breed: breeds.join(', '), // Display string
          breeds: breeds, // Array for filtering/editing
          age: dog.age,
          birthYear: dog.birth_year,
          birthMonth: dog.birth_month,
          birthDay: dog.birth_day,
          computedAge: computedAge || dog.age, // Use computed age if available, otherwise fall back to manual age
          size: dog.size as 'Small' | 'Medium' | 'Large',
          gender: dog.gender as 'Male' | 'Female',
          location: dog.rescues?.region || 'Unknown', // Use rescue region as location
          rescue: dog.rescues?.name || 'Unknown',
          rescueWebsite: dog.rescues?.website,
          image: dog.image || DEFAULT_DOG_IMAGE,
          profileUrl: dog.profile_url ?? undefined,
          goodWithKids: dog.good_with_kids,
          goodWithDogs: dog.good_with_dogs,
          goodWithCats: dog.good_with_cats,
          description: dog.description,
        };
      });
    },
  });
};
