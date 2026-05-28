# Supabase Setup Guide

## 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in
2. Click **New Project**
3. Choose organization, name (`it-support-helpdesk`), database password, and region
4. Wait for the project to finish provisioning

## 2. Run Database Migration

1. Open **SQL Editor** in your Supabase dashboard
2. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
3. Paste and click **Run**
4. Verify tables appear under **Table Editor**

## 3. Configure Authentication

1. Go to **Authentication > Providers**
2. Enable **Email** provider
3. Under **Authentication > URL Configuration**, set:
   - Site URL: your app URL (for mobile use a deep link scheme, e.g. `io.supabase.ithelpdesk://login-callback/`)
   - Redirect URLs: add the same deep link
4. Optional: disable email confirmation for development under **Authentication > Providers > Email**

## 4. Get API Keys

1. Go to **Project Settings > API**
2. Copy:
   - **Project URL** → use as `SUPABASE_URL`
   - **anon public** key → use as `SUPABASE_ANON_KEY`

## 5. Configure the Flutter App

Edit `lib/core/constants/supabase_constants.dart`:

```dart
static const String supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
static const String supabaseAnonKey = 'YOUR-ANON-KEY';
```

## 6. Enable Realtime

Realtime is enabled via the migration SQL. Verify under **Database > Replication** that `tickets`, `ticket_comments`, and `notifications` are listed.

## 7. Storage Buckets

The migration creates three buckets:
- `avatars` — user profile photos
- `ticket-images` — images attached when creating tickets
- `repair-images` — images uploaded by technicians during repair

## 8. Create Admin User (Optional)

After registering your first user via the app:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'your-admin@company.com';
```

## 9. Create Technician

```sql
-- First set role to technician
UPDATE public.profiles SET role = 'technician' WHERE email = 'tech@company.com';

-- Then insert technician record
INSERT INTO public.technicians (profile_id, specialization)
SELECT id, 'General IT Support' FROM public.profiles WHERE email = 'tech@company.com';
```
