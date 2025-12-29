import { useState, useMemo } from 'react';
import DogCard from './DogCard';
import FilterSidebar from './FilterSidebar';
import { useDogs } from '@/hooks/useDogs';
import type { SizeFilter, AgeFilter } from '@/types/dog';
import { Search, Loader2 } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';

type ViewMode = 'text-only' | 'with-images';

const DogGrid = () => {
  const [sizeFilter, setSizeFilter] = useState<SizeFilter>('All');
  const [ageFilter, setAgeFilter] = useState<AgeFilter>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('text-only');
  const { data: dogs = [], isLoading, error } = useDogs();

  const filteredDogs = useMemo(() => {
    return dogs.filter((dog) => {
      const matchesSize = sizeFilter === 'All' || dog.size === sizeFilter;
      const matchesAge = ageFilter === 'All' || dog.age === ageFilter;
      const matchesSearch =
        searchQuery === '' ||
        dog.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dog.breed.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dog.location.toLowerCase().includes(searchQuery.toLowerCase());

      return matchesSize && matchesAge && matchesSearch;
    });
  }, [dogs, sizeFilter, ageFilter, searchQuery]);

  const handleClearFilters = () => {
    setSizeFilter('All');
    setAgeFilter('All');
    setSearchQuery('');
  };

  return (
    <section id="dogs" className="py-16 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="font-display text-3xl md:text-4xl font-bold text-foreground mb-4">
            Dogs Looking for Homes
          </h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Browse our selection of rescue dogs from shelters across the UK. Each one deserves a loving forever home.
          </p>
        </div>

        <div className="flex flex-col lg:flex-row gap-8">
          <div className="lg:w-64 shrink-0">
            <FilterSidebar
              sizeFilter={sizeFilter}
              ageFilter={ageFilter}
              onSizeChange={setSizeFilter}
              onAgeChange={setAgeFilter}
              onClearFilters={handleClearFilters}
            />
          </div>

        <div className="flex-1">
            <div className="mb-6 p-4 bg-card rounded-lg shadow-soft">
              <Label className="text-base font-semibold mb-3 block">View Mode</Label>
              <RadioGroup value={viewMode} onValueChange={(value) => setViewMode(value as ViewMode)}>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="text-only" id="text-only" />
                  <Label htmlFor="text-only" className="cursor-pointer">Text Only</Label>
                </div>
                <div className="flex items-center space-x-2">
                  <RadioGroupItem value="with-images" id="with-images" disabled />
                  <Label htmlFor="with-images" className="cursor-not-allowed opacity-50">
                    With Images <span className="text-xs text-muted-foreground">(Coming Soon)</span>
                  </Label>
                </div>
              </RadioGroup>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between mb-8">
              <div className="relative w-full sm:w-80">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <Input
                  type="search"
                  placeholder="Search by name, breed, or location..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10"
                />
              </div>
              <p className="text-muted-foreground">
                <span className="font-semibold text-foreground">{filteredDogs.length}</span> dogs found
              </p>
            </div>

            {isLoading ? (
              <div className="flex items-center justify-center py-16">
                <Loader2 className="w-8 h-8 animate-spin text-primary" />
              </div>
            ) : error ? (
              <div className="text-center py-16 bg-card rounded-2xl shadow-soft">
                <p className="font-display text-xl text-foreground mb-2">Error loading dogs</p>
                <p className="text-muted-foreground">Please try again later</p>
              </div>
            ) : filteredDogs.length > 0 ? (
              <div className="grid sm:grid-cols-2 xl:grid-cols-3 gap-6">
                {filteredDogs.map((dog, index) => (
                  <div
                    key={dog.id}
                    className="animate-fade-up"
                    style={{ animationDelay: `${index * 0.1}s` }}
                  >
                    <DogCard dog={dog} viewMode={viewMode} />
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-16 bg-card rounded-2xl shadow-soft">
                <p className="font-display text-xl text-foreground mb-2">No dogs found</p>
                <p className="text-muted-foreground">Try adjusting your filters or search query</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
};

export default DogGrid;
