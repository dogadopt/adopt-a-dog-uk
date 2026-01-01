# Base Path Configuration

## Overview

The application base path is now controlled via the `VITE_BASE_PATH` environment variable, making it easy to switch between subdirectory and root domain deployments.

## Problem Solved

Previously, the application was hardcoded to use `/adopt-a-dog-uk/` as the base path in production builds. This caused 404 errors when accessing assets and made it difficult to migrate to a root domain deployment.

## Solution

The base path is now configurable via the `VITE_BASE_PATH` environment variable:

- **Current deployment:** `/` (custom domain at www.dogadopt.co.uk)
- **Alternative deployment:** `/adopt-a-dog-uk/` (GitHub Pages subdirectory at dogadopt.github.io/adopt-a-dog-uk/)

**IMPORTANT:** Since we use a custom domain (www.dogadopt.co.uk), the base path MUST be `/` for production.

## Configuration

### Local Development

1. Edit your `.env` file:
   ```bash
   VITE_BASE_PATH="/"  # Use "/" for custom domain (production configuration)
   ```

2. The default value (if not set) is `/` for convenience in local development.

**Note:** Use `/adopt-a-dog-uk/` only if testing subdirectory deployment (not used in production).

### Production Deployment (GitHub Actions)

1. Add the `VITE_BASE_PATH` secret in GitHub repository settings:
   - Go to **Settings → Secrets and variables → Actions**
   - Click **New repository secret**
   - Name: `VITE_BASE_PATH`
   - Value: `/` (for custom domain www.dogadopt.co.uk)

2. The GitHub Actions workflow automatically uses this secret during the build process.

**CRITICAL:** For custom domain deployment, this MUST be set to `/` or left empty (defaults to `/`).

## Custom Domain Configuration

The site is deployed to a custom domain (www.dogadopt.co.uk) via GitHub Pages:

1. Ensure `VITE_BASE_PATH` GitHub secret is set to `/`
2. Add `public/CNAME` file with domain name (www.dogadopt.co.uk)
3. Configure DNS with CNAME pointing to `dogadopt.github.io`
4. Enable HTTPS in GitHub Pages settings

### Migration Back to Subdirectory (if needed)

To deploy to subdirectory (dogadopt.github.io/adopt-a-dog-uk/):

1. Update the GitHub secret `VITE_BASE_PATH` from `/` to `/adopt-a-dog-uk/`
2. Remove or update the `public/CNAME` file
3. Trigger a new deployment (push to main or manual workflow dispatch)
4. No code changes required!

## Technical Details

### Files Modified

- **vite.config.ts**: Uses `loadEnv()` to read `VITE_BASE_PATH` and applies it as the base path
- **.env.example**: Documents the new environment variable
- **.github/workflows/deploy.yml**: Passes the secret to the build process
- **src/App.tsx**: Already uses `basename={import.meta.env.BASE_URL}` for React Router

### How It Works

1. Vite reads `VITE_BASE_PATH` from environment variables during build
2. Sets the `base` configuration option (default: `/`)
3. Vite automatically prefixes all asset URLs with the base path
4. React Router's `basename` uses `import.meta.env.BASE_URL` (set by Vite)
5. All routing and asset loading works correctly regardless of deployment path

## Testing

### Test Custom Domain Configuration (Current Production)
```bash
npm run build
cat dist/index.html | grep "src="
# Should show: src="/assets/..." (root path)
```

### Test Subdirectory Configuration (Alternative)
```bash
VITE_BASE_PATH="/adopt-a-dog-uk/" npm run build
cat dist/index.html | grep "src="
# Should show: src="/adopt-a-dog-uk/assets/..."
```

## Benefits

✅ **Easy migration**: Change one environment variable, no code changes  
✅ **Clear documentation**: Environment variable is explicitly documented  
✅ **Safe default**: Defaults to `/` for local development  
✅ **Centralized configuration**: Single source of truth for base path  
✅ **No 404 errors**: Assets load correctly with proper path prefix  

## See Also

- [CI/CD Setup](./CI_CD_SETUP.md) - Complete deployment pipeline documentation
- [GitHub Secrets Setup](./GITHUB_SECRETS_SETUP.md) - How to configure all secrets
