# Copilot Instructions: Adopt-a-Dog UK

## Architecture Overview

**Stack:** React + TypeScript + Vite + shadcn/ui + Supabase (auth & database)

**Database Schema:** Custom `dogadopt` schema (not default `public`) with:
- `dogs` ↔ `dogs_breeds` ↔ `breeds` (many-to-many relationship via junction table)
- `rescues` ↔ `locations` (rescues have multiple locations)
- `profiles` + `user_roles` (admin/user roles)
- Comprehensive audit tables: `dogs_audit_logs`, `rescues_audit_logs`, `locations_audit_logs`

**Critical Pattern:** ALL Supabase queries use custom schema:
```typescript
const supabase = createClient<Database>(url, key, {
  db: { schema: 'dogadopt' as any }
});
```

## Data Patterns

### Multi-Breed Support
Dogs can have multiple breeds via `dogs_breeds` junction table with `display_order`. Always:
- Query with: `.select('*, dogs_breeds(display_order, breeds(id, name))')`
- Sort breeds by `display_order` before displaying
- Store as array in type: `breeds: string[]` but display as: `breed: string` (joined)

### Audit System
Changes to dogs, rescues, and locations are auto-logged via PostgreSQL triggers with:
- **Complete snapshots:** `old_snapshot` and `new_snapshot` JSONB with resolved foreign keys
- **Change tracking:** `changed_fields` array, `change_summary` text
- **Resolved views:** Use `dogs_audit_logs_resolved` for human-readable audit queries
- See [docs/UNIFIED_DOG_AUDIT_SYSTEM.md](../docs/UNIFIED_DOG_AUDIT_SYSTEM.md) for details

## Development Workflows

### Initial Setup
```bash
task setup              # Full setup (deps + env + Supabase)
task quick-start        # Quick setup (no Supabase)
npm run dev             # Start dev server (port 8080)
```

### Database Management
```bash
npm run supabase:start  # Start local Supabase (Docker)
npm run supabase:reset  # Reset DB and run all migrations
./scripts/make-admin.sh user@email.com  # Promote user to admin
```

### Authentication Flow
1. Sign up at `/auth` (creates user in `auth.users`)
2. Profile auto-created in `dogadopt.profiles` via trigger
3. User role defaults to 'user' in `dogadopt.user_roles`
4. Promote to admin: `./scripts/make-admin.sh <email>`
5. DEV BYPASS: Set `DEV_BYPASS_AUTH = true` in `useAuth.tsx` (testing only!)

## Critical Conventions

### RLS Policies
- Public read for dogs, rescues, locations
- Admin-only write/delete (check via `dogadopt.is_admin(auth.uid())` function)
- Audit logs: Admin read-only, system write via triggers

### Component Architecture
- **Hooks:** `useDogs()`, `useRescues()`, `useAuth()` wrap all data fetching
- **Forms:** Admin forms use controlled components with `useState<DogFormData>`
- **UI Components:** shadcn/ui in `src/components/ui/` (auto-generated, minimal edits)
- **Routing:** React Router v6 (`createBrowserRouter` in [main.tsx](../src/main.tsx))

### File Locations
- Types: `src/types/dog.ts` (canonical `Dog` interface)
- Supabase: `src/integrations/supabase/` (auto-generated types, client config)
- Migrations: `supabase/migrations/*.sql` (ordered by timestamp)
- Docs: `docs/*.md` (UNIFIED_DOG_AUDIT_SYSTEM, AUTHENTICATION, etc.)

## Common Tasks

### Adding a Dog Field
1. Update migration: `supabase/migrations/2025122803_dogadopt_dogs_and_breeds.sql`
2. Regenerate types: `npx supabase gen types typescript --local > src/integrations/supabase/types.ts`
3. Update `Dog` interface in `src/types/dog.ts`
4. Update `useDogs()` query and transform
5. Update `Admin.tsx` form and submission

### Querying with Relationships
```typescript
// ALWAYS include relationships in initial query
await supabase
  .from('dogs')
  .select(`
    *,
    rescues(id, name, region, website),
    dogs_breeds(display_order, breeds(id, name))
  `);
```

## Known Patterns

- **Breed Combobox:** Custom multi-select in `BreedCombobox.tsx` using cmdk
- **Image Uploads:** Currently direct URLs; storage bucket configured but not implemented
- **Location Display:** Shows `rescues.region` as location (legacy; locations table exists but unused in UI)
- **Task Runner:** Taskfile.yml defines all workflows; use `task <command>` or fallback to `npm run <script>`

## Testing & Verification

```bash
./test-audit.sh                        # Test audit logging system
./test-rescues-locations-audit.sh      # Test rescue/location audits
./verify-audit.sh                      # Verify audit completeness
```

## Migration Strategy

Migrations are consolidated and numbered:
1. `2025122801` - Users & Profiles
2. `2025122802` - Rescues & Locations  
3. `2025122803` - Dogs & Breeds (includes audit triggers)
4. `2025122804` - Rescues/Locations Audit

Never edit existing migrations; create new ones for schema changes.

## External Dependencies

- **Supabase:** Local Docker via `supabase` CLI
- **Task:** Build automation (Taskfile.yml)
- **Bun:** Lockfile present (`bun.lockb`) but npm works fine
- **Docker:** Required for local Supabase instance

## Development Notes

- Port 8080 for dev server (Vite)
- Supabase Studio: http://localhost:54323 (when running)
- Mock Google OAuth auto-creates users in local dev
- Admin panel at `/admin` (requires admin role)
- Public site at `/` (all dogs viewable)
