-- ============================================================================
-- Tracklet Migration: Departments, User Profiles, Auth Trigger & Profile RPCs
-- ============================================================================

-- 1. Create public.departments Table
CREATE TABLE IF NOT EXISTS public.departments (
  department_id text NOT NULL,
  department_name text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT departments_pkey PRIMARY KEY (department_id),
  CONSTRAINT departments_name_unique UNIQUE (department_name)
);

-- Seed 21 Canonical Departments idempotently
INSERT INTO public.departments (department_id, department_name)
VALUES
  ('AR', 'Architecture & Planning'),
  ('BT', 'Biotechnology'),
  ('CA', 'Fine Arts & Cultural Activities'),
  ('CE', 'Civil Engineering'),
  ('CH', 'Chemical Engineering'),
  ('CS', 'Computer Science & Engineering'),
  ('CY', 'Chemistry'),
  ('EC', 'Electronics & Communication Engineering'),
  ('EE', 'Electrical Engineering'),
  ('EN', 'Energy Engineering'),
  ('EP', 'Engineering Physics'),
  ('GS', 'Global Studies'),
  ('HS', 'Humanities & Social Sciences'),
  ('IE', 'Industrial Engineering'),
  ('IK', 'Indian Knowledge Systems'),
  ('MA', 'Mathematics'),
  ('ME', 'Mechanical Engineering'),
  ('MS', 'Materials Science & Engineering'),
  ('MT', 'Metallurgical & Materials Engineering'),
  ('PE', 'Production Engineering'),
  ('PH', 'Physics')
ON CONFLICT (department_id) DO UPDATE SET
  department_name = EXCLUDED.department_name;

-- 2. Create public.users Table
CREATE TABLE IF NOT EXISTS public.users (
  user_id uuid NOT NULL,
  full_name text NULL,
  department_id text NULL,
  batch text NULL,
  hostel text NULL,
  onboarding_completed boolean NOT NULL DEFAULT false,
  notification_prefs jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (user_id),
  CONSTRAINT users_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id)
    REFERENCES public.departments(department_id) ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT users_notification_prefs_is_object CHECK (jsonb_typeof(notification_prefs) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_users_department_id ON public.users (department_id);

-- Attach updated_at trigger using existing public.set_updated_at()
DROP TRIGGER IF EXISTS trg_users_set_updated_at ON public.users;
CREATE TRIGGER trg_users_set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- 3. Auth Trigger to Provision Profile on New User Registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_full_name text;
BEGIN
  v_full_name := NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), '');

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
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user failed for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill missing public.users for any existing auth.users
INSERT INTO public.users (user_id, full_name, created_at, updated_at)
SELECT
  id,
  NULLIF(trim(raw_user_meta_data->>'full_name'), ''),
  COALESCE(created_at, now()),
  COALESCE(created_at, now())
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- 4. RPC Functions

-- 4.1 get_departments()
CREATE OR REPLACE FUNCTION public.get_departments()
RETURNS TABLE(
  department_id text,
  department_name text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
  SELECT d.department_id, d.department_name
  FROM public.departments d
  ORDER BY d.department_name ASC;
$$;

-- 4.2 get_my_profile()
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

-- 4.3 ensure_my_profile()
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

-- 4.4 complete_onboarding(...)
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

-- 4.5 update_my_profile(...)
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

-- 5. Row Level Security & Grants

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Department Policies
DROP POLICY IF EXISTS "Allow public read access for departments" ON public.departments;
CREATE POLICY "Allow public read access for departments"
  ON public.departments FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "Allow service role full access on departments" ON public.departments;
CREATE POLICY "Allow service role full access on departments"
  ON public.departments FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- User Policies
DROP POLICY IF EXISTS "Allow users to read their own profile" ON public.users;
CREATE POLICY "Allow users to read their own profile"
  ON public.users FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.users;
CREATE POLICY "Allow users to update their own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow service role full access on users" ON public.users;
CREATE POLICY "Allow service role full access on users"
  ON public.users FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Function Grants
REVOKE ALL ON FUNCTION public.get_departments() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_departments() TO anon, authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.ensure_my_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ensure_my_profile() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(text, text, text, text, jsonb) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.update_my_profile(text, text, text, text, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_my_profile(text, text, text, text, jsonb) TO authenticated, service_role;
