-- ============================================================
-- Migration: ticket_reviews
-- ให้ user รีวิวช่างหลังปิดงาน
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ticket_reviews (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id     UUID NOT NULL UNIQUE REFERENCES public.tickets(id) ON DELETE CASCADE,
  reviewer_id   UUID NOT NULL REFERENCES public.profiles(id),
  technician_id UUID NOT NULL REFERENCES public.profiles(id),
  rating        SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment       TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ticket_reviews_ticket_id     ON public.ticket_reviews(ticket_id);
CREATE INDEX idx_ticket_reviews_technician_id ON public.ticket_reviews(technician_id);

-- RLS
ALTER TABLE public.ticket_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviewer can insert own review"
  ON public.ticket_reviews FOR INSERT
  TO authenticated
  WITH CHECK (reviewer_id = auth.uid());

CREATE POLICY "Anyone authenticated can view reviews"
  ON public.ticket_reviews FOR SELECT
  TO authenticated
  USING (TRUE);

-- ── อัปเดต rating เฉลี่ยใน technicians ──────────────────────
CREATE OR REPLACE FUNCTION public.update_technician_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.technicians
  SET rating = (
    SELECT ROUND(AVG(r.rating)::NUMERIC, 2)
    FROM public.ticket_reviews r
    WHERE r.technician_id = NEW.technician_id
  )
  WHERE profile_id = NEW.technician_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_technician_rating
  AFTER INSERT ON public.ticket_reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_technician_rating();

-- ── Realtime ─────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.ticket_reviews;
