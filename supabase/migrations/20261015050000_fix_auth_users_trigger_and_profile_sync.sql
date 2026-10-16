-- Migration: Fix Auth Users Trigger and Profile Synchronization for Google OAuth
-- Ensures public.users is always created on authentication, prevents orphaned auth users,
-- and guarantees onboarding status persists across devices.

-- 1. Backfill any missing auth.users into public.users
INSERT INTO public.users (user_id, full_name, created_at, updated_at)
SELECT
  id,
  NULLIF(trim(COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name')), ''),
  COALESCE(created_at, now()),
  COALESCE(created_at, now())
FROM auth.users
ON CONFLICT (user_id) DO UPDATE SET
  full_name = COALESCE(public.users.full_name, EXCLUDED.full_name);

-- 2. Update handle_new_user to extract Google OAuth display names and UPSERT safely
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_full_name text;
BEGIN
  v_full_name := NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name')), '');

  INSERT INTO public.users (
    user_id,
    full_name,
    department_id,
    batch,
    hostel,
    onboarding_completed,
    notification_prefs,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    v_full_name,
    NULL,
    NULL,
    NULL,
    false,
    '{}'::jsonb,
    COALESCE(NEW.created_at, now()),
    COALESCE(NEW.created_at, now())
  )
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = COALESCE(public.users.full_name, EXCLUDED.full_name),
    updated_at = now();

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$function$;

-- 3. Ensure trigger fires on INSERT and on sign-in updates so existing Google users get synced
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE OF last_sign_in_at, raw_user_meta_data ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Update ensure_my_profile to ensure record existence with Google OAuth metadata
CREATE OR REPLACE FUNCTION public.ensure_my_profile()
RETURNS TABLE(
  user_id uuid,
  full_name text,
  department_id text,
  department_name text,
  batch text,
  hostel text,
  onboarding_completed boolean,
  notification_prefs jsonb,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
#variable_conflict use_column
DECLARE
  v_uid uuid := auth.uid();
  v_meta_name text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  SELECT NULLIF(trim(COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name')), '')
  INTO v_meta_name
  FROM auth.users
  WHERE id = v_uid;

  INSERT INTO public.users (user_id, full_name, onboarding_completed, notification_prefs)
  VALUES (v_uid, v_meta_name, false, '{}'::jsonb)
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = COALESCE(public.users.full_name, EXCLUDED.full_name);

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

-- 5. Update update_my_profile to ensure profile record exists before updating
CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_full_name text DEFAULT NULL,
  p_department_id text DEFAULT NULL,
  p_batch text DEFAULT NULL,
  p_hostel text DEFAULT NULL,
  p_notification_prefs jsonb DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  department_id text,
  department_name text,
  batch text,
  hostel text,
  onboarding_completed boolean,
  notification_prefs jsonb,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
#variable_conflict use_column
DECLARE
  v_uid uuid := auth.uid();
  v_dept_name text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  IF p_department_id IS NOT NULL THEN
    SELECT d.department_name INTO v_dept_name
    FROM public.departments d
    WHERE d.department_id = p_department_id;

    IF v_dept_name IS NULL THEN
      RAISE EXCEPTION 'Invalid department ID: %', p_department_id USING ERRCODE = '23503';
    END IF;
  END IF;

  IF p_notification_prefs IS NOT NULL AND jsonb_typeof(p_notification_prefs) <> 'object' THEN
    RAISE EXCEPTION 'Notification preferences must be a JSON object' USING ERRCODE = '22023';
  END IF;

  -- Ensure record exists before updating
  INSERT INTO public.users (user_id, onboarding_completed, notification_prefs)
  VALUES (v_uid, false, '{}'::jsonb)
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE public.users
  SET
    full_name = CASE WHEN p_full_name IS NOT NULL THEN trim(p_full_name) ELSE public.users.full_name END,
    department_id = CASE WHEN p_department_id IS NOT NULL THEN p_department_id ELSE public.users.department_id END,
    batch = CASE WHEN p_batch IS NOT NULL THEN trim(p_batch) ELSE public.users.batch END,
    hostel = CASE WHEN p_hostel IS NOT NULL THEN trim(p_hostel) ELSE public.users.hostel END,
    notification_prefs = CASE WHEN p_notification_prefs IS NOT NULL THEN p_notification_prefs ELSE public.users.notification_prefs END,
    updated_at = now()
  WHERE public.users.user_id = v_uid;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

-- 6. Add policy allowing authenticated users to insert their own profile
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Allow users to insert their own profile'
  ) THEN
    CREATE POLICY "Allow users to insert their own profile"
      ON public.users FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END;
$$;
