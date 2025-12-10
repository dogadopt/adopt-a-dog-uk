import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import type { Dog } from '@/types/dog';

export const useDogs = () => {
  return useQuery({
    queryKey: ['dogs'],
    queryFn: async (): Promise<Dog[]> => {
      const { data, error } = await supabase
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

      return data.map((dog) => ({
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
