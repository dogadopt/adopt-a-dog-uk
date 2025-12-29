import { ReactNode } from 'react';
import { isSupabaseConfigured } from '@/integrations/supabase/client';

interface ConfigurationCheckProps {
  children: ReactNode;
}

const ConfigurationCheck = ({ children }: ConfigurationCheckProps) => {
  if (!isSupabaseConfigured) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-red-50 to-red-100 flex items-center justify-center p-4">
        <div className="max-w-2xl bg-white rounded-lg shadow-xl p-8">
          <div className="flex items-center mb-6">
            <div className="flex-shrink-0">
              <svg className="h-12 w-12 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <div className="ml-4">
              <h1 className="text-3xl font-bold text-gray-900">Configuration Required</h1>
              <p className="text-lg text-gray-600 mt-1">Supabase environment variables are not set</p>
            </div>
          </div>

          <div className="bg-red-50 border-l-4 border-red-600 p-4 mb-6">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-600" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-800 font-semibold">
                  Missing required environment variables: VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">For Local Development:</h2>
              <ol className="list-decimal list-inside space-y-2 text-gray-700 ml-2">
                <li className="pl-2">Copy <code className="bg-gray-100 px-2 py-1 rounded text-sm">.env.example</code> to <code className="bg-gray-100 px-2 py-1 rounded text-sm">.env</code></li>
                <li className="pl-2">Fill in your Supabase project URL and publishable key</li>
                <li className="pl-2">Restart the development server</li>
              </ol>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-3">For Production Deployment (GitHub Pages):</h2>
              <ol className="list-decimal list-inside space-y-2 text-gray-700 ml-2">
                <li className="pl-2">Go to your repository Settings → Secrets and variables → Actions</li>
                <li className="pl-2">Add the following repository secrets:
                  <ul className="list-disc list-inside ml-6 mt-2 space-y-1">
                    <li><code className="bg-gray-100 px-2 py-1 rounded text-sm">VITE_SUPABASE_URL</code></li>
                    <li><code className="bg-gray-100 px-2 py-1 rounded text-sm">VITE_SUPABASE_PUBLISHABLE_KEY</code></li>
                    <li><code className="bg-gray-100 px-2 py-1 rounded text-sm">VITE_SUPABASE_PROJECT_ID</code></li>
                  </ul>
                </li>
                <li className="pl-2">Re-run the deployment workflow or push a new commit</li>
              </ol>
            </div>

            <div className="bg-blue-50 border-l-4 border-blue-500 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-blue-500" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <p className="text-sm text-blue-800">
                    <strong>Need help?</strong> See <code className="bg-blue-100 px-2 py-1 rounded">docs/CI_CD_SETUP.md</code> for detailed setup instructions.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-8 pt-6 border-t border-gray-200">
            <p className="text-sm text-gray-500">
              Check your browser console for additional debugging information.
            </p>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
};

export default ConfigurationCheck;
