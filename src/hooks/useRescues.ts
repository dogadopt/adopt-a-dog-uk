import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';

export interface Rescue {
  id: string;
  name: string;
  type: string;
  region: string;
  website: string | null;
  latitude: number | null;
  longitude: number | null;
  distance?: number; // Distance in km from user's location
}

export const useRescues = (userLocation?: { latitude: number; longitude: number }) => {
  return useQuery({
    queryKey: ['rescues', userLocation],
    queryFn: async (): Promise<Rescue[]> => {
      const { data, error } = await (supabase as any)
        .from('rescues')
        .select('id, name, type, region, website, latitude, longitude')
        .order('name', { ascending: true });

      if (error) {
        throw error;
      }

      let rescues = data as unknown as Rescue[];

      // Calculate distances if user location is provided
      if (userLocation) {
        rescues = rescues.map(rescue => {
          if (rescue.latitude && rescue.longitude) {
            const distance = calculateDistance(
              userLocation.latitude,
              userLocation.longitude,
              rescue.latitude,
              rescue.longitude
            );
            return { ...rescue, distance };
          }
          return rescue;
        });

        // Sort by distance when user location is available
        rescues.sort((a, b) => {
          if (a.distance && b.distance) return a.distance - b.distance;
          if (a.distance) return -1;
          if (b.distance) return 1;
          return 0;
        });
      }

      return rescues;
    },
  });
};

// Haversine formula to calculate distance between two coordinates
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return Math.round(distance * 10) / 10; // Round to 1 decimal place
}

function toRad(degrees: number): number {
  return degrees * (Math.PI / 180);
}
