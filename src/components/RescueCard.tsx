import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MapPin, ExternalLink, Navigation } from 'lucide-react';
import type { Rescue } from '@/hooks/useRescues';

interface RescueCardProps {
  rescue: Rescue;
  showDistance?: boolean;
}

const RescueCard = ({ rescue, showDistance = false }: RescueCardProps) => {
  const hasWebsite = !!rescue.website;

  return (
    <article className="group bg-card rounded-2xl overflow-hidden shadow-card hover:shadow-hover transition-all duration-300 hover:-translate-y-1">
      <div className="p-5 space-y-4">
        <div className="flex gap-2 mb-2 flex-wrap">
          <Badge variant="secondary">{rescue.type}</Badge>
          {showDistance && rescue.distance !== undefined && (
            <Badge variant="outline" className="gap-1">
              <Navigation className="w-3 h-3" />
              {rescue.distance} km
            </Badge>
          )}
        </div>
        
        <div>
          <h3 className="font-display text-xl font-semibold text-foreground">{rescue.name}</h3>
        </div>

        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <MapPin className="w-4 h-4" />
          <span>{rescue.region}</span>
        </div>

        <Button 
          variant="default" 
          className="w-full"
          asChild={hasWebsite}
          disabled={!hasWebsite}
        >
          {hasWebsite ? (
            <a 
              href={rescue.website}
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center justify-center gap-2"
            >
              Visit Website
              <ExternalLink className="w-4 h-4" />
            </a>
          ) : (
            <span>No Website Available</span>
          )}
        </Button>
      </div>
    </article>
  );
};

export default RescueCard;
