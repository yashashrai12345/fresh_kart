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

## Step 4: Configure Google Sign-In (OAuth)
1. Go to your **Supabase Dashboard** > **Authentication** > **URL Configuration**.
2. Under **Redirect URLs**, click **Add URL** and add:
   - `io.supabase.freshkart://login-callback`
   - (For local web testing if needed: `http://localhost:3000` or your dev server URL)
3. Go to **Authentication** > **Providers** > **Google**.
4. Toggle **Enable Google provider**.
5. Obtain a **Client ID** and **Client Secret** from the [Google Cloud Console](https://console.cloud.google.com/apis/credentials):
   - In Google Cloud Console, create OAuth 2.0 Client IDs (Type: Web application).
   - In **Authorized redirect URIs**, add your Supabase callback URL:
     `https://<your-project-ref>.supabase.co/auth/v1/callback`
   - Paste the generated **Client ID** and **Client Secret** into the Supabase Google provider settings.
6. Click **Save**.

*Note: Fresh Kart includes a built-in Local Fallback engine so you can test all admin and mobile app features immediately, even before configuring Supabase.*

