-- =============================================================================
-- HealthBase · Loop 11 · Family Health & Permission Controls
--
-- Features:
--   - Managed family profiles (Mum, Dad, Spouse, Grandparent, etc.)
--   - Non-biological relationships supported via custom relationship labels
--   - Explicit permission roles: 'view', 'contribute', 'manage'
--   - Database-level RLS: A person never automatically gains access
--   - Invite codes for sharing profiles with accept/reject/revoke lifecycle
--   - Instant revocation by profile owner
-- =============================================================================

-- 1. Extend health_profiles with relationship labels and managed flag
ALTER TABLE public.health_profiles
  ADD COLUMN IF NOT EXISTS relationship_label text,
  ADD COLUMN IF NOT EXISTS is_managed boolean NOT NULL DEFAULT true;

-- 2. Allow authenticated users to insert family profiles they own
CREATE POLICY health_profiles_insert_family ON public.health_profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    owner_account_id = (SELECT auth.uid())
    AND is_self = false
  );

-- Allow profile owner to delete family profiles
CREATE POLICY health_profiles_delete ON public.health_profiles
  FOR DELETE TO authenticated
  USING (
    owner_account_id = (SELECT auth.uid())
    AND is_self = false
  );

GRANT INSERT, DELETE ON public.health_profiles TO authenticated;

-- 3. Profile Invites table for secure sharing tokens
CREATE TABLE IF NOT EXISTS public.profile_invites (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id     uuid NOT NULL REFERENCES public.health_profiles (id) ON DELETE CASCADE,
  role           public.access_role NOT NULL DEFAULT 'view',
  invite_code    text NOT NULL UNIQUE,
  invited_email  text,
  created_by     uuid NOT NULL REFERENCES public.accounts (id) ON DELETE CASCADE,
  expires_at     timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  is_used        boolean NOT NULL DEFAULT false,
  used_by        uuid REFERENCES public.accounts (id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profile_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_invites FORCE ROW LEVEL SECURITY;

-- Invites RLS: Creator or manage-role can view created invites
CREATE POLICY profile_invites_select ON public.profile_invites
  FOR SELECT TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    OR app.can_access_profile(profile_id, 'manage')
  );

CREATE POLICY profile_invites_delete ON public.profile_invites
  FOR DELETE TO authenticated
  USING (
    created_by = (SELECT auth.uid())
    OR app.can_access_profile(profile_id, 'manage')
  );

-- Deny-by-default first (no anon access, narrow authenticated grants).
REVOKE ALL ON public.profile_invites FROM anon, authenticated;

GRANT SELECT, DELETE ON public.profile_invites TO authenticated;

-- 4. Enable INSERT and UPDATE on profile_access for authenticated users
CREATE POLICY profile_access_insert ON public.profile_access
  FOR INSERT TO authenticated
  WITH CHECK (
    app.can_access_profile(profile_id, 'manage')
  );

-- NOTE: grantees can NOT update their own grant (that arm would let a
-- 'view' grantee promote itself to 'manage'). Accept/decline flows go
-- through the SECURITY DEFINER accept_profile_invite() RPC instead.
CREATE POLICY profile_access_update ON public.profile_access
  FOR UPDATE TO authenticated
  USING (
    app.can_access_profile(profile_id, 'manage')
  )
  WITH CHECK (
    app.can_access_profile(profile_id, 'manage')
  );

CREATE POLICY profile_access_delete ON public.profile_access
  FOR DELETE TO authenticated
  USING (
    exists (
      SELECT 1 FROM public.health_profiles hp
      WHERE hp.id = profile_access.profile_id
        AND hp.owner_account_id = (SELECT auth.uid())
    )
  );

GRANT INSERT, UPDATE, DELETE ON public.profile_access TO authenticated;

-- 5. Secure RPC: create_profile_invite
CREATE OR REPLACE FUNCTION public.create_profile_invite(
  p_profile_id uuid,
  p_role public.access_role,
  p_invited_email text DEFAULT NULL
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_code text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING errcode = '42501';
  END IF;

  -- Verify user has 'manage' permission on the target profile
  IF NOT app.can_access_profile(p_profile_id, 'manage') THEN
    RAISE EXCEPTION 'Permission denied: manage permission required to share profile' USING errcode = '42501';
  END IF;

  -- Generate a 128-bit random invite code (32 hex chars). Short 8-char
  -- codes are brute-forceable and must not be used.
  v_code := upper(encode(extensions.gen_random_bytes(16), 'hex'));

  INSERT INTO public.profile_invites (
    profile_id,
    role,
    invite_code,
    invited_email,
    created_by
  ) VALUES (
    p_profile_id,
    p_role,
    v_code,
    nullif(btrim(p_invited_email), ''),
    v_uid
  );

  RETURN v_code;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_profile_invite(uuid, public.access_role, text) TO authenticated;

-- 6. Secure RPC: accept_profile_invite
CREATE OR REPLACE FUNCTION public.accept_profile_invite(
  p_invite_code text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_invite public.profile_invites%ROWTYPE;
  v_profile public.health_profiles%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING errcode = '42501';
  END IF;

  SELECT * INTO v_invite
  FROM public.profile_invites
  WHERE invite_code = upper(btrim(p_invite_code));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid invite code.' USING errcode = 'P0002';
  END IF;

  IF v_invite.is_used THEN
    RAISE EXCEPTION 'This invite code has already been used.' USING errcode = 'P0001';
  END IF;

  IF v_invite.expires_at < now() THEN
    RAISE EXCEPTION 'This invite code has expired.' USING errcode = 'P0001';
  END IF;

  -- Enforce the invited email when the inviter set one.
  IF v_invite.invited_email IS NOT NULL
    AND lower(v_invite.invited_email) <> lower(coalesce(auth.email(), '')) THEN
    RAISE EXCEPTION 'This invite was sent to a different email address.' USING errcode = '42501';
  END IF;

  -- Ensure user is not accepting their own profile invite
  IF v_invite.created_by = v_uid THEN
    RAISE EXCEPTION 'You cannot accept an invite for your own profile.' USING errcode = 'P0001';
  END IF;

  -- Upsert profile_access record with 'active' status
  INSERT INTO public.profile_access (
    profile_id,
    grantee_account_id,
    role,
    status,
    granted_by
  ) VALUES (
    v_invite.profile_id,
    v_uid,
    v_invite.role,
    'active',
    v_invite.created_by
  )
  ON CONFLICT (profile_id, grantee_account_id)
  DO UPDATE SET
    role = EXCLUDED.role,
    status = 'active',
    granted_by = EXCLUDED.granted_by,
    updated_at = now();

  -- Mark invite as used
  UPDATE public.profile_invites
  SET is_used = true,
      used_by = v_uid
  WHERE id = v_invite.id;

  SELECT * INTO v_profile
  FROM public.health_profiles
  WHERE id = v_invite.profile_id;

  RETURN jsonb_build_object(
    'profile_id', v_profile.id,
    'display_name', v_profile.display_name,
    'role', v_invite.role
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_profile_invite(text) TO authenticated;

-- 7. Secure RPC: revoke_profile_access
CREATE OR REPLACE FUNCTION public.revoke_profile_access(
  p_access_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_access public.profile_access%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING errcode = '42501';
  END IF;

  SELECT * INTO v_access
  FROM public.profile_access
  WHERE id = p_access_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile access grant not found.' USING errcode = 'P0002';
  END IF;

  -- Must be profile owner to revoke
  IF NOT EXISTS (
    SELECT 1 FROM public.health_profiles hp
    WHERE hp.id = v_access.profile_id
      AND hp.owner_account_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Permission denied: Only the profile owner can revoke access.' USING errcode = '42501';
  END IF;

  UPDATE public.profile_access
  SET status = 'revoked',
      updated_at = now()
  WHERE id = p_access_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_profile_access(uuid) TO authenticated;
