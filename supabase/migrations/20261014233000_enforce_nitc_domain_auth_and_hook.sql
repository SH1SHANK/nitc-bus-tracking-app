-- ============================================================================
-- Migration: Enforce @nitc.ac.in Domain Restriction and Before User Created Hook
-- ============================================================================

-- 1. Helper function: Strict Domain and Syntax Validation for NITC Emails
CREATE OR REPLACE FUNCTION public.is_nitc_email(p_email text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_clean text := trim(lower(coalesce(p_email, '')));
  v_parts text[];
BEGIN
  IF v_clean = '' THEN
    RETURN false;
  END IF;

  -- Must contain exactly one '@' delimiter (no multiple '@' allowed)
  v_parts := string_to_array(v_clean, '@');
  IF array_length(v_parts, 1) <> 2 THEN
    RETURN false;
  END IF;

  -- Local-part must not be empty
  IF v_parts[1] = '' THEN
    RETURN false;
  END IF;

  -- Domain part must match 'nitc.ac.in' or any department subdomain '*.nitc.ac.in'
  IF v_parts[2] = 'nitc.ac.in' OR v_parts[2] LIKE '%.nitc.ac.in' THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- 2. Helper function: Server-side check for calling authenticated user
-- Validates against trusted auth.users table (not client-supplied claims)
CREATE OR REPLACE FUNCTION public.is_authorized_nitc_user()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_email_confirmed_at timestamptz;
BEGIN
  IF v_uid IS NULL THEN
    RETURN false;
  END IF;

  SELECT email, email_confirmed_at
  INTO v_email, v_email_confirmed_at
  FROM auth.users
  WHERE id = v_uid;

  -- Reject if email is null, unconfirmed, or does not belong to @nitc.ac.in
  IF v_email IS NULL OR v_email_confirmed_at IS NULL THEN
    RETURN false;
  END IF;

  RETURN public.is_nitc_email(v_email);
END;
$$;

-- 3. Update public.users RLS Policies to enforce NITC domain authorization
DROP POLICY IF EXISTS "Allow users to read their own profile" ON public.users;
CREATE POLICY "Allow users to read their own profile"
  ON public.users FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id AND public.is_authorized_nitc_user());

DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.users;
CREATE POLICY "Allow users to update their own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id AND public.is_authorized_nitc_user())
  WITH CHECK (auth.uid() = user_id AND public.is_authorized_nitc_user());

-- 4. Update Profile RPCs to reject unauthorized users at database level

-- 4.1 get_my_profile()
CREATE OR REPLACE FUNCTION public.get_my_profile()
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
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    u.user_id,
    u.full_name,
    u.department_id,
    d.department_name,
    u.batch,
    u.hostel,
    u.onboarding_completed,
    u.notification_prefs,
    u.created_at,
    u.updated_at
  FROM public.users u
  LEFT JOIN public.departments d ON d.department_id = u.department_id
  WHERE u.user_id = v_uid;
END;
$$;

-- 4.2 ensure_my_profile()
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

  SELECT NULLIF(trim(raw_user_meta_data->>'full_name'), '')
  INTO v_meta_name
  FROM auth.users
  WHERE id = v_uid;

  INSERT INTO public.users (user_id, full_name, onboarding_completed, notification_prefs)
  VALUES (v_uid, v_meta_name, false, '{}'::jsonb)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

-- 4.3 complete_onboarding(...)
CREATE OR REPLACE FUNCTION public.complete_onboarding(
  p_full_name text,
  p_department_id text,
  p_batch text,
  p_hostel text,
  p_notification_prefs jsonb DEFAULT '{}'::jsonb
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
  v_clean_name text := trim(COALESCE(p_full_name, ''));
  v_clean_batch text := trim(COALESCE(p_batch, ''));
  v_clean_hostel text := trim(COALESCE(p_hostel, ''));
  v_prefs jsonb := COALESCE(p_notification_prefs, '{}'::jsonb);
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  IF NOT public.is_authorized_nitc_user() THEN
    RAISE EXCEPTION 'Access restricted to verified @nitc.ac.in accounts.' USING ERRCODE = '42501';
  END IF;

  IF v_clean_name = '' THEN
    RAISE EXCEPTION 'Full name is required' USING ERRCODE = '22000';
  END IF;

  IF p_department_id IS NULL OR trim(p_department_id) = '' THEN
    RAISE EXCEPTION 'Department is required' USING ERRCODE = '22000';
  END IF;

  SELECT d.department_name INTO v_dept_name
  FROM public.departments d
  WHERE d.department_id = p_department_id;

  IF v_dept_name IS NULL THEN
    RAISE EXCEPTION 'Invalid department ID: %', p_department_id USING ERRCODE = '23503';
  END IF;

  IF v_clean_batch = '' THEN
    RAISE EXCEPTION 'Batch is required' USING ERRCODE = '22000';
  END IF;

  IF v_clean_hostel = '' THEN
    RAISE EXCEPTION 'Hostel is required' USING ERRCODE = '22000';
  END IF;

  IF jsonb_typeof(v_prefs) <> 'object' THEN
    RAISE EXCEPTION 'Notification preferences must be a JSON object' USING ERRCODE = '22023';
  END IF;

  -- Ensure record exists before updating
  INSERT INTO public.users (user_id, onboarding_completed)
  VALUES (v_uid, false)
  ON CONFLICT (user_id) DO NOTHING;

  UPDATE public.users
  SET
    full_name = v_clean_name,
    department_id = p_department_id,
    batch = v_clean_batch,
    hostel = v_clean_hostel,
    notification_prefs = v_prefs,
    onboarding_completed = true,
    updated_at = now()
  WHERE public.users.user_id = v_uid;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

-- 4.4 update_my_profile(...)
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

  UPDATE public.users
  SET
    full_name = CASE WHEN p_full_name IS NOT NULL THEN trim(p_full_name) ELSE public.users.full_name END,
    department_id = CASE WHEN p_department_id IS NOT NULL THEN p_department_id ELSE public.users.department_id END,
    batch = CASE WHEN p_batch IS NOT NULL THEN trim(p_batch) ELSE public.users.batch END,
    hostel = CASE WHEN p_hostel IS NOT NULL THEN trim(p_hostel) ELSE public.users.hostel END,
    notification_prefs = CASE WHEN p_notification_prefs IS NOT NULL THEN p_notification_prefs ELSE public.users.notification_prefs END,
    updated_at = now()
  WHERE public.users.user_id = v_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found' USING ERRCODE = 'P0002';
  END IF;

  RETURN QUERY SELECT * FROM public.get_my_profile();
END;
$$;

-- 5. Supabase Auth Before User Created Hook
CREATE OR REPLACE FUNCTION public.hook_before_user_created(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_email text;
  v_provider text;
  v_is_anonymous boolean;
  v_email_verified boolean;
  v_email_confirmed_at text;
BEGIN
  -- Extract provider
  v_provider := COALESCE(
    event->'user'->'app_metadata'->>'provider',
    event->'app_metadata'->>'provider',
    event->'user'->>'provider',
    ''
  );

  -- Extract is_anonymous
  v_is_anonymous := COALESCE(
    (event->'user'->>'is_anonymous')::boolean,
    (event->>'is_anonymous')::boolean,
    v_provider = 'anonymous',
    false
  );

  -- 1. Allow Anonymous Guest sign-ins
  IF v_is_anonymous IS TRUE OR v_provider = 'anonymous' THEN
    RETURN '{}'::jsonb;
  END IF;

  -- Extract email from incoming event payload (user object, identities, or metadata)
  v_email := COALESCE(
    event->'user'->>'email',
    event->>'email',
    event->'user'->'user_metadata'->>'email',
    event->'user'->'identities'->0->'identity_data'->>'email'
  );

  -- If no email is provided for a non-anonymous account, reject
  IF v_email IS NULL OR trim(v_email) = '' THEN
    RETURN jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Please sign in using your @nitc.ac.in institute email address.'
      )
    );
  END IF;

  -- 2. Validate complete domain strictly: must be @nitc.ac.in or department subdomain
  IF NOT public.is_nitc_email(v_email) THEN
    RETURN jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Please sign in using your @nitc.ac.in institute email address.'
      )
    );
  END IF;

  -- Extract email verification indicators
  v_email_confirmed_at := COALESCE(
    event->'user'->>'email_confirmed_at',
    event->>'email_confirmed_at'
  );

  v_email_verified := COALESCE(
    (event->'user'->'user_metadata'->>'email_verified')::boolean,
    (event->'user_metadata'->>'email_verified')::boolean,
    (event->'user'->'identities'->0->'identity_data'->>'email_verified')::boolean,
    false
  );

  -- 3. For Google OAuth registrations, verify that Google verified the email
  IF v_provider = 'google' THEN
    IF NOT (v_email_verified IS TRUE OR v_email_confirmed_at IS NOT NULL) THEN
      RETURN jsonb_build_object(
        'error', jsonb_build_object(
          'http_code', 403,
          'message', 'Google account email is not verified.'
        )
      );
    END IF;
  END IF;

  -- Allow user creation to proceed
  RETURN '{}'::jsonb;
END;
$$;

-- Permissions for Auth Hook
GRANT EXECUTE ON FUNCTION public.hook_before_user_created(jsonb) TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.hook_before_user_created(jsonb) FROM authenticated, anon, public;
