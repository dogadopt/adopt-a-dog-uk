# GitHub Secrets Setup Guide

This guide explains how to configure the required GitHub repository secrets for deployment.

## Why Secrets Are Required

The application uses Supabase for backend services (authentication, database). To deploy to GitHub Pages, the build process needs to embed these credentials into the application at build time.

**Important:** These credentials are **public** keys meant for client-side use. They are not sensitive secrets, but should still be managed through GitHub Secrets for easier management and to follow security best practices.

## Required Secrets

You need to set up the following secrets in your GitHub repository:

### Application Secrets (Required for Build)
- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_PUBLISHABLE_KEY` - Your Supabase anonymous/publishable key (client-side key)
- `VITE_SUPABASE_PROJECT_ID` - Your Supabase project ID

### Deployment Secrets (Required for Database Migrations)
- `SUPABASE_ACCESS_TOKEN` - Supabase CLI access token
- `SUPABASE_PROJECT_REF` - Your Supabase project reference ID

## How to Set Up Secrets

### Step 1: Get Your Supabase Credentials

1. **Go to your Supabase project dashboard**: https://supabase.com/dashboard
2. **Navigate to Settings → API**
3. **Copy the following values:**
   - **Project URL** → This is your `VITE_SUPABASE_URL`
   - **Project API keys → anon/public** → This is your `VITE_SUPABASE_PUBLISHABLE_KEY`
4. **Get the Project ID:**
   - Look at your project URL: `https://supabase.com/dashboard/project/[PROJECT_ID]`
   - Or find it in Settings → General
   - This is your `VITE_SUPABASE_PROJECT_ID`
5. **Get the Project Reference:**
   - In Settings → General, look for "Reference ID"
   - This is your `SUPABASE_PROJECT_REF`
6. **Generate an Access Token:**
   - Go to https://supabase.com/dashboard/account/tokens
   - Click "Generate New Token"
   - Give it a descriptive name (e.g., "GitHub Actions Deploy")
   - Copy the token immediately (you won't see it again!)
   - This is your `SUPABASE_ACCESS_TOKEN`

### Step 2: Add Secrets to GitHub

1. **Go to your GitHub repository**
2. **Click on Settings** (repository settings, not your account)
3. **In the left sidebar, click on "Secrets and variables" → "Actions"**
4. **Click on "New repository secret"**
5. **Add each secret one by one:**
   - Click "New repository secret"
   - Enter the name exactly as shown above (e.g., `VITE_SUPABASE_URL`)
   - Paste the corresponding value
   - Click "Add secret"
6. **Repeat for all 5 secrets**

### Step 3: Verify Setup

After adding all secrets:

1. **Go to the Actions tab** in your repository
2. **Find the latest "Deploy to GitHub Pages" workflow run**
3. **If it failed due to missing secrets, click "Re-run all jobs"**
4. **Wait for the deployment to complete**
5. **Visit your GitHub Pages site** (usually `https://[username].github.io/adopt-a-dog-uk/`)

## Troubleshooting

### Build is failing
- Double-check that all 5 secrets are set in GitHub repository settings
- Make sure the secret names match exactly (they are case-sensitive)
- Verify the values don't have extra spaces or line breaks

### Site shows "Configuration Required" error
- This means the environment variables were not available during build
- Check that the secrets are set in GitHub repository settings (not organization settings)
- Re-run the deployment workflow after adding the secrets

### Migrations are failing
- Verify your `SUPABASE_ACCESS_TOKEN` is valid and not expired
- Check that the token has the necessary permissions
- Ensure `SUPABASE_PROJECT_REF` matches your production project

## Security Notes

- **Publishable/Anonymous Key**: This key is safe to use in client-side code. It's designed for public use but has Row Level Security (RLS) policies to protect your data.
- **Access Token**: This is more sensitive and should only be used in CI/CD environments, never in client-side code.
- **Never commit** any of these values directly to your code repository.
- **Rotate tokens periodically** for better security.

## Local Development

For local development, you don't need GitHub Secrets. Instead:

1. Copy `.env.example` to `.env`
2. Fill in the same Supabase values
3. The `.env` file is gitignored and won't be committed

## Need More Help?

- See `docs/CI_CD_SETUP.md` for complete CI/CD pipeline documentation
- Check the [Supabase documentation](https://supabase.com/docs) for more details about credentials
- Review the [GitHub Actions documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets) for secrets management
