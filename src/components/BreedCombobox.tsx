import * as React from "react";
import { Check, ChevronsUpDown, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Badge } from "@/components/ui/badge";
import { ALL_DOG_BREEDS } from "@/data/dogBreeds";

interface BreedComboboxProps {
  value: string[];
  onChange: (value: string[]) => void;
  placeholder?: string;
  maxSelections?: number;
}

export function BreedCombobox({
  value = [],
  onChange,
  placeholder = "Select breeds...",
  maxSelections,
}: BreedComboboxProps) {
  const [open, setOpen] = React.useState(false);
  const [search, setSearch] = React.useState("");

  const handleSelect = (breed: string) => {
    const isSelected = value.includes(breed);
    
    if (isSelected) {
      // Remove breed
      onChange(value.filter((b) => b !== breed));
    } else {
      // Add breed if under max limit
      if (!maxSelections || value.length < maxSelections) {
        onChange([...value, breed]);
      }
    }
  };

  const handleRemove = (breed: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    onChange(value.filter((b) => b !== breed));
  };

  const handleBadgeKeyDown = (breed: string, e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onChange(value.filter((b) => b !== breed));
    }
  };

  const filteredBreeds = React.useMemo(() => {
    if (!search) return ALL_DOG_BREEDS;
    return ALL_DOG_BREEDS.filter((breed) =>
      breed.toLowerCase().includes(search.toLowerCase())
    );
  }, [search]);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between h-auto min-h-[2.5rem]"
        >
          <div className="flex flex-wrap gap-1 flex-1">
            {value.length === 0 ? (
              <span className="text-muted-foreground">{placeholder}</span>
            ) : (
              value.map((breed) => (
                <Badge
                  key={breed}
                  variant="secondary"
                  className="mr-1"
                >
                  {breed}
                  <button
                    type="button"
                    className="ml-1 ring-offset-background rounded-full outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
                    onClick={(e) => handleRemove(breed, e)}
                    onKeyDown={(e) => handleBadgeKeyDown(breed, e)}
                    aria-label={`Remove ${breed}`}
                  >
                    <X className="h-3 w-3" />
                  </button>
                </Badge>
              ))
            )}
          </div>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[400px] p-0" align="start">
        <Command>
          <CommandInput
            placeholder="Search breeds..."
            value={search}
            onValueChange={setSearch}
          />
          <CommandList>
            <CommandEmpty>No breed found.</CommandEmpty>
            <CommandGroup>
              {filteredBreeds.map((breed) => {
                const isSelected = value.includes(breed);
                return (
                  <CommandItem
                    key={breed}
                    value={breed}
                    onSelect={() => handleSelect(breed)}
                  >
                    <Check
                      className={cn(
                        "mr-2 h-4 w-4",
                        isSelected ? "opacity-100" : "opacity-0"
                      )}
                    />
                    {breed}
                  </CommandItem>
                );
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
