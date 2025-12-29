# Dog Breeds Feature - Testing Guide

## Overview
This feature adds comprehensive dog breed support with:
- 250+ standard dog breeds from Wikipedia
- 15+ common cross-breeds (Cockapoo, Labradoodle, etc.)
- Multi-breed selection for cross-breeds
- Database constraints ensuring breed validity
- Autocomplete combobox UI in admin panel

## Database Changes

### New Tables
1. **dogadopt.breeds** - Reference table with all valid breed names
2. **dogadopt.dog_breeds** - Junction table for many-to-many dog-breed relationships

### Migration
The migration file `20251221180000_dogadopt_add_breed_support.sql`:
- Creates breed reference tables
- Populates with 250+ breeds from Wikipedia
- Migrates existing dog data to new structure
- Maintains backward compatibility with the `breed` column (comma-separated)

## Testing Locally with Supabase

### Prerequisites
- Supabase CLI installed: `npm install -g supabase`
- Docker running

### Steps
1. Start local Supabase instance:
   ```bash
   npm run supabase:start
   ```

2. The migration will run automatically

3. Start the dev server:
   ```bash
   npm run dev
   ```

4. Login as admin and navigate to `/admin`

5. Try creating/editing a dog:
   - Click "Add Dog" or edit existing dog
   - Use the breed combobox to search and select breeds
   - Select multiple breeds for cross-breeds (e.g., "Labrador Retriever" + "Poodle (Standard)" for a Labradoodle)
   - Save and verify the breeds display correctly

### Testing the Breed Combobox
- **Search**: Type to filter breeds (e.g., "terrier" shows all terrier breeds)
- **Multi-select**: Click multiple breeds to add them
- **Remove**: Click the X on a breed badge to remove it
- **Clear**: Click X on each badge to remove breeds
- **Validation**: Try to submit without selecting a breed (should show error)

## UI Components

### BreedCombobox
Located at: `src/components/BreedCombobox.tsx`
- Uses shadcn/ui Command component for autocomplete
- Supports multiple selections
- Displays selected breeds as badges
- Real-time search filtering

### Updated Admin Panel
Located at: `src/pages/Admin.tsx`
- Replaced text input with BreedCombobox
- Validates at least one breed is selected
- Stores breeds as comma-separated string for backward compatibility
- Parses existing comma-separated breeds when editing

## Data Files

### Dog Breeds Data
Located at: `src/data/dogBreeds.ts`
- `DOG_BREEDS` - 250+ standard breeds
- `COMMON_CROSS_BREEDS` - 15+ popular cross-breeds
- `ALL_DOG_BREEDS` - Combined and sorted list
- Based on FCI, AKC, KC (UK), and CKC registrations

## Backward Compatibility

The implementation maintains full backward compatibility:
- The `breed` column in `dogs` table still exists and stores comma-separated values
- UI components that display breeds work with both single and multiple breeds
- Search functionality works across comma-separated breed strings
- Existing dogs are automatically migrated to the new structure

## Future Enhancements

Potential improvements:
1. Add breed filtering to public search
2. Show breed badges separately instead of comma-separated
3. Add breed images/icons
4. Add breed-specific information (size ranges, temperament)
5. Support custom breed names for rare/unknown breeds
