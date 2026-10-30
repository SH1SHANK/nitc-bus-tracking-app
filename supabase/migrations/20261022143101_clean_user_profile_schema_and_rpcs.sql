-- ============================================================================
-- Migration: Clean public.users, strip legacy academic fields, streamline profile RPCs
-- ============================================================================
-- 1. Drops legacy columns (department_id, batch, hostel, hostel_id) from public.users
-- 2. Simplifies get_my_profile, ensure_my_profile, update_my_profile, and complete_onboarding
--    to focus strictly on user_id, full_name, username, notification_prefs, onboarding_completed.
-- ============================================================================

-- 1. Drop foreign key constraints and legacy columns if they exist
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_department_id_fkey;
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_hostel_id_fkey;
DROP INDEX IF EXISTS idx_users_department_id;
DROP INDEX IF EXISTS idx_users_hostel_id;

ALTER TABLE public.users DROP COLUMN IF EXISTS department_id;
ALTER TABLE public.users DROP COLUMN IF EXISTS batch;
ALTER TABLE public.users DROP COLUMN IF EXISTS hostel;
ALTER TABLE public.users DROP COLUMN IF EXISTS hostel_id;

-- 2. Simplified get_my_profile()
DROP FUNCTION IF EXISTS public.get_my_profile();
CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
  email text,
  onboarding_completed boolean,
  notification_prefs jsonb,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_email text := auth.jwt() ->> 'email';
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT
    u.user_id,
    u.full_name,
    u.username,
    COALESCE(v_email, ''),
    u.onboarding_completed,
    u.notification_prefs,
    u.created_at,
    u.updated_at
  FROM public.users u
  WHERE u.user_id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;

-- 3. Simplified ensure_my_profile()
DROP FUNCTION IF EXISTS public.ensure_my_profile();
CREATE OR REPLACE FUNCTION public.ensure_my_profile()
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
  email text,
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
DECLARE
  v_uid uuid := auth.uid();
  v_name text;
  v_username text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  v_name := trim(COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'full_name',
    auth.jwt() -> 'user_metadata' ->> 'name',
    split_part(auth.jwt() ->> 'email', '@', 1),
    'Student'
  ));
  v_username := trim(COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'username',
    split_part(auth.jwt() ->> 'email', '@', 1)
  ));

  INSERT INTO public.users (
    user_id,
    full_name,
    username,
    onboarding_completed,
    notification_prefs
  )
  VALUES (
    v_uid,
    v_name,
    v_username,
    false,
    '{}'::jsonb
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    full_name = COALESCE(public.users.full_name, EXCLUDED.full_name),
    username = COALESCE(public.users.username, EXCLUDED.username);

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_my_profile() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_my_profile() TO authenticated;

-- 4. Simplified update_my_profile()
DROP FUNCTION IF EXISTS public.update_my_profile(text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS public.update_my_profile(text, jsonb, text);
CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_full_name text DEFAULT NULL,
  p_notification_prefs jsonb DEFAULT NULL,
  p_username text DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
  email text,
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
  v_clean_user text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF p_notification_prefs IS NOT NULL AND jsonb_typeof(p_notification_prefs) <> 'object' THEN
    RAISE EXCEPTION 'Notification preferences must be a JSON object' USING ERRCODE = '22023';
  END IF;

  IF p_username IS NOT NULL THEN
    v_clean_user := trim(p_username);
    IF char_length(v_clean_user) < 3 OR char_length(v_clean_user) > 20 THEN
      RAISE EXCEPTION 'Username must be between 3 and 20 characters.' USING ERRCODE = '22023';
    END IF;
    IF NOT (v_clean_user ~ '^[A-Za-z][A-Za-z0-9_]{1,18}[A-Za-z0-9]$') THEN
      RAISE EXCEPTION 'Username must start with a letter, end with a letter or digit, and contain no spaces.' USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.users
      WHERE lower(username) = lower(v_clean_user) AND user_id <> v_uid
    ) THEN
      RAISE EXCEPTION 'Username is already taken' USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.users (user_id, onboarding_completed, notification_prefs)
  VALUES (v_uid, false, '{}'::jsonb)
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE public.users
  SET
    full_name = CASE WHEN p_full_name IS NOT NULL THEN trim(p_full_name) ELSE public.users.full_name END,
    notification_prefs = CASE WHEN p_notification_prefs IS NOT NULL THEN p_notification_prefs ELSE public.users.notification_prefs END,
    username = CASE WHEN p_username IS NOT NULL THEN v_clean_user ELSE public.users.username END,
    updated_at = now()
  WHERE public.users.user_id = v_uid;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_profile(text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_my_profile(text, jsonb, text) TO authenticated;

-- 5. Simplified change_my_username()
DROP FUNCTION IF EXISTS public.change_my_username(text);
CREATE OR REPLACE FUNCTION public.change_my_username(p_username text)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
  email text,
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
  v_clean text := trim(p_username);
  v_lower text := lower(v_clean);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF v_clean IS NULL OR char_length(v_clean) < 3 OR char_length(v_clean) > 20 THEN
    RAISE EXCEPTION 'Username must be between 3 and 20 characters.' USING ERRCODE = '22023';
  END IF;

  IF NOT (v_clean ~ '^[A-Za-z][A-Za-z0-9_]{1,18}[A-Za-z0-9]$') THEN
    RAISE EXCEPTION 'Username must start with a letter, end with a letter or digit, and contain no spaces.' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE lower(username) = v_lower AND user_id <> v_uid
  ) THEN
    RAISE EXCEPTION 'Username is already taken' USING ERRCODE = '23505';
  END IF;

  UPDATE public.users
  SET username = v_clean,
      updated_at = now()
  WHERE public.users.user_id = v_uid;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.change_my_username(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.change_my_username(text) TO authenticated;

-- 6. Simplified complete_onboarding()
DROP FUNCTION IF EXISTS public.complete_onboarding(text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS public.complete_onboarding(text, jsonb, text);
CREATE OR REPLACE FUNCTION public.complete_onboarding(
  p_full_name text,
  p_notification_prefs jsonb DEFAULT '{}'::jsonb,
  p_username text DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
  email text,
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
  v_clean_user text;
  v_name text := trim(p_full_name);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF v_name IS NULL OR char_length(v_name) = 0 THEN
    v_name := 'Student';
  END IF;

  IF p_notification_prefs IS NOT NULL AND jsonb_typeof(p_notification_prefs) <> 'object' THEN
    RAISE EXCEPTION 'Notification preferences must be a JSON object' USING ERRCODE = '22023';
  END IF;

  IF p_username IS NOT NULL THEN
    v_clean_user := trim(p_username);
    IF char_length(v_clean_user) < 3 OR char_length(v_clean_user) > 20 THEN
      RAISE EXCEPTION 'Username must be between 3 and 20 characters.' USING ERRCODE = '22023';
    END IF;
    IF NOT (v_clean_user ~ '^[A-Za-z][A-Za-z0-9_]{1,18}[A-Za-z0-9]$') THEN
      RAISE EXCEPTION 'Username must start with a letter, end with a letter or digit, and contain no spaces.' USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.users
      WHERE lower(username) = lower(v_clean_user) AND user_id <> v_uid
    ) THEN
      RAISE EXCEPTION 'Username is already taken' USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.users (
    user_id,
    full_name,
    username,
    onboarding_completed,
    notification_prefs
  )
  VALUES (
    v_uid,
    v_name,
    v_clean_user,
    true,
    COALESCE(p_notification_prefs, '{}'::jsonb)
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    full_name = COALESCE(v_name, public.users.full_name),
    username = COALESCE(v_clean_user, public.users.username),
    onboarding_completed = true,
    notification_prefs = EXCLUDED.notification_prefs,
    updated_at = now();

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.complete_onboarding(text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(text, jsonb, text) TO authenticated;
