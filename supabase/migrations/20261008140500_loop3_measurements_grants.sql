-- Grant table privileges to authenticated and revoke from anon for measurements table
revoke all on public.measurements from anon, authenticated;
grant select, insert, update, delete on public.measurements to authenticated;
