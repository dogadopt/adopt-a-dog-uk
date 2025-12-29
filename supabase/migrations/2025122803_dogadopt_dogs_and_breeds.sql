-- Dogs and Breeds - Consolidated Migration
-- Dog profiles, breed management, adoption status, comprehensive audit logging, and storage setup
-- Includes multi-breed support, complete audit trail for dogs and breeds, and resolved views

-- Create adoption_status enum
CREATE TYPE dogadopt.adoption_status AS ENUM (
  'available',
  'reserved',
  'adopted',
  'on_hold',
  'fostered',
  'withdrawn'
);

-- Create dogs table
CREATE TABLE dogadopt.dogs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  age TEXT NOT NULL CHECK (age IN ('Puppy', 'Young', 'Adult', 'Senior')),
  size TEXT NOT NULL CHECK (size IN ('Small', 'Medium', 'Large')),
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
  rescue_id UUID REFERENCES dogadopt.rescues(id),
  location_id UUID REFERENCES dogadopt.locations(id) ON DELETE SET NULL,
  image TEXT NOT NULL,
  good_with_kids BOOLEAN NOT NULL DEFAULT false,
  good_with_dogs BOOLEAN NOT NULL DEFAULT false,
  good_with_cats BOOLEAN NOT NULL DEFAULT false,
  description TEXT NOT NULL,
  profile_url TEXT,
  status dogadopt.adoption_status NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'adopted', 'on_hold', 'fostered', 'withdrawn')),
  status_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  last_updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create breeds reference table
CREATE TABLE dogadopt.breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create junction table for dog-breed many-to-many relationship (plural naming)
CREATE TABLE dogadopt.dogs_breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL REFERENCES dogadopt.dogs(id) ON DELETE CASCADE,
  breed_id UUID NOT NULL REFERENCES dogadopt.breeds(id) ON DELETE RESTRICT,
  display_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(dog_id, breed_id)
);

-- Create audit log table (plural naming)
CREATE TABLE dogadopt.dogs_audit_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  
  -- Complete resolved snapshots
  old_snapshot JSONB,
  new_snapshot JSONB,
  
  -- Computed change summary
  changed_fields TEXT[],
  change_summary TEXT,
  
  -- Metadata
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes for dogs
CREATE INDEX idx_dogs_location_id ON dogadopt.dogs(location_id);
CREATE INDEX idx_dogs_status ON dogadopt.dogs(status);

-- Create indexes for dogs_breeds
CREATE INDEX idx_dogs_breeds_dog_id ON dogadopt.dogs_breeds(dog_id);
CREATE INDEX idx_dogs_breeds_breed_id ON dogadopt.dogs_breeds(breed_id);

-- Create indexes for dogs_audit_logs
CREATE INDEX idx_dogs_audit_logs_dog_id ON dogadopt.dogs_audit_logs(dog_id);
CREATE INDEX idx_dogs_audit_logs_changed_at ON dogadopt.dogs_audit_logs(changed_at);
CREATE INDEX idx_dogs_audit_logs_operation ON dogadopt.dogs_audit_logs(operation);
CREATE INDEX idx_dogs_audit_logs_changed_by ON dogadopt.dogs_audit_logs(changed_by);
CREATE INDEX idx_dogs_audit_logs_changed_fields ON dogadopt.dogs_audit_logs USING GIN(changed_fields);

-- Enable RLS on all tables
ALTER TABLE dogadopt.dogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.breeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dogs_breeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dogs_audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for dogs
CREATE POLICY "Dogs are publicly viewable" 
ON dogadopt.dogs FOR SELECT 
USING (true);

CREATE POLICY "Admins can insert dogs"
ON dogadopt.dogs FOR INSERT
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can update dogs"
ON dogadopt.dogs FOR UPDATE
USING (dogadopt.has_role(auth.uid(), 'admin'))
WITH CHECK (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "Admins can delete dogs"
ON dogadopt.dogs FOR DELETE
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for breeds
CREATE POLICY "Breeds are publicly viewable" 
ON dogadopt.breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage breeds"
ON dogadopt.breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dogs_breeds
CREATE POLICY "Dog breeds are publicly viewable" 
ON dogadopt.dogs_breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage dog breeds"
ON dogadopt.dogs_breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dogs_audit_logs
CREATE POLICY "Admins can view audit logs"
ON dogadopt.dogs_audit_logs FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert audit logs"
ON dogadopt.dogs_audit_logs FOR INSERT
WITH CHECK (true);

-- Insert standard dog breeds
INSERT INTO dogadopt.breeds (name) VALUES
  ('Affenpinscher'), ('Afghan Hound'), ('Airedale Terrier'), ('Akita'),
  ('Alaskan Malamute'), ('American Bulldog'), ('American Staffordshire Terrier'),
  ('Australian Cattle Dog'), ('Australian Shepherd'), ('Basenji'), ('Basset Hound'),
  ('Beagle'), ('Bearded Collie'), ('Bedlington Terrier'), ('Belgian Malinois'),
  ('Bernese Mountain Dog'), ('Bichon Frise'), ('Bloodhound'), ('Border Collie'),
  ('Border Terrier'), ('Borzoi'), ('Boston Terrier'), ('Boxer'), ('Brittany'),
  ('Bull Terrier'), ('Bulldog'), ('Bullmastiff'), ('Cairn Terrier'), ('Cane Corso'),
  ('Cardigan Welsh Corgi'), ('Cavalier King Charles Spaniel'), ('Chesapeake Bay Retriever'),
  ('Chihuahua'), ('Chinese Crested'), ('Chinese Shar-Pei'), ('Chow Chow'),
  ('Cocker Spaniel'), ('Collie'), ('Dachshund'), ('Dalmatian'), ('Doberman Pinscher'),
  ('English Cocker Spaniel'), ('English Setter'), ('English Springer Spaniel'),
  ('English Toy Spaniel'), ('Flat-Coated Retriever'), ('Fox Terrier (Smooth)'),
  ('Fox Terrier (Wire)'), ('French Bulldog'), ('German Pinscher'), ('German Shepherd'),
  ('German Shorthaired Pointer'), ('German Wirehaired Pointer'), ('Giant Schnauzer'),
  ('Golden Retriever'), ('Gordon Setter'), ('Great Dane'), ('Great Pyrenees'),
  ('Greyhound'), ('Havanese'), ('Ibizan Hound'), ('Irish Setter'), ('Irish Terrier'),
  ('Irish Water Spaniel'), ('Irish Wolfhound'), ('Italian Greyhound'),
  ('Jack Russell Terrier'), ('Japanese Chin'), ('Keeshond'), ('Kerry Blue Terrier'),
  ('Labrador Retriever'), ('Lakeland Terrier'), ('Lhasa Apso'), ('Maltese'),
  ('Manchester Terrier'), ('Mastiff'), ('Miniature Pinscher'), ('Miniature Schnauzer'),
  ('Mixed Breed'), ('Newfoundland'), ('Norfolk Terrier'), ('Norwegian Elkhound'),
  ('Norwich Terrier'), ('Old English Sheepdog'), ('Papillon'), ('Pekingese'),
  ('Pembroke Welsh Corgi'), ('Pointer'), ('Pomeranian'), ('Poodle (Miniature)'),
  ('Poodle (Standard)'), ('Poodle (Toy)'), ('Portuguese Water Dog'), ('Pug'),
  ('Puli'), ('Rhodesian Ridgeback'), ('Rottweiler'), ('Saint Bernard'), ('Saluki'),
  ('Samoyed'), ('Schipperke'), ('Scottish Deerhound'), ('Scottish Terrier'),
  ('Sealyham Terrier'), ('Shetland Sheepdog'), ('Shiba Inu'), ('Shih Tzu'),
  ('Siberian Husky'), ('Silky Terrier'), ('Skye Terrier'),
  ('Soft Coated Wheaten Terrier'), ('Staffordshire Bull Terrier'), ('Standard Schnauzer'),
  ('Tibetan Terrier'), ('Vizsla'), ('Weimaraner'), ('Welsh Springer Spaniel'),
  ('Welsh Terrier'), ('West Highland White Terrier'), ('Whippet'),
  ('Wire Fox Terrier'), ('Yorkshire Terrier'),
  -- Common cross-breeds
  ('Cockapoo'), ('Labradoodle'), ('Goldendoodle'), ('Cavapoo'), ('Puggle'),
  ('Yorkipoo'), ('Maltipoo'), ('Schnoodle'), ('Pomsky'), ('Aussiedoodle'),
  ('Bernedoodle'), ('Sheepadoodle')
ON CONFLICT (name) DO NOTHING;

-- Create comprehensive view with all dog data and relationships resolved
CREATE OR REPLACE VIEW dogadopt.dogs_complete AS
SELECT 
  -- Core dog fields
  d.id,
  d.name,
  d.age,
  d.size,
  d.gender,
  d.image,
  d.description,
  d.good_with_kids,
  d.good_with_dogs,
  d.good_with_cats,
  d.status,
  d.status_notes,
  d.profile_url,
  d.created_at,
  
  -- Breed information (multiple formats for convenience)
  string_agg(b.name, ', ' ORDER BY db.display_order) AS breed,
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) AS breeds,
  COALESCE(
    string_agg(b.name, ', ' ORDER BY db.display_order),
    ''
  ) AS breeds_display,
  COALESCE(
    array_agg(b.name ORDER BY db.display_order) FILTER (WHERE b.name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) AS breeds_array,
  
  -- Rescue information
  r.name AS rescue_name,
  r.id AS rescue_id,
  r.region AS rescue_region,
  r.website AS rescue_website,
  
  -- Location information
  l.name AS location_name,
  l.id AS location_id,
  l.region AS location_region,
  l.enquiry_url AS location_enquiry_url
  
FROM dogadopt.dogs d
LEFT JOIN dogadopt.dogs_breeds db ON d.id = db.dog_id
LEFT JOIN dogadopt.breeds b ON db.breed_id = b.id
LEFT JOIN dogadopt.rescues r ON d.rescue_id = r.id
LEFT JOIN dogadopt.locations l ON d.location_id = l.id
GROUP BY 
  d.id, 
  d.name,
  d.age,
  d.size,
  d.gender,
  d.image,
  d.description,
  d.good_with_kids,
  d.good_with_dogs,
  d.good_with_cats,
  d.status,
  d.status_notes,
  d.profile_url,
  d.created_at,
  r.name, 
  r.id, 
  r.region, 
  r.website,
  l.name, 
  l.id, 
  l.region, 
  l.enquiry_url;

-- Function to get complete resolved snapshot of a dog (used by audit system)
CREATE OR REPLACE FUNCTION dogadopt.get_dog_resolved_snapshot(p_dog_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(dc)::jsonb
  INTO v_snapshot
  FROM dogadopt.dogs_complete dc
  WHERE dc.id = p_dog_id;
  
  RETURN v_snapshot;
END;
$$;

-- Audit trigger function for dogs table
-- Captures complete before/after snapshots with proper state handling
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_dog_record JSONB;
  new_dog_record JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        new_snapshot,
        change_summary,
        metadata
      ) VALUES (
        NEW.id,
        'INSERT',
        auth.uid(),
        new_snapshot,
        format('Dog "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_dog_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB with basic fields only
      old_dog_record := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'age', OLD.age,
        'size', OLD.size,
        'gender', OLD.gender,
        'image', OLD.image,
        'description', OLD.description,
        'good_with_kids', OLD.good_with_kids,
        'good_with_dogs', OLD.good_with_dogs,
        'good_with_cats', OLD.good_with_cats,
        'status', OLD.status,
        'status_notes', OLD.status_notes,
        'profile_url', OLD.profile_url,
        'rescue_id', OLD.rescue_id,
        'location_id', OLD.location_id,
        'created_at', OLD.created_at
      );
      
      new_dog_record := jsonb_build_object(
        'id', NEW.id,
        'name', NEW.name,
        'age', NEW.age,
        'size', NEW.size,
        'gender', NEW.gender,
        'image', NEW.image,
        'description', NEW.description,
        'good_with_kids', NEW.good_with_kids,
        'good_with_dogs', NEW.good_with_dogs,
        'good_with_cats', NEW.good_with_cats,
        'status', NEW.status,
        'status_notes', NEW.status_notes,
        'profile_url', NEW.profile_url,
        'rescue_id', NEW.rescue_id,
        'location_id', NEW.location_id,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots (with breeds, rescue, location)
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      -- Merge the dog-specific changes with the resolved data
      -- Use the old_dog_record for fields that changed in the dogs table
      old_snapshot := old_snapshot || old_dog_record;
      new_snapshot := new_snapshot || new_dog_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.dogs_audit_logs (
          dog_id,
          operation,
          changed_by,
          old_snapshot,
          new_snapshot,
          changed_fields,
          change_summary,
          metadata
        ) VALUES (
          NEW.id,
          'UPDATE',
          auth.uid(),
          old_snapshot,
          new_snapshot,
          changed_fields_array,
          format('Dog "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_dog_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        old_snapshot,
        change_summary,
        metadata
      ) VALUES (
        OLD.id,
        'DELETE',
        auth.uid(),
        old_snapshot,
        format('Dog "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_dog_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_dog_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Audit trigger function for dogs_breeds table
-- Captures breed additions, removals, and reordering
CREATE OR REPLACE FUNCTION dogadopt.audit_dog_breed_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  v_dog_id UUID;
  v_dog_name TEXT;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    
    -- Determine which dog_id to use
    IF (TG_OP = 'DELETE') THEN
      v_dog_id := OLD.dog_id;
    ELSE
      v_dog_id := NEW.dog_id;
    END IF;
    
    -- Get dog name for summary
    SELECT name INTO v_dog_name FROM dogadopt.dogs WHERE id = v_dog_id;
    
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(v_dog_id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        old_snapshot,
        new_snapshot,
        changed_fields,
        change_summary,
        metadata
      ) VALUES (
        v_dog_id,
        'UPDATE',
        auth.uid(),
        old_snapshot,
        new_snapshot,
        ARRAY['breeds', 'breeds_array', 'breeds_display'],
        format('Breed added to dog "%s"', v_dog_name),
        jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_added')
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE (display_order changes)
    IF (TG_OP = 'UPDATE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.dog_id);
      
      -- Only log if breeds actually changed
      IF old_snapshot->>'breeds_display' IS DISTINCT FROM new_snapshot->>'breeds_display' THEN
        INSERT INTO dogadopt.dogs_audit_logs (
          dog_id,
          operation,
          changed_by,
          old_snapshot,
          new_snapshot,
          changed_fields,
          change_summary,
          metadata
        ) VALUES (
          NEW.dog_id,
          'UPDATE',
          auth.uid(),
          old_snapshot,
          new_snapshot,
          ARRAY['breeds', 'breeds_array', 'breeds_display'],
          format('Breed order updated for dog "%s"', v_dog_name),
          jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_reordered')
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.dog_id);
      
      INSERT INTO dogadopt.dogs_audit_logs (
        dog_id,
        operation,
        changed_by,
        old_snapshot,
        new_snapshot,
        changed_fields,
        change_summary,
        metadata
      ) VALUES (
        OLD.dog_id,
        'UPDATE',
        auth.uid(),
        old_snapshot,
        new_snapshot,
        ARRAY['breeds', 'breeds_array', 'breeds_display'],
        format('Breed removed from dog "%s"', v_dog_name),
        jsonb_build_object('trigger', 'audit_dog_breed_changes', 'table', TG_TABLE_NAME, 'sub_operation', 'breed_removed')
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_dog_breed_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Create triggers
CREATE TRIGGER dogs_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_changes();

CREATE TRIGGER dogs_breeds_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs_breeds
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_breed_changes();

-- Create comprehensive resolved audit log view
CREATE OR REPLACE VIEW dogadopt.dogs_audit_logs_resolved AS
SELECT 
  dal.id AS audit_id,
  dal.dog_id,
  dal.operation,
  dal.changed_at,
  dal.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Dog information from snapshot
  COALESCE(dal.new_snapshot->>'name', dal.old_snapshot->>'name') AS dog_name,
  COALESCE(dal.new_snapshot->>'age', dal.old_snapshot->>'age') AS dog_age,
  COALESCE(dal.new_snapshot->>'size', dal.old_snapshot->>'size') AS dog_size,
  COALESCE(dal.new_snapshot->>'gender', dal.old_snapshot->>'gender') AS dog_gender,
  
  -- Status tracking
  dal.old_snapshot->>'status' AS old_status,
  dal.new_snapshot->>'status' AS new_status,
  
  -- Breed tracking
  dal.old_snapshot->>'breeds_display' AS old_breeds,
  dal.new_snapshot->>'breeds_display' AS new_breeds,
  
  -- Rescue and location
  COALESCE(dal.new_snapshot->>'rescue_name', dal.old_snapshot->>'rescue_name') AS rescue_name,
  COALESCE(dal.new_snapshot->>'location_name', dal.old_snapshot->>'location_name') AS location_name,
  
  -- Change details
  dal.changed_fields,
  dal.change_summary,
  
  -- Full snapshots for detailed analysis
  dal.old_snapshot,
  dal.new_snapshot,
  
  -- Metadata
  dal.metadata,
  dal.metadata->>'table' AS source_table,
  dal.metadata->>'sub_operation' AS sub_operation,
  
  dal.created_at
FROM dogadopt.dogs_audit_logs dal
LEFT JOIN auth.users u ON u.id = dal.changed_by
ORDER BY dal.changed_at DESC;

-- Helper function to manage dog breeds
CREATE OR REPLACE FUNCTION dogadopt.set_dog_breeds(
  p_dog_id UUID,
  p_breed_names TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt
AS $$
DECLARE
  v_breed_name TEXT;
  v_breed_id UUID;
  v_order INT;
BEGIN
  -- Delete existing breed associations
  DELETE FROM dogadopt.dogs_breeds WHERE dog_id = p_dog_id;
  
  -- Insert new breed associations
  v_order := 1;
  FOREACH v_breed_name IN ARRAY p_breed_names
  LOOP
    -- Get or create breed
    SELECT id INTO v_breed_id
    FROM dogadopt.breeds
    WHERE LOWER(name) = LOWER(TRIM(v_breed_name));
    
    IF v_breed_id IS NULL THEN
      INSERT INTO dogadopt.breeds (name)
      VALUES (TRIM(v_breed_name))
      RETURNING id INTO v_breed_id;
    END IF;
    
    -- Associate breed with dog
    INSERT INTO dogadopt.dogs_breeds (dog_id, breed_id, display_order)
    VALUES (p_dog_id, v_breed_id, v_order);
    
    v_order := v_order + 1;
  END LOOP;
END;
$$;

-- Helper function to get tracked URL
CREATE OR REPLACE FUNCTION dogadopt.get_dog_profile_url(
  _dog_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  dog_record RECORD;
  base_url TEXT;
  tracking_params TEXT;
BEGIN
  SELECT 
    d.id,
    d.profile_url,
    l.enquiry_url,
    r.website
  INTO dog_record
  FROM dogadopt.dogs d
  LEFT JOIN dogadopt.locations l ON l.id = d.location_id
  LEFT JOIN dogadopt.rescues r ON r.id = d.rescue_id
  WHERE d.id = _dog_id;

  -- Determine base URL (priority: dog profile > location enquiry > rescue website)
  IF dog_record.profile_url IS NOT NULL AND dog_record.profile_url != '' THEN
    base_url := dog_record.profile_url;
  ELSIF dog_record.enquiry_url IS NOT NULL AND dog_record.enquiry_url != '' THEN
    base_url := dog_record.enquiry_url;
  ELSIF dog_record.website IS NOT NULL AND dog_record.website != '' THEN
    base_url := dog_record.website;
  ELSE
    RETURN NULL;
  END IF;

  -- Build tracking parameters
  tracking_params := 'utm_source=dogadoptuk&utm_medium=referral&utm_campaign=dog_profile&utm_content=' || _dog_id::text;

  -- Append tracking parameters
  IF base_url LIKE '%?%' THEN
    RETURN base_url || '&' || tracking_params;
  ELSE
    RETURN base_url || '?' || tracking_params;
  END IF;
END;
$$;

-- Grant permissions
GRANT SELECT ON dogadopt.dogs TO anon, authenticated;
GRANT ALL ON dogadopt.dogs TO authenticated;
GRANT SELECT ON dogadopt.breeds TO anon, authenticated;
GRANT SELECT ON dogadopt.dogs_breeds TO anon, authenticated;
GRANT ALL ON dogadopt.dogs_breeds TO authenticated;
GRANT SELECT ON dogadopt.dogs_complete TO anon, authenticated;
GRANT SELECT ON dogadopt.dogs_audit_logs_resolved TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.set_dog_breeds TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_dog_profile_url TO anon, authenticated;

-- Create storage bucket for dog adoption images
INSERT INTO storage.buckets (id, name, public)
VALUES ('dog-adopt-images', 'dog-adopt-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public read access for dog images"
ON storage.objects FOR SELECT
USING (bucket_id = 'dog-adopt-images');

CREATE POLICY "Authenticated users can upload dog images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update dog images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete dog images"
ON storage.objects FOR DELETE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

-- Add documentation
COMMENT ON TABLE dogadopt.dogs IS 'Dog profiles with adoption status tracking';
COMMENT ON COLUMN dogadopt.dogs.status IS 'Current adoption status: available, reserved, adopted, on_hold, fostered, or withdrawn';
COMMENT ON COLUMN dogadopt.dogs.profile_url IS 'Direct URL to this dog''s profile page on the rescue''s website';
COMMENT ON TABLE dogadopt.breeds IS 'Reference table of dog breeds';
COMMENT ON TABLE dogadopt.dogs_breeds IS 'Junction table linking dogs to breeds (many-to-many relationship). Supports multi-breed dogs with display ordering.';
COMMENT ON TABLE dogadopt.dogs_audit_logs IS 'Complete audit log with fully resolved dog snapshots. Enables event sourcing and time-travel queries. View dogs_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.dogs_complete IS 'Comprehensive dog view with all breeds and foreign keys fully resolved. Single source for all dog data with relationships.';
COMMENT ON VIEW dogadopt.dogs_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all dog and breed changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
COMMENT ON FUNCTION dogadopt.set_dog_breeds IS 'Helper function to set breeds for a dog. Manages the many-to-many relationship.';
COMMENT ON FUNCTION dogadopt.audit_dog_changes IS 'Audit trigger for dogs table. Captures complete snapshots including OLD/NEW record state for proper before/after tracking.';
COMMENT ON FUNCTION dogadopt.audit_dog_breed_changes IS 'Audit trigger function for dogs_breeds table. Captures breed additions, removals, and reordering.';
