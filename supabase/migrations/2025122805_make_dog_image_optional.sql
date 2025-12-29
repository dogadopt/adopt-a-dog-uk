-- Make dog image column nullable and set default
-- This allows dogs to be created without an image

-- Drop the NOT NULL constraint on the image column
ALTER TABLE dogadopt.dogs ALTER COLUMN image DROP NOT NULL;

-- Set a default value for the image column
ALTER TABLE dogadopt.dogs ALTER COLUMN image SET DEFAULT '/dog-coming-soon.svg';

-- Update the audit trigger function to handle null images properly
-- The existing trigger already handles this, but we'll document the behavior
COMMENT ON COLUMN dogadopt.dogs.image IS 'URL to dog image. Defaults to /dog-coming-soon.svg if not provided.';
