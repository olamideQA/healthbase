-- ============================================================================
-- HealthBase Migration: Loop 3 — Measurement Engine & Sync Schema
--
-- Strictly complies with:
--   - Industry standard health logging
--   - Idempotent UUID primary keys
--   - Canonical scientific storage units
--   - Strict physical plausibility CHECK constraints
--   - Soft deletes (tombstones) & versioning for offline-first sync
--   - Profile-scoped Row-Level Security
-- ============================================================================

-- ----------------------------------------------------------------- enums -----
create type public.measurement_type as enum (
  'heart_rate',
  'blood_pressure',
  'temperature',
  'weight',
  'blood_glucose'
);

create type public.measurement_source as enum (
  'manual',
  'camera',
  'device',
  'import'
);

create type public.measurement_provenance as enum (
  'measured',
  'manually_entered',
  'estimated'
);

-- ----------------------------------------------------------- measurements ----
create table public.measurements (
  id                  uuid primary key default gen_random_uuid(),
  profile_id          uuid not null references public.health_profiles (id) on delete cascade,
  type                public.measurement_type not null,

  -- Typed canonical metrics
  heart_rate_bpm      numeric(5, 1),
  systolic_mmhg       numeric(5, 1),
  diastolic_mmhg      numeric(5, 1),
  pulse_bpm           numeric(5, 1),
  temperature_celsius numeric(4, 2),
  weight_kg           numeric(5, 2),
  glucose_mmol_l      numeric(5, 2),

  -- Provenance & Context
  source              public.measurement_source not null default 'manual',
  provenance          public.measurement_provenance not null default 'manually_entered',
  quality             jsonb,
  recorded_at         timestamptz not null default now(),
  recorded_utc_offset integer not null default 0,
  notes               text,
  daily_check_id      uuid,

  -- Sync & Tombstone Tracking
  is_deleted          boolean not null default false,
  version             integer not null default 1,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  -- Notes length constraint
  constraint measurements_notes_length check (notes is null or char_length(notes) <= 1000),

  -- Mandatory typed columns per measurement type
  constraint measurements_type_columns_check check (
    case type
      when 'heart_rate'      then heart_rate_bpm is not null
      when 'blood_pressure'  then systolic_mmhg is not null and diastolic_mmhg is not null
      when 'temperature'     then temperature_celsius is not null
      when 'weight'          then weight_kg is not null
      when 'blood_glucose'   then glucose_mmol_l is not null
    end
  ),

  -- Physical plausibility bounds (derived from SafetyBoundaries)
  constraint bounds_heart_rate check (
    heart_rate_bpm is null or (heart_rate_bpm >= 25.0 and heart_rate_bpm <= 260.0)
  ),
  constraint bounds_systolic check (
    systolic_mmhg is null or (systolic_mmhg >= 50.0 and systolic_mmhg <= 280.0)
  ),
  constraint bounds_diastolic check (
    diastolic_mmhg is null or (diastolic_mmhg >= 30.0 and diastolic_mmhg <= 180.0)
  ),
  constraint bounds_pulse check (
    pulse_bpm is null or (pulse_bpm >= 25.0 and pulse_bpm <= 260.0)
  ),
  constraint bounds_temperature check (
    temperature_celsius is null or (temperature_celsius >= 30.0 and temperature_celsius <= 45.0)
  ),
  constraint bounds_weight check (
    weight_kg is null or (weight_kg >= 1.0 and weight_kg <= 400.0)
  ),
  constraint bounds_glucose check (
    glucose_mmol_l is null or (glucose_mmol_l >= 0.5 and glucose_mmol_l <= 40.0)
  ),
  constraint bounds_bp_systolic_higher check (
    systolic_mmhg is null or diastolic_mmhg is null or systolic_mmhg > diastolic_mmhg
  )
);

-- --------------------------------------------------------------- indexes -----
create index measurements_profile_recorded_idx 
  on public.measurements (profile_id, recorded_at desc);

create index measurements_profile_type_recorded_idx 
  on public.measurements (profile_id, type, recorded_at desc);

create index measurements_sync_cursor_idx 
  on public.measurements (profile_id, updated_at asc);

-- ------------------------------------------------------------- version trigger --
create or replace function app.set_measurement_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  new.version = coalesce(old.version, 0) + 1;
  return new;
end;
$$;

create trigger measurements_set_updated_at
  before update on public.measurements
  for each row execute function app.set_measurement_updated_at();

-- ------------------------------------------------------------------- RLS -----
alter table public.measurements enable row level security;
alter table public.measurements force row level security;

-- SELECT: permitted if caller has 'view' access to the profile
create policy measurements_select
  on public.measurements
  for select
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'view')
  );

-- INSERT: permitted if caller has 'contribute' access to the profile
create policy measurements_insert
  on public.measurements
  for insert
  with check (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  );

-- UPDATE: permitted if caller has 'contribute' access to the profile
create policy measurements_update
  on public.measurements
  for update
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  )
  with check (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  );

-- DELETE: permitted if caller has 'manage' access to the profile
create policy measurements_delete
  on public.measurements
  for delete
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'manage')
  );
