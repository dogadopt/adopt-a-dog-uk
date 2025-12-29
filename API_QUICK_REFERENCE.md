# dogadopt API Quick Reference

Quick reference guide for the most commonly used API endpoints.

## Base URLs

- **REST API**: `https://{project-ref}.supabase.co/rest/v1`
- **Auth API**: `https://{project-ref}.supabase.co/auth/v1`
- **Storage API**: `https://{project-ref}.supabase.co/storage/v1`

## Authentication

### Sign Up
```http
POST /auth/v1/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### Sign In
```http
POST /auth/v1/token?grant_type=password
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

### Google OAuth
```http
GET /auth/v1/authorize?provider=google&redirect_to=https://yourapp.com/
```

### Sign Out
```http
POST /auth/v1/logout
Authorization: Bearer <token>
```

## Dogs

### List All Dogs
```http
GET /rest/v1/dogs?select=*,rescues(id,name,region,website),dogs_breeds(display_order,breeds(id,name))&order=created_at.desc
```

### Filter Available Dogs
```http
GET /rest/v1/dogs?status=eq.available&select=*,rescues(name,region)
```

### Create Dog (Admin)
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
  "image": "https://...",
  "description": "Friendly dog",
  "good_with_kids": true,
  "good_with_dogs": true,
  "good_with_cats": false
}
```

### Update Dog (Admin)
```http
PATCH /rest/v1/dogs?id=eq.<dog-id>
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Name",
  "status": "adopted"
}
```

### Delete Dog (Admin)
```http
DELETE /rest/v1/dogs?id=eq.<dog-id>
Authorization: Bearer <token>
```

### Set Dog Breeds (Admin)
```http
POST /rest/v1/rpc/set_dog_breeds
Authorization: Bearer <token>
Content-Type: application/json

{
  "p_dog_id": "uuid",
  "p_breed_names": ["Labrador Retriever", "Poodle"]
}
```

## Breeds

### List All Breeds
```http
GET /rest/v1/breeds?order=name.asc
```

### Search Breeds
```http
GET /rest/v1/breeds?name=ilike.*labrador*
```

## Rescues

### List All Rescues
```http
GET /rest/v1/rescues?order=name.asc
```

### Filter by Region
```http
GET /rest/v1/rescues?region=eq.London&order=name.asc
```

## User Roles

### Check Admin Status
```http
GET /rest/v1/user_roles?user_id=eq.<user-id>&select=role
Authorization: Bearer <token>
```

## Storage

### Upload Image (Admin)
```http
POST /storage/v1/object/dog-adopt-images
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <image-file>
```

### Get Public Image URL
```http
GET /storage/v1/object/public/dog-adopt-images/<filename>
```

## Common Query Parameters

### Filtering
- `eq` - Equals: `?age=eq.Adult`
- `neq` - Not equals: `?age=neq.Puppy`
- `in` - In list: `?size=in.(Small,Medium)`
- `is` - Is null/not null: `?rescue_id=is.null`
- `like` - Pattern match: `?name=like.*buddy*`
- `ilike` - Case-insensitive pattern: `?name=ilike.*buddy*`

### Ordering
- `?order=created_at.desc` - Descending
- `?order=name.asc` - Ascending
- `?order=age.asc,name.desc` - Multiple columns

### Limiting & Pagination
- `?limit=10` - Limit results
- `?offset=20` - Skip results
- Use `Range` header for pagination

### Selection
- `?select=id,name` - Specific columns
- `?select=*` - All columns
- `?select=*,rescues(name)` - With relations

## HTTP Status Codes

- `200` OK - Request succeeded
- `201` Created - Resource created
- `204` No Content - Successful deletion
- `400` Bad Request - Invalid input
- `401` Unauthorized - No or invalid token
- `403` Forbidden - Insufficient permissions
- `404` Not Found - Resource doesn't exist

## Required Headers

### For All Requests
```http
apikey: your-supabase-anon-key
```

### For Authenticated Requests
```http
Authorization: Bearer <access-token>
```

### For Write Operations
```http
Content-Type: application/json
```

## Example Using curl

### List Dogs
```bash
curl "https://your-project.supabase.co/rest/v1/dogs?select=*" \
  -H "apikey: your-anon-key"
```

### Create Dog (Admin)
```bash
curl -X POST "https://your-project.supabase.co/rest/v1/dogs" \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-access-token" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Buddy",
    "age": "Adult",
    "size": "Medium",
    "gender": "Male",
    "image": "https://example.com/image.jpg",
    "description": "A friendly dog",
    "good_with_kids": true,
    "good_with_dogs": true,
    "good_with_cats": false
  }'
```

## Example Using JavaScript/TypeScript

### Setup
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://your-project.supabase.co',
  'your-anon-key'
);
```

### Fetch Dogs
```typescript
const { data: dogs, error } = await supabase
  .from('dogs')
  .select('*, rescues(name, region), dogs_breeds(breeds(name))')
  .eq('status', 'available')
  .order('created_at', { ascending: false });
```

### Create Dog
```typescript
const { data, error } = await supabase
  .from('dogs')
  .insert({
    name: 'Buddy',
    age: 'Adult',
    size: 'Medium',
    gender: 'Male',
    image: imageUrl,
    description: 'A friendly dog',
    good_with_kids: true,
    good_with_dogs: true,
    good_with_cats: false
  })
  .select()
  .single();
```

### Update Dog
```typescript
const { error } = await supabase
  .from('dogs')
  .update({ status: 'adopted' })
  .eq('id', dogId);
```

### Set Dog Breeds
```typescript
const { error } = await supabase.rpc('set_dog_breeds', {
  p_dog_id: dogId,
  p_breed_names: ['Labrador Retriever', 'Poodle']
});
```

### Upload Image
```typescript
const { error } = await supabase.storage
  .from('dog-adopt-images')
  .upload(fileName, file);

const { data: { publicUrl } } = supabase.storage
  .from('dog-adopt-images')
  .getPublicUrl(fileName);
```

## Resources

- Full documentation: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- OpenAPI spec: [openapi.yaml](openapi.yaml)
- Supabase docs: https://supabase.io/docs
