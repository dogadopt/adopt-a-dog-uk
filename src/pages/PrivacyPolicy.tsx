import Header from '@/components/Header';
import Footer from '@/components/Footer';

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-12 max-w-4xl">
        <h1 className="font-display text-4xl font-bold mb-8">Privacy Policy</h1>
        
        <div className="prose prose-slate max-w-none">
          <p className="text-muted-foreground mb-6">
            <strong>Last Updated:</strong> 31 December 2024
          </p>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">1. Introduction</h2>
            <p className="text-muted-foreground mb-4">
              Welcome to dogadopt.co.uk ("we," "our," or "us"). We are committed to protecting your privacy and personal data. 
              This Privacy Policy explains how we collect, use, and safeguard your information when you visit our website.
            </p>
            <p className="text-muted-foreground mb-4">
              dogadopt.co.uk is a 100% non-profit platform dedicated to connecting rescue dogs with loving families across the UK. 
              We do not sell, rent, or share your personal information with third parties for marketing purposes.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">2. Information We Collect</h2>
            <h3 className="text-xl font-semibold mb-3">2.1 Information You Provide</h3>
            <p className="text-muted-foreground mb-4">
              When you create an account or contact us, we may collect:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Email address</li>
              <li>Name (if provided)</li>
              <li>Any information you include in messages to us</li>
            </ul>

            <h3 className="text-xl font-semibold mb-3">2.2 Automatically Collected Information</h3>
            <p className="text-muted-foreground mb-4">
              When you visit our website, we may automatically collect:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>IP address</li>
              <li>Browser type and version</li>
              <li>Device information</li>
              <li>Pages visited and time spent on pages</li>
              <li>Referring website addresses</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">3. How We Use Your Information</h2>
            <p className="text-muted-foreground mb-4">
              We use the information we collect to:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Provide and maintain our service</li>
              <li>Create and manage user accounts</li>
              <li>Respond to your inquiries and provide customer support</li>
              <li>Improve our website and user experience</li>
              <li>Send important updates about our service</li>
              <li>Prevent fraud and ensure security</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">4. Data Storage and Security</h2>
            <p className="text-muted-foreground mb-4">
              We take the security of your personal data seriously. We use industry-standard security measures to protect 
              your information from unauthorized access, disclosure, alteration, or destruction. Your data is stored securely 
              using Supabase, which complies with GDPR and other data protection regulations.
            </p>
            <p className="text-muted-foreground mb-4">
              However, no method of transmission over the internet or electronic storage is 100% secure, and we cannot 
              guarantee absolute security.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">5. Cookies and Tracking Technologies</h2>
            <p className="text-muted-foreground mb-4">
              We use essential cookies and similar tracking technologies to improve your browsing experience and analyze 
              website traffic. These help us understand how visitors interact with our website.
            </p>
            <p className="text-muted-foreground mb-4">
              You can control cookies through your browser settings. However, disabling cookies may affect the functionality 
              of our website.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">6. Third-Party Services</h2>
            <p className="text-muted-foreground mb-4">
              We use the following third-party services that may collect information:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li><strong>Supabase:</strong> For authentication and database services</li>
              <li><strong>Hosting providers:</strong> For website hosting and delivery</li>
            </ul>
            <p className="text-muted-foreground mb-4">
              These third parties have their own privacy policies and are responsible for their data practices.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">7. Your Rights</h2>
            <p className="text-muted-foreground mb-4">
              Under UK GDPR and data protection laws, you have the right to:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Access your personal data</li>
              <li>Correct inaccurate personal data</li>
              <li>Request deletion of your personal data</li>
              <li>Object to processing of your personal data</li>
              <li>Request restriction of processing your personal data</li>
              <li>Data portability</li>
              <li>Withdraw consent at any time</li>
            </ul>
            <p className="text-muted-foreground mb-4">
              To exercise any of these rights, please contact us at{' '}
              <a href="mailto:info@dogadopt.co.uk" className="text-primary hover:underline">
                info@dogadopt.co.uk
              </a>
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">8. Children's Privacy</h2>
            <p className="text-muted-foreground mb-4">
              Our service is not intended for children under 13 years of age. We do not knowingly collect personal 
              information from children under 13. If you are a parent or guardian and believe your child has provided 
              us with personal information, please contact us.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">9. Changes to This Privacy Policy</h2>
            <p className="text-muted-foreground mb-4">
              We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new 
              Privacy Policy on this page and updating the "Last Updated" date.
            </p>
            <p className="text-muted-foreground mb-4">
              You are advised to review this Privacy Policy periodically for any changes.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">10. Contact Us</h2>
            <p className="text-muted-foreground mb-4">
              If you have any questions about this Privacy Policy or our privacy practices, please contact us at:
            </p>
            <p className="text-muted-foreground mb-4">
              Email:{' '}
              <a href="mailto:info@dogadopt.co.uk" className="text-primary hover:underline">
                info@dogadopt.co.uk
              </a>
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default PrivacyPolicy;
