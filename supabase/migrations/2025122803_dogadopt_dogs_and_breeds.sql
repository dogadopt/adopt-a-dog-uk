-- Dogs and Breeds
-- Dog profiles, breed management, adoption status, audit logging, and storage setup

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

-- Create indexes for dogs
CREATE INDEX idx_dogs_location_id ON dogadopt.dogs(location_id);
CREATE INDEX idx_dogs_status ON dogadopt.dogs(status);

-- RLS Policies for dogs (publicly viewable, admins can manage)
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

-- Enable RLS on dogs table
ALTER TABLE dogadopt.dogs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for dogs (publicly viewable, admins can manage)
CREATE TABLE dogadopt.breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create junction table for dog-breed many-to-many relationship
CREATE TABLE dogadopt.dog_breeds (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  dog_id UUID NOT NULL REFERENCES dogadopt.dogs(id) ON DELETE CASCADE,
  breed_id UUID NOT NULL REFERENCES dogadopt.breeds(id) ON DELETE RESTRICT,
  display_order INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(dog_id, breed_id)
);

-- Create indexes
CREATE INDEX idx_dog_breeds_dog_id ON dogadopt.dog_breeds(dog_id);
CREATE INDEX idx_dog_breeds_breed_id ON dogadopt.dog_breeds(breed_id);

-- Enable RLS on new tables
ALTER TABLE dogadopt.breeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE dogadopt.dog_breeds ENABLE ROW LEVEL SECURITY;

-- RLS Policies for breeds
CREATE POLICY "Breeds are publicly viewable" 
ON dogadopt.breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage breeds"
ON dogadopt.breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- RLS Policies for dog_breeds
CREATE POLICY "Dog breeds are publicly viewable" 
ON dogadopt.dog_breeds FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage dog breeds"
ON dogadopt.dog_breeds FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

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
  DELETE FROM dogadopt.dog_breeds WHERE dog_id = p_dog_id;
  
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
    INSERT INTO dogadopt.dog_breeds (dog_id, breed_id, display_order)
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

-- Create comprehensive audit log table
CREATE TABLE dogadopt.dog_audit_log (
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

-- Create indexes
CREATE INDEX idx_dog_audit_dog_id ON dogadopt.dog_audit_log(dog_id);
CREATE INDEX idx_dog_audit_changed_at ON dogadopt.dog_audit_log(changed_at);
CREATE INDEX idx_dog_audit_operation ON dogadopt.dog_audit_log(operation);
CREATE INDEX idx_dog_audit_changed_by ON dogadopt.dog_audit_log(changed_by);
CREATE INDEX idx_dog_audit_changed_fields ON dogadopt.dog_audit_log USING GIN(changed_fields);

-- Enable RLS
ALTER TABLE dogadopt.dog_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view audit logs"
ON dogadopt.dog_audit_log FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert audit logs"
ON dogadopt.dog_audit_log FOR INSERT
WITH CHECK (true);

-- Function to get resolved snapshot
CREATE OR REPLACE FUNCTION dogadopt.get_dog_resolved_snapshot(p_dog_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(dr)::jsonb
  INTO v_snapshot
  FROM dogadopt.dogs_resolved dr
  WHERE dr.id = p_dog_id;
  
  RETURN v_snapshot;
END;
$$;

-- Comprehensive audit trigger function
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
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.dog_audit_log (
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
      old_snapshot := dogadopt.get_dog_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_dog_resolved_snapshot(NEW.id);
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.dog_audit_log (
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
      
      INSERT INTO dogadopt.dog_audit_log (
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

-- Create trigger on dogs table
CREATE TRIGGER dogs_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.dogs
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_dog_changes();

-- Note: Comprehensive audit view (dog_audit_log_resolved) is created in migration 2025122805

-- Grant permissions
GRANT SELECT ON dogadopt.dogs TO anon, authenticated;
GRANT ALL ON dogadopt.dogs TO authenticated;
GRANT SELECT ON dogadopt.breeds TO anon, authenticated;
GRANT SELECT ON dogadopt.dog_breeds TO anon, authenticated;
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
COMMENT ON TABLE dogadopt.dog_breeds IS 'Junction table linking dogs to breeds (supports multi-breed dogs)';
COMMENT ON FUNCTION dogadopt.set_dog_breeds IS 'Helper function to set breeds for a dog. Manages the many-to-many relationship.';
COMMENT ON TABLE dogadopt.dog_audit_log IS 'Complete audit log with fully resolved dog snapshots. Enables event sourcing and time-travel queries.';
