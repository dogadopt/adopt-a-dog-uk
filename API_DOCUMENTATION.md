# dogadopt API Documentation

This document provides an overview of the dogadopt API, which powers the dog adoption platform connecting rescue organizations with potential adopters.

## Overview

The dogadopt API is built on **Supabase**, leveraging:
- **PostgreSQL** database with Row Level Security (RLS)
- **Supabase Auth** for authentication
- **Supabase Storage** for image management
- **PostgREST** for RESTful API access

## OpenAPI Specification

The complete API specification is available in the `openapi.yaml` file at the root of this repository. This specification follows the OpenAPI 3.0.3 standard and can be used with various tools:

### Viewing the API Documentation

1. **Using Swagger UI** (online):
   - Visit [Swagger Editor](https://editor.swagger.io/)
   - Copy and paste the contents of `openapi.yaml`

2. **Using Redoc** (local):
   ```bash
   npx @redocly/cli preview-docs openapi.yaml
   ```

3. **Using Swagger UI** (local):
   ```bash
   npx swagger-ui-watcher openapi.yaml
   ```

## Authentication

All write operations and protected resources require authentication using JWT bearer tokens.

### Authentication Flow

1. **Sign Up** - Create a new account
   ```http
   POST /auth/v1/signup
   Content-Type: application/json

   {
     "email": "user@example.com",
     "password": "securePassword123"
   }
   ```

2. **Sign In** - Get access token
   ```http
   POST /auth/v1/token?grant_type=password
   Content-Type: application/json

   {
     "email": "user@example.com",
     "password": "securePassword123"
   }
   ```

3. **Use Token** - Include in subsequent requests
   ```http
   Authorization: Bearer <access_token>
   ```

### OAuth (Google)

For Google OAuth authentication:
```http
GET /auth/v1/authorize?provider=google&redirect_to=https://yourapp.com/
```

## API Endpoints

### Dogs

#### List All Dogs
Retrieve all dogs with their breeds, rescue information, and compatibility details.

```http
GET /rest/v1/dogs?select=*,rescues(id,name,region,website),dogs_breeds(display_order,breeds(id,name))&order=created_at.desc
```

**Query Parameters:**
- `status` - Filter by adoption status (available, reserved, adopted, etc.)
- `order` - Sort order (e.g., `created_at.desc`)

**Response:** Array of dog objects with nested rescue and breed information

#### Create Dog (Admin Only)
```http
POST /rest/v1/dogs
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Buddy",
  "age": "Adult",
  "size": "Medium",
  "gender": "Male",
  "rescue_id": "uuid",
  "location_id": "uuid",  // Optional - rescue region is used if not provided
  "image": "https://...",
  "description": "A friendly dog...",
  "good_with_kids": true,
  "good_with_dogs": true,
  "good_with_cats": false
}
```

**Note:** The `location` field in dog responses is computed from the rescue's region. The database field is `location_id` (UUID reference to locations table), but it's optional.

#### Update Dog (Admin Only)
Update an existing dog using PostgREST query filter syntax:
```http
PATCH /rest/v1/dogs?id=eq.<dog-id>
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Name",
  "status": "adopted"
}
```

**Note:** PostgREST uses query parameters for filtering. The `id=eq.<uuid>` syntax means "where id equals <uuid>".

#### Delete Dog (Admin Only)
```http
DELETE /rest/v1/dogs?id=eq.<dog-id>
Authorization: Bearer <token>
```

#### Set Dog Breeds (Admin Only)
Associate breeds with a dog using the stored procedure:
```http
POST /rest/v1/rpc/set_dog_breeds
Authorization: Bearer <token>
Content-Type: application/json

{
  "p_dog_id": "uuid",
  "p_breed_names": ["Labrador Retriever", "Golden Retriever"]
}
```

### Breeds

#### List All Breeds
```http
GET /rest/v1/breeds?order=name.asc
```

**Response:** Array of breed objects

### Rescues

#### List All Rescue Organizations
```http
GET /rest/v1/rescues?order=name.asc
```

**Query Parameters:**
- `region` - Filter by region (e.g., `region=eq.London`)

**Response:** Array of rescue organization objects

### User Roles

#### Check User Role (Authenticated)
```http
GET /rest/v1/user_roles?user_id=eq.<user-id>&select=role
Authorization: Bearer <token>
```

### Storage

#### Upload Dog Image (Admin Only)
```http
POST /storage/v1/object/dog-adopt-images
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <binary-image-data>
```

**Constraints:**
- Maximum file size: 5MB
- Accepted formats: JPEG, PNG, WebP, GIF

**Response:**
```json
{
  "Key": "filename.jpg",
  "Id": "unique-id"
}
```

#### Get Dog Image Public URL
```http
GET /storage/v1/object/public/dog-adopt-images/<filename>
```

Or use the Supabase client method:
```typescript
const { data: { publicUrl } } = supabase.storage
  .from('dog-adopt-images')
  .getPublicUrl(fileName);
```

## Data Models

### Dog

```typescript
interface Dog {
  id: string;              // UUID
  name: string;
  age: 'Puppy' | 'Young' | 'Adult' | 'Senior';
  size: 'Small' | 'Medium' | 'Large';
  gender: 'Male' | 'Female';
  rescue_id?: string;      // UUID
  location_id?: string;    // UUID (optional - typically uses rescue.region)
  image: string;           // URL
  description: string;
  good_with_kids: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
  profile_url?: string;
  status: 'available' | 'reserved' | 'adopted' | 'on_hold' | 'fostered' | 'withdrawn';
  status_notes?: string;
  created_at: string;      // ISO 8601
  last_updated_at: string; // ISO 8601
}

// Frontend representation includes computed location from rescue
interface DogFrontend extends Dog {
  location: string;        // Computed from rescues.region
  rescue: string;          // Computed from rescues.name
  breeds: string[];        // Array from dogs_breeds join
  breed: string;           // Display string from breeds array
}
```

### Breed

```typescript
interface Breed {
  id: string;         // UUID
  name: string;
  created_at: string; // ISO 8601
}
```

### Rescue

```typescript
interface Rescue {
  id: string;         // UUID
  name: string;
  type: string;       // Default: 'Full'
  region: string;
  website?: string;   // URL
  created_at: string; // ISO 8601
}
```

### User & Authentication

```typescript
interface User {
  id: string;         // UUID
  email: string;
  aud: string;
  role: string;
  created_at: string;
  app_metadata: Record<string, any>;
  user_metadata: Record<string, any>;
}

interface Session {
  access_token: string;
  token_type: string;
  expires_in: number;
  expires_at: number;
  refresh_token: string;
  user: User;
}
```

## Using the Supabase Client

The application uses the Supabase JavaScript client for API interactions:

### PostgREST Query Syntax

Supabase uses PostgREST, which provides powerful query capabilities through URL parameters:

**Filtering:**
- `column=eq.value` - Equals
- `column=neq.value` - Not equals
- `column=gt.value` - Greater than
- `column=gte.value` - Greater than or equal
- `column=lt.value` - Less than
- `column=lte.value` - Less than or equal
- `column=like.*pattern*` - Pattern matching
- `column=ilike.*pattern*` - Case-insensitive pattern matching
- `column=is.null` - Is null
- `column=in.(value1,value2)` - In list

**Examples:**
```http
# Filter by status
GET /rest/v1/dogs?status=eq.available

# Filter by multiple values
GET /rest/v1/dogs?size=in.(Small,Medium)

# Pattern matching
GET /rest/v1/dogs?name=ilike.*buddy*

# Update specific dog
PATCH /rest/v1/dogs?id=eq.550e8400-e29b-41d4-a716-446655440000
```

### Setup
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);
```

### Example: Fetch Dogs with Breeds
```typescript
const { data, error } = await supabase
  .from('dogs')
  .select(`
    *,
    rescues (id, name, region, website),
    dogs_breeds (
      display_order,
      breeds (id, name)
    )
  `)
  .order('created_at', { ascending: false });
```

### Example: Create Dog (Admin)
```typescript
const { data, error } = await supabase
  .from('dogs')
  .insert([{
    name: 'Buddy',
    age: 'Adult',
    size: 'Medium',
    gender: 'Male',
    // ... other fields
  }])
  .select()
  .single();
```

### Example: Upload Image
```typescript
const { error } = await supabase.storage
  .from('dog-adopt-images')
  .upload(fileName, file);

const { data: { publicUrl } } = supabase.storage
  .from('dog-adopt-images')
  .getPublicUrl(fileName);
```

## Authorization

The API uses Row Level Security (RLS) policies:

### Public Access
- **Read** all dogs, breeds, and rescues
- **View** public images

### Authenticated Users
- **Read** their own user role
- All public access permissions

### Admin Users
- **Create, Update, Delete** dogs
- **Upload** dog images
- **Manage** breed associations
- All authenticated user permissions

### Checking Admin Status

```typescript
const { data } = await supabase
  .from('user_roles')
  .select('role')
  .eq('user_id', userId)
  .eq('role', 'admin')
  .maybeSingle();

const isAdmin = !!data;
```

## Error Handling

All errors follow a consistent format:

```json
{
  "message": "Error description",
  "code": "error_code",
  "hint": "How to fix this",
  "details": "Additional information"
}
```

### Common HTTP Status Codes
- `200` - Success
- `201` - Created
- `204` - No Content (successful deletion)
- `400` - Bad Request (invalid input)
- `401` - Unauthorized (missing or invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found

## Rate Limiting

Supabase implements rate limiting based on your plan. Default limits:
- Free tier: ~500 requests per second
- Paid tiers: Higher limits available

## Best Practices

1. **Always use select** to fetch only needed data
2. **Use filters** to reduce response size
3. **Implement pagination** for large datasets
4. **Cache responses** when appropriate
5. **Handle errors gracefully** with proper user feedback
6. **Validate input** before sending to API
7. **Use environment variables** for sensitive data

## Development Tools

### Testing the API

1. **Using curl:**
   ```bash
   curl -X GET "https://your-project.supabase.co/rest/v1/dogs" \
     -H "apikey: your-anon-key" \
     -H "Authorization: Bearer your-token"
   ```

2. **Using Postman:**
   - Import the `openapi.yaml` file into Postman
   - Configure environment variables for your Supabase project

3. **Using the Supabase Dashboard:**
   - Navigate to the Table Editor
   - Use the SQL Editor for complex queries

## Support & Resources

- **OpenAPI Spec**: `openapi.yaml` in repository root
- **Supabase Documentation**: https://supabase.io/docs
- **PostgREST Documentation**: https://postgrest.org/
- **Database Migrations**: `/supabase/migrations/`

## Version History

### v1.0.0 (Current)
- Initial API specification
- Dogs, Breeds, and Rescues endpoints
- Authentication with Supabase Auth
- Image storage support
- Admin role-based access control
