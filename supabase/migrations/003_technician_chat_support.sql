-- ============================================================
-- Migration: ตรวจสอบ realtime สำหรับ ticket_comments
-- ticket_comments ถูก add ใน supabase_realtime แล้วใน 001_initial_schema.sql
-- ถ้ายังไม่ได้ add ให้รัน query นี้
-- ============================================================

-- ตรวจสอบว่า ticket_comments อยู่ใน realtime publication แล้วหรือยัง
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'ticket_comments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ticket_comments;
  END IF;
END $$;

-- ============================================================
-- ให้ technician อัปเดต assigned_to ของตัวเองได้
-- (RLS policy เพิ่มเติม สำหรับ acceptTicket)
-- ============================================================

-- Drop ถ้ามีอยู่แล้ว แล้ว recreate
DROP POLICY IF EXISTS "Technicians can self-assign tickets" ON public.tickets;

CREATE POLICY "Technicians can self-assign tickets"
  ON public.tickets FOR UPDATE
  TO authenticated
  USING (
    public.is_technician_or_admin()
    AND (assigned_to IS NULL OR assigned_to = auth.uid())
  )
  WITH CHECK (
    public.is_technician_or_admin()
  );
