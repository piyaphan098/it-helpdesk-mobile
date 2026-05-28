-- ============================================================
-- Migration 007: Create technician_posts table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.technician_posts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  technician_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  image_urls      TEXT[] NOT NULL DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookup by technician
CREATE INDEX IF NOT EXISTS idx_technician_posts_technician_id
  ON public.technician_posts(technician_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER technician_posts_updated_at
  BEFORE UPDATE ON public.technician_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS
ALTER TABLE public.technician_posts ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public can read all posts"
  ON public.technician_posts FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Technician can insert own posts"
  ON public.technician_posts FOR INSERT
  TO authenticated
  WITH CHECK (technician_id = auth.uid());

CREATE POLICY "Technician can update own posts"
  ON public.technician_posts FOR UPDATE
  TO authenticated
  USING (technician_id = auth.uid());

CREATE POLICY "Technician can delete own posts"
  ON public.technician_posts FOR DELETE
  TO authenticated
  USING (technician_id = auth.uid());