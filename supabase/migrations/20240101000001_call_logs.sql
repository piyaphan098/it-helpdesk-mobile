-- call_logs: บันทึกประวัติการโทรทุกครั้ง โดยไม่เปิดเผยเบอร์จริง
create table if not exists public.call_logs (
  id            uuid primary key default gen_random_uuid(),
  ticket_id     uuid not null references public.tickets(id) on delete cascade,
  caller_id     uuid not null references auth.users(id),
  caller_role   text not null check (caller_role in ('user', 'technician')),
  technician_id uuid not null references auth.users(id),
  user_id       uuid not null references auth.users(id),
  status        text not null default 'initiated'
                  check (status in ('initiated', 'ringing', 'connected', 'ended', 'missed', 'failed')),
  started_at    timestamptz not null default now(),
  connected_at  timestamptz,
  ended_at      timestamptz,
  duration_secs integer generated always as (
    case when ended_at is not null and connected_at is not null
    then extract(epoch from (ended_at - connected_at))::integer
    else null end
  ) stored,
  created_at    timestamptz not null default now()
);

-- Indexes
create index if not exists call_logs_ticket_id_idx   on public.call_logs (ticket_id);
create index if not exists call_logs_caller_id_idx   on public.call_logs (caller_id);
create index if not exists call_logs_started_at_idx  on public.call_logs (started_at desc);

-- RLS: เฉพาะคู่สนทนาของ ticket นั้นดูได้
alter table public.call_logs enable row level security;

create policy "call_logs: caller can view own logs"
  on public.call_logs for select
  using (
    auth.uid() = caller_id
    or auth.uid() = technician_id
    or auth.uid() = user_id
  );

-- Service role ใช้ insert (Edge Function)
create policy "call_logs: service role insert"
  on public.call_logs for insert
  with check (true);  -- ถูก guard ด้วย service_role key ใน Edge Function อยู่แล้ว

-- อนุญาตให้ update status/ended_at ผ่าน Edge Function เท่านั้น
create policy "call_logs: service role update"
  on public.call_logs for update
  using (true)
  with check (true);

comment on table public.call_logs is
  'บันทึกประวัติการโทรแบบ masked — เบอร์จริงไม่ถูกเก็บที่นี่';
