-- =============================================================================
-- HealthBase · RLS test suite · Loop 1 (identity)
--
-- Runs entirely inside a transaction that is ROLLED BACK, so no fixture data
-- persists. Any failed assertion raises an exception and aborts the run.
-- Executed against the linked project by scripts/run_db_tests.ps1.
-- =============================================================================
begin;

-- ------------------------------------------------------------ fixtures -------
insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                        email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
                        created_at, updated_at)
values
  ('00000000-0000-4000-a000-00000000000a', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'rls-user-a@test.invalid', '', now(),
   '{"display_name":"User A"}', '{}', now(), now()),
  ('00000000-0000-4000-a000-00000000000b', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'rls-user-b@test.invalid', '', now(),
   '{"display_name":"   "}', '{}', now(), now());

-- --------------------------------------------- T1: signup trigger -----------
do $$
begin
  if (select count(*) from public.accounts
      where id in ('00000000-0000-4000-a000-00000000000a',
                   '00000000-0000-4000-a000-00000000000b')) <> 2 then
    raise exception 'FAIL T1.1: signup trigger did not create both accounts';
  end if;

  if (select count(*) from public.health_profiles
      where is_self and owner_account_id in ('00000000-0000-4000-a000-00000000000a',
                                             '00000000-0000-4000-a000-00000000000b')) <> 2 then
    raise exception 'FAIL T1.2: signup trigger did not create both self profiles';
  end if;

  if (select display_name from public.health_profiles
      where owner_account_id = '00000000-0000-4000-a000-00000000000a') is distinct from 'User A' then
    raise exception 'FAIL T1.3: display_name not copied from signup metadata';
  end if;

  if (select display_name from public.health_profiles
      where owner_account_id = '00000000-0000-4000-a000-00000000000b') is not null then
    raise exception 'FAIL T1.4: blank display_name should be stored as NULL';
  end if;

  if (select preferred_units from public.accounts
      where id = '00000000-0000-4000-a000-00000000000a') <> 'metric' then
    raise exception 'FAIL T1.5: preferred_units default';
  end if;
end $$;

-- --------------------------------------------- T2: authenticated user A -----
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-a000-00000000000a","role":"authenticated"}', true);

do $$
declare
  n integer;
  b_profile uuid;
begin
  -- visibility
  if (select count(*) from public.accounts) <> 1 then
    raise exception 'FAIL T2.1: user A must see exactly 1 account row';
  end if;
  if exists (select 1 from public.accounts where id = '00000000-0000-4000-a000-00000000000b') then
    raise exception 'FAIL T2.2: user A can see user B account';
  end if;
  if (select count(*) from public.health_profiles) <> 1 then
    raise exception 'FAIL T2.3: user A must see exactly 1 health profile';
  end if;
  if (select count(*) from public.profile_access) <> 0 then
    raise exception 'FAIL T2.4: user A must see no access grants';
  end if;

  -- cross-user writes affect nothing
  update public.health_profiles set display_name = 'hacked'
   where owner_account_id = '00000000-0000-4000-a000-00000000000b';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL T2.5: user A updated user B profile'; end if;

  update public.accounts set preferred_units = 'imperial'
   where id = '00000000-0000-4000-a000-00000000000b';
  get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL T2.6: user A updated user B account'; end if;

  -- own writes succeed
  update public.health_profiles set display_name = 'User A Edited', height_cm = 172.5
   where owner_account_id = '00000000-0000-4000-a000-00000000000a';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL T2.7: user A could not update own profile'; end if;

  update public.accounts set preferred_units = 'imperial'
   where id = '00000000-0000-4000-a000-00000000000a';
  get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL T2.8: user A could not update own units'; end if;

  -- protected columns cannot be changed
  begin
    update public.health_profiles set owner_account_id = '00000000-0000-4000-a000-00000000000b'
     where owner_account_id = '00000000-0000-4000-a000-00000000000a';
    raise exception 'FAIL T2.9: owner_account_id is writable';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.health_profiles set is_self = false
     where owner_account_id = '00000000-0000-4000-a000-00000000000a';
    raise exception 'FAIL T2.10: is_self is writable';
  exception when insufficient_privilege then null;
  end;

  -- no direct inserts / deletes
  begin
    insert into public.accounts (id) values (gen_random_uuid());
    raise exception 'FAIL T2.11: user A inserted an account';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.health_profiles (owner_account_id, is_self)
    values ('00000000-0000-4000-a000-00000000000b', false);
    raise exception 'FAIL T2.12: user A inserted a profile';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.health_profiles;
    raise exception 'FAIL T2.13: user A could delete profiles';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.profile_access (profile_id, grantee_account_id, role, status)
    select id, '00000000-0000-4000-a000-00000000000a', 'manage', 'active'
    from public.health_profiles limit 1;
    raise exception 'FAIL T2.14: user A could self-grant access';
  exception when insufficient_privilege then null;
  end;

  -- authorization helper
  reset role;
  select id into b_profile from public.health_profiles
   where owner_account_id = '00000000-0000-4000-a000-00000000000b';
  set local role authenticated;
  if app.can_access_profile(b_profile, 'view') then
    raise exception 'FAIL T2.15: can_access_profile granted A access to B';
  end if;

  -- validation
  begin
    update public.health_profiles set date_of_birth = current_date + 1
     where owner_account_id = '00000000-0000-4000-a000-00000000000a';
    raise exception 'FAIL T2.16: future date_of_birth accepted';
  exception when check_violation then null;
  end;

  begin
    update public.health_profiles set height_cm = 500
     where owner_account_id = '00000000-0000-4000-a000-00000000000a';
    raise exception 'FAIL T2.17: impossible height accepted';
  exception when check_violation or numeric_value_out_of_range then null;
  end;
end $$;

-- --------------------------------------------- T3: anonymous ----------------
reset role;
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);

do $$
begin
  begin
    perform count(*) from public.accounts;
    raise exception 'FAIL T3.1: anon can read accounts';
  exception when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.health_profiles;
    raise exception 'FAIL T3.2: anon can read health_profiles';
  exception when insufficient_privilege then null;
  end;

  begin
    perform count(*) from public.profile_access;
    raise exception 'FAIL T3.3: anon can read profile_access';
  exception when insufficient_privilege then null;
  end;

  begin
    perform public.delete_my_account();
    raise exception 'FAIL T3.4: anon can call delete_my_account';
  exception when insufficient_privilege then null;
  end;
end $$;

-- --------------------------------------------- T4: account deletion ---------
reset role;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-4000-a000-00000000000b","role":"authenticated"}', true);
select public.delete_my_account();
reset role;

do $$
begin
  if exists (select 1 from auth.users where id = '00000000-0000-4000-a000-00000000000b') then
    raise exception 'FAIL T4.1: auth user B not deleted';
  end if;
  if exists (select 1 from public.accounts where id = '00000000-0000-4000-a000-00000000000b') then
    raise exception 'FAIL T4.2: account B not cascaded';
  end if;
  if exists (select 1 from public.health_profiles where owner_account_id = '00000000-0000-4000-a000-00000000000b') then
    raise exception 'FAIL T4.3: profile B not cascaded';
  end if;
  if not exists (select 1 from public.accounts where id = '00000000-0000-4000-a000-00000000000a') then
    raise exception 'FAIL T4.4: deleting B affected A';
  end if;
end $$;

rollback;

select 'ALL_RLS_TESTS_PASSED' as result;
