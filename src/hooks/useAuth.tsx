import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '@/integrations/supabase/client';

// DEV ONLY: Set to true to bypass auth and simulate admin access
// Disabled by default - use proper Supabase auth instead
const DEV_BYPASS_AUTH = false;

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAdmin: boolean;
  isLoading: boolean;
  isDevBypass: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string) => Promise<{ error: Error | null }>;
  signInWithGoogle: () => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Mock user for dev bypass
const mockDevUser: User = {
  id: 'dev-bypass-user',
  email: 'dev@localhost',
  aud: 'authenticated',
  role: 'authenticated',
  created_at: new Date().toISOString(),
  app_metadata: {},
  user_metadata: {},
} as User;

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(DEV_BYPASS_AUTH ? mockDevUser : null);
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(DEV_BYPASS_AUTH);
  const [isLoading, setIsLoading] = useState(!DEV_BYPASS_AUTH);

  const checkAdminRole = async (userId: string) => {
    const { data, error } = await (supabase as any)
      .from('user_roles')
      .select('role')
      .eq('user_id', userId)
      .eq('role', 'admin')
      .maybeSingle();
    
    if (error) {
      console.error('Error checking admin role:', error);
      return false;
    }
    return !!data;
  };

  useEffect(() => {
    // Skip real auth if dev bypass is enabled
    if (DEV_BYPASS_AUTH) {
      console.warn('⚠️ DEV AUTH BYPASS ENABLED - Remove before production!');
      return;
    }

    // Set up auth state listener FIRST
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        
        // Defer admin check with setTimeout to avoid deadlock
        if (session?.user) {
          setTimeout(() => {
            checkAdminRole(session.user.id).then(setIsAdmin);
          }, 0);
        } else {
          setIsAdmin(false);
        }
        setIsLoading(false);
      }
    );

    // THEN check for existing session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        checkAdminRole(session.user.id).then(setIsAdmin);
      }
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return { error };
  };

  const signUp = async (email: string, password: string) => {
    const redirectUrl = `${window.location.origin}/`;
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: { emailRedirectTo: redirectUrl }
    });
    return { error };
  };

  const signInWithGoogle = async () => {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
    const isLocal = supabaseUrl.includes('localhost') || supabaseUrl.includes('127.0.0.1');
    
    if (isLocal) {
      // Mock Google Auth for local development
      const mockEmail = `google.user.${Date.now()}@gmail.com`;
      const mockPassword = 'google-auth-mock-password';
      
      try {
        // First, try to sign up the mock user
        const { error: signUpError } = await supabase.auth.signUp({
          email: mockEmail,
          password: mockPassword,
          options: {
            data: {
              full_name: 'Google User',
              avatar_url: 'https://via.placeholder.com/150/0066CC/FFFFFF?text=G',
              provider: 'google'
            }
          }
        });
        
        if (signUpError && !signUpError.message.includes('already registered')) {
          return { error: signUpError };
        }
        
        // Then sign in with the mock credentials
        const { error: signInError } = await supabase.auth.signInWithPassword({
          email: mockEmail,
          password: mockPassword,
        });
        
        if (signInError) return { error: signInError };
        return { error: null };
      } catch (error: any) {
        console.error('Mock Google auth error:', error);
        return { error: new Error('Mock Google authentication failed') };
      }
    } else {
      // Production Google OAuth
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/`
        }
      });
      return { error };
    }
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setIsAdmin(false);
  };

  return (
    <AuthContext.Provider value={{ user, session, isAdmin, isLoading, isDevBypass: DEV_BYPASS_AUTH, signIn, signUp, signInWithGoogle, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
