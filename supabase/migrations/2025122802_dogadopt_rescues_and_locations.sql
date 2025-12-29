-- Rescues and Locations
-- Rescue organizations, physical locations (centres, foster homes), and related data

-- Create rescues table
CREATE TABLE dogadopt.rescues (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'Full',
  region TEXT NOT NULL,
  website TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS on rescues
ALTER TABLE dogadopt.rescues ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rescues (publicly viewable, admins can manage)
CREATE POLICY "Rescues are publicly viewable" 
ON dogadopt.rescues FOR SELECT 
USING (true);

CREATE POLICY "Admins can manage rescues"
ON dogadopt.rescues FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- ========================================
-- RESCUES AUDIT SYSTEM
-- ========================================

-- Create rescues audit log table
CREATE TABLE dogadopt.rescues_audit_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  rescue_id UUID NOT NULL,
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

-- Create indexes for rescues_audit_logs
CREATE INDEX idx_rescues_audit_logs_rescue_id ON dogadopt.rescues_audit_logs(rescue_id);
CREATE INDEX idx_rescues_audit_logs_changed_at ON dogadopt.rescues_audit_logs(changed_at);
CREATE INDEX idx_rescues_audit_logs_operation ON dogadopt.rescues_audit_logs(operation);
CREATE INDEX idx_rescues_audit_logs_changed_by ON dogadopt.rescues_audit_logs(changed_by);
CREATE INDEX idx_rescues_audit_logs_changed_fields ON dogadopt.rescues_audit_logs USING GIN(changed_fields);

-- Enable RLS on rescues_audit_logs
ALTER TABLE dogadopt.rescues_audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rescues_audit_logs
CREATE POLICY "Admins can view rescue audit logs"
ON dogadopt.rescues_audit_logs FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert rescue audit logs"
ON dogadopt.rescues_audit_logs FOR INSERT
WITH CHECK (true);

-- Function to get complete resolved snapshot of a rescue
CREATE OR REPLACE FUNCTION dogadopt.get_rescue_resolved_snapshot(p_rescue_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(r)::jsonb
  INTO v_snapshot
  FROM dogadopt.rescues r
  WHERE r.id = p_rescue_id;
  
  RETURN v_snapshot;
END;
$$;

-- Audit trigger function for rescues table
-- Captures complete before/after snapshots with proper state handling
CREATE OR REPLACE FUNCTION dogadopt.audit_rescue_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_rescue_record JSONB;
  new_rescue_record JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_rescue_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.rescues_audit_logs (
        rescue_id,
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
        format('Rescue "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_rescue_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB
      old_rescue_record := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'type', OLD.type,
        'region', OLD.region,
        'website', OLD.website,
        'created_at', OLD.created_at
      );
      
      new_rescue_record := jsonb_build_object(
        'id', NEW.id,
        'name', NEW.name,
        'type', NEW.type,
        'region', NEW.region,
        'website', NEW.website,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots
      old_snapshot := dogadopt.get_rescue_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_rescue_resolved_snapshot(NEW.id);
      
      -- Merge the rescue-specific changes
      old_snapshot := old_snapshot || old_rescue_record;
      new_snapshot := new_snapshot || new_rescue_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.rescues_audit_logs (
          rescue_id,
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
          format('Rescue "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_rescue_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      -- Build snapshot from OLD record since the record is already deleted
      old_snapshot := jsonb_build_object(
        'id', OLD.id,
        'name', OLD.name,
        'type', OLD.type,
        'region', OLD.region,
        'website', OLD.website,
        'created_at', OLD.created_at
      );
      
      INSERT INTO dogadopt.rescues_audit_logs (
        rescue_id,
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
        format('Rescue "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_rescue_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_rescue_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Create trigger for rescues
CREATE TRIGGER rescues_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.rescues
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_rescue_changes();

-- Create comprehensive resolved audit log view for rescues
CREATE OR REPLACE VIEW dogadopt.rescues_audit_logs_resolved AS
SELECT 
  ral.id AS audit_id,
  ral.rescue_id,
  ral.operation,
  ral.changed_at,
  ral.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Rescue information from snapshot
  COALESCE(ral.new_snapshot->>'name', ral.old_snapshot->>'name') AS rescue_name,
  COALESCE(ral.new_snapshot->>'type', ral.old_snapshot->>'type') AS rescue_type,
  COALESCE(ral.new_snapshot->>'region', ral.old_snapshot->>'region') AS rescue_region,
  
  -- Field tracking
  ral.old_snapshot->>'name' AS old_name,
  ral.new_snapshot->>'name' AS new_name,
  ral.old_snapshot->>'type' AS old_type,
  ral.new_snapshot->>'type' AS new_type,
  ral.old_snapshot->>'region' AS old_region,
  ral.new_snapshot->>'region' AS new_region,
  ral.old_snapshot->>'website' AS old_website,
  ral.new_snapshot->>'website' AS new_website,
  
  -- Change details
  ral.changed_fields,
  ral.change_summary,
  
  -- Full snapshots for detailed analysis
  ral.old_snapshot,
  ral.new_snapshot,
  
  -- Metadata
  ral.metadata,
  ral.metadata->>'table' AS source_table,
  
  ral.created_at
FROM dogadopt.rescues_audit_logs ral
LEFT JOIN auth.users u ON u.id = ral.changed_by
ORDER BY ral.changed_at DESC;

-- Insert ADCH member rescue organizations
INSERT INTO dogadopt.rescues (name, type, region, website) VALUES
('Aireworth Dogs in Need', 'Full', 'Yorkshire & The Humber', 'www.areworthdogsinneed.co.uk'),
('Akita Rescue & Welfare Trust (UK)', 'Full', 'South East England', 'www.akitarescue.org.uk'),
('All Creatures Great & Small', 'Full', 'South Wales', 'www.allcreaturesgreatandsmall.org.uk'),
('All Dogs Matter', 'Full', 'London', 'www.alldogsmatter.co.uk'),
('Animal Care - Lancaster, Morecambe & District', 'Full', 'North West England', 'www.animalcare-lancaster.co.uk'),
('Animal Concern Cumbria', 'Full', 'North West England', 'www.animalconcerncumbria.org'),
('Animal Rescue Cumbria', 'Full', 'North West England', 'www.animalrescuecumbria.co.uk'),
('Animal Support Angels', 'Full', 'East England', 'www.animalsupportangels.com'),
('Animal Welfare Furness', 'Full', 'North West England', 'www.animals-in-need.org'),
('Animals in Need Northants', 'Full', 'East Midlands', 'www.animalsinneed.uk'),
('Ashbourne Animal Welfare', 'Full', 'East Midlands', 'www.ashbourneanimalwelfare.org'),
('Balto''s Dog Rescue', 'Full', 'National', 'www.baltosdogrescue.uk'),
('Bath Cats and Dogs Home', 'Full', 'South West England', 'www.bcdh.org.uk'),
('Battersea', 'Full', 'London', 'www.battersea.org.uk'),
('Benvardin Animal Rescue Kennels', 'Full', 'Northern Ireland', 'www.benvardinkennels.com'),
('Berwick Animal Rescue Kennels', 'Full', 'North East England', 'www.b-a-r-k.co.uk'),
('Birmingham Dogs Home', 'Full', 'West Midlands', 'www.birminghamdogshome.org.uk'),
('Bleakholt Animal Sanctuary', 'Full', 'North West England', 'www.bleakholt.org'),
('Blue Cross', 'Full', 'National', 'www.bluecross.org.uk'),
('Border Collie Trust GB', 'Full', 'West Midlands', 'www.bordercollietrust.org.uk'),
('Borders Pet Rescue', 'Full', 'Scottish Borders', 'www.borderspetrescue.org'),
('Boxer Welfare Scotland', 'Full', 'Aberdeen & Grampian', 'www.boxerwelfarescotland.org.uk'),
('Bristol Animal Rescue Centre', 'Full', 'South West England', 'www.bristolarc.org.uk'),
('Bristol Dog Action Welfare Group', 'Full', 'South West England', 'www.dawg.org.uk'),
('Bulldog Rescue & Re-homing Trust', 'Full', 'South East England', 'www.bulldogrescue.co.uk'),
('Carla Lane Animals In Need', 'Full', 'North West England', 'www.carlalaneanimalsinneed.co.uk'),
('Causeway Coast Dog Rescue', 'Full', 'Northern Ireland', 'www.causewaycoastdogrescue.org'),
('Cheltenham Animal Shelter', 'Full', 'South West England', 'www.gawa.org.uk'),
('Chilterns Dog Rescue Society', 'Full', 'East England', 'www.chilternsdogrescue.org.uk'),
('Dog Aid Society Scotland', 'Full', 'Scotland', 'www.dogaidsociety.com'),
('Dogs Trust', 'Full', 'National', 'www.dogstrust.org.uk'),
('Dogs Trust Ireland', 'Full', 'Ireland', 'www.dogstrust.ie'),
('Dumfries & Galloway Canine Rescue Centre', 'Full', 'Dumfries & Galloway', 'www.caninerescue.co.uk'),
('Durham Dogs and Cats Home', 'Full', 'North East England', 'www.durhamdogsandcats.uk'),
('Eden Animal Rescue', 'Full', 'North West England', 'www.edenanimalrescue.org.uk'),
('Edinburgh Dog & Cat Home', 'Full', 'Edinburgh & the Lothians', 'www.edch.org.uk'),
('Fen Bank Greyhound Sanctuary', 'Full', 'East England', 'www.fenbankgreyhounds.co.uk'),
('Ferne Animal Sanctuary', 'Full', 'South West England', 'www.ferneanimalsanctuary.org'),
('Foal Farm Animal Rescue', 'Full', 'South East England', 'www.foalfarm.org.uk'),
('Forest Dog Rescue', 'Full', 'West Midlands', 'www.forest-dog-rescue.org.uk'),
('Forever Hounds Trust', 'Full', 'South East England', 'www.foreverhoundstrust.org'),
('Freshfields Animal Rescue', 'Full', 'North West England', 'www.freshfields.org.uk'),
('Friends of Akitas Trust UK', 'Full', 'East Midlands', 'www.friendsofakitas.co.uk'),
('Gables Dogs & Cats Home', 'Full', 'South West England', 'www.gablesfarm.org.uk'),
('Garbos German Shepherd Dog Rescue', 'Full', 'South East England', 'www.garbosgsdrescue.co.uk'),
('German Shepherd Rescue Elite', 'Full', 'South East England', 'www.gsrelite.co.uk'),
('German Shepherd Rescue South', 'Full', 'South East England', 'www.german-shepherd-rescue-hampshire.org.uk'),
('German Shorthaired Pointer Rescue UK', 'Full', 'South Wales', 'www.gsprescue-uk.org.uk'),
('Greenacres Rescue', 'Full', 'South Wales', 'www.greenacresrescue.org.uk'),
('Greyhound Gap', 'Full', 'West Midlands', 'www.greyhoundgap.org.uk'),
('Greyhound Rescue Wales', 'Full', 'Mid Wales', 'www.greyhoundrescuewales.co.uk'),
('Greyhound Trust', 'Full', 'South East England', 'www.greyhoundtrust.org.uk'),
('Greyhound Welfare South Wales', 'Full', 'South Wales', 'www.facebook.com/GreyhoundWelfareSouthWales'),
('Grovehill Animal Trust', 'Full', 'Northern Ireland', 'www.grovehillanimaltrust.org'),
('Happy Landings Animal Shelter', 'Full', 'South West England', 'www.happy-landings.org.uk'),
('Happy Staffie Rescue', 'Full', 'West Midlands', 'www.happystaffie.co.uk'),
('Holly Hedge Animal Sanctuary', 'Full', 'South West England', 'www.hollyhedge.org.uk'),
('Hope Rescue', 'Full', 'South Wales', 'www.hoperescue.org.uk'),
('Jerry Green Dog Rescue', 'Full', 'East Midlands', 'www.jerrygreendogs.org.uk'),
('Just Springers Rescue', 'Full', 'South East England', 'www.justspringersrescue.co.uk'),
('K9 Focus', 'Full', 'South West England', 'www.k9focus.co.uk'),
('Keith''s Rescue Dogs', 'Full', 'East Midlands', 'www.keithsrescuedogs.co.uk'),
('Labrador Lifeline Trust', 'Full', 'South East England', 'www.labrador-lifeline.com'),
('Labrador Rescue Trust', 'Full', 'South West England', 'www.labrador-rescue.com'),
('Last Chance Animal Rescue', 'Full', 'South East England', 'www.lastchanceanimalrescue.co.uk'),
('Leicester Animal Aid', 'Full', 'East Midlands', 'www.leicesteranimalaid.org.uk'),
('Lord Whisky Sanctuary Fund', 'Full', 'South East England', 'www.lordwhisky.co.uk'),
('MADRA', 'Full', 'Ireland', 'www.madra.ie'),
('Manchester & District Home For Lost Dogs', 'Full', 'North West England', 'www.dogshome.net'),
('Margaret Green Animal Rescue', 'Full', 'South West England', 'www.margaretgreenanimalrescue.org.uk'),
('Maxi''s Mates', 'Full', 'Yorkshire & The Humber', 'www.maxismates.org.uk'),
('Mayflower Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.mayflowersanctuary.co.uk'),
('Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org'),
('Mid Antrim Animal Sanctuary', 'Full', 'Northern Ireland', 'www.midantrim.org'),
('Mrs Murrays Home for Stray Dogs and Cats', 'Full', 'Aberdeen & Grampian', 'www.mrsmurrays.co.uk'),
('National Animal Welfare Trust', 'Full', 'National', 'www.nawt.org.uk'),
('Newcastle Dog & Cat Shelter', 'Full', 'North East England', 'www.dogscatshelter.co.uk'),
('Norfolk Greyhound Welfare', 'Full', 'East England', 'www.norfolkgreyhoundwelfare.co.uk'),
('North Clwyd Animal Rescue', 'Full', 'North Wales', 'www.ncar.co.uk'),
('North Lincolnshire Greyhound Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.nlgs.org.uk'),
('Oak Tree Animals'' Charity', 'Full', 'South West England', 'www.oaktreeanimals.org.uk'),
('Old Windsor Safari Park', 'Full', 'South East England', 'www.windsorgreatpark.co.uk'),
('Oldies Club', 'Full', 'National', 'www.oldies.org.uk'),
('Paws Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.pawsanimalsanctuary.co.uk'),
('Pennine Pen Animal Rescue', 'Full', 'Yorkshire & The Humber', 'www.penninepen.org.uk'),
('Pointer Rescue Service', 'Full', 'National', 'www.pointer-rescue.co.uk'),
('Preston & District RSPCA', 'Full', 'North West England', 'www.rspca-preston.org.uk'),
('Redwings Horse Sanctuary', 'Full', 'East England', 'www.redwings.org.uk'),
('Retired Greyhound Trust', 'Full', 'South East England', 'www.retiredgreyhounds.co.uk'),
('Rochdale Dog Rescue', 'Full', 'North West England', 'www.rochdaledog.rescue.org.uk'),
('Scottish SPCA', 'Full', 'Scotland', 'www.scottishspca.org'),
('Scruples & Wellies Animal Rescue', 'Full', 'South West England', 'www.scruplesandwellies.org'),
('Setter Rescue Scotland', 'Full', 'Scotland', 'www.setterrescuescotland.co.uk'),
('Severn Edge Vets Charity', 'Full', 'West Midlands', 'www.severnedgevets.co.uk'),
('Shropshire Cat Rescue', 'Full', 'West Midlands', 'www.shropshirecatrescue.org.uk'),
('SSPCA', 'Full', 'Scotland', 'www.scottishspca.org'),
('Staffie Smiles', 'Full', 'West Midlands', 'www.staffiesmiles.com'),
('The Greyhound Trust', 'Full', 'National', 'www.greyhoundtrust.org.uk'),
('The Mayhew Animal Home', 'Full', 'London', 'www.themayhew.org'),
('The Surrey Border Collie & Sheepdog Welfare Society', 'Full', 'South East England', 'www.bordercolliewelfare.org'),
('Underheugh Animal Sanctuary', 'Full', 'North East England', 'www.underheugh.co.uk'),
('Viva Rescue', 'Full', 'West Midlands', 'www.vivarescue.org.uk'),
('West London Dog Rescue', 'Full', 'London', 'www.wldr.org'),
('Westmorland Animal Sanctuary', 'Full', 'North West England', 'www.westmorlandanimalsanctuary.org.uk'),
('Wild at Heart Foundation', 'Full', 'National', 'www.wildatheartfoundation.org'),
('Woodgreen, The Animals Charity', 'Full', 'East England', 'www.woodgreen.org.uk'),
('Yorkshire Animal Sanctuary', 'Full', 'Yorkshire & The Humber', 'www.yorkshireanimalsanctuary.co.uk'),
('Yorkshire Coast Dog Rescue', 'Full', 'Yorkshire & The Humber', 'www.yorkshirecoastdogrescue.co.uk');

-- Create location_type enum
CREATE TYPE dogadopt.location_type AS ENUM ('centre', 'foster_home', 'office', 'other');

-- Create locations table
CREATE TABLE dogadopt.locations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  rescue_id UUID NOT NULL REFERENCES dogadopt.rescues(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  location_type dogadopt.location_type NOT NULL DEFAULT 'centre',
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT NOT NULL,
  county TEXT,
  postcode TEXT,
  region TEXT,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  phone TEXT,
  email TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  enquiry_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX idx_locations_rescue_id ON dogadopt.locations(rescue_id);

-- Enable RLS on locations
ALTER TABLE dogadopt.locations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations
CREATE POLICY "Locations are publicly viewable"
ON dogadopt.locations FOR SELECT
USING (true);

CREATE POLICY "Admins can manage locations"
ON dogadopt.locations FOR ALL
USING (dogadopt.has_role(auth.uid(), 'admin'));

-- ========================================
-- LOCATIONS AUDIT SYSTEM
-- ========================================

-- Create locations audit log table
CREATE TABLE dogadopt.locations_audit_logs (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  location_id UUID NOT NULL,
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

-- Create indexes for locations_audit_logs
CREATE INDEX idx_locations_audit_logs_location_id ON dogadopt.locations_audit_logs(location_id);
CREATE INDEX idx_locations_audit_logs_changed_at ON dogadopt.locations_audit_logs(changed_at);
CREATE INDEX idx_locations_audit_logs_operation ON dogadopt.locations_audit_logs(operation);
CREATE INDEX idx_locations_audit_logs_changed_by ON dogadopt.locations_audit_logs(changed_by);
CREATE INDEX idx_locations_audit_logs_changed_fields ON dogadopt.locations_audit_logs USING GIN(changed_fields);

-- Enable RLS on locations_audit_logs
ALTER TABLE dogadopt.locations_audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for locations_audit_logs
CREATE POLICY "Admins can view location audit logs"
ON dogadopt.locations_audit_logs FOR SELECT
USING (dogadopt.has_role(auth.uid(), 'admin'));

CREATE POLICY "System can insert location audit logs"
ON dogadopt.locations_audit_logs FOR INSERT
WITH CHECK (true);

-- Create view with rescue information joined
CREATE OR REPLACE VIEW dogadopt.locations_complete AS
SELECT 
  l.id,
  l.rescue_id,
  l.name,
  l.location_type,
  l.address_line1,
  l.address_line2,
  l.city,
  l.county,
  l.postcode,
  l.region,
  l.latitude,
  l.longitude,
  l.phone,
  l.email,
  l.is_public,
  l.enquiry_url,
  l.created_at,
  
  -- Rescue information
  r.name AS rescue_name,
  r.type AS rescue_type,
  r.region AS rescue_region,
  r.website AS rescue_website
  
FROM dogadopt.locations l
LEFT JOIN dogadopt.rescues r ON l.rescue_id = r.id;

-- Function to get complete resolved snapshot of a location
CREATE OR REPLACE FUNCTION dogadopt.get_location_resolved_snapshot(p_location_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_snapshot JSONB;
BEGIN
  SELECT row_to_json(lc)::jsonb
  INTO v_snapshot
  FROM dogadopt.locations_complete lc
  WHERE lc.id = p_location_id;
  
  RETURN v_snapshot;
END;
$$;

-- Audit trigger function for locations table
-- Captures complete before/after snapshots with proper state handling
CREATE OR REPLACE FUNCTION dogadopt.audit_location_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = dogadopt, public
AS $$
DECLARE
  old_snapshot JSONB;
  new_snapshot JSONB;
  changed_fields_array TEXT[];
  old_location_record JSONB;
  new_location_record JSONB;
  v_rescue_info JSONB;
BEGIN
  BEGIN  -- Add exception handling to prevent blocking operations
    -- Handle INSERT
    IF (TG_OP = 'INSERT') THEN
      new_snapshot := dogadopt.get_location_resolved_snapshot(NEW.id);
      
      INSERT INTO dogadopt.locations_audit_logs (
        location_id,
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
        format('Location "%s" created', NEW.name),
        jsonb_build_object('trigger', 'audit_location_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF (TG_OP = 'UPDATE') THEN
      -- Convert OLD and NEW to JSONB
      old_location_record := jsonb_build_object(
        'id', OLD.id,
        'rescue_id', OLD.rescue_id,
        'name', OLD.name,
        'location_type', OLD.location_type,
        'address_line1', OLD.address_line1,
        'address_line2', OLD.address_line2,
        'city', OLD.city,
        'county', OLD.county,
        'postcode', OLD.postcode,
        'region', OLD.region,
        'latitude', OLD.latitude,
        'longitude', OLD.longitude,
        'phone', OLD.phone,
        'email', OLD.email,
        'is_public', OLD.is_public,
        'enquiry_url', OLD.enquiry_url,
        'created_at', OLD.created_at
      );
      
      new_location_record := jsonb_build_object(
        'id', NEW.id,
        'rescue_id', NEW.rescue_id,
        'name', NEW.name,
        'location_type', NEW.location_type,
        'address_line1', NEW.address_line1,
        'address_line2', NEW.address_line2,
        'city', NEW.city,
        'county', NEW.county,
        'postcode', NEW.postcode,
        'region', NEW.region,
        'latitude', NEW.latitude,
        'longitude', NEW.longitude,
        'phone', NEW.phone,
        'email', NEW.email,
        'is_public', NEW.is_public,
        'enquiry_url', NEW.enquiry_url,
        'created_at', NEW.created_at
      );
      
      -- Get full resolved snapshots (with rescue info)
      old_snapshot := dogadopt.get_location_resolved_snapshot(OLD.id);
      new_snapshot := dogadopt.get_location_resolved_snapshot(NEW.id);
      
      -- Merge the location-specific changes with the resolved data
      old_snapshot := old_snapshot || old_location_record;
      new_snapshot := new_snapshot || new_location_record;
      
      -- Identify changed fields
      SELECT ARRAY_AGG(key)
      INTO changed_fields_array
      FROM jsonb_each(old_snapshot)
      WHERE old_snapshot->>key IS DISTINCT FROM new_snapshot->>key;
      
      -- Only log if something actually changed
      IF changed_fields_array IS NOT NULL AND array_length(changed_fields_array, 1) > 0 THEN
        INSERT INTO dogadopt.locations_audit_logs (
          location_id,
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
          format('Location "%s" updated (%s fields changed)', 
            NEW.name, 
            array_length(changed_fields_array, 1)
          ),
          jsonb_build_object(
            'trigger', 'audit_location_changes',
            'table', TG_TABLE_NAME,
            'changed_count', array_length(changed_fields_array, 1)
          )
        );
      END IF;
      
      RETURN NEW;
    END IF;

    -- Handle DELETE
    IF (TG_OP = 'DELETE') THEN
      -- Build snapshot from OLD record since the record is already deleted
      -- Get rescue info via the rescue_id (rescue still exists even though location is deleted)
      old_snapshot := jsonb_build_object(
        'id', OLD.id,
        'rescue_id', OLD.rescue_id,
        'name', OLD.name,
        'location_type', OLD.location_type,
        'address_line1', OLD.address_line1,
        'address_line2', OLD.address_line2,
        'city', OLD.city,
        'county', OLD.county,
        'postcode', OLD.postcode,
        'region', OLD.region,
        'latitude', OLD.latitude,
        'longitude', OLD.longitude,
        'phone', OLD.phone,
        'email', OLD.email,
        'is_public', OLD.is_public,
        'enquiry_url', OLD.enquiry_url,
        'created_at', OLD.created_at
      );
      
      -- Try to enrich with rescue information if rescue still exists
      IF OLD.rescue_id IS NOT NULL THEN
        SELECT jsonb_build_object(
          'rescue_name', r.name,
          'rescue_type', r.type,
          'rescue_region', r.region,
          'rescue_website', r.website
        ) INTO v_rescue_info
        FROM dogadopt.rescues r
        WHERE r.id = OLD.rescue_id;
        
        IF v_rescue_info IS NOT NULL THEN
          old_snapshot := old_snapshot || v_rescue_info;
        END IF;
      END IF;
      
      INSERT INTO dogadopt.locations_audit_logs (
        location_id,
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
        format('Location "%s" deleted', OLD.name),
        jsonb_build_object('trigger', 'audit_location_changes', 'table', TG_TABLE_NAME)
      );
      
      RETURN OLD;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't block the operation
    RAISE WARNING 'audit_location_changes failed: %', SQLERRM;
    IF (TG_OP = 'DELETE') THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END;

  RETURN NULL;
END;
$$;

-- Create trigger for locations
CREATE TRIGGER locations_audit_trigger
  AFTER INSERT OR UPDATE OR DELETE ON dogadopt.locations
  FOR EACH ROW
  EXECUTE FUNCTION dogadopt.audit_location_changes();

-- Create comprehensive resolved audit log view for locations
CREATE OR REPLACE VIEW dogadopt.locations_audit_logs_resolved AS
SELECT 
  lal.id AS audit_id,
  lal.location_id,
  lal.operation,
  lal.changed_at,
  lal.changed_by,
  u.email AS changed_by_email,
  u.raw_user_meta_data->>'full_name' AS changed_by_name,
  
  -- Location information from snapshot
  COALESCE(lal.new_snapshot->>'name', lal.old_snapshot->>'name') AS location_name,
  COALESCE(lal.new_snapshot->>'location_type', lal.old_snapshot->>'location_type') AS location_type,
  COALESCE(lal.new_snapshot->>'city', lal.old_snapshot->>'city') AS city,
  COALESCE(lal.new_snapshot->>'region', lal.old_snapshot->>'region') AS region,
  
  -- Rescue information
  COALESCE(lal.new_snapshot->>'rescue_name', lal.old_snapshot->>'rescue_name') AS rescue_name,
  
  -- Field tracking for key changes
  lal.old_snapshot->>'name' AS old_name,
  lal.new_snapshot->>'name' AS new_name,
  lal.old_snapshot->>'location_type' AS old_location_type,
  lal.new_snapshot->>'location_type' AS new_location_type,
  lal.old_snapshot->>'city' AS old_city,
  lal.new_snapshot->>'city' AS new_city,
  lal.old_snapshot->>'region' AS old_region,
  lal.new_snapshot->>'region' AS new_region,
  lal.old_snapshot->>'is_public' AS old_is_public,
  lal.new_snapshot->>'is_public' AS new_is_public,
  
  -- Change details
  lal.changed_fields,
  lal.change_summary,
  
  -- Full snapshots for detailed analysis
  lal.old_snapshot,
  lal.new_snapshot,
  
  -- Metadata
  lal.metadata,
  lal.metadata->>'table' AS source_table,
  
  lal.created_at
FROM dogadopt.locations_audit_logs lal
LEFT JOIN auth.users u ON u.id = lal.changed_by
ORDER BY lal.changed_at DESC;

-- Create a default location for each rescue
INSERT INTO dogadopt.locations (rescue_id, name, city, region, location_type, is_public)
SELECT 
  r.id,
  r.name || ' - ' || r.region,
  COALESCE(
    CASE 
      WHEN r.region LIKE '%London%' THEN 'London'
      WHEN r.region LIKE '%Edinburgh%' THEN 'Edinburgh'
      WHEN r.region LIKE '%Cardiff%' THEN 'Cardiff'
      WHEN r.region LIKE '%Belfast%' THEN 'Belfast'
      WHEN r.region LIKE '%Birmingham%' THEN 'Birmingham'
      WHEN r.region LIKE '%Manchester%' THEN 'Manchester'
      WHEN r.region LIKE '%Leeds%' THEN 'Leeds'
      WHEN r.region LIKE '%Bristol%' THEN 'Bristol'
      ELSE SPLIT_PART(r.region, ' ', 1)
    END,
    r.region
  ),
  r.region,
  'centre',
  true
FROM dogadopt.rescues r;

-- Grant permissions
GRANT SELECT ON dogadopt.rescues TO anon, authenticated;
GRANT ALL ON dogadopt.rescues TO authenticated;
GRANT SELECT ON dogadopt.locations TO anon, authenticated;

-- Grant permissions for rescues audit
GRANT SELECT ON dogadopt.rescues_audit_logs_resolved TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_rescue_resolved_snapshot TO authenticated;

-- Grant permissions for locations audit
GRANT SELECT ON dogadopt.locations_complete TO anon, authenticated;
GRANT SELECT ON dogadopt.locations_audit_logs_resolved TO authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_location_resolved_snapshot TO authenticated;

-- Add documentation comments
COMMENT ON TABLE dogadopt.locations IS 'Physical locations for rescues - supports centres, foster homes, and other locations with privacy controls';
COMMENT ON COLUMN dogadopt.locations.is_public IS 'If true, show full address details. If false, show only city/region for privacy (e.g., foster homes)';

COMMENT ON TABLE dogadopt.rescues_audit_logs IS 'Complete audit log with fully resolved rescue snapshots. Enables event sourcing and time-travel queries. View rescues_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.rescues_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all rescue changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
COMMENT ON FUNCTION dogadopt.audit_rescue_changes IS 'Audit trigger for rescues table. Captures complete snapshots including OLD/NEW record state for proper before/after tracking.';

COMMENT ON TABLE dogadopt.locations_audit_logs IS 'Complete audit log with fully resolved location snapshots including rescue information. Enables event sourcing and time-travel queries. View locations_audit_logs_resolved for human-readable audit data.';
COMMENT ON VIEW dogadopt.locations_complete IS 'Comprehensive location view with rescue information fully resolved. Single source for all location data with relationships.';
COMMENT ON VIEW dogadopt.locations_audit_logs_resolved IS 'Comprehensive resolved audit log view showing all location changes with human-readable fields. Includes complete before/after snapshots and metadata about the source of changes.';
COMMENT ON FUNCTION dogadopt.audit_location_changes IS 'Audit trigger for locations table. Captures complete snapshots including OLD/NEW record state for proper before/after tracking.';
