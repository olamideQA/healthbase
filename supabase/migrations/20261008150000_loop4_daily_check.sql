-- ============================================================================
-- HealthBase Migration: Loop 4 — Daily Health Check Schema
--
-- Features:
--   - daily_checks (feeling, medication_status, check_date, unique per day)
--   - daily_check_symptoms (symptom_code, is_urgent, custom_description)
--   - measurements linked via measurements.daily_check_id
--   - Row Level Security scoped via app.can_access_profile
-- ============================================================================

-- ----------------------------------------------------------------- enums -----
create type public.check_feeling as enum (
  'good',
  'okay',
  'not_great',
  'unwell'
);

create type public.medication_status as enum (
  'yes',
  'no',
  'some',
  'none_scheduled'
);

-- ------------------------------------------------------------ daily_checks ---
create table public.daily_checks (
  id                uuid primary key default gen_random_uuid(),
  profile_id        uuid not null references public.health_profiles (id) on delete cascade,
  check_date        date not null default current_date,
  feeling           public.check_feeling not null,
  medication_status public.medication_status not null,
  notes             text,
  is_deleted        boolean not null default false,
  version           integer not null default 1,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint daily_checks_notes_len check (notes is null or char_length(notes) <= 1000)
);

-- Unique index per profile and date for non-deleted checks
create unique index daily_checks_profile_date_active_idx
  on public.daily_checks (profile_id, check_date)
  where not is_deleted;

create index daily_checks_profile_date_idx
  on public.daily_checks (profile_id, check_date desc);

-- ----------------------------------------------------- daily_check_symptoms --
create table public.daily_check_symptoms (
  id                 uuid primary key default gen_random_uuid(),
  daily_check_id     uuid not null references public.daily_checks (id) on delete cascade,
  symptom_code       text not null,
  is_urgent          boolean not null default false,
  custom_description text,
  created_at         timestamptz not null default now(),

  constraint symptoms_desc_len check (custom_description is null or char_length(custom_description) <= 500)
);

create index daily_check_symptoms_check_idx
  on public.daily_check_symptoms (daily_check_id);

-- Foreign key on measurements.daily_check_id
alter table public.measurements
  add constraint measurements_daily_check_fkey
  foreign key (daily_check_id)
  references public.daily_checks (id)
  on delete set null;

-- ------------------------------------------------------------- version trigger --
create or replace function app.set_daily_check_updated_at()
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

create trigger daily_checks_set_updated_at
  before update on public.daily_checks
  for each row execute function app.set_daily_check_updated_at();

-- ------------------------------------------------------------------- RLS -----
alter table public.daily_checks enable row level security;
alter table public.daily_checks force row level security;

alter table public.daily_check_symptoms enable row level security;
alter table public.daily_check_symptoms force row level security;

-- daily_checks RLS
create policy daily_checks_select
  on public.daily_checks for select
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'view')
  );

create policy daily_checks_insert
  on public.daily_checks for insert
  with check (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  );

create policy daily_checks_update
  on public.daily_checks for update
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  )
  with check (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'contribute')
  );

create policy daily_checks_delete
  on public.daily_checks for delete
  using (
    (select auth.role()) = 'authenticated'
    and app.can_access_profile(profile_id, 'manage')
  );

-- daily_check_symptoms RLS
create policy daily_check_symptoms_select
  on public.daily_check_symptoms for select
  using (
    (select auth.role()) = 'authenticated'
    and exists (
      select 1 from public.daily_checks dc
      where dc.id = daily_check_symptoms.daily_check_id
        and app.can_access_profile(dc.profile_id, 'view')
    )
  );

create policy daily_check_symptoms_insert
  on public.daily_check_symptoms for insert
  with check (
    (select auth.role()) = 'authenticated'
    and exists (
      select 1 from public.daily_checks dc
      where dc.id = daily_check_symptoms.daily_check_id
        and app.can_access_profile(dc.profile_id, 'contribute')
    )
  );

create policy daily_check_symptoms_update
  on public.daily_check_symptoms for update
  using (
    (select auth.role()) = 'authenticated'
    and exists (
      select 1 from public.daily_checks dc
      where dc.id = daily_check_symptoms.daily_check_id
        and app.can_access_profile(dc.profile_id, 'contribute')
    )
  )
  with check (
    (select auth.role()) = 'authenticated'
    and exists (
      select 1 from public.daily_checks dc
      where dc.id = daily_check_symptoms.daily_check_id
        and app.can_access_profile(dc.profile_id, 'contribute')
    )
  );

create policy daily_check_symptoms_delete
  on public.daily_check_symptoms for delete
  using (
    (select auth.role()) = 'authenticated'
    and exists (
      select 1 from public.daily_checks dc
      where dc.id = daily_check_symptoms.daily_check_id
        and app.can_access_profile(dc.profile_id, 'manage')
    )
  );

-- Grants
revoke all on public.daily_checks, public.daily_check_symptoms from anon, authenticated;
grant select, insert, update, delete on public.daily_checks, public.daily_check_symptoms to authenticated;
