import Header from '@/components/Header';
import Footer from '@/components/Footer';
import { Mail, MapPin, Heart } from 'lucide-react';

const Contact = () => {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-12 max-w-4xl">
        <h1 className="font-display text-4xl font-bold mb-8">Contact Us</h1>
        
        <div className="prose prose-slate max-w-none">
          <p className="text-muted-foreground mb-8 text-lg">
            We'd love to hear from you! Whether you have questions, feedback, or need assistance, 
            feel free to reach out to us.
          </p>

          <section className="mb-12">
            <div className="bg-card border border-border rounded-lg p-8 shadow-sm">
              <div className="flex items-start gap-4 mb-6">
                <div className="bg-primary/10 p-3 rounded-lg">
                  <Mail className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h2 className="text-2xl font-semibold mb-2">Email</h2>
                  <p className="text-muted-foreground mb-2">
                    For all inquiries, please email us at:
                  </p>
                  <a 
                    href="mailto:info@dogadopt.co.uk" 
                    className="text-xl text-primary hover:underline font-medium"
                  >
                    info@dogadopt.co.uk
                  </a>
                </div>
              </div>

              <div className="border-t border-border pt-6 mt-6">
                <p className="text-muted-foreground text-sm">
                  We typically respond within 24-48 hours during business days. Please note that we are a 
                  small team running a non-profit platform, so response times may vary.
                </p>
              </div>
            </div>
          </section>

          <section className="mb-12">
            <h2 className="text-2xl font-semibold mb-6">What We Can Help With</h2>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-card border border-border rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-3">General Inquiries</h3>
                <ul className="text-muted-foreground space-y-2 text-sm">
                  <li>• Information about our platform</li>
                  <li>• How to use dogadopt.co.uk</li>
                  <li>• Questions about dog adoption</li>
                  <li>• Partnership opportunities</li>
                </ul>
              </div>

              <div className="bg-card border border-border rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-3">Rescue Organizations</h3>
                <ul className="text-muted-foreground space-y-2 text-sm">
                  <li>• Listing your rescue on our platform</li>
                  <li>• Updating rescue information</li>
                  <li>• Adding or updating dog listings</li>
                  <li>• Technical support for rescues</li>
                </ul>
              </div>

              <div className="bg-card border border-border rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-3">Website Issues</h3>
                <ul className="text-muted-foreground space-y-2 text-sm">
                  <li>• Reporting bugs or errors</li>
                  <li>• Technical difficulties</li>
                  <li>• Account issues</li>
                  <li>• Suggestions for improvements</li>
                </ul>
              </div>

              <div className="bg-card border border-border rounded-lg p-6">
                <h3 className="text-lg font-semibold mb-3">Privacy & Legal</h3>
                <ul className="text-muted-foreground space-y-2 text-sm">
                  <li>• Privacy concerns</li>
                  <li>• Data protection inquiries</li>
                  <li>• Terms of service questions</li>
                  <li>• Legal matters</li>
                </ul>
              </div>
            </div>
          </section>

          <section className="mb-12">
            <div className="bg-primary/5 border border-primary/20 rounded-lg p-6">
              <h2 className="text-2xl font-semibold mb-4 flex items-center gap-2">
                <Heart className="w-6 h-6 text-primary" />
                Important Note
              </h2>
              <p className="text-muted-foreground mb-4">
                <strong>dogadopt.co.uk does not handle adoptions directly.</strong> We are a platform that connects 
                potential adopters with rescue organizations.
              </p>
              <p className="text-muted-foreground mb-4">
                If you're interested in adopting a specific dog, please contact the rescue organization listed on 
                that dog's profile page directly. Each rescue organization has its own adoption process, requirements, 
                and timelines.
              </p>
              <p className="text-muted-foreground">
                We cannot provide updates on specific dogs or adoption applications.
              </p>
            </div>
          </section>

          <section className="mb-12">
            <h2 className="text-2xl font-semibold mb-6">About dogadopt.co.uk</h2>
            <div className="bg-card border border-border rounded-lg p-6">
              <div className="flex items-start gap-4">
                <div className="bg-primary/10 p-3 rounded-lg">
                  <MapPin className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold mb-3">Our Mission</h3>
                  <p className="text-muted-foreground mb-4">
                    We are a 100% non-profit platform dedicated to promoting dog adoption over purchasing. 
                    Our goal is to help every rescue dog in the UK find their forever home by making it easier 
                    for potential adopters to discover dogs in need.
                  </p>
                  <p className="text-muted-foreground mb-4">
                    Currently independent, we aim to feature quality rescue organisations and hope to build 
                    strong partnerships with ADCH (Association of Dogs and Cats Homes) and rescue organisations 
                    across the UK in the future.
                  </p>
                  <p className="text-muted-foreground">
                    <strong className="text-primary">#AdoptDontShop</strong>
                  </p>
                </div>
              </div>
            </div>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-6">Before You Contact Us</h2>
            <p className="text-muted-foreground mb-4">
              Please check our website for answers to common questions:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground space-y-2">
              <li>
                Visit our <a href="/about" className="text-primary hover:underline">About page</a> to learn more about 
                dogadopt.co.uk and how we work
              </li>
              <li>
                Browse our <a href="/rescues" className="text-primary hover:underline">Rescues page</a> to find contact 
                information for specific rescue organizations
              </li>
              <li>
                Read our <a href="/privacy" className="text-primary hover:underline">Privacy Policy</a> for information 
                about how we handle your data
              </li>
              <li>
                Review our <a href="/terms" className="text-primary hover:underline">Terms of Service</a> for details 
                about using our platform
              </li>
            </ul>
          </section>

          <section className="mb-8 bg-card border border-border rounded-lg p-6">
            <h2 className="text-xl font-semibold mb-4">Response Times</h2>
            <p className="text-muted-foreground mb-4">
              We're a small, dedicated team passionate about helping rescue dogs. We aim to respond to all emails 
              within 24-48 hours during business days (Monday-Friday).
            </p>
            <p className="text-muted-foreground">
              Please note that response times may be longer during weekends, holidays, or periods of high volume. 
              We appreciate your patience and understanding.
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Contact;
