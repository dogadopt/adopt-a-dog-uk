export interface Dog {
  id: string;
  name: string;
  breed: string; // Computed display string from breeds array
  breeds: string[]; // Multiple breeds array (source of truth)
  age: string; // Manual age category (Puppy/Young/Adult/Senior) - used as fallback
  birthYear?: number | null; // Birth year (required if any birth date provided)
  birthMonth?: number | null; // Birth month (1-12, requires birthYear)
  birthDay?: number | null; // Birth day (1-31, requires birthYear and birthMonth)
  computedAge?: string; // Computed age category from birth date (if available)
  rescueSinceDate?: string | null; // Date the dog was taken into the rescue (ISO format YYYY-MM-DD)
  size: 'Small' | 'Medium' | 'Large';
  gender: 'Male' | 'Female';
  status: 'available' | 'reserved' | 'adopted' | 'on_hold' | 'fostered' | 'withdrawn'; // Adoption status
  statusNotes?: string | null; // Optional notes about the status
  location: string;
  rescue: string;
  rescueWebsite?: string;
  image: string;
  profileUrl?: string;
  goodWithKids: boolean;
  goodWithDogs: boolean;
  goodWithCats: boolean;
  description: string;
  distance?: number; // Distance in km from user's location (calculated when user location is available)
}

export type SizeFilter = 'All' | 'Small' | 'Medium' | 'Large';
export type AgeFilter = 'All' | 'Puppy' | 'Young' | 'Adult' | 'Senior';
