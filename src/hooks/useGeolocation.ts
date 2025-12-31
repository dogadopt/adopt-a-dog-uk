import { useState, useEffect } from 'react';

export interface GeolocationState {
  latitude: number | null;
  longitude: number | null;
  error: string | null;
  loading: boolean;
}

export const useGeolocation = () => {
  const [location, setLocation] = useState<GeolocationState>({
    latitude: null,
    longitude: null,
    error: null,
    loading: false,
  });

  const requestLocation = () => {
    if (!navigator.geolocation) {
      setLocation({
        latitude: null,
        longitude: null,
        error: 'Geolocation is not supported by your browser',
        loading: false,
      });
      return;
    }

    // Check if we're on a secure context (HTTPS or localhost)
    if (window.location.protocol !== 'https:' && window.location.hostname !== 'localhost') {
      setLocation({
        latitude: null,
        longitude: null,
        error: 'Geolocation requires a secure connection (HTTPS)',
        loading: false,
      });
      return;
    }

    setLocation(prev => ({ ...prev, loading: true, error: null }));
    console.log('Requesting location...');

    navigator.geolocation.getCurrentPosition(
      (position) => {
        console.log('Location acquired:', position.coords.latitude, position.coords.longitude);
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          error: null,
          loading: false,
        });
      },
      (error) => {
        console.error('Geolocation error:', error.code, error.message);
        let errorMessage = 'Unable to retrieve your location';
        
        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMessage = 'Location permission denied. Please enable location access in your browser settings.';
            break;
          case error.POSITION_UNAVAILABLE:
            errorMessage = 'Location information is unavailable.';
            break;
          case error.TIMEOUT:
            errorMessage = 'Location request timed out. Please try again.';
            break;
        }

        setLocation({
          latitude: null,
          longitude: null,
          error: errorMessage,
          loading: false,
        });
      },
      {
        enableHighAccuracy: false,
        timeout: 10000,
        maximumAge: 300000, // Cache for 5 minutes
      }
    );
  };

  const clearLocation = () => {
    setLocation({
      latitude: null,
      longitude: null,
      error: null,
      loading: false,
    });
  };

  return {
    ...location,
    requestLocation,
    clearLocation,
    hasLocation: location.latitude !== null && location.longitude !== null,
  };
};
