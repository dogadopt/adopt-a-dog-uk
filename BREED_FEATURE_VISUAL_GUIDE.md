# Dog Breeds Feature - Visual Reference

## Breed Combobox Component

### Component Features
The `BreedCombobox` component provides an intuitive multi-select interface for choosing dog breeds:

```tsx
<BreedCombobox
  value={formData.breeds}
  onChange={(breeds) => setFormData({ ...formData, breeds })}
  placeholder="Select one or more breeds..."
/>
```

### Visual States

#### 1. Empty State
```
┌─────────────────────────────────────────────┐
│ Select breeds...                         ▼  │
└─────────────────────────────────────────────┘
```

#### 2. With Selected Breeds (Single)
```
┌─────────────────────────────────────────────┐
│ [Labrador Retriever ×]                   ▼  │
└─────────────────────────────────────────────┘
```

#### 3. With Selected Breeds (Multiple - Cross-breed)
```
┌─────────────────────────────────────────────┐
│ [Labrador Retriever ×] [Poodle ×]        ▼  │
└─────────────────────────────────────────────┘
```

#### 4. Dropdown Open State
```
┌─────────────────────────────────────────────┐
│ [Golden Retriever ×]                     ▲  │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│ 🔍 Search breeds...                         │
├─────────────────────────────────────────────┤
│ ✓ Golden Retriever                          │
│   Labrador Retriever                        │
│   German Shepherd                           │
│   Border Collie                             │
│   Beagle                                    │
│   Poodle (Standard)                         │
│   Yorkshire Terrier                         │
│   ... (250+ more breeds)                    │
└─────────────────────────────────────────────┘
```

#### 5. Dropdown with Search Filter
```
┌─────────────────────────────────────────────┐
│ []                                       ▼  │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│ 🔍 terrier                                  │
├─────────────────────────────────────────────┤
│   Airedale Terrier                          │
│   American Staffordshire Terrier            │
│   Australian Terrier                        │
│   Bedlington Terrier                        │
│   Border Terrier                            │
│   Boston Terrier                            │
│   Bull Terrier                              │
│   Cairn Terrier                             │
│   ... (30+ terrier breeds)                  │
└─────────────────────────────────────────────┘
```

### Admin Form Integration

The breed selector is integrated into the Add/Edit Dog form:

```
┌──────────────────────────────────────────────────────────┐
│  Add New Dog                                         [×] │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Name                                                    │
│  ┌────────────────────────────────────────────┐        │
│  │ Max                                         │        │
│  └────────────────────────────────────────────┘        │
│                                                          │
│  Breed(s)                                               │
│  ┌────────────────────────────────────────────┐        │
│  │ [German Shepherd ×]                      ▼ │        │
│  └────────────────────────────────────────────┘        │
│  Select multiple breeds for cross-breeds or mixes       │
│                                                          │
│  Age          Size           Gender                     │
│  [Adult ▼]    [Large ▼]      [Male ▼]                  │
│                                                          │
│  Location                Rescue Organisation            │
│  [Leeds     ]            [Select rescue ▼]              │
│                                                          │
│  ... (rest of form)                                     │
└──────────────────────────────────────────────────────────┘
```

## Available Breeds

### Standard Breeds (250+)
The component includes all major recognized dog breeds:
- Sporting Dogs: Golden Retriever, Labrador Retriever, Cocker Spaniel, etc.
- Working Dogs: German Shepherd, Rottweiler, Siberian Husky, etc.
- Terriers: Yorkshire Terrier, Jack Russell Terrier, Bull Terrier, etc.
- Toy Dogs: Chihuahua, Pomeranian, Pug, Shih Tzu, etc.
- Hounds: Beagle, Bloodhound, Greyhound, Dachshund, etc.
- Non-Sporting: Bulldog, Dalmatian, French Bulldog, etc.
- Herding: Border Collie, Australian Shepherd, Collie, etc.

### Common Cross-Breeds (15+)
Popular designer breeds are pre-included:
- Cockapoo (Cocker Spaniel × Poodle)
- Labradoodle (Labrador × Poodle)
- Goldendoodle (Golden Retriever × Poodle)
- Cavapoo (Cavalier King Charles × Poodle)
- Puggle (Pug × Beagle)
- Schnoodle (Schnauzer × Poodle)
- And more...

### Generic Option
- "Mixed Breed" for unknown or complex mixes
- "Terrier Mix" for general terrier crosses

## User Experience

### For Admins Adding Dogs

1. **Single Breed Dogs**
   - Search for and select one breed
   - Example: "German Shepherd"

2. **Cross-Breed Dogs**
   - Select 2+ breeds that make up the cross
   - Example: "Labrador Retriever" + "Poodle (Standard)" = Labradoodle
   - Example: "Cocker Spaniel" + "Poodle (Miniature)" = Cockapoo

3. **Designer Breeds**
   - Can select the pre-defined cross-breed name
   - Example: Select "Labradoodle" directly
   - OR select the parent breeds

4. **Unknown Mixes**
   - Use "Mixed Breed" for complex or unknown mixes
   - Can add multiple guessed breeds if desired

### For Public Users

The breeds display on the dog cards as comma-separated text:
- Single breed: "German Shepherd"
- Cross-breed: "Labrador Retriever, Poodle"
- Designer breed: "Cockapoo"

## Technical Implementation

### Data Structure
```typescript
// In Admin form
interface DogFormData {
  breeds: string[];  // Array of breed names
  // ... other fields
}

// In Database
{
  breed: "Labrador Retriever, Poodle"  // Comma-separated string
}

// In Dog Type
interface Dog {
  breed: string;       // Comma-separated for backward compatibility
  breeds?: string[];   // Optional array for future use
}
```

### Search Capabilities
The breed string is searchable in the public interface:
- Search "labrador" matches dogs with Labrador in their breed list
- Search "poodle" matches Labradoodles, Cockapoos, etc.
- Search "terrier" matches all terrier breeds and mixes

## Benefits

1. **Data Consistency**: Only valid breed names can be entered
2. **Better Search**: Users can find specific breeds easily
3. **Cross-Breed Support**: Properly represent designer breeds
4. **User-Friendly**: Autocomplete reduces typing and errors
5. **Flexible**: Supports both pure breeds and complex mixes
6. **Professional**: Matches veterinary and kennel club standards
