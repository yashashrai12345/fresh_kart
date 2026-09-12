-- Green Basket Migration 003: Store Maintenance Mode
-- Adds maintenance mode controls to public.store_settings

alter table if exists public.store_settings
  add column if not exists is_maintenance_mode boolean not null default false,
  add column if not exists maintenance_title text default 'Store Under Maintenance',
  add column if not exists maintenance_message text default 'We are currently restocking fresh produce from the APMC Mandi. Ordering will resume shortly!',
  add column if not exists maintenance_estimated_resume timestamptz,
  add column if not exists maintenance_allow_browsing boolean not null default true;

-- Update existing default record if present
update public.store_settings
set
  is_maintenance_mode = coalesce(is_maintenance_mode, false),
  maintenance_title = coalesce(maintenance_title, 'Store Under Maintenance'),
  maintenance_message = coalesce(maintenance_message, 'We are currently restocking fresh produce from the APMC Mandi. Ordering will resume shortly!'),
  maintenance_allow_browsing = coalesce(maintenance_allow_browsing, true)
where id = '00000000-0000-0000-0000-000000000001';
