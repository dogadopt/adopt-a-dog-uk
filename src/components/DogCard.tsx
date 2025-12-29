import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Heart, MapPin, Users } from 'lucide-react';
import type { Dog } from '@/types/dog';

interface DogCardProps {
  dog: Dog;
  viewMode?: 'text-only' | 'with-images';
}

const DogCard = ({ dog, viewMode = 'text-only' }: DogCardProps) => {
  const showImage = viewMode === 'with-images';

  return (
    <article className="group bg-card rounded-2xl overflow-hidden shadow-card hover:shadow-hover transition-all duration-300 hover:-translate-y-1">
      {showImage && (
        <div className="relative aspect-square overflow-hidden">
          <img
            src={dog.image}
            alt={`${dog.name} - ${dog.breed} available for adoption`}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
          <div className="absolute top-3 left-3 flex gap-2">
            <Badge variant="warm">{dog.age}</Badge>
            <Badge variant="secondary">{dog.size}</Badge>
          </div>
          <button className="absolute top-3 right-3 w-10 h-10 bg-card/90 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-primary hover:text-primary-foreground transition-colors shadow-soft">
            <Heart className="w-5 h-5" />
          </button>
        </div>
      )}

      <div className="p-5 space-y-4">
        {!showImage && (
          <div className="flex gap-2 mb-2">
            <Badge variant="warm">{dog.age}</Badge>
            <Badge variant="secondary">{dog.size}</Badge>
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

        <Button variant="default" className="w-full">
          View Profile
        </Button>
      </div>
    </article>
  );
};

export default DogCard;
