import { Heart, Menu, Shield } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Link } from 'react-router-dom';

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { user, isAdmin } = useAuth();

  return (
    <header className="sticky top-0 z-50 bg-card/80 backdrop-blur-md border-b border-border">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center">
              <Heart className="w-5 h-5 text-primary-foreground" fill="currentColor" />
            </div>
            <span className="font-display text-xl font-semibold text-foreground">
              dogadopt<span className="text-primary">.co.uk</span>
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-8">
            <a href="#dogs" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              Find a Dog
            </a>
            <a href="#about" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              About
            </a>
            <a href="#rescues" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              Rescues
            </a>
            {isAdmin && (
              <Link to="/admin" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
                <Shield className="w-4 h-4" />
                Admin
              </Link>
            )}
            {!user && (
              <Link to="/auth">
                <Button variant="outline" size="sm">
                  Sign In
                </Button>
              </Link>
            )}
            <Button variant="default" size="sm">
              Donate
            </Button>
          </nav>

          <Button 
            variant="ghost" 
            size="icon" 
            className="md:hidden"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            <Menu className="w-5 h-5" />
          </Button>
        </div>

        {isMenuOpen && (
          <nav className="md:hidden py-4 border-t border-border animate-fade-up">
            <div className="flex flex-col gap-4">
              <a href="#dogs" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                Find a Dog
              </a>
              <a href="#about" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                About
              </a>
              <a href="#rescues" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                Rescues
              </a>
              {isAdmin && (
                <Link to="/admin" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
                  <Shield className="w-4 h-4" />
                  Admin
                </Link>
              )}
              {!user && (
                <Link to="/auth">
                  <Button variant="outline" size="sm" className="w-fit">
                    Sign In
                  </Button>
                </Link>
              )}
              <Button variant="default" size="sm" className="w-fit">
                Donate
              </Button>
            </div>
          </nav>
        )}
      </div>
    </header>
  );
};

export default Header;
