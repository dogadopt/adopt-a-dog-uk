export interface Dog {
  id: string;
  name: string;
  breed: string; // Computed display string from breeds array
  breeds: string[]; // Multiple breeds array (source of truth)
  age: string;
  size: 'Small' | 'Medium' | 'Large';
  gender: 'Male' | 'Female';
  location: string;
  rescue: string;
  rescueWebsite?: string;
  image: string;
  goodWithKids: boolean;
  goodWithDogs: boolean;
  goodWithCats: boolean;
  description: string;
}

export type SizeFilter = 'All' | 'Small' | 'Medium' | 'Large';
export type AgeFilter = 'All' | 'Puppy' | 'Young' | 'Adult' | 'Senior';
