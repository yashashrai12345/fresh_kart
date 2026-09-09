-- =============================================================
-- Fresh Kart Migration 001: Auth-based User Identity + Secure RLS
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- =============================================================

-- ---------------------------------------------------------------
-- STEP 1: Add user_id to orders table (nullable for backward compat)
-- ---------------------------------------------------------------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Index for fast per-user order queries
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);

-- ---------------------------------------------------------------
-- STEP 2: Add user_id to wishlist table
-- ---------------------------------------------------------------
ALTER TABLE public.wishlist
  ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;

-- Drop the old device_id unique constraint (if it exists) and add user-based one
ALTER TABLE public.wishlist DROP CONSTRAINT IF EXISTS wishlist_device_id_product_id_key;
ALTER TABLE public.wishlist ADD CONSTRAINT IF NOT EXISTS wishlist_user_id_product_id_key UNIQUE (user_id, product_id);

-- Index for fast per-user wishlist queries
CREATE INDEX IF NOT EXISTS idx_wishlist_user_id ON public.wishlist(user_id);

-- ---------------------------------------------------------------
-- STEP 3: Admin role helper function
-- Checks if the calling authenticated user has role='admin' set
-- in their app_metadata (set via Supabase service-role API or dashboard)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(
      (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
      false
    )
  );
END;
$$;

-- ---------------------------------------------------------------
-- STEP 4: Drop ALL existing unsafe RLS policies
-- ---------------------------------------------------------------

-- store_settings
DROP POLICY IF EXISTS "Allow public read on store_settings" ON public.store_settings;
DROP POLICY IF EXISTS "Allow admin write on store_settings" ON public.store_settings;

-- categories
DROP POLICY IF EXISTS "Allow public read on categories" ON public.categories;
DROP POLICY IF EXISTS "Allow admin write on categories" ON public.categories;

-- products
DROP POLICY IF EXISTS "Allow public read on products" ON public.products;
DROP POLICY IF EXISTS "Allow admin write on products" ON public.products;

-- orders (DANGEROUS existing policies)
DROP POLICY IF EXISTS "Allow public insert on orders" ON public.orders;
DROP POLICY IF EXISTS "Allow device read on orders" ON public.orders;
DROP POLICY IF EXISTS "Allow admin write on orders" ON public.orders;

-- wishlist (DANGEROUS existing policy)
DROP POLICY IF EXISTS "Allow device all on wishlist" ON public.wishlist;

-- ---------------------------------------------------------------
-- STEP 5: Create SECURE RLS policies
-- ---------------------------------------------------------------

-- === STORE SETTINGS ===
-- Anyone can read store settings (public info)
CREATE POLICY "store_settings_public_read"
  ON public.store_settings FOR SELECT
  USING (true);

-- Only admin can insert/update/delete
CREATE POLICY "store_settings_admin_write"
  ON public.store_settings FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- === CATEGORIES ===
-- Public can read active categories; admin can read all
CREATE POLICY "categories_public_read"
  ON public.categories FOR SELECT
  USING (is_active = true OR public.is_admin());

-- Only admin can insert/update/delete
CREATE POLICY "categories_admin_write"
  ON public.categories FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- === PRODUCTS ===
-- Public can read all products
CREATE POLICY "products_public_read"
  ON public.products FOR SELECT
  USING (true);

-- Only admin can insert/update/delete
CREATE POLICY "products_admin_write"
  ON public.products FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- === ORDERS ===
-- Authenticated customer can insert their own order
CREATE POLICY "orders_customer_insert"
  ON public.orders FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Authenticated customer can only read their own orders
CREATE POLICY "orders_customer_read"
  ON public.orders FOR SELECT
  USING (auth.uid() = user_id OR public.is_admin());

-- Only admin can update order status
CREATE POLICY "orders_admin_update"
  ON public.orders FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Only admin can delete orders (rare, business decision)
CREATE POLICY "orders_admin_delete"
  ON public.orders FOR DELETE
  USING (public.is_admin());

-- === WISHLIST ===
-- Customer can read their own wishlist
CREATE POLICY "wishlist_customer_read"
  ON public.wishlist FOR SELECT
  USING (auth.uid() = user_id);

-- Customer can insert to their own wishlist
CREATE POLICY "wishlist_customer_insert"
  ON public.wishlist FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

-- Customer can delete from their own wishlist only
CREATE POLICY "wishlist_customer_delete"
  ON public.wishlist FOR DELETE
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------
-- STEP 6: Ensure RLS is enabled on all tables (re-confirm)
-- ---------------------------------------------------------------
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------
-- STEP 7: Realtime (ensure still enabled - non-destructive)
-- ---------------------------------------------------------------
DO $$
BEGIN
  -- orders
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
  -- products
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'products'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
  END IF;
  -- categories
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'categories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
  END IF;
END;
$$;

-- ---------------------------------------------------------------
-- STEP 8: Grant admin role to your admin user
-- MANUAL STEP: Replace 'YOUR-ADMIN-USER-UUID' with actual UUID from
-- Supabase Dashboard > Authentication > Users
-- Then run this separately:
-- ---------------------------------------------------------------
-- UPDATE auth.users
--   SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
--   WHERE id = 'YOUR-ADMIN-USER-UUID';

-- ---------------------------------------------------------------
-- DONE. Verify with:
-- SELECT * FROM pg_policies WHERE schemaname = 'public';
-- ---------------------------------------------------------------
