import * as React from "react";
import { FreeTextCombobox } from "@/components/ui/free-text-combobox";

interface LocationComboboxProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

// Common UK locations/regions for suggestions
const COMMON_UK_LOCATIONS = [
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
] as const;

export function LocationCombobox({
  value = "",
  onChange,
  placeholder = "Enter location...",
}: LocationComboboxProps) {
  return (
    <FreeTextCombobox
      value={value}
      onChange={onChange}
      suggestions={COMMON_UK_LOCATIONS}
      placeholder={placeholder}
      searchPlaceholder="Search or enter location..."
    />
  );
}
