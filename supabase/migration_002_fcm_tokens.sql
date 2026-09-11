-- Fresh Kart: FCM Push Notification Token Storage
-- Run this in Supabase Dashboard → SQL Editor

-- Table to store FCM device/browser tokens
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     text NOT NULL,            -- Firebase UID (customer) or 'admin' (admin browser)
  token       text NOT NULL UNIQUE,     -- FCM registration token
  platform    text DEFAULT 'android',   -- 'android' | 'web'
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- Index for fast lookup by user_id
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);

-- RLS: users can only manage their own tokens; 'admin' tokens need service role
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Allow the Flutter app (authenticated via Firebase UID) to insert/update its own token
-- Note: The app stores the Firebase UID as user_id (not Supabase auth uid)
-- so we use a permissive policy scoped to anon key
CREATE POLICY "Allow upsert own FCM token"
  ON public.user_fcm_tokens
  FOR ALL
  USING (true)   -- The Edge Function uses service_role which bypasses RLS
  WITH CHECK (true);

-- ── After creating the table, set up the Database Webhooks ─────────────────
-- In Supabase Dashboard → Database → Webhooks → Create a new hook:
--
-- Webhook 1 (new orders → notify admin):
--   Name:    notify-on-new-order
--   Table:   public.orders
--   Events:  INSERT
--   URL:     https://nzptqpjpafzdhdknzutf.supabase.co/functions/v1/send-notification
--   Headers: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56cHRxcGpwYWZ6ZGhka256dXRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NDc4NzUsImV4cCI6MjEwNDQyMzg3NX0.xU_GzACu6XremXkGKlEy8-_itkPPz1rcGEfWz4mKqns
--
-- Webhook 2 (status update → notify customer):
--   Name:    notify-on-status-update
--   Table:   public.orders
--   Events:  UPDATE
--   URL:     https://nzptqpjpafzdhdknzutf.supabase.co/functions/v1/send-notification
--   Headers: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56cHRxcGpwYWZ6ZGhka256dXRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NDc4NzUsImV4cCI6MjEwNDQyMzg3NX0.xU_GzACu6XremXkGKlEy8-_itkPPz1rcGEfWz4mKqns
--
-- ── Edge Function secrets (via Dashboard or Terminal) ───────────────────────
-- Dashboard: Project Settings → Edge Functions → Secrets (Add Secret)
-- 1. Name: FIREBASE_PROJECT_ID
--    Value: weighty-forest-411105
-- 2. Name: FIREBASE_SERVICE_ACCOUNT_JSON
--    Value: (contents of supabase/service-account.json)
--
-- Deploy the Edge Function (run in terminal from project root):
-- cmd /c "npx supabase login"
-- cmd /c "npx supabase link --project-ref nzptqpjpafzdhdknzutf"
-- cmd /c "npx supabase functions deploy send-notification --no-verify-jwt"
