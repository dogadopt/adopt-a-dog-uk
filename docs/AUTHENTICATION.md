# Supabase Authentication Setup

This document explains the authentication setup for the Adopt a Dog UK application.

## Overview

The application uses Supabase Authentication with support for:
- **Email/Password authentication**
- **Google OAuth** (production only, disabled in dev mode by default)
- **Role-based access control** (admin users via `user_roles` table)

## Development vs Production

### Development Mode (DEV_BYPASS_AUTH)

In development, authentication is **bypassed by default** to make local development easier:
- You don't need to sign in to access the app
- Admin access is automatically granted
- Google OAuth is hidden from the UI
- A yellow banner indicates "Dev Mode: Auth Bypassed"

To **disable** the bypass and test real authentication locally:
```bash
# In your .env file
VITE_DEV_BYPASS_AUTH="false"
```

### Production Mode

In production:
- Authentication is always required
- Google OAuth is available
- Admin access requires a user role entry in the database
- No bypass is possible

## Setting Up Google OAuth

### 1. Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Configure the **OAuth consent screen** if not already done
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Set Application Type to **Web application**
6. Add authorized redirect URIs:
   - Development: `http://localhost:54321/auth/v1/callback` (Supabase local)
   - Production: `https://your-project-id.supabase.co/auth/v1/callback`

7. Copy the **Client ID** and **Client Secret**

### 2. Configure Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Authentication** → **Providers**
3. Enable **Google** provider
4. Paste your Google **Client ID** and **Client Secret**
5. Save the configuration

### 3. Test Authentication

#### Development Testing
```bash
# Disable bypass to test real auth
VITE_DEV_BYPASS_AUTH="false"

# Start the dev server
npm run dev
```

Navigate to `/auth` and click "Continue with Google"

#### Production Testing
Deploy your application and test the Google OAuth flow in production.

## Admin Access Setup

After a user signs up (via email or Google), they need to be granted admin access:

### Using SQL in Supabase Dashboard

```sql
-- Get the user's ID from the auth.users table
SELECT id, email FROM auth.users;

-- Grant admin role (replace with actual user ID)
INSERT INTO dogadopt.user_roles (user_id, role)
VALUES ('user-uuid-here', 'admin');
```

### Verify Admin Access

1. Sign in to the application
2. Try to access `/admin` route
3. If you're an admin, you'll see the admin panel
4. If not, you'll be redirected with an "Access Denied" message

## Security Considerations

### Google OAuth Configuration
- **Always use HTTPS** in production
- Keep your Google Client Secret secure
- Never commit secrets to version control
- Regularly rotate credentials

### Admin Role Management
- Admin roles are granted via the `user_roles` table
- Row Level Security (RLS) policies enforce admin-only operations
- Only admins can:
  - Add new dogs
  - Edit dog information
  - Delete dogs
  - Manage the admin panel

### Development Security
- `DEV_BYPASS_AUTH` is **automatically disabled** in production builds
- The bypass only works when `import.meta.env.DEV === true`
- This is enforced at build time by Vite

## Troubleshooting

### Google OAuth Not Working

1. **Verify redirect URIs** match exactly (including protocol and trailing slashes)
2. **Check Supabase logs** in Dashboard → Logs → Auth
3. **Verify Google credentials** are correctly saved in Supabase
4. **Ensure OAuth consent screen** is properly configured in Google Cloud Console

### Admin Access Not Working

1. **Check user_roles table** has correct entry
2. **Verify user is authenticated** (check browser console)
3. **Check RLS policies** are enabled and correct
4. **Review Supabase logs** for permission errors

### Dev Bypass Not Working

1. **Ensure you're running in dev mode** (`npm run dev`)
2. **Check .env file** doesn't have `VITE_DEV_BYPASS_AUTH="false"`
3. **Clear browser cache** and local storage
4. **Restart dev server**

## Environment Variables

Required environment variables (see `.env.example`):

```bash
# Supabase Configuration (required)
VITE_SUPABASE_PROJECT_ID="your-project-id"
VITE_SUPABASE_URL="https://your-project-id.supabase.co"
VITE_SUPABASE_PUBLISHABLE_KEY="your-anon-key"

# Development Settings (optional)
VITE_DEV_BYPASS_AUTH="true"  # Set to "false" to disable dev bypass
```

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Row Level Security (RLS) Guide](https://supabase.com/docs/guides/auth/row-level-security)
