-- =============================================================================
-- HealthBase · Loop 1 · Identity foundation
--
-- accounts         : one row per login (id = auth.users.id)
-- health_profiles  : a person whose health is tracked. The account holder's own
--                    profile has is_self = true. Dependent/family profiles arrive
--                    in Loop 11 and reuse this table unchanged.
-- profile_access   : explicit sharing grants (populated in Loop 11). Created now
--                    so every RLS policy is written once against
--                    app.can_access_profile() and never rewritten.
--
-- Security posture: RLS enabled and deny-by-default on every table, anon has no
-- table privileges, authenticated has column-scoped UPDATE only where needed.
-- =============================================================================

create schema if not exists app;
revoke all on schema app from public;
grant usage on schema app to authenticated;

-- ---------------------------------------------------------------- enums ------
create type public.sex_type as enum ('female', 'male', 'intersex', 'prefer_not_to_say');
create type public.unit_system as enum ('metric', 'imperial');
create type public.access_role as enum ('view', 'contribute', 'manage');
create type public.access_status as enum ('pending', 'active', 'revoked');

-- ---------------------------------------------------------------- helpers ----
create or replace function app.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function app.role_rank(p_role public.access_role)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'view' then 1
    when 'contribute' then 2
    when 'manage' then 3
  end;
$$;

-- ---------------------------------------------------------------- accounts ---
create table public.accounts (
  id               uuid primary key references auth.users (id) on delete cascade,
  preferred_units  public.unit_system not null default 'metric',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create trigger accounts_set_updated_at
  before update on public.accounts
  for each row execute function app.set_updated_at();

-- --------------------------------------------------------- health_profiles ---
create table public.health_profiles (
  id                       uuid primary key default gen_random_uuid(),
  owner_account_id         uuid not null references public.accounts (id) on delete cascade,
  is_self                  boolean not null default false,
  display_name             text check (display_name is null or char_length(btrim(display_name)) between 1 and 80),
  date_of_birth            date check (date_of_birth is null or date_of_birth >= date '1900-01-01'),
  sex                      public.sex_type,
  height_cm                numeric(4, 1) check (height_cm is null or height_cm between 40 and 260),
  weight_kg                numeric(4, 1) check (weight_kg is null or weight_kg between 1 and 400),
  onboarding_completed_at  timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create unique index health_profiles_one_self_per_account
  on public.health_profiles (owner_account_id) where is_self;
create index health_profiles_owner_idx on public.health_profiles (owner_account_id);

create trigger health_profiles_set_updated_at
  before update on public.health_profiles
  for each row execute function app.set_updated_at();

-- date_of_birth upper bound needs current_date, which is not immutable, so it is
-- enforced by trigger rather than CHECK.
create or replace function app.validate_health_profile()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.date_of_birth is not null and new.date_of_birth > current_date then
    raise exception 'date_of_birth cannot be in the future' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger health_profiles_validate
  before insert or update on public.health_profiles
  for each row execute function app.validate_health_profile();

-- ---------------------------------------------------------- profile_access ---
create table public.profile_access (
  id                  uuid primary key default gen_random_uuid(),
  profile_id          uuid not null references public.health_profiles (id) on delete cascade,
  grantee_account_id  uuid not null references public.accounts (id) on delete cascade,
  role                public.access_role not null,
  status              public.access_status not null default 'pending',
  granted_by          uuid references public.accounts (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (profile_id, grantee_account_id)
);

create index profile_access_grantee_idx on public.profile_access (grantee_account_id);

create trigger profile_access_set_updated_at
  before update on public.profile_access
  for each row execute function app.set_updated_at();

-- ------------------------------------------------------- authorization core --
-- Single source of truth for "may the current user access this profile at
-- least at role X". SECURITY DEFINER so it can read profile ownership/grants
-- without recursing through RLS.
create or replace function app.can_access_profile(p_profile_id uuid, p_min_role public.access_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
           select 1
           from public.health_profiles hp
           where hp.id = p_profile_id
             and hp.owner_account_id = (select auth.uid())
         )
      or exists (
           select 1
           from public.profile_access pa
           where pa.profile_id = p_profile_id
             and pa.grantee_account_id = (select auth.uid())
             and pa.status = 'active'
             and app.role_rank(pa.role) >= app.role_rank(p_min_role)
         );
$$;

-- --------------------------------------------------------- signup trigger ----
create or replace function app.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := nullif(btrim(new.raw_user_meta_data ->> 'display_name'), '');
begin
  if v_name is not null and char_length(v_name) > 80 then
    v_name := left(v_name, 80);
  end if;

  insert into public.accounts (id) values (new.id);

  insert into public.health_profiles (owner_account_id, is_self, display_name)
  values (new.id, true, v_name);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- -------------------------------------------------------- account deletion ---
-- Required by Apple App Store and Google Play. Cascades to accounts,
-- health_profiles, profile_access and (in later loops) all health records.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  delete from auth.users where id = v_uid;
end;
$$;

-- ---------------------------------------------------------------- RLS --------
alter table public.accounts        enable row level security;
alter table public.health_profiles enable row level security;
alter table public.profile_access  enable row level security;

alter table public.accounts        force row level security;
alter table public.health_profiles force row level security;
alter table public.profile_access  force row level security;

-- accounts: read and update own row only. Rows are created by the signup
-- trigger and removed by delete_my_account(); clients can do neither.
create policy accounts_select_own on public.accounts
  for select to authenticated
  using (id = (select auth.uid()));

create policy accounts_update_own on public.accounts
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- health_profiles: visibility and edits flow through can_access_profile().
create policy health_profiles_select on public.health_profiles
  for select to authenticated
  using (app.can_access_profile(id, 'view'));

create policy health_profiles_update on public.health_profiles
  for update to authenticated
  using (app.can_access_profile(id, 'manage'))
  with check (app.can_access_profile(id, 'manage'));

-- profile_access: grantee and profile owner may see a grant. Mutations are
-- added in Loop 11 via audited RPCs.
create policy profile_access_select on public.profile_access
  for select to authenticated
  using (
    grantee_account_id = (select auth.uid())
    or exists (
      select 1 from public.health_profiles hp
      where hp.id = profile_access.profile_id
        and hp.owner_account_id = (select auth.uid())
    )
  );

-- ---------------------------------------------------------------- grants -----
-- Supabase grants broad table privileges by default; narrow them explicitly.
revoke all on public.accounts, public.health_profiles, public.profile_access from anon, authenticated;

grant select on public.accounts to authenticated;
grant update (preferred_units) on public.accounts to authenticated;

grant select on public.health_profiles to authenticated;
grant update (display_name, date_of_birth, sex, height_cm, weight_kg, onboarding_completed_at)
  on public.health_profiles to authenticated;

grant select on public.profile_access to authenticated;

revoke all on function app.set_updated_at() from public;
revoke all on function app.validate_health_profile() from public;
revoke all on function app.handle_new_user() from public;
revoke all on function app.role_rank(public.access_role) from public;
revoke all on function app.can_access_profile(uuid, public.access_role) from public;
grant execute on function app.role_rank(public.access_role) to authenticated;
grant execute on function app.can_access_profile(uuid, public.access_role) to authenticated;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
