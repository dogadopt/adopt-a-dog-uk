# Production 404 Error Fix - Deployment Instructions

## Problem
The production website at https://www.dogadopt.co.uk/ was showing a blank page with a 404 error for `/src/main.tsx`. The site was only accessible at https://www.dogadopt.co.uk/adopt-a-dog-uk/ which is the wrong path.

## Root Cause
The application was built with `VITE_BASE_PATH="/adopt-a-dog-uk/"` which is only correct for subdirectory deployments (like `username.github.io/repo-name/`). When using a **custom domain** (www.dogadopt.co.uk), the base path must be `/` (root).

## Solution
Update the GitHub Actions secret `VITE_BASE_PATH` to use the root path for custom domain deployment.

## Required Action: Update GitHub Secret

**You must update the GitHub secret to fix the production deployment:**

1. Go to: https://github.com/dogadopt/adopt-a-dog-uk/settings/secrets/actions

2. Find the secret named `VITE_BASE_PATH`
   - If it exists: Click "Update" and change the value to `/`
   - If it doesn't exist: Click "New repository secret", name it `VITE_BASE_PATH`, and set value to `/`

3. Trigger a new deployment:
   - Option A: Push this branch to main (recommended after review)
   - Option B: Go to Actions → Deploy to GitHub Pages → Run workflow manually

## What This Changes

### Before (Broken):
- Build output: `<script src="/adopt-a-dog-uk/assets/main-xxx.js">`
- Browser tries to load: `https://www.dogadopt.co.uk/adopt-a-dog-uk/assets/main-xxx.js`
- Result: 404 error (assets are at root `/assets/`, not in subdirectory)

### After (Fixed):
- Build output: `<script src="/assets/main-xxx.js">`
- Browser loads: `https://www.dogadopt.co.uk/assets/main-xxx.js`
- Result: ✅ Site loads correctly

## Files Modified in This PR

1. **`.env.example`** - Updated to show correct base path for custom domain (`/`)
2. **`public/CNAME`** - Added CNAME file to preserve custom domain during GitHub Pages deployment
3. **`docs/BASE_PATH_CONFIGURATION.md`** - Updated documentation to reflect custom domain deployment
4. **`DEPLOYMENT_FIX_INSTRUCTIONS.md`** - This file with step-by-step fix instructions

## Verification After Deployment

After updating the secret and redeploying:

1. Visit https://www.dogadopt.co.uk/ (should load correctly)
2. Check browser console (F12) - should have no 404 errors
3. Verify all images and assets load correctly
4. Test navigation between pages

## Technical Details

- The `VITE_BASE_PATH` environment variable is read in `vite.config.ts`
- Vite uses this to set the `base` configuration option
- All asset URLs are automatically prefixed with this base path during build
- React Router's `basename` is set to match via `import.meta.env.BASE_URL`

## Custom Domain vs Subdirectory Deployment

| Deployment Type | Base Path | URL Example |
|----------------|-----------|-------------|
| Custom domain (current) | `/` | www.dogadopt.co.uk/ |
| Subdirectory (alternative) | `/adopt-a-dog-uk/` | dogadopt.github.io/adopt-a-dog-uk/ |

**Our production uses custom domain, so base path must be `/`**

## Need Help?

If you encounter issues:
1. Verify the GitHub secret is set to exactly `/` (just a forward slash)
2. Check that GitHub Pages custom domain is set to `www.dogadopt.co.uk` in repo settings
3. Ensure DNS CNAME record points to `dogadopt.github.io`
4. Wait 1-2 minutes after deployment for DNS/CDN cache to update

## See Also
- [BASE_PATH_CONFIGURATION.md](docs/BASE_PATH_CONFIGURATION.md) - Detailed base path configuration guide
- [CI_CD_SETUP.md](docs/CI_CD_SETUP.md) - Complete CI/CD pipeline documentation
- [GITHUB_SECRETS_SETUP.md](docs/GITHUB_SECRETS_SETUP.md) - All GitHub secrets configuration
