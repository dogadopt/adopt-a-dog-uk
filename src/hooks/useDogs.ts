import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import type { Dog } from '@/types/dog';

interface DogRow {
  id: string;
  name: string;
  breed: string;
  age: string;
  size: string;
  gender: string;
  location: string;
  rescue: string;
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
          )
        `)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      return (data as unknown as DogRow[]).map((dog) => ({
        id: dog.id,
        name: dog.name,
        breed: dog.breed,
        age: dog.age,
        size: dog.size as 'Small' | 'Medium' | 'Large',
        gender: dog.gender as 'Male' | 'Female',
        location: dog.location,
        rescue: dog.rescues?.name || dog.rescue,
        rescueWebsite: dog.rescues?.website,
        image: dog.image,
        goodWithKids: dog.good_with_kids,
        goodWithDogs: dog.good_with_dogs,
        goodWithCats: dog.good_with_cats,
        description: dog.description,
      }));
    },
  });
};
