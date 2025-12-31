# Combobox Components Refactoring

## Overview
This document describes the refactoring of duplicated combobox components into reusable generic components.

## Problem Statement
The codebase contained three similar combobox implementations:
- `RescueCombobox.tsx` - Select rescue organizations
- `LocationCombobox.tsx` - Enter locations with suggestions
- `BreedCombobox.tsx` - Multi-select dog breeds

Each component duplicated significant code (97-142 lines each) with similar patterns:
- Popover/PopoverTrigger/PopoverContent structure
- Command/CommandInput/CommandList patterns
- Button with ChevronsUpDown icon
- Check icon for selected items
- State management for open/close

## Solution
Created three reusable generic components in `src/components/ui/`:

### 1. Combobox Component
**File:** `src/components/ui/combobox.tsx`

Generic single-select combobox with:
- Search/filter functionality
- Custom rendering via render props
- Support for descriptions and keywords
- Keyboard navigation
- Accessibility features

**Usage Example:**
```typescript
const options: ComboboxOption[] = [
  { value: "1", label: "Option 1", description: "Description" },
  { value: "2", label: "Option 2" }
];

<Combobox
  options={options}
  value={selectedValue}
  onChange={setValue}
  placeholder="Select option..."
/>
```

### 2. FreeTextCombobox Component
**File:** `src/components/ui/free-text-combobox.tsx`

Combobox that allows free text entry with suggestions:
- User can type custom values
- Suggestions filter as user types
- Shows helpful message when no suggestions match
- Syncs external value changes

**Usage Example:**
```typescript
<FreeTextCombobox
  value={location}
  onChange={setLocation}
  suggestions={["London", "Manchester", "Edinburgh"]}
  placeholder="Enter location..."
/>
```

### 3. MultiSelectCombobox Component
**File:** `src/components/ui/multi-select-combobox.tsx`

Multi-select combobox with badge display:
- Select multiple options
- Visual badges for selected items
- Remove items via X button
- Optional max selections limit
- Keyboard accessible (Tab + Enter/Space)

**Usage Example:**
```typescript
<MultiSelectCombobox
  options={allBreeds}
  value={selectedBreeds}
  onChange={setSelectedBreeds}
  placeholder="Select breeds..."
  maxSelections={3}
/>
```

## Refactored Components

### RescueCombobox
**Before:** 97 lines | **After:** 38 lines | **Reduction:** 61%

Now transforms rescue data into `ComboboxOption` format and uses the generic `Combobox` component.

```typescript
const options = rescues.map(rescue => ({
  value: rescue.id,
  label: rescue.name,
  description: rescue.region,
  keywords: [rescue.region]
}));
```

### LocationCombobox  
**Before:** 131 lines | **After:** 41 lines | **Reduction:** 69%

Uses `FreeTextCombobox` with predefined UK location suggestions. Extracted location list to a constant.

### BreedCombobox
**Before:** 142 lines | **After:** 29 lines | **Reduction:** 80%

Uses `MultiSelectCombobox` and passes `ALL_DOG_BREEDS` directly. Simplified significantly while maintaining all functionality.

## Geolocation Utilities

### Problem
The `calculateDistance` and `toRad` functions were only in `useRescues.ts` but are general-purpose utilities.

### Solution
Created `src/lib/geolocation.ts` with:
- `calculateDistance()` - Haversine formula for coordinate distance
- `toRad()` - Convert degrees to radians
- Full JSDoc documentation
- Exported for reuse across codebase

## Benefits

### Code Quality
1. **DRY Principle:** Eliminated ~260 lines of duplicate code
2. **Single Source of Truth:** Combobox behavior in one place
3. **Maintainability:** Bug fixes apply to all instances
4. **Type Safety:** Full TypeScript type coverage
5. **Documentation:** JSDoc comments for utilities

### Developer Experience
1. **Reusability:** New combobox needs leverage existing components
2. **Consistency:** All comboboxes have same UX
3. **Simplicity:** Implementing new comboboxes is now trivial
4. **Testing:** Test generic components once, not three times

### Accessibility
- Keyboard navigation (Tab, Enter, Space)
- ARIA labels and roles
- Focus management
- Screen reader support

## Migration Guide

### Creating a New Single-Select Combobox
```typescript
import { Combobox, type ComboboxOption } from "@/components/ui/combobox";

const options: ComboboxOption[] = data.map(item => ({
  value: item.id,
  label: item.name,
  description: item.description, // optional
  keywords: [item.tag] // optional, for search
}));

<Combobox
  options={options}
  value={value}
  onChange={onChange}
  placeholder="Select..."
  searchPlaceholder="Search..."
  emptyText="No results found."
/>
```

### Creating a New Multi-Select Combobox
```typescript
import { MultiSelectCombobox } from "@/components/ui/multi-select-combobox";

<MultiSelectCombobox
  options={allOptions}
  value={selectedValues}
  onChange={setSelectedValues}
  placeholder="Select multiple..."
  maxSelections={5} // optional
/>
```

### Creating a New Free-Text Combobox
```typescript
import { FreeTextCombobox } from "@/components/ui/free-text-combobox";

<FreeTextCombobox
  value={value}
  onChange={onChange}
  suggestions={commonSuggestions}
  placeholder="Type or select..."
/>
```

## Future Considerations

### Potential Enhancements
1. **Async Options:** Support for loading options asynchronously
2. **Grouping:** Group options by category
3. **Custom Icons:** Per-option icons
4. **Virtualization:** For very large option lists
5. **Multi-Column:** Display additional data columns

### Additional Refactoring Opportunities
The refactoring identified other duplication patterns for future work:
1. Toast notifications in `Admin.tsx` (similar error/success patterns)
2. Form validation helpers (repeated validation logic)
3. Query hooks patterns (`useDogs` and `useRescues` structure)

## Backward Compatibility

All refactored components maintain their original public APIs:
- Same props interface
- Same behavior
- Same exports
- No breaking changes

Existing code using these components continues to work without modification.

## Testing

### Verification Performed
- ✅ TypeScript compilation
- ✅ ESLint linting (0 new errors)
- ✅ Production build
- ✅ Code review
- ✅ Security scan (CodeQL)

### Test Coverage
While the repository doesn't have unit tests, the refactoring:
- Maintains existing functionality
- Improves code structure for future testing
- Makes components easier to test in isolation

## References

- [Radix UI Popover](https://www.radix-ui.com/docs/primitives/components/popover)
- [cmdk (Command)](https://cmdk.paco.me/)
- [shadcn/ui Components](https://ui.shadcn.com/)
