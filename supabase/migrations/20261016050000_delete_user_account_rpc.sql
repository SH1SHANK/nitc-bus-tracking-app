-- Migration: Add delete_user_account RPC function
-- Allows authenticated users to permanently delete their own account and profile data.
-- Enforces authentication, strict security definer with pinned search_path, and cascading deletion.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  -- 1. Ensure user is authenticated
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- 2. Delete user profile record in public schema
  DELETE FROM public.users WHERE user_id = v_uid;

  -- 3. Delete auth account in auth.users (cascades to identities, sessions, mfa, etc.)
  DELETE FROM auth.users WHERE id = v_uid;

  RETURN jsonb_build_object(
    'ok', true,
    'message', 'User account permanently deleted.'
  );
END;
$$;

-- Secure grants: authenticated users only
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM anon, public;

COMMENT ON FUNCTION public.delete_user_account() IS 'Permanently deletes the currently authenticated user profile and auth account.';
