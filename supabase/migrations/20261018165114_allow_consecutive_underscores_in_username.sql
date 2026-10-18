-- ============================================================================
-- Migration: 20261018165000_allow_consecutive_underscores_in_username.sql
-- Allow consecutive underscores ('__') in usernames.
--
-- Requirements:
-- - Length: 3 to 20 characters
-- - Allowed: ASCII letters, digits, underscores
-- - Starts with letter
-- - Ends with letter or digit (cannot start or end with underscore)
-- - Consecutive underscores are permitted
-- - No spaces
-- ============================================================================

-- 1. Update CHECK constraint on public.users
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_username_format;
ALTER TABLE public.users ADD CONSTRAINT users_username_format
  CHECK (
    username IS NULL OR (
      char_length(username) >= 3 AND
      char_length(username) <= 20 AND
      username ~ '^[A-Za-z][A-Za-z0-9_]{1,18}[A-Za-z0-9]$'
    )
  );

-- 2. Update RPC: check_username_available
CREATE OR REPLACE FUNCTION public.check_username_available(p_username text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_clean text := lower(trim(p_username));
  v_uid uuid := auth.uid();
BEGIN
  IF v_clean IS NULL OR char_length(v_clean) < 3 OR char_length(v_clean) > 20 THEN
    RETURN false;
  END IF;

  IF NOT (v_clean ~ '^[a-z][a-z0-9_]{1,18}[a-z0-9]$') THEN
    RETURN false;
  END IF;

  RETURN NOT EXISTS (
    SELECT 1
    FROM public.users
    WHERE lower(username) = v_clean
      AND (v_uid IS NULL OR user_id <> v_uid)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_username_available(text) TO anon, authenticated;

-- 3. Update RPC: change_my_username
CREATE OR REPLACE FUNCTION public.change_my_username(p_username text)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
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
  v_clean text := trim(p_username);
  v_lower text := lower(v_clean);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
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

-- 4. Update RPC: update_my_profile
CREATE OR REPLACE FUNCTION public.update_my_profile(
  p_full_name text DEFAULT NULL,
  p_department_id text DEFAULT NULL,
  p_batch text DEFAULT NULL,
  p_hostel text DEFAULT NULL,
  p_notification_prefs jsonb DEFAULT NULL,
  p_username text DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
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
  v_clean_user text;
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
    department_id = CASE WHEN p_department_id IS NOT NULL THEN p_department_id ELSE public.users.department_id END,
    batch = CASE WHEN p_batch IS NOT NULL THEN trim(p_batch) ELSE public.users.batch END,
    hostel = CASE WHEN p_hostel IS NOT NULL THEN trim(p_hostel) ELSE public.users.hostel END,
    notification_prefs = CASE WHEN p_notification_prefs IS NOT NULL THEN p_notification_prefs ELSE public.users.notification_prefs END,
    username = CASE WHEN p_username IS NOT NULL THEN v_clean_user ELSE public.users.username END,
    updated_at = now()
  WHERE public.users.user_id = v_uid;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.update_my_profile(text, text, text, text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_my_profile(text, text, text, text, jsonb, text) TO authenticated;

-- 5. Update RPC: complete_onboarding
CREATE OR REPLACE FUNCTION public.complete_onboarding(
  p_full_name text,
  p_department_id text,
  p_batch text,
  p_hostel text,
  p_notification_prefs jsonb DEFAULT '{}'::jsonb,
  p_username text DEFAULT NULL
)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  username text,
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
  v_clean_user text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  IF p_full_name IS NULL OR trim(p_full_name) = '' THEN
    RAISE EXCEPTION 'Full name is required' USING ERRCODE = '22023';
  END IF;

  SELECT d.department_name INTO v_dept_name
  FROM public.departments d
  WHERE d.department_id = p_department_id;

  IF v_dept_name IS NULL THEN
    RAISE EXCEPTION 'Invalid department ID: %', p_department_id USING ERRCODE = '23503';
  END IF;

  IF p_batch IS NULL OR trim(p_batch) = '' THEN
    RAISE EXCEPTION 'Batch is required' USING ERRCODE = '22023';
  END IF;

  IF p_hostel IS NULL OR trim(p_hostel) = '' THEN
    RAISE EXCEPTION 'Hostel is required' USING ERRCODE = '22023';
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
    department_id,
    batch,
    hostel,
    onboarding_completed,
    notification_prefs,
    updated_at
  )
  VALUES (
    v_uid,
    trim(p_full_name),
    v_clean_user,
    p_department_id,
    trim(p_batch),
    trim(p_hostel),
    true,
    COALESCE(p_notification_prefs, '{}'::jsonb),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    username = COALESCE(EXCLUDED.username, public.users.username),
    department_id = EXCLUDED.department_id,
    batch = EXCLUDED.batch,
    hostel = EXCLUDED.hostel,
    onboarding_completed = true,
    notification_prefs = EXCLUDED.notification_prefs,
    updated_at = now();

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb, text) TO authenticated;
