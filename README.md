# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS
- Supabase (Authentication & Database)

## Authentication Setup

This application uses Supabase for authentication.

### Local Development Setup

**Step 1: Sign Up**
1. Navigate to `/auth` in your browser
2. Sign up with any email/password (e.g., `admin@test.com` / `admin123`)

**Step 2: Make Yourself Admin**

Run the helper script:
```bash
./scripts/make-admin.sh admin@test.com
```

Or manually via SQL:
```bash
docker exec supabase_db_dog-adopt psql -U postgres -c "UPDATE dogadopt.user_roles SET role = 'admin' WHERE user_id = (SELECT id FROM auth.users WHERE email = 'admin@test.com');"
```

**Step 3: Access Admin Panel**
- Refresh your browser
- You'll see an "Admin" link in the header
- Navigate to `/admin` to manage dogs

### Google OAuth (Mock for Local Dev)

When you click "Continue with Google" locally, it creates a mock Google user automatically.
To promote a mock Google user to admin, find their email and run the make-admin script.

### Production Setup

For production deployment:
1. Set up Supabase authentication providers in your Supabase dashboard
2. Configure OAuth providers (Google, etc.) as needed
3. Create admin users by running the SQL command to update their role to 'admin'

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
