import { Heart, Home, Shield, Sparkles } from 'lucide-react';

const features = [
  {
    icon: Heart,
    title: 'Save a Life',
    description: 'Every dog adopted from a rescue means another life saved and one less supporting puppy farms. Give a deserving dog their second chance.',
  },
  {
    icon: Home,
    title: 'Find Your Match',
    description: 'Our comprehensive profiles help you find a dog that fits your lifestyle, home, and family perfectly.',
  },
  {
    icon: Shield,
    title: 'ADCH Quality Only',
    description: 'We exclusively feature ADCH-accredited rescues - trusted organisations committed to the highest animal welfare standards.',
  },
  {
    icon: Sparkles,
    title: '100% Non-Profit',
    description: 'This platform exists purely to help dogs find homes. We have no commercial interest - just a mission to end needless suffering.',
  },
];

const AboutSection = () => {
  return (
    <section id="about" className="py-20 bg-card">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <span className="inline-block px-4 py-2 bg-primary/10 rounded-full text-primary text-sm font-medium mb-4">
            Why Adopt Don't Shop?
          </span>
          <h2 className="font-display text-3xl md:text-4xl font-bold text-foreground mb-4">
            The Joy of Rescue Dog Adoption
          </h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Adopting a rescue dog is rewarding and ethical. Here's why thousands choose adoption and why you should too.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <div
              key={feature.title}
              className="bg-background rounded-2xl p-6 shadow-soft hover:shadow-card transition-shadow duration-300 animate-fade-up"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              <div className="w-12 h-12 bg-primary/10 rounded-xl flex items-center justify-center mb-4">
                <feature.icon className="w-6 h-6 text-primary" />
              </div>
              <h3 className="font-display text-lg font-semibold text-foreground mb-2">{feature.title}</h3>
              <p className="text-muted-foreground text-sm">{feature.description}</p>
            </div>
          ))}
        </div>

        <div className="mt-16 bg-gradient-to-r from-primary/10 via-primary/5 to-accent/10 rounded-3xl p-8 md:p-12">
          <div className="max-w-3xl mx-auto text-center">
            <h3 className="font-display text-2xl md:text-3xl font-bold text-foreground mb-4">
              Understanding the Crisis: Over 100,000 Dogs Need Homes
            </h3>
            <p className="text-muted-foreground mb-4">
              This website exists to give you visibility on the true number of rescue dogs in the UK so their plight can be understood. 
              While puppy farms and irresponsible breeders continue to profit, rescue centres are overflowing with dogs desperate for loving families.
            </p>
            <p className="text-muted-foreground mb-4">
              We help you understand the adoption process and connect you with ADCH-accredited rescues - the gold standard in animal welfare. 
              By choosing to adopt, you're not just getting a pet — you're making a stand against the cruel puppy trade and supporting ethical, quality rescues.
            </p>
            <p className="text-foreground font-medium mb-2">
              <span className="text-primary">#AdoptDontShop</span> — Because every dog deserves a second chance.
            </p>
            <p className="text-sm text-muted-foreground italic">
              Currently independent, we hope to build strong relationships with ADCH and rescue organisations to help even more dogs find forever homes.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AboutSection;
