import * as React from "react";
import { Check, ChevronsUpDown } from "lucide-react";
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

interface LocationComboboxProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export function LocationCombobox({
  value = "",
  onChange,
  placeholder = "Enter location...",
}: LocationComboboxProps) {
  const [open, setOpen] = React.useState(false);
  const [search, setSearch] = React.useState(value);

  // Sync search state with value prop when it changes externally
  React.useEffect(() => {
    setSearch(value);
  }, [value]);

  // Common UK locations/regions for suggestions
  const commonLocations = React.useMemo(() => [
    "London",
    "South East England",
    "South West England",
    "North West England",
    "North East England",
    "East England",
    "East Midlands",
    "West Midlands",
    "Yorkshire & The Humber",
    "Scotland",
    "Wales",
    "Northern Ireland",
    "National",
  ], []);

  const filteredLocations = React.useMemo(() => {
    if (!search) return commonLocations;
    const searchLower = search.toLowerCase();
    return commonLocations.filter((location) =>
      location.toLowerCase().includes(searchLower)
    );
  }, [search, commonLocations]);

  const handleSelect = (location: string) => {
    onChange(location);
    setOpen(false);
  };

  const handleInputChange = (newValue: string) => {
    setSearch(newValue);
    // Allow free text entry
    onChange(newValue);
  };

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between"
        >
          <span className={cn(!value && "text-muted-foreground")}>
            {value || placeholder}
          </span>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[400px] p-0" align="start">
        <Command>
          <CommandInput
            placeholder="Search or enter location..."
            value={search}
            onValueChange={handleInputChange}
          />
          <CommandList>
            <CommandEmpty>
              <div className="py-6 text-center text-sm">
                <p className="text-muted-foreground">No suggestions found.</p>
                <p className="text-xs text-muted-foreground mt-1">
                  Press Enter to use "{search}"
                </p>
              </div>
            </CommandEmpty>
            <CommandGroup>
              {filteredLocations.map((location) => {
                const isSelected = value === location;
                return (
                  <CommandItem
                    key={location}
                    value={location}
                    onSelect={() => handleSelect(location)}
                  >
                    <Check
                      className={cn(
                        "mr-2 h-4 w-4",
                        isSelected ? "opacity-100" : "opacity-0"
                      )}
                    />
                    {location}
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
