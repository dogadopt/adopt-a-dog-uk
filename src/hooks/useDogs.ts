import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import type { Dog } from '@/types/dog';

interface DogRow {
  id: string;
  name: string;
  age: string;
  size: string;
  gender: string;
  location_id: string | null;
  rescue_id: string | null;
  image: string;
  description: string;
  good_with_kids: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
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
          rescues (
            id,
            name,
            region,
            website
          ),
          dogs_breeds (
            display_order,
            breeds (
              id,
              name
            )
          )
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

        return {
          id: dog.id,
          name: dog.name,
          breed: breeds.join(', '), // Display string
          breeds: breeds, // Array for filtering/editing
          age: dog.age,
          size: dog.size as 'Small' | 'Medium' | 'Large',
          gender: dog.gender as 'Male' | 'Female',
          location: dog.rescues?.region || 'Unknown', // Use rescue region as location
          rescue: dog.rescues?.name || 'Unknown',
          rescueWebsite: dog.rescues?.website,
          image: dog.image,
          goodWithKids: dog.good_with_kids,
          goodWithDogs: dog.good_with_dogs,
          goodWithCats: dog.good_with_cats,
          description: dog.description,
        };
      });
    },
  });
};
