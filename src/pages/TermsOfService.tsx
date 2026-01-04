import Header from '@/components/Header';
import Footer from '@/components/Footer';

const TermsOfService = () => {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto px-4 py-12 max-w-4xl">
        <h1 className="font-display text-4xl font-bold mb-8">Terms of Service</h1>
        
        <div className="prose prose-slate max-w-none">
          <p className="text-muted-foreground mb-6">
            <strong>Last Updated:</strong> 31 December 2024
          </p>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
            <p className="text-muted-foreground mb-4">
              Welcome to dogadopt.co.uk. By accessing or using our website, you agree to be bound by these Terms of Service 
              ("Terms"). If you do not agree to these Terms, please do not use our website.
            </p>
            <p className="text-muted-foreground mb-4">
              dogadopt.co.uk is a 100% non-profit platform dedicated to promoting dog adoption and connecting rescue dogs 
              with loving families across the UK.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">2. Description of Service</h2>
            <p className="text-muted-foreground mb-4">
              dogadopt.co.uk provides:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>A searchable database of rescue dogs available for adoption</li>
              <li>Information about UK rescue organizations</li>
              <li>Resources and guidance for potential dog adopters</li>
              <li>A platform to connect adopters with rescue organizations</li>
            </ul>
            <p className="text-muted-foreground mb-4">
              We do not facilitate direct adoptions. All adoption applications and processes are handled directly by the 
              respective rescue organizations.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">3. User Accounts</h2>
            <p className="text-muted-foreground mb-4">
              To access certain features of our website, you may need to create an account. You agree to:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Provide accurate and complete information</li>
              <li>Maintain the security of your account credentials</li>
              <li>Notify us immediately of any unauthorized use of your account</li>
              <li>Be responsible for all activities that occur under your account</li>
            </ul>
            <p className="text-muted-foreground mb-4">
              We reserve the right to suspend or terminate accounts that violate these Terms.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">4. User Conduct</h2>
            <p className="text-muted-foreground mb-4">
              You agree not to:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Use the website for any illegal purpose</li>
              <li>Attempt to gain unauthorized access to our systems</li>
              <li>Interfere with or disrupt the website or servers</li>
              <li>Post false, misleading, or fraudulent information</li>
              <li>Harass, abuse, or harm other users or rescue organizations</li>
              <li>Scrape, crawl, or systematically collect data from the website</li>
              <li>Impersonate any person or entity</li>
              <li>Use the website to promote commercial breeding or puppy farming</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">5. Content and Intellectual Property</h2>
            <p className="text-muted-foreground mb-4">
              All content on dogadopt.co.uk, including text, graphics, logos, images, and software, is the property of 
              dogadopt.co.uk or its content suppliers and is protected by UK and international copyright laws.
            </p>
            <p className="text-muted-foreground mb-4">
              Dog listings, photos, and descriptions are provided by rescue organizations and remain their property. 
              You may not reproduce, distribute, or use this content without permission from the respective rescue organization.
            </p>
            <p className="text-muted-foreground mb-4">
              You may view and print content from the website for personal, non-commercial use only.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">6. Third-Party Links and Services</h2>
            <p className="text-muted-foreground mb-4">
              Our website contains links to third-party websites and services, including rescue organization websites. 
              We are not responsible for the content, privacy practices, or terms of service of these third-party sites.
            </p>
            <p className="text-muted-foreground mb-4">
              Links to third-party sites do not imply endorsement or affiliation. You access third-party sites at your own risk.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">7. Rescue Organizations</h2>
            <p className="text-muted-foreground mb-4">
              dogadopt.co.uk is an independent platform. We are not affiliated with any rescue organization unless 
              explicitly stated. Each rescue organization:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Operates independently</li>
              <li>Has its own adoption policies and procedures</li>
              <li>Is responsible for the accuracy of their listings</li>
              <li>Handles all adoption applications and communications</li>
            </ul>
            <p className="text-muted-foreground mb-4">
              We do not guarantee the availability, health, temperament, or suitability of any dog listed on our platform.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">8. Disclaimer of Warranties</h2>
            <p className="text-muted-foreground mb-4">
              The website is provided "as is" and "as available" without any warranties of any kind, either express or implied. 
              We do not warrant that:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>The website will be uninterrupted or error-free</li>
              <li>Information on the website is accurate, complete, or current</li>
              <li>The website is free from viruses or harmful components</li>
              <li>Any dog listing will result in a successful adoption</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">9. Limitation of Liability</h2>
            <p className="text-muted-foreground mb-4">
              To the fullest extent permitted by law, dogadopt.co.uk and its operators, employees, and affiliates shall not 
              be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Loss of profits, data, or use</li>
              <li>Costs of procurement of substitute services</li>
              <li>Any issues arising from adoptions or interactions with rescue organizations</li>
              <li>Any damages resulting from your use of or inability to use the website</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">10. Indemnification</h2>
            <p className="text-muted-foreground mb-4">
              You agree to indemnify and hold harmless dogadopt.co.uk, its operators, and affiliates from any claims, 
              losses, damages, liabilities, and expenses (including legal fees) arising from:
            </p>
            <ul className="list-disc pl-6 text-muted-foreground mb-4 space-y-2">
              <li>Your use of the website</li>
              <li>Your violation of these Terms</li>
              <li>Your violation of any rights of another party</li>
            </ul>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">11. Changes to Terms</h2>
            <p className="text-muted-foreground mb-4">
              We reserve the right to modify these Terms at any time. We will notify users of any material changes by 
              posting the updated Terms on this page and updating the "Last Updated" date.
            </p>
            <p className="text-muted-foreground mb-4">
              Your continued use of the website after changes are posted constitutes your acceptance of the modified Terms.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">12. Termination</h2>
            <p className="text-muted-foreground mb-4">
              We may suspend or terminate your access to the website at any time, with or without cause or notice, for 
              any reason including violation of these Terms.
            </p>
            <p className="text-muted-foreground mb-4">
              Upon termination, your right to use the website will immediately cease.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">13. Governing Law</h2>
            <p className="text-muted-foreground mb-4">
              These Terms shall be governed by and construed in accordance with the laws of England and Wales, without 
              regard to its conflict of law provisions.
            </p>
            <p className="text-muted-foreground mb-4">
              Any disputes arising from these Terms or your use of the website shall be subject to the exclusive jurisdiction 
              of the courts of England and Wales.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">14. Severability</h2>
            <p className="text-muted-foreground mb-4">
              If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or 
              eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">15. Contact Information</h2>
            <p className="text-muted-foreground mb-4">
              If you have any questions about these Terms of Service, please contact us at:
            </p>
            <p className="text-muted-foreground mb-4">
              Email:{' '}
              <a href="mailto:info@dogadopt.co.uk" className="text-primary hover:underline">
                info@dogadopt.co.uk
              </a>
            </p>
          </section>

          <section className="mb-8">
            <h2 className="text-2xl font-semibold mb-4">16. Entire Agreement</h2>
            <p className="text-muted-foreground mb-4">
              These Terms, together with our Privacy Policy, constitute the entire agreement between you and dogadopt.co.uk 
              regarding your use of the website and supersede all prior agreements and understandings.
            </p>
          </section>
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default TermsOfService;
