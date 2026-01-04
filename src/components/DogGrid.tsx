import { useState, useMemo, useEffect, useRef } from 'react';
import DogCard from './DogCard';
import FilterSidebar from './FilterSidebar';
import { useDogs } from '@/hooks/useDogs';
import { useGeolocation } from '@/hooks/useGeolocation';
import type { SizeFilter, AgeFilter, StatusFilter } from '@/types/dog';
import { Search, Loader2, MapPin, Navigation, X } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination';

type ViewMode = 'text-only' | 'with-images';

const ITEMS_PER_PAGE = 10;

const DogGrid = () => {
  const [sizeFilter, setSizeFilter] = useState<SizeFilter>('All');
  const [ageFilter, setAgeFilter] = useState<AgeFilter>('All');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('available');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('text-only');
  const [currentPage, setCurrentPage] = useState(1);
  const { 
    latitude, 
    longitude, 
    error: locationError, 
    loading: locationLoading,
    hasLocation,
    requestLocation,
    clearLocation 
  } = useGeolocation();
  
  const userLocation = hasLocation ? { latitude: latitude!, longitude: longitude! } : undefined;
  const { data: dogs = [], isLoading, error } = useDogs(userLocation);
  const gridTopRef = useRef<HTMLDivElement>(null);

  // Debug logging
  useEffect(() => {
    console.log('Location state changed:', { 
      hasLocation, 
      latitude, 
      longitude, 
      locationError, 
      locationLoading 
    });
  }, [hasLocation, latitude, longitude, locationError, locationLoading]);

  useEffect(() => {
    console.log('Dogs loaded:', dogs.length, 'with location:', !!userLocation);
    if (userLocation && dogs.length > 0) {
      const withDistance = dogs.filter(d => d.distance !== undefined).length;
      console.log(`${withDistance} dogs have calculated distances`);
    }
  }, [dogs, userLocation]);

  const handleLocationRequest = () => {
    console.log('Find Near Me button clicked');
    console.log('Navigator geolocation available:', !!navigator.geolocation);
    console.log('Is secure context:', window.isSecureContext);
    console.log('Current protocol:', window.location.protocol);
    requestLocation();
  };

  const filteredDogs = useMemo(() => {
    return dogs.filter((dog) => {
      const matchesSize = sizeFilter === 'All' || dog.size === sizeFilter;
      // Use computedAge (from birth date if available) for filtering
      const effectiveAge = dog.computedAge || dog.age;
      const matchesAge = ageFilter === 'All' || effectiveAge === ageFilter;
      const matchesStatus = dog.status === statusFilter;
      const matchesSearch =
        searchQuery === '' ||
        dog.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dog.breed.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dog.location.toLowerCase().includes(searchQuery.toLowerCase());

      return matchesSize && matchesAge && matchesStatus && matchesSearch;
    });
  }, [dogs, sizeFilter, ageFilter, statusFilter, searchQuery]);

  // Calculate pagination values
  const totalPages = Math.ceil(filteredDogs.length / ITEMS_PER_PAGE);
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;
  const paginatedDogs = filteredDogs.slice(startIndex, endIndex);

  const handleClearFilters = () => {
    setSizeFilter('All');
    setAgeFilter('All');
    setStatusFilter('available');
    setSearchQuery('');
    setCurrentPage(1);
  };

  const handleSizeChange = (size: SizeFilter) => {
    setSizeFilter(size);
    setCurrentPage(1);
  };

  const handleAgeChange = (age: AgeFilter) => {
    setAgeFilter(age);
    setCurrentPage(1);
  };

  const handleStatusChange = (status: StatusFilter) => {
    setStatusFilter(status);
    setCurrentPage(1);
  };

  const handleSearchChange = (query: string) => {
    setSearchQuery(query);
    setCurrentPage(1);
  };

  // Scroll to top of dog grid when page changes
  useEffect(() => {
    if (gridTopRef.current) {
      gridTopRef.current.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, [currentPage]);

  return (
    <section id="dogs" className="py-16 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12" ref={gridTopRef}>
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
              statusFilter={statusFilter}
              onSizeChange={handleSizeChange}
              onAgeChange={handleAgeChange}
              onStatusChange={handleStatusChange}
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
                  onChange={(e) => handleSearchChange(e.target.value)}
                  className="pl-10"
                />
              </div>
              <div className="flex items-center gap-2">
                {hasLocation ? (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={clearLocation}
                    className="gap-2"
                  >
                    <MapPin className="w-4 h-4" />
                    Near Me
                    <X className="w-3 h-3" />
                  </Button>
                ) : (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={handleLocationRequest}
                    disabled={locationLoading}
                    className="gap-2"
                  >
                    {locationLoading ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      <Navigation className="w-4 h-4" />
                    )}
                    Find Near Me
                  </Button>
                )}
                <p className="text-muted-foreground">
                  <span className="font-semibold text-foreground">{filteredDogs.length}</span> dogs found
                </p>
              </div>
            </div>

            {locationError && (
              <Alert variant="destructive" className="mb-6">
                <AlertDescription>
                  <div className="space-y-2">
                    <p className="font-semibold">{locationError}</p>
                    {window.location.protocol !== 'https:' && window.location.hostname !== 'localhost' && (
                      <p className="text-sm">Note: This site must use HTTPS for location features to work.</p>
                    )}
                    <p className="text-sm">
                      To enable location: Click the lock icon in your browser's address bar and allow location access.
                    </p>
                  </div>
                </AlertDescription>
              </Alert>
            )}

            {hasLocation && (
              <Alert className="mb-6 border-primary/50 bg-primary/5">
                <MapPin className="w-4 h-4" />
                <AlertDescription>
                  Showing dogs sorted by distance from your location
                </AlertDescription>
              </Alert>
            )}

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
              <>
                <div className="grid sm:grid-cols-2 xl:grid-cols-3 gap-6">
                  {paginatedDogs.map((dog, index) => (
                    <div
                      key={dog.id}
                      className="animate-fade-up"
                      style={{ animationDelay: `${index * 0.1}s` }}
                    >
                      <DogCard dog={dog} viewMode={viewMode} showDistance={hasLocation} />
                    </div>
                  ))}
                </div>
                
                {totalPages > 1 && (
                  <div className="mt-8">
                    <Pagination>
                      <PaginationContent>
                        <PaginationItem>
                          <PaginationPrevious
                            onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                            className={currentPage === 1 ? 'pointer-events-none opacity-50' : 'cursor-pointer'}
                          />
                        </PaginationItem>
                        
                        {/* First page */}
                        <PaginationItem>
                          <PaginationLink
                            {...(currentPage !== 1 && { onClick: () => setCurrentPage(1) })}
                            isActive={currentPage === 1}
                            className={currentPage !== 1 ? 'cursor-pointer' : ''}
                          >
                            1
                          </PaginationLink>
                        </PaginationItem>
                        
                        {/* Left ellipsis */}
                        {currentPage > 3 && (
                          <PaginationItem>
                            <PaginationEllipsis />
                          </PaginationItem>
                        )}
                        
                        {/* Pages around current */}
                        {currentPage > 2 && (
                          <PaginationItem>
                            <PaginationLink
                              onClick={() => setCurrentPage(currentPage - 1)}
                              className="cursor-pointer"
                            >
                              {currentPage - 1}
                            </PaginationLink>
                          </PaginationItem>
                        )}
                        
                        {currentPage !== 1 && currentPage !== totalPages && (
                          <PaginationItem>
                            <PaginationLink
                              isActive
                            >
                              {currentPage}
                            </PaginationLink>
                          </PaginationItem>
                        )}
                        
                        {currentPage < totalPages - 1 && (
                          <PaginationItem>
                            <PaginationLink
                              onClick={() => setCurrentPage(currentPage + 1)}
                              className="cursor-pointer"
                            >
                              {currentPage + 1}
                            </PaginationLink>
                          </PaginationItem>
                        )}
                        
                        {/* Right ellipsis */}
                        {currentPage < totalPages - 2 && (
                          <PaginationItem>
                            <PaginationEllipsis />
                          </PaginationItem>
                        )}
                        
                        {/* Last page */}
                        <PaginationItem>
                          <PaginationLink
                            {...(currentPage !== totalPages && { onClick: () => setCurrentPage(totalPages) })}
                            isActive={currentPage === totalPages}
                            className={currentPage !== totalPages ? 'cursor-pointer' : ''}
                          >
                            {totalPages}
                          </PaginationLink>
                        </PaginationItem>
                        
                        <PaginationItem>
                          <PaginationNext
                            onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
                            className={currentPage === totalPages ? 'pointer-events-none opacity-50' : 'cursor-pointer'}
                          />
                        </PaginationItem>
                      </PaginationContent>
                    </Pagination>
                  </div>
                )}
              </>
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
