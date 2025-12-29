import { Button } from '@/components/ui/button';
import { Heart, Search } from 'lucide-react';
import heroImage from '@/assets/hero-dog.jpg';
import { useDogs } from '@/hooks/useDogs';
import { useRescues } from '@/hooks/useRescues';

const Hero = () => {
  const { data: dogs = [] } = useDogs();
  const { data: rescues = [] } = useRescues();
  return (
    <section className="relative min-h-[600px] gradient-hero overflow-hidden">
      <div className="container mx-auto px-4 py-16 lg:py-24">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-8 animate-fade-up">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-primary/10 rounded-full">
              <Heart className="w-4 h-4 text-primary" fill="currentColor" />
              <span className="text-sm font-medium text-primary">Adopt Don't Shop</span>
            </div>
            
            <h1 className="font-display text-4xl md:text-5xl lg:text-6xl font-bold text-foreground leading-tight">
              Find Your Perfect
              <span className="text-primary block">Rescue Companion</span>
            </h1>
            
            <p className="text-lg text-muted-foreground max-w-lg">
              Discover rescue dogs from quality ADCH-accredited shelters across the UK. 
              100% non-profit. Every adoption saves a life and helps end the puppy farming crisis.
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <Button variant="hero" asChild>
                <a href="#dogs">
                  <Search className="w-5 h-5 mr-2" />
                  Browse Dogs
                </a>
              </Button>
              <Button variant="heroOutline" asChild>
                <a href="#about">Learn More</a>
              </Button>
            </div>

            <div className="grid grid-cols-3 gap-8 pt-8 border-t border-border">
              <div>
                <p className="font-display text-3xl font-bold text-primary">{dogs.length.toLocaleString()}</p>
                <p className="text-sm text-muted-foreground">Dogs Available</p>
              </div>
              <div>
                <p className="font-display text-3xl font-bold text-primary">{rescues.length.toLocaleString()}</p>
                <p className="text-sm text-muted-foreground">UK Rescues</p>
              </div>
              <div>
                <p className="font-display text-3xl font-bold text-primary">0</p>
                <p className="text-sm text-muted-foreground">Happy Adoptions</p>
              </div>
            </div>
          </div>

          <div className="relative lg:h-[500px] animate-scale-in" style={{ animationDelay: '0.2s' }}>
            <div className="absolute inset-0 bg-primary/20 rounded-3xl transform rotate-3" />
            <img
              src={heroImage}
              alt="Happy golden retriever looking for a home"
              className="relative w-full h-full object-cover rounded-3xl shadow-hover"
            />
            <div className="absolute -bottom-4 -left-4 bg-card rounded-2xl p-4 shadow-card animate-float">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-accent/10 rounded-full flex items-center justify-center">
                  <Heart className="w-6 h-6 text-accent" fill="currentColor" />
                </div>
                <div>
                  <p className="font-display font-semibold text-foreground">Adopt Today</p>
                  <p className="text-sm text-muted-foreground">Give a dog a second chance</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
