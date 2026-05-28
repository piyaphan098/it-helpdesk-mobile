-- Migration: เพิ่ม latitude และ longitude ใน tickets
-- รัน query นี้ใน Supabase SQL Editor

ALTER TABLE public.tickets
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Index สำหรับ geo query (optional แต่ดีถ้าอยากกรองตาม area)
CREATE INDEX IF NOT EXISTS idx_tickets_location
  ON public.tickets (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

COMMENT ON COLUMN public.tickets.latitude  IS 'Latitude ของตำแหน่งที่เกิดปัญหา (จาก GPS หรือ tap บนแผนที่)';
COMMENT ON COLUMN public.tickets.longitude IS 'Longitude ของตำแหน่งที่เกิดปัญหา';
