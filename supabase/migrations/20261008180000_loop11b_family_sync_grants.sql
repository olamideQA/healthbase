-- Migration: Loop 11b — family offline-sync support grants
--
-- The offline-first client syncs managed family profiles it owns, including
-- relationship_label and is_managed. The base UPDATE grant from Loop 1 does
-- not cover those columns, so uploads would be rejected with 42501
-- (which the client treats as permanent). Extend the grant; RLS policies
-- already restrict such updates to managers/owners.

GRANT UPDATE (relationship_label, is_managed)
  ON public.health_profiles TO authenticated;
