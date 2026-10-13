# Tracklet — Supabase Authentication Configuration & Deployment Guide

This document specifies the required Supabase Auth configuration, callback routing, email templates, mobile deep-link intent filters, and security policies for production deployments of Tracklet.

---

## 1. Authentication Providers

### 1.1 Email & Password
- **Status:** Enabled
- **Sign-up restriction:** NITC Institute emails ending in `@nitc.ac.in`.
- **Minimum Password Length:** 6 characters.
- **Secure Password Storage:** Delegated directly to Supabase Auth (Argon2id/bcrypt in `auth.users`).

### 1.2 Google OAuth (Optional / Supported)
- **Status:** Enabled
- **Provider ID:** `google`
- **Authorized Client IDs:** Configured via Google Cloud Console with Android package `com.tracklet.nitc` and iOS bundle `com.tracklet.nitc`.
- **Redirect URI:** `https://<YOUR_SUPABASE_PROJECT_REF>.supabase.co/auth/v1/callback`

---

## 2. Site URL & Redirect URLs

Configure the following URLs in **Supabase Dashboard → Authentication → URL Configuration**:

- **Site URL:**
  ```
  https://tracklet.nitc.ac.in
  ```
- **Redirect URLs (Wildcards / Deep Links):**
  ```
  nitcbus://auth-callback
  nitcbus://auth-callback/**
  https://tracklet-demo.vercel.app/auth/callback
  https://tracklet.nitc.ac.in/auth/callback
  https://tracklet.nitc.ac.in/reset-password
  ```

---

## 3. Email Templates & Delivery

In **Supabase Dashboard → Authentication → Email Templates**:

### 3.1 Confirmation / Verification Email Template
- **Subject:** `Confirm your Tracklet NITC student account`
- **Body HTML:**
```html
<h2>Welcome to Tracklet!</h2>
<p>Thanks for registering your NITC campus transit account.</p>
<p>Please confirm your student email by clicking the link below:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm Student Account</a></p>
<p>If you did not request this, please disregard this email.</p>
```

### 3.2 Password Reset / Recovery Email Template
- **Subject:** `Reset your Tracklet password`
- **Body HTML:**
```html
<h2>Reset Your Tracklet Password</h2>
<p>We received a request to reset your password for your Tracklet account.</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
<p>This recovery link is valid for 1 hour. If you didn't request a password reset, you can safely ignore this email.</p>
```

### 3.3 Custom SMTP Provider
- Configure dedicated SMTP (e.g., AWS SES, Resend, SendGrid) under **Authentication → SMTP Settings** to prevent spam filtering and stay within default Supabase rate limits (30 emails/hr on free tier).

---

## 4. Mobile Deep Linking Configuration

### 4.1 Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="nitcbus" android:host="auth-callback" />
</intent-filter>
```

### 4.2 iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.tracklet.nitc</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>nitcbus</string>
        </array>
    </dict>
</array>
```

---

## 5. Database Schema & RLS Policies

The user profile lifecycle is managed via `public.users` linked to `auth.users`:

1. **Trigger on Account Creation (`handle_new_user`):**
   ```sql
   CREATE OR REPLACE FUNCTION public.handle_new_user()
   RETURNS trigger
   LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = public, pg_temp
   AS $$
   BEGIN
     INSERT INTO public.users (user_id, full_name, onboarding_completed, notification_prefs)
     VALUES (NEW.id, NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''), false, '{}'::jsonb)
     ON CONFLICT (user_id) DO NOTHING;
     RETURN NEW;
   END;
   $$;
   ```

2. **Row Level Security (RLS):**
   ```sql
   ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

   CREATE POLICY "Allow users to read their own profile"
     ON public.users FOR SELECT
     TO authenticated
     USING (auth.uid() = user_id);

   CREATE POLICY "Allow users to update their own profile"
     ON public.users FOR UPDATE
     TO authenticated
     USING (auth.uid() = user_id)
     WITH CHECK (auth.uid() = user_id);
   ```

3. **RPC Security:**
   - `get_my_profile()`: `SECURITY DEFINER`, restricted to authenticated users.
   - `ensure_my_profile()`: `SECURITY DEFINER`, creates row on demand using `auth.uid()`.
   - `complete_onboarding(...)`: `SECURITY DEFINER`, validates all required student fields and sets `onboarding_completed = true`.
   - `update_my_profile(...)`: `SECURITY DEFINER`, ensures user isolation.
