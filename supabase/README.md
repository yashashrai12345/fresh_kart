# Fresh Kart Supabase Setup Guide

This directory contains the database schema and sample seed catalog for **Fresh Kart**.

## Step 1: Create a Free Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and create a free account.
2. Click **New Project** and name it `fresh-kart`.
3. Choose your closest region (e.g. `ap-south-1` Mumbai).
4. Save your **Database Password**.

## Step 2: Run Database Schema & Seed
1. In your Supabase project dashboard, open the **SQL Editor** from the left navigation.
2. Click **New Query**, copy the contents of `schema.sql`, and click **Run**.
3. Create another query, copy the contents of `seed.sql`, and click **Run**.

## Step 3: Get API Credentials
1. Go to **Project Settings** > **API**.
2. Copy your:
   - **Project URL** (`https://<project-ref>.supabase.co`)
   - **anon / public key** (`eyJhbGci...`)
3. Set these credentials in:
   - Flutter app: `lib/config/app_constants.dart` (or via `--dart-define`)
   - Admin panel: `admin_panel/.env` (or via `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`)

*Note: Fresh Kart includes a built-in Local Fallback engine so you can test all admin and mobile app features immediately, even before configuring Supabase.*
