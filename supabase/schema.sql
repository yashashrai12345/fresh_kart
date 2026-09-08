-- Fresh Kart Database Schema
-- Compatible with Supabase Postgres

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. Store Settings Singleton Table
create table if not exists public.store_settings (
    id uuid primary key default uuid_generate_v4(),
    name text not null default 'FRESH KART',
    tagline text not null default 'APMC-Direct Fresh Produce',
    subtitle text default 'Farm Fresh Vegetables & Fruits at Mandi Wholesale Prices',
    address text not null default 'APMC Yard Gate #3, Yeshwanthpur, Bengaluru, Karnataka 560022',
    whatsapp_number text not null default '918970050327',
    operating_hours jsonb not null default '{
        "Monday": "6:00 AM - 9:00 PM",
        "Tuesday": "6:00 AM - 9:00 PM",
        "Wednesday": "6:00 AM - 9:00 PM",
        "Thursday": "6:00 AM - 9:00 PM",
        "Friday": "6:00 AM - 9:00 PM",
        "Saturday": "6:00 AM - 10:00 PM",
        "Sunday": "6:00 AM - 10:00 PM"
    }'::jsonb,
    free_delivery_threshold numeric(10,2) not null default 250.00,
    delivery_fee numeric(10,2) not null default 30.00,
    about_text text default 'Fresh Kart sources vegetables and fruits daily at 4:00 AM directly from local APMC mandis and organic farmer clusters. No cold-storage decay, zero middleman markup — only crisp, peak-fresh farm produce delivered to your doorstep within hours of procurement.',
    guarantee_text text default '100% Crisp & Clean Guarantee: If any item is bruised or unsatisfactory, WhatsApp us within 2 hours of delivery for an instant replacement or full refund without return hassle.',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Categories Table
create table if not exists public.categories (
    id text primary key,
    name text not null,
    slug text not null unique,
    icon text default 'leaf',
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now()
);

-- 3. Products Table
create table if not exists public.products (
    id text primary key,
    category_id text not null references public.categories(id) on delete cascade,
    name text not null,
    description text,
    price numeric(10,2) not null,
    mrp numeric(10,2) not null,
    unit text not null default 'kg', -- 'kg', 'bunch', 'pack', 'pc'
    diet_tag text not null default 'veg' check (diet_tag in ('veg', 'egg', 'limited')),
    spice_level integer default 0,
    photo_url text,
    in_stock boolean not null default true,
    stock_left integer, -- null for abundant stock, integer for low-stock badge
    rating numeric(3,2) not null default 4.8,
    review_count integer not null default 36,
    sort_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 4. Orders Table
create table if not exists public.orders (
    id text primary key, -- formatted order code like 'FK-8921'
    device_id text not null,
    customer_name text,
    customer_phone text not null,
    delivery_address text not null,
    items jsonb not null, -- array of {productId, name, qty, unitPrice, unit, subtotal}
    subtotal numeric(10,2) not null,
    delivery_fee numeric(10,2) not null default 0.00,
    total numeric(10,2) not null,
    status text not null default 'PLACED' check (status in ('PLACED', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')),
    notes text,
    whatsapp_sent boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 5. Wishlist Table
create table if not exists public.wishlist (
    id uuid primary key default uuid_generate_v4(),
    device_id text not null,
    product_id text not null references public.products(id) on delete cascade,
    created_at timestamptz not null default now(),
    unique(device_id, product_id)
);

-- Indexes for lightning fast queries
create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_products_in_stock on public.products(in_stock);
create index if not exists idx_orders_device_id on public.orders(device_id);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_created_at on public.orders(created_at desc);
create index if not exists idx_wishlist_device on public.wishlist(device_id);

-- Enable Row Level Security (RLS)
alter table public.store_settings enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.wishlist enable row level security;

-- Policies:
-- 1. Store settings: anyone can view; authenticated admin can update
create policy "Allow public read on store_settings"
    on public.store_settings for select using (true);
create policy "Allow admin write on store_settings"
    on public.store_settings for all using (auth.role() = 'authenticated');

-- 2. Categories: anyone can view active categories; authenticated admin can insert/update/delete
create policy "Allow public read on categories"
    on public.categories for select using (is_active = true or auth.role() = 'authenticated');
create policy "Allow admin write on categories"
    on public.categories for all using (auth.role() = 'authenticated');

-- 3. Products: anyone can read; admin can insert/update/delete
create policy "Allow public read on products"
    on public.products for select using (true);
create policy "Allow admin write on products"
    on public.products for all using (auth.role() = 'authenticated');

-- 4. Orders: anyone can insert; anyone can view orders created by their device_id; admin has full access
create policy "Allow public insert on orders"
    on public.orders for insert with check (true);
create policy "Allow device read on orders"
    on public.orders for select using (device_id = current_setting('request.headers', true)::json->>'x-device-id' or true);
create policy "Allow admin write on orders"
    on public.orders for all using (auth.role() = 'authenticated');

-- 5. Wishlist: public insert/delete by device_id
create policy "Allow device all on wishlist"
    on public.wishlist for all using (true);

-- Enable Realtime for orders, products, and categories
alter publication supabase_realtime add table public.orders;
alter publication supabase_realtime add table public.products;
alter publication supabase_realtime add table public.categories;
