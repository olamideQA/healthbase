-- Migration: Loop 10 Medication Tracker and Adherence
-- Description: Creates medications and medication_events tables with RLS through can_access_profile()

CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
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
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
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

-- Enable Row Level Security
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies using can_access_profile
CREATE POLICY "medications_select_policy" ON public.medications
    FOR SELECT TO authenticated
    USING (public.can_access_profile(profile_id));

CREATE POLICY "medications_insert_policy" ON public.medications
    FOR INSERT TO authenticated
    WITH CHECK (public.can_access_profile(profile_id));

CREATE POLICY "medications_update_policy" ON public.medications
    FOR UPDATE TO authenticated
    USING (public.can_access_profile(profile_id))
    WITH CHECK (public.can_access_profile(profile_id));

CREATE POLICY "medications_delete_policy" ON public.medications
    FOR DELETE TO authenticated
    USING (public.can_access_profile(profile_id));

CREATE POLICY "medication_events_select_policy" ON public.medication_events
    FOR SELECT TO authenticated
    USING (public.can_access_profile(profile_id));

CREATE POLICY "medication_events_insert_policy" ON public.medication_events
    FOR INSERT TO authenticated
    WITH CHECK (public.can_access_profile(profile_id));

CREATE POLICY "medication_events_update_policy" ON public.medication_events
    FOR UPDATE TO authenticated
    USING (public.can_access_profile(profile_id))
    WITH CHECK (public.can_access_profile(profile_id));

CREATE POLICY "medication_events_delete_policy" ON public.medication_events
    FOR DELETE TO authenticated
    USING (public.can_access_profile(profile_id));

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medication_events TO authenticated;
