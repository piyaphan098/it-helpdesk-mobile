-- ============================================================
-- Migration: Technician Posts Storage Bucket
-- ============================================================

-- Create storage bucket for technician portfolio images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'technician-posts',
  'technician-posts',
  TRUE,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public read technician posts"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'technician-posts');

CREATE POLICY "Technician upload own posts"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'technician-posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Technician delete own posts"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'technician-posts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
