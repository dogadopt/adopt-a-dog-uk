# CI/CD Pipeline Documentation

## Overview

This repository uses GitHub Actions for continuous integration and deployment. The pipeline automatically builds, tests, and deploys the application to GitHub Pages, while also managing Supabase database migrations.

## Workflows

### 1. CI Workflow (`ci.yml`)

**Trigger:** Runs on pull requests and pushes to `main` branch

**Purpose:** Validates code quality and ensures the application builds successfully

**Steps:**
- Checkout code
- Install Node.js dependencies
- Run linter (ESLint)
- Run type checking (TypeScript)
- Build application
- Upload build artifacts

**Configuration:** No secrets required

### 2. Deploy Workflow (`deploy.yml`)

**Trigger:** Runs on pushes to `main` branch and manual workflow dispatch

**Purpose:** Deploys the application to GitHub Pages

**Steps:**
- Build the application with production environment variables
- Configure GitHub Pages
- Deploy to GitHub Pages

**Required Secrets:**
- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_PUBLISHABLE_KEY` - Your Supabase publishable/anon key
- `VITE_SUPABASE_PROJECT_ID` - Your Supabase project ID

**Permissions Required:**
- Contents: read
- Pages: write
- ID token: write

### 3. Supabase Migrations Workflow (`supabase-migrations.yml`)

**Trigger:** Runs when migration files change in `supabase/migrations/**` or manual workflow dispatch

**Purpose:** Applies database migrations to production Supabase project

**Steps:**
- Setup Supabase CLI
- Link to production project
- Run pending migrations

**Required Secrets:**
- `SUPABASE_ACCESS_TOKEN` - Supabase access token for CLI authentication
- `SUPABASE_PROJECT_REF` - Your Supabase project reference ID

## Setup Instructions

### 1. Enable GitHub Pages

1. Go to your repository settings
2. Navigate to **Pages** section
3. Under **Source**, select "GitHub Actions"
4. Save the configuration

### 2. Configure Repository Secrets

Add the following secrets in your repository settings (Settings → Secrets and variables → Actions):

**For Application Deployment:**
```
VITE_SUPABASE_URL=https://your-project-id.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-anon-key
VITE_SUPABASE_PROJECT_ID=your-project-id
```

**For Supabase Migrations:**
```
SUPABASE_ACCESS_TOKEN=your-access-token
SUPABASE_PROJECT_REF=your-project-ref
```

### 3. Obtaining Supabase Credentials

**Project URL and Keys:**
1. Go to your Supabase project dashboard
2. Navigate to Settings → API
3. Copy the Project URL and anon/public key

**Access Token:**
1. Go to https://supabase.com/dashboard/account/tokens
2. Generate a new access token
3. Store it securely as a repository secret

**Project Reference:**
1. Found in your Supabase project URL: `https://supabase.com/dashboard/project/[PROJECT_REF]`
2. Or in Settings → General

### 4. Verify Deployment

After setting up:
1. Push changes to `main` branch
2. Check the Actions tab for workflow runs
3. Verify deployment at `https://[your-username].github.io/adopt-a-dog-uk/`

## Local Development

The base path configuration is automatically handled:
- **Development:** Uses root path `/`
- **Production:** Uses `/adopt-a-dog-uk/` for GitHub Pages

No changes needed in your development workflow.

## Troubleshooting

### Build Failures

Check the Actions tab for detailed logs. Common issues:
- Missing or incorrect environment variables
- TypeScript errors
- Linting errors (warnings don't fail the build)

### Deployment Issues

- Ensure GitHub Pages is enabled and set to "GitHub Actions" source
- Verify all required secrets are set correctly
- Check that the repository has Pages write permissions

### Migration Failures

- Verify `SUPABASE_ACCESS_TOKEN` has sufficient permissions
- Ensure `SUPABASE_PROJECT_REF` matches your production project
- Check migration files for syntax errors

## Manual Deployment

You can trigger deployments manually:
1. Go to Actions tab
2. Select "Deploy to GitHub Pages" workflow
3. Click "Run workflow"
4. Select the branch and run

## Security Notes

- Never commit secrets to the repository
- Use GitHub Secrets for all sensitive data
- Access tokens should have minimum required permissions
- Rotate tokens periodically for security

## Monitoring

Monitor your workflows:
- Actions tab shows all workflow runs
- Email notifications for failures (configurable in GitHub settings)
- Check deployment status before each release
