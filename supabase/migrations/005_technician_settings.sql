-- ============================================================
-- Migration: technician_settings
-- เก็บ: เปิด/ปิดรับงาน, พื้นที่รับงาน (lat/lng/radius)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.technician_settings (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  technician_id   UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_available    BOOLEAN NOT NULL DEFAULT TRUE,
  -- พื้นที่รับงาน
  service_lat     DOUBLE PRECISION,
  service_lng     DOUBLE PRECISION,
  service_radius_km DOUBLE PRECISION NOT NULL DEFAULT 10.0,
  -- masked phone สำหรับ proxy call (ไม่เก็บเบอร์จริงตรงนี้)
  masked_phone    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_technician_settings_technician_id
  ON public.technician_settings(technician_id);

-- updated_at trigger
CREATE TRIGGER trg_technician_settings_updated_at
  BEFORE UPDATE ON public.technician_settings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- RLS
ALTER TABLE public.technician_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Technicians view own settings"
  ON public.technician_settings FOR SELECT
  TO authenticated
  USING (technician_id = auth.uid() OR public.is_admin());

CREATE POLICY "Technicians update own settings"
  ON public.technician_settings FOR UPDATE
  TO authenticated
  USING (technician_id = auth.uid())
  WITH CHECK (technician_id = auth.uid());

CREATE POLICY "Technicians insert own settings"
  ON public.technician_settings FOR INSERT
  TO authenticated
  WITH CHECK (technician_id = auth.uid());

-- ── Function: คืน ticket ที่อยู่ใน service radius ────────────
-- ใช้ Haversine formula เปรียบเทียบระยะทาง
CREATE OR REPLACE FUNCTION public.is_ticket_in_service_area(
  tech_id     UUID,
  ticket_lat  DOUBLE PRECISION,
  ticket_lng  DOUBLE PRECISION
) RETURNS BOOLEAN AS $$
DECLARE
  s RECORD;
  dist_km DOUBLE PRECISION;
BEGIN
  SELECT * INTO s FROM public.technician_settings
  WHERE technician_id = tech_id;

  -- ถ้าไม่ได้ตั้ง service area หรือ ticket ไม่มี GPS → แสดงทุก ticket
  IF NOT FOUND OR s.service_lat IS NULL OR ticket_lat IS NULL THEN
    RETURN TRUE;
  END IF;

  -- Haversine
  dist_km := 6371 * 2 * ASIN(SQRT(
    POWER(SIN(RADIANS((ticket_lat - s.service_lat) / 2)), 2) +
    COS(RADIANS(s.service_lat)) * COS(RADIANS(ticket_lat)) *
    POWER(SIN(RADIANS((ticket_lng - s.service_lng) / 2)), 2)
  ));

  RETURN dist_km <= s.service_radius_km;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
