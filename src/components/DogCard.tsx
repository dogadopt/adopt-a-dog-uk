import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Heart, MapPin, Users, Navigation } from 'lucide-react';
import type { Dog, StatusFilter } from '@/types/dog';

interface DogCardProps {
  dog: Dog;
  viewMode?: 'text-only' | 'with-images';
  showDistance?: boolean;
}

const DogCard = ({ dog, viewMode = 'text-only', showDistance = false }: DogCardProps) => {
  const showImage = viewMode === 'with-images';
  
  // Use computed age from birth date if available, otherwise fall back to manual age
  const displayAge = dog.computedAge || dog.age;

  // Format status for display
  const formatStatus = (status: StatusFilter) => {
    switch (status) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'adopted':
        return 'Adopted';
      case 'on_hold':
        return 'On Hold';
      case 'fostered':
        return 'Fostered';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status;
    }
  };

  // Get badge variant based on status
  const getStatusVariant = (status: StatusFilter): 'default' | 'secondary' | 'destructive' | 'outline' | 'warm' | 'success' => {
    switch (status) {
      case 'available':
        return 'success';
      case 'reserved':
        return 'warm';
      case 'adopted':
        return 'secondary';
      case 'on_hold':
        return 'outline';
      case 'fostered':
        return 'default';
      case 'withdrawn':
        return 'destructive';
      default:
        return 'default';
    }
  };

  // Add UTM parameters to dog profile URL
  const getDogProfileUrl = () => {
    if (!dog.profileUrl) return null;
    
    try {
      const url = new URL(dog.profileUrl);
      url.searchParams.set('utm_source', 'dogadopt');
      url.searchParams.set('utm_medium', 'referral');
      url.searchParams.set('utm_campaign', 'dog_profile');
      return url.toString();
    } catch (e) {
      // If URL is invalid, return null to prevent broken links
      console.warn(`Invalid profile URL for dog ${dog.name}:`, dog.profileUrl, e);
      return null;
    }
  };

  const profileUrl = getDogProfileUrl();
  const isProfileLinkEnabled = !!profileUrl;

  return (
    <article className="group bg-card rounded-2xl overflow-hidden shadow-card hover:shadow-hover transition-all duration-300 hover:-translate-y-1">
      {showImage && (
        <div className="relative aspect-square overflow-hidden">
          <img
            src={dog.image}
            alt={`${dog.name} - ${dog.breed} available for adoption`}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
          <div className="absolute top-3 left-3 flex gap-2 flex-wrap">
            <Badge variant={getStatusVariant(dog.status)}>{formatStatus(dog.status)}</Badge>
            <Badge variant="warm">{displayAge}</Badge>
            <Badge variant="secondary">{dog.size}</Badge>
          </div>
          <button className="absolute top-3 right-3 w-10 h-10 bg-card/90 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-primary hover:text-primary-foreground transition-colors shadow-soft">
            <Heart className="w-5 h-5" />
          </button>
        </div>
      )}

      <div className="p-5 space-y-4">
        {!showImage && (
          <div className="flex gap-2 mb-2 flex-wrap">
            <Badge variant={getStatusVariant(dog.status)}>{formatStatus(dog.status)}</Badge>
            <Badge variant="warm">{displayAge}</Badge>
            <Badge variant="secondary">{dog.size}</Badge>
            {showDistance && dog.distance !== undefined && (
              <Badge variant="outline" className="gap-1">
                <Navigation className="w-3 h-3" />
                {dog.distance} km
              </Badge>
            )}
          </div>
        )}
        <div>
          <h3 className="font-display text-xl font-semibold text-foreground">{dog.name}</h3>
          <p className="text-muted-foreground">{dog.breed}</p>
        </div>

        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <MapPin className="w-4 h-4" />
          <span>{dog.location}</span>
          <span className="text-border">•</span>
          <span>{dog.rescue}</span>
        </div>

        {dog.rescueSinceDate && (
          <div className="text-xs text-muted-foreground">
            {(() => {
              try {
                const date = new Date(dog.rescueSinceDate);
                if (isNaN(date.getTime())) return null;
                return `In rescue since ${date.toLocaleDateString('en-GB', { 
                  year: 'numeric', 
                  month: 'short', 
                  day: 'numeric' 
                })}`;
              } catch (e) {
                return null;
              }
            })()}
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          {dog.goodWithKids && (
            <Badge variant="success" className="text-xs">
              <Users className="w-3 h-3 mr-1" />
              Good with kids
            </Badge>
          )}
          {dog.goodWithDogs && (
            <Badge variant="success" className="text-xs">
              Good with dogs
            </Badge>
          )}
          {dog.goodWithCats && (
            <Badge variant="success" className="text-xs">
              Good with cats
            </Badge>
          )}
        </div>

        <Button 
          variant="default" 
          className="w-full"
          asChild={isProfileLinkEnabled}
          disabled={!isProfileLinkEnabled}
        >
          {isProfileLinkEnabled ? (
            <a 
              href={profileUrl}
              target="_blank"
              rel="noopener noreferrer"
            >
              View Profile
            </a>
          ) : (
            <span>View Profile</span>
          )}
        </Button>
      </div>
    </article>
  );
};

export default DogCard;
