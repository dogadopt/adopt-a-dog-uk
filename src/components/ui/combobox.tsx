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

export interface ComboboxOption {
  value: string;
  label: string;
  keywords?: string[];
  description?: string;
}

export interface ComboboxProps {
  options: ComboboxOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  searchPlaceholder?: string;
  emptyText?: string;
  className?: string;
  renderTrigger?: (selectedOption: ComboboxOption | undefined) => React.ReactNode;
  renderOption?: (option: ComboboxOption, isSelected: boolean) => React.ReactNode;
}

/**
 * Generic combobox component for single selection with search
 */
export function Combobox({
  options,
  value,
  onChange,
  placeholder = "Select option...",
  searchPlaceholder = "Search...",
  emptyText = "No option found.",
  className,
  renderTrigger,
  renderOption,
}: ComboboxProps) {
  const [open, setOpen] = React.useState(false);

  const selectedOption = React.useMemo(() => {
    return options.find((option) => option.value === value);
  }, [options, value]);

  const handleSelect = (optionValue: string) => {
    onChange(optionValue === value ? "" : optionValue);
    setOpen(false);
  };

  const defaultRenderTrigger = (selected: ComboboxOption | undefined) => (
    <span className={cn(!selected && "text-muted-foreground")}>
      {selected ? selected.label : placeholder}
    </span>
  );

  const defaultRenderOption = (option: ComboboxOption, isSelected: boolean) => (
    <>
      <Check
        className={cn(
          "mr-2 h-4 w-4",
          isSelected ? "opacity-100" : "opacity-0"
        )}
      />
      {option.description ? (
        <div className="flex flex-col">
          <span>{option.label}</span>
          <span className="text-xs text-muted-foreground">
            {option.description}
          </span>
        </div>
      ) : (
        <span>{option.label}</span>
      )}
    </>
  );

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn("w-full justify-between", className)}
        >
          {renderTrigger ? renderTrigger(selectedOption) : defaultRenderTrigger(selectedOption)}
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[400px] p-0" align="start">
        <Command>
          <CommandInput placeholder={searchPlaceholder} />
          <CommandList>
            <CommandEmpty>{emptyText}</CommandEmpty>
            <CommandGroup>
              {options.map((option) => {
                const isSelected = value === option.value;
                return (
                  <CommandItem
                    key={option.value}
                    value={option.value}
                    keywords={option.keywords}
                    onSelect={() => handleSelect(option.value)}
                  >
                    {renderOption ? renderOption(option, isSelected) : defaultRenderOption(option, isSelected)}
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
