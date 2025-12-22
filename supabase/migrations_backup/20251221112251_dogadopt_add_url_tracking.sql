-- Add URL tracking fields for dogs and locations
-- Enables tracking referrals to rescue websites with UTM parameters

-- Add profile_url to dogs table
ALTER TABLE dogadopt.dogs ADD COLUMN profile_url TEXT;

-- Add enquiry_url to locations table
ALTER TABLE dogadopt.locations ADD COLUMN enquiry_url TEXT;

-- Create helper function to build tracked URL
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
  -- Get dog with related data
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
    -- No URL available
    RETURN NULL;
  END IF;

  -- Build tracking parameters
  tracking_params := 'utm_source=dogadoptuk&utm_medium=referral&utm_campaign=dog_profile&utm_content=' || _dog_id::text;

  -- Append tracking parameters (handle existing query string)
  IF base_url LIKE '%?%' THEN
    -- URL already has query string
    RETURN base_url || '&' || tracking_params;
  ELSE
    -- URL doesn't have query string
    RETURN base_url || '?' || tracking_params;
  END IF;
END;
$$;

-- Create view for easy access to tracked URLs
CREATE VIEW dogadopt.dogs_with_tracked_urls AS
SELECT 
  d.*,
  dogadopt.get_dog_profile_url(d.id) as tracked_url,
  CASE 
    WHEN d.profile_url IS NOT NULL THEN 'dog_profile'
    WHEN l.enquiry_url IS NOT NULL THEN 'location_enquiry'
    WHEN r.website IS NOT NULL THEN 'rescue_website'
    ELSE NULL
  END as url_source
FROM dogadopt.dogs d
LEFT JOIN dogadopt.locations l ON l.id = d.location_id
LEFT JOIN dogadopt.rescues r ON r.id = d.rescue_id;

-- Add comments for documentation
COMMENT ON COLUMN dogadopt.dogs.profile_url IS 'Direct URL to this dog''s profile page on the rescue''s website. Optional - if not provided, will fallback to location or rescue URL.';
COMMENT ON COLUMN dogadopt.locations.enquiry_url IS 'General enquiry or contact URL for this location. Used as fallback if dog doesn''t have specific profile URL.';
COMMENT ON FUNCTION dogadopt.get_dog_profile_url IS 'Returns dog profile URL with tracking parameters (utm_source=dogadoptuk). Falls back to location enquiry URL or rescue website if dog profile URL not available.';
COMMENT ON VIEW dogadopt.dogs_with_tracked_urls IS 'Convenience view showing all dogs with their tracked URLs. The tracked_url includes UTM parameters for traffic tracking.';

-- Grant permissions
GRANT SELECT ON dogadopt.dogs_with_tracked_urls TO anon, authenticated;
GRANT EXECUTE ON FUNCTION dogadopt.get_dog_profile_url TO anon, authenticated;

-- Example usage in comments
COMMENT ON FUNCTION dogadopt.get_dog_profile_url IS 
'Returns tracked URL for a dog with UTM parameters (utm_source=dogadoptuk).

Priority:
1. dog.profile_url (if set)
2. location.enquiry_url (if dog has location)
3. rescue.website (fallback)

Example:
SELECT get_dog_profile_url(''a7a43391-92c6-4fd8-a13b-6063fb234e0a'');

Returns:
https://dogstrust.org.uk/dogs/bella?utm_source=dogadoptuk&utm_medium=referral&utm_campaign=dog_profile&utm_content=a7a43391-92c6-4fd8-a13b-6063fb234e0a

Tracking parameters:
- utm_source=dogadoptuk     (platform identifier)
- utm_medium=referral       (traffic type)
- utm_campaign=dog_profile  (campaign name)
- utm_content={dog_id}      (specific dog identifier)';
