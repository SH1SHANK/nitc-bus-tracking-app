-- Migration: 20261019230000_make_onboarding_fields_optional.sql
-- Description: Allow complete_onboarding to succeed when academic details are not supplied during onboarding.

CREATE OR REPLACE FUNCTION public.complete_onboarding(
  p_full_name text DEFAULT NULL,
  p_department_id text DEFAULT NULL,
  p_batch text DEFAULT NULL,
  p_hostel text DEFAULT NULL,
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
  v_name text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  v_name := NULLIF(trim(p_full_name), '');
  IF v_name IS NULL THEN
    SELECT COALESCE(NULLIF(trim(users.full_name), ''), 'Student') INTO v_name
    FROM public.users WHERE users.user_id = v_uid;
  END IF;
  IF v_name IS NULL THEN
    v_name := 'Student';
  END IF;

  IF p_department_id IS NOT NULL AND trim(p_department_id) <> '' THEN
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
      WHERE lower(users.username) = lower(v_clean_user) AND users.user_id <> v_uid
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
    v_name,
    v_clean_user,
    NULLIF(trim(p_department_id), ''),
    NULLIF(trim(p_batch), ''),
    NULLIF(trim(p_hostel), ''),
    true,
    COALESCE(p_notification_prefs, '{}'::jsonb),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = COALESCE(v_name, public.users.full_name),
    username = COALESCE(EXCLUDED.username, public.users.username),
    department_id = COALESCE(EXCLUDED.department_id, public.users.department_id),
    batch = COALESCE(EXCLUDED.batch, public.users.batch),
    hostel = COALESCE(EXCLUDED.hostel, public.users.hostel),
    onboarding_completed = true,
    notification_prefs = EXCLUDED.notification_prefs,
    updated_at = now();

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

REVOKE ALL ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb, text) TO authenticated;
