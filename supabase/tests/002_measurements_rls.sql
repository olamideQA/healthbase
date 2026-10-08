-- ============================================================================
-- Supabase SQL Test Suite: 002_measurements_rls.sql
--
-- Tests:
-- 1. Check constraints on plausibility bounds and required typed columns
-- 2. RLS isolation: User A cannot see User B's measurements
-- 3. Anonymous role is completely denied
-- 4. Version increment trigger on update
-- ============================================================================

begin;

-- Fixtures: Create test users in auth.users (triggers create accounts & health_profiles)
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
                        created_at, updated_at)
values
  ('00000000-0000-4000-a000-00000000001a', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'meas-user-a@test.invalid', '', now(),
   '{"display_name":"User A"}', '{}', now(), now()),
  ('00000000-0000-4000-a000-00000000001b', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'meas-user-b@test.invalid', '', now(),
   '{"display_name":"User B"}', '{}', now(), now());

do $$
declare
  v_user_a uuid := '00000000-0000-4000-a000-00000000001a';
  v_user_b uuid := '00000000-0000-4000-a000-00000000001b';
  v_prof_a uuid;
  v_prof_b uuid;
  v_meas_id uuid;
  v_count integer;
  v_version integer;
  v_threw boolean;
begin
  select id into v_prof_a from public.health_profiles where owner_account_id = v_user_a and is_self;
  select id into v_prof_b from public.health_profiles where owner_account_id = v_user_b and is_self;

  if v_prof_a is null or v_prof_b is null then
    raise exception 'TEST SETUP FAILED: Self profiles not created by trigger';
  end if;

  -- --------------------------------------------------------------------------
  -- 1. Constraint Tests: Heart Rate Plausibility
  -- --------------------------------------------------------------------------
  v_threw := false;
  begin
    insert into public.measurements (profile_id, type, heart_rate_bpm)
    values (v_prof_a, 'heart_rate', 10.0); -- below 25.0
  exception when check_violation then
    v_threw := true;
  end;
  if not v_threw then
    raise exception 'TEST FAILED: Heart rate below 25 bpm should have thrown check violation';
  end if;

  v_threw := false;
  begin
    insert into public.measurements (profile_id, type, heart_rate_bpm)
    values (v_prof_a, 'heart_rate', 300.0); -- above 260.0
  exception when check_violation then
    v_threw := true;
  end;
  if not v_threw then
    raise exception 'TEST FAILED: Heart rate above 260 bpm should have thrown check violation';
  end if;

  -- --------------------------------------------------------------------------
  -- 2. Constraint Tests: Blood Pressure Systolic > Diastolic
  -- --------------------------------------------------------------------------
  v_threw := false;
  begin
    insert into public.measurements (profile_id, type, systolic_mmhg, diastolic_mmhg)
    values (v_prof_a, 'blood_pressure', 80.0, 90.0); -- systolic <= diastolic
  exception when check_violation then
    v_threw := true;
  end;
  if not v_threw then
    raise exception 'TEST FAILED: Systolic <= Diastolic should have thrown check violation';
  end if;

  -- --------------------------------------------------------------------------
  -- 3. Constraint Tests: Required Typed Columns
  -- --------------------------------------------------------------------------
  v_threw := false;
  begin
    insert into public.measurements (profile_id, type)
    values (v_prof_a, 'weight'); -- weight_kg is null
  exception when check_violation then
    v_threw := true;
  end;
  if not v_threw then
    raise exception 'TEST FAILED: Missing weight_kg for weight measurement should have thrown check violation';
  end if;

  -- --------------------------------------------------------------------------
  -- 4. Valid insert as User A
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_a::text, 'role', 'authenticated')::text, true);

  insert into public.measurements (profile_id, type, heart_rate_bpm, source, provenance)
  values (v_prof_a, 'heart_rate', 72.0, 'manual', 'manually_entered')
  returning id into v_meas_id;

  select count(*) into v_count from public.measurements where id = v_meas_id;
  if v_count <> 1 then
    raise exception 'TEST FAILED: User A should be able to select their own measurement';
  end if;

  -- --------------------------------------------------------------------------
  -- 5. RLS Isolation: User B cannot see User A's measurement
  -- --------------------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from public.measurements where id = v_meas_id;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B should NOT see User A measurement (got % rows)', v_count;
  end if;

  -- User B cannot insert measurement into User A's profile
  v_threw := false;
  begin
    insert into public.measurements (profile_id, type, heart_rate_bpm)
    values (v_prof_a, 'heart_rate', 80.0);
  exception when others then
    v_threw := true;
  end;

  reset role;
  select count(*) into v_count from public.measurements where profile_id = v_prof_a and heart_rate_bpm = 80.0;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B was able to insert into User A profile';
  end if;

  -- --------------------------------------------------------------------------
  -- 6. Anonymous role is completely denied
  -- --------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);

  v_threw := false;
  begin
    select count(*) into v_count from public.measurements where id = v_meas_id;
  exception when insufficient_privilege then
    v_threw := true;
  end;

  if not v_threw and coalesce(v_count, 0) > 0 then
    raise exception 'TEST FAILED: Anon should be denied';
  end if;

  -- --------------------------------------------------------------------------
  -- 7. Version Increment Trigger Test
  -- --------------------------------------------------------------------------
  reset role;
  update public.measurements
  set heart_rate_bpm = 75.0
  where id = v_meas_id
  returning version into v_version;

  if v_version <> 2 then
    raise exception 'TEST FAILED: Expected version 2 after update, got %', v_version;
  end if;

  raise notice 'ALL_MEASUREMENT_RLS_AND_CONSTRAINT_TESTS_PASSED';
end $$;

rollback;
