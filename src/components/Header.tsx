import { Heart, Menu, Shield, LogOut, User, MessageSquare } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

const Header = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const { user, isAdmin, signOut } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  const handleLogoClick = (e: React.MouseEvent<HTMLAnchorElement>) => {
    // If we're already on the homepage, scroll to top and clear hash
    if (location.pathname === '/') {
      e.preventDefault();
      window.scrollTo({ top: 0, behavior: 'smooth' });
      window.history.replaceState(null, '', '/');
    }
  };

  return (
    <header className="sticky top-0 z-50 bg-card/80 backdrop-blur-md border-b border-border">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-2" onClick={handleLogoClick}>
            <img 
              src="/brand_images/logos/Original Logo Symbol.png" 
              alt="DogAdopt Logo" 
              className="w-10 h-10 object-contain"
            />
            <span className="font-display text-xl font-semibold text-foreground">
              dogadopt<span className="text-primary">.co.uk</span>
            </span>
          </Link>

          <nav className="hidden md:flex items-center gap-8">
            <a href="/#dogs" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              Find a Dog
            </a>
            <Link to="/about" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              About
            </Link>
            <Link to="/rescues" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
              Rescues
            </Link>
            <Link to="/chat" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
              <MessageSquare className="w-4 h-4" />
              Chat
            </Link>
            {isAdmin && (
              <Link to="/admin" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
                <Shield className="w-4 h-4" />
                Admin
              </Link>
            )}
            {user ? (
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="sm">
                    <User className="w-4 h-4 mr-2" />
                    Account
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuLabel>
                    <div className="flex flex-col">
                      <span className="text-sm font-medium">My Account</span>
                      <span className="text-xs text-muted-foreground truncate max-w-[200px]">
                        {user.email}
                      </span>
                    </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleSignOut}>
                    <LogOut className="w-4 h-4 mr-2" />
                    Sign Out
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            ) : (
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
              <a href="/#dogs" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                Find a Dog
              </a>
              <Link to="/about" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                About
              </Link>
              <Link to="/rescues" className="text-muted-foreground hover:text-foreground transition-colors font-medium">
                Rescues
              </Link>
              <Link to="/chat" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
                <MessageSquare className="w-4 h-4" />
                Chat
              </Link>
              {isAdmin && (
                <Link to="/admin" className="text-muted-foreground hover:text-foreground transition-colors font-medium flex items-center gap-1">
                  <Shield className="w-4 h-4" />
                  Admin
                </Link>
              )}
              {user ? (
                <div className="flex flex-col gap-2">
                  <div className="text-xs text-muted-foreground px-2">
                    {user.email}
                  </div>
                  <Button variant="outline" size="sm" className="w-fit" onClick={handleSignOut}>
                    <LogOut className="w-4 h-4 mr-2" />
                    Sign Out
                  </Button>
                </div>
              ) : (
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
