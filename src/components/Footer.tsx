import { Heart } from 'lucide-react';
import { Link } from 'react-router-dom';

const Footer = () => {
  return (
    <footer id="rescues" className="bg-foreground text-background py-16">
      <div className="container mx-auto px-4">
        <div className="grid md:grid-cols-4 gap-8 mb-12">
          <div className="md:col-span-2">
            <a href="/" className="flex items-center gap-2 mb-4">
              <img 
                src="/brand_images/logos/Original Logo Symbol.png" 
                alt="DogAdopt Logo" 
                className="w-10 h-10 object-contain"
              />
              <span className="font-display text-xl font-semibold">
                dogadopt<span className="text-primary">.co.uk</span>
              </span>
            </a>
            <p className="text-background/70 max-w-md mb-3">
              100% non-profit platform connecting rescue dogs with loving families across the UK. 
              Our mission is to promote adoption over purchasing and help every dog find their forever home.
            </p>
            <p className="text-background/60 text-sm max-w-md">
              Currently independent, we aim to feature quality rescue organisations and hope to build strong partnerships with ADCH and rescue organisations in the future.
            </p>
          </div>

          <div>
            <h4 className="font-display font-semibold mb-4">Quick Links</h4>
            <ul className="space-y-2 text-background/70">
              <li><a href="#dogs" className="hover:text-primary transition-colors">Find a Dog</a></li>
              <li><Link to="/about" className="hover:text-primary transition-colors">Why Adopt?</Link></li>
              <li><a href="#rescues" className="hover:text-primary transition-colors">Rescue Organisations</a></li>
              <li><Link to="/contact" className="hover:text-primary transition-colors">Contact</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="font-display font-semibold mb-4">Legal</h4>
            <ul className="space-y-2 text-background/70">
              <li><Link to="/privacy" className="hover:text-primary transition-colors">Privacy Policy</Link></li>
              <li><Link to="/terms" className="hover:text-primary transition-colors">Terms of Service</Link></li>
            </ul>
          </div>
        </div>

        <div className="border-t border-background/20 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-background/50 text-sm text-center md:text-left">
            © {new Date().getFullYear()} dogadopt.co.uk - 100% Non-Profit. Made with <Heart className="w-4 h-4 inline text-primary" fill="currentColor" /> for rescue dogs everywhere.
          </p>
          <p className="text-background/50 text-sm">
            <span className="text-primary">#AdoptDontShop</span>
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
