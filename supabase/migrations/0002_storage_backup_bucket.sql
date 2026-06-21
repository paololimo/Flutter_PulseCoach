-- Create private backup bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', false)
ON CONFLICT (id) DO NOTHING;

-- RLS: each authenticated user can only access objects under their own prefix.
-- Explicit TO authenticated + WITH CHECK so the read (USING) and write (WITH
-- CHECK) boundaries are both auditable rather than relying on implicit defaults.
CREATE POLICY "backup_objects_own"
  ON storage.objects FOR ALL
  TO authenticated
  USING (
    bucket_id = 'backups'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'backups'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
