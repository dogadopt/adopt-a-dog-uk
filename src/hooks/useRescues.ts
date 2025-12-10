import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export interface Rescue {
  id: string;
  name: string;
  type: string;
  region: string;
  website: string | null;
}

export const useRescues = () => {
  return useQuery({
    queryKey: ['rescues'],
    queryFn: async (): Promise<Rescue[]> => {
      const { data, error } = await supabase
        .from('rescues')
        .select('*')
        .order('name', { ascending: true });

      if (error) {
        throw error;
      }

      return data;
    },
  });
};
