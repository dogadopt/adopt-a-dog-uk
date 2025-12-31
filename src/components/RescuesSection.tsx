import { useState, useMemo } from 'react';
import RescueCard from './RescueCard';
import { useRescues } from '@/hooks/useRescues';
import { useGeolocation } from '@/hooks/useGeolocation';
import { Search, Loader2, MapPin, Navigation, X } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import {
  Pagination,
  PaginationContent,
  PaginationEllipsis,
  PaginationItem,
  PaginationLink,
  PaginationNext,
  PaginationPrevious,
} from '@/components/ui/pagination';

const ITEMS_PER_PAGE = 12;

const RescuesSection = () => {
  const [searchQuery, setSearchQuery] = useState('');
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
  const { data: rescues = [], isLoading, error } = useRescues(userLocation);

  const filteredRescues = useMemo(() => {
    return rescues.filter((rescue) => {
      const matchesSearch =
        searchQuery === '' ||
        rescue.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        rescue.region.toLowerCase().includes(searchQuery.toLowerCase()) ||
        rescue.type.toLowerCase().includes(searchQuery.toLowerCase());

      return matchesSearch;
    });
  }, [rescues, searchQuery]);

  // Calculate pagination values
  const totalPages = Math.ceil(filteredRescues.length / ITEMS_PER_PAGE);
  const startIndex = (currentPage - 1) * ITEMS_PER_PAGE;
  const endIndex = startIndex + ITEMS_PER_PAGE;
  const paginatedRescues = filteredRescues.slice(startIndex, endIndex);

  const handleSearchChange = (query: string) => {
    setSearchQuery(query);
    setCurrentPage(1);
  };

  return (
    <section id="rescues" className="py-16 bg-background">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="font-display text-3xl md:text-4xl font-bold text-foreground mb-4">
            Rescue Organizations
          </h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Browse rescue organizations across the UK. Each organization is dedicated to finding loving homes for dogs in need.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between mb-8">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Search by name, region, or type..."
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
                onClick={requestLocation}
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
              <span className="font-semibold text-foreground">{filteredRescues.length}</span> rescues
            </p>
          </div>
        </div>

        {locationError && (
          <Alert variant="destructive" className="mb-6">
            <AlertDescription>{locationError}</AlertDescription>
          </Alert>
        )}

        {hasLocation && (
          <Alert className="mb-6 border-primary/50 bg-primary/5">
            <MapPin className="w-4 h-4" />
            <AlertDescription>
              Showing rescues sorted by distance from your location
            </AlertDescription>
          </Alert>
        )}

        {isLoading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : error ? (
          <div className="text-center py-16 bg-card rounded-2xl shadow-soft">
            <p className="font-display text-xl text-foreground mb-2">Error loading rescues</p>
            <p className="text-muted-foreground">Please try again later</p>
          </div>
        ) : filteredRescues.length > 0 ? (
          <>
            <div className="grid sm:grid-cols-2 xl:grid-cols-3 gap-6">
              {paginatedRescues.map((rescue, index) => (
                <div
                  key={rescue.id}
                  className="animate-fade-up"
                  style={{ animationDelay: `${index * 0.1}s` }}
                >
                  <RescueCard rescue={rescue} showDistance={hasLocation} />
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
            <p className="font-display text-xl text-foreground mb-2">No rescues found</p>
            <p className="text-muted-foreground">Try adjusting your search query</p>
          </div>
        )}
      </div>
    </section>
  );
};

export default RescuesSection;
