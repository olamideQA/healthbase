-- Migration: Loop 10 Medication Tracker and Adherence
-- Description: Creates medications and medication_events tables with RLS through
-- app.can_access_profile(). RLS is deny-by-default (FORCE) like Loops 1/3/4.
--
-- NOTE (fixed): profile FK points at health_profiles (not a `profiles`
-- table), and policies pass an explicit minimum role to
-- app.can_access_profile(uuid, role).

CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.health_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL, -- Free text entered by user, never calculated
    frequency TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    reminder_time TEXT,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.medication_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.health_profiles(id) ON DELETE CASCADE,
    medication_id UUID NOT NULL REFERENCES public.medications(id) ON DELETE CASCADE,
    scheduled_time TIMESTAMPTZ NOT NULL,
    recorded_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('taken', 'missed', 'not_recorded')),
    notes TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_medications_profile_active ON public.medications(profile_id, is_active) WHERE NOT is_deleted;
CREATE INDEX IF NOT EXISTS idx_medication_events_medication ON public.medication_events(medication_id, scheduled_time) WHERE NOT is_deleted;
CREATE INDEX IF NOT EXISTS idx_medication_events_profile_date ON public.medication_events(profile_id, scheduled_time) WHERE NOT is_deleted;

-- Server-owned updated_at + version, mirroring Loops 3/4.
CREATE OR REPLACE FUNCTION app.set_medication_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  NEW.version = coalesce(OLD.version, 0) + 1;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS medications_set_updated_at ON public.medications;
CREATE TRIGGER medications_set_updated_at
  BEFORE UPDATE ON public.medications
  FOR EACH ROW EXECUTE FUNCTION app.set_medication_updated_at();

DROP TRIGGER IF EXISTS medication_events_set_updated_at ON public.medication_events;
CREATE TRIGGER medication_events_set_updated_at
  BEFORE UPDATE ON public.medication_events
  FOR EACH ROW EXECUTE FUNCTION app.set_medication_updated_at();

-- Enable Row Level Security (forced: table owners get no bypass).
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications FORCE ROW LEVEL SECURITY;
ALTER TABLE public.medication_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_events FORCE ROW LEVEL SECURITY;

-- Narrow the default grants first (deny-by-default).
REVOKE ALL ON public.medications, public.medication_events FROM anon, authenticated;

-- RLS Policies using app.can_access_profile with explicit minimum roles.
CREATE POLICY "medications_select_policy" ON public.medications
    FOR SELECT TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'view')
    );

CREATE POLICY "medications_insert_policy" ON public.medications
    FOR INSERT TO authenticated
    WITH CHECK (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    );

CREATE POLICY "medications_update_policy" ON public.medications
    FOR UPDATE TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    )
    WITH CHECK (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    );

CREATE POLICY "medications_delete_policy" ON public.medications
    FOR DELETE TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'manage')
    );

CREATE POLICY "medication_events_select_policy" ON public.medication_events
    FOR SELECT TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'view')
    );

CREATE POLICY "medication_events_insert_policy" ON public.medication_events
    FOR INSERT TO authenticated
    WITH CHECK (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    );

CREATE POLICY "medication_events_update_policy" ON public.medication_events
    FOR UPDATE TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    )
    WITH CHECK (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'contribute')
    );

CREATE POLICY "medication_events_delete_policy" ON public.medication_events
    FOR DELETE TO authenticated
    USING (
      (SELECT auth.role()) = 'authenticated'
      AND app.can_access_profile(profile_id, 'manage')
    );

-- Grant permissions to authenticated users (RLS still enforced).
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medication_events TO authenticated;
