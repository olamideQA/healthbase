-- ============================================================================
-- Supabase SQL Test Suite: 003_daily_checks_rls.sql
--
-- Tests:
-- 1. Daily check insertion with symptoms for authenticated user
-- 2. RLS Isolation: User A vs User B on daily_checks and daily_check_symptoms
-- 3. Anonymous role is completely denied
-- 4. Unique check_date per profile constraint
-- 5. Version increment trigger
-- ============================================================================

begin;

insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
                        created_at, updated_at)
values
  ('00000000-0000-4000-a000-00000000002a', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'check-user-a@test.invalid', '', now(),
   '{"display_name":"Check User A"}', '{}', now(), now()),
  ('00000000-0000-4000-a000-00000000002b', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'check-user-b@test.invalid', '', now(),
   '{"display_name":"Check User B"}', '{}', now(), now());

do $$
declare
  v_user_a uuid := '00000000-0000-4000-a000-00000000002a';
  v_user_b uuid := '00000000-0000-4000-a000-00000000002b';
  v_prof_a uuid;
  v_prof_b uuid;
  v_check_id uuid;
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
  -- 1. Valid insert as User A
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_a::text, 'role', 'authenticated')::text, true);

  insert into public.daily_checks (profile_id, check_date, feeling, medication_status, notes)
  values (v_prof_a, current_date, 'good', 'yes', 'Feeling rested')
  returning id into v_check_id;

  insert into public.daily_check_symptoms (daily_check_id, symptom_code, is_urgent)
  values (v_check_id, 'headache', false);

  select count(*) into v_count from public.daily_checks where id = v_check_id;
  if v_count <> 1 then
    raise exception 'TEST FAILED: User A should select their own check';
  end if;

  select count(*) into v_count from public.daily_check_symptoms where daily_check_id = v_check_id;
  if v_count <> 1 then
    raise exception 'TEST FAILED: User A should select their own symptoms';
  end if;

  -- --------------------------------------------------------------------------
  -- 2. Unique check per date constraint
  -- --------------------------------------------------------------------------
  v_threw := false;
  begin
    insert into public.daily_checks (profile_id, check_date, feeling, medication_status)
    values (v_prof_a, current_date, 'okay', 'yes');
  exception when unique_violation then
    v_threw := true;
  end;
  if not v_threw then
    raise exception 'TEST FAILED: Duplicate active check on same date should have thrown unique violation';
  end if;

  -- --------------------------------------------------------------------------
  -- 3. RLS Isolation: User B cannot see User A's check or symptoms
  -- --------------------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from public.daily_checks where id = v_check_id;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B should NOT see User A check';
  end if;

  select count(*) into v_count from public.daily_check_symptoms where daily_check_id = v_check_id;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B should NOT see User A symptoms';
  end if;

  -- User B cannot insert symptoms into User A's check
  v_threw := false;
  begin
    insert into public.daily_check_symptoms (daily_check_id, symptom_code)
    values (v_check_id, 'cough');
  exception when others then
    v_threw := true;
  end;

  reset role;
  select count(*) into v_count from public.daily_check_symptoms where daily_check_id = v_check_id and symptom_code = 'cough';
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B was able to insert symptoms into User A check';
  end if;

  -- --------------------------------------------------------------------------
  -- 4. Anonymous role is completely denied
  -- --------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);

  v_threw := false;
  begin
    select count(*) into v_count from public.daily_checks where id = v_check_id;
  exception when insufficient_privilege then
    v_threw := true;
  end;
  if not v_threw and coalesce(v_count, 0) > 0 then
    raise exception 'TEST FAILED: Anon should be denied';
  end if;

  -- --------------------------------------------------------------------------
  -- 5. Version Increment Trigger Test
  -- --------------------------------------------------------------------------
  reset role;
  update public.daily_checks
  set feeling = 'okay'
  where id = v_check_id
  returning version into v_version;

  if v_version <> 2 then
    raise exception 'TEST FAILED: Expected version 2 after update, got %', v_version;
  end if;

  raise notice 'ALL_DAILY_CHECK_RLS_AND_CONSTRAINT_TESTS_PASSED';
end $$;

rollback;
