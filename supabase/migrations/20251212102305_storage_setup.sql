-- Create storage bucket for dog adoption images
INSERT INTO storage.buckets (id, name, public)
VALUES ('dog-adopt-images', 'dog-adopt-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow anyone to view images (public bucket)
CREATE POLICY "Public read access for dog images"
ON storage.objects FOR SELECT
USING (bucket_id = 'dog-adopt-images');

-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload dog images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

-- Allow authenticated users to update their uploads
CREATE POLICY "Authenticated users can update dog images"
ON storage.objects FOR UPDATE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete dog images"
ON storage.objects FOR DELETE
USING (bucket_id = 'dog-adopt-images' AND auth.role() = 'authenticated');