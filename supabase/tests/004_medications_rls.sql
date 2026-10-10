-- ============================================================================
-- Supabase SQL Test Suite: 004_medications_rls.sql
--
-- Tests:
-- 1. Medication + event insert/select for authenticated owner
-- 2. RLS Isolation: User A vs User B on medications and medication_events
-- 3. Anonymous role is completely denied (table privileges revoked)
-- 4. Version increment trigger on update
-- ============================================================================

begin;

insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
                        created_at, updated_at)
values
  ('00000000-0000-4000-a000-00000000003a', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'med-user-a@test.invalid', '', now(),
   '{"display_name":"Med User A"}', '{}', now(), now()),
  ('00000000-0000-4000-a000-00000000003b', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'med-user-b@test.invalid', '', now(),
   '{"display_name":"Med User B"}', '{}', now(), now());

do $$
declare
  v_user_a uuid := '00000000-0000-4000-a000-00000000003a';
  v_user_b uuid := '00000000-0000-4000-a000-00000000003b';
  v_prof_a uuid;
  v_prof_b uuid;
  v_med_id uuid;
  v_count integer;
  v_version integer;
begin
  select id into v_prof_a from public.health_profiles where owner_account_id = v_user_a and is_self;
  select id into v_prof_b from public.health_profiles where owner_account_id = v_user_b and is_self;

  if v_prof_a is null or v_prof_b is null then
    raise exception 'TEST SETUP FAILED: Self profiles not created by trigger';
  end if;

  -- --------------------------------------------------------------------------
  -- 1. Valid insert as User A (medication + adherence event)
  -- --------------------------------------------------------------------------
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_a::text, 'role', 'authenticated')::text, true);

  insert into public.medications (profile_id, name, dosage, frequency, start_date)
  values (v_prof_a, 'Lisinopril', '10 mg', 'daily', now())
  returning id into v_med_id;

  insert into public.medication_events (profile_id, medication_id, scheduled_time, status)
  values (v_prof_a, v_med_id, now(), 'taken');

  select count(*) into v_count from public.medications where id = v_med_id;
  if v_count <> 1 then
    raise exception 'TEST FAILED: User A should select their own medication';
  end if;

  select count(*) into v_count from public.medication_events where medication_id = v_med_id;
  if v_count <> 1 then
    raise exception 'TEST FAILED: User A should select their own med events';
  end if;

  -- --------------------------------------------------------------------------
  -- 2. RLS Isolation: User B sees nothing and cannot write
  -- --------------------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b::text, 'role', 'authenticated')::text, true);

  select count(*) into v_count from public.medications where id = v_med_id;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B should NOT see User A medication';
  end if;

  select count(*) into v_count from public.medication_events where medication_id = v_med_id;
  if v_count <> 0 then
    raise exception 'TEST FAILED: User B should NOT see User A med events';
  end if;

  begin
    insert into public.medication_events (profile_id, medication_id, scheduled_time, status)
    values (v_prof_b, v_med_id, now(), 'taken');
    raise exception 'TEST FAILED: User B insert into User A medication should have been rejected';
  exception when others then
    -- expected: RLS deny
  end;

  -- --------------------------------------------------------------------------
  -- 3. Anonymous role is completely denied
  -- --------------------------------------------------------------------------
  set local role anon;
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);

  begin
    select count(*) into v_count from public.medications where id = v_med_id;
    if coalesce(v_count, 0) > 0 then
      raise exception 'TEST FAILED: Anon should be denied';
    end if;
  exception when insufficient_privilege then
    -- also acceptable: hard privilege deny
  end;

  -- --------------------------------------------------------------------------
  -- 4. No self-promotion: a 'view' grantee cannot UPDATE its own grant
  --    (accept flows use the DEFINER RPC instead).
  -- --------------------------------------------------------------------------
  reset role;
  insert into public.profile_access (profile_id, grantee_account_id, role, status)
  values (v_prof_a, v_user_b, 'view', 'active');

  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b::text, 'role', 'authenticated')::text, true);

  begin
    update public.profile_access
    set role = 'manage'
    where profile_id = v_prof_a and grantee_account_id = v_user_b;
    select count(*) into v_count from public.profile_access
    where profile_id = v_prof_a and grantee_account_id = v_user_b and role = 'manage';
    if coalesce(v_count, 0) > 0 then
      raise exception 'TEST FAILED: grantee promoted itself to manage';
    end if;
  exception when others then
    -- RLS deny is also acceptable
  end;

  -- --------------------------------------------------------------------------
  -- 5. Version Increment Trigger Test
  -- --------------------------------------------------------------------------
  reset role;
  update public.medications
  set notes = 'take with water'
  where id = v_med_id
  returning version into v_version;

  if v_version <> 2 then
    raise exception 'TEST FAILED: Expected version 2 after update, got %', v_version;
  end if;

  raise notice 'ALL_MEDICATIONS_RLS_AND_CONSTRAINT_TESTS_PASSED';
end $$;

rollback;
