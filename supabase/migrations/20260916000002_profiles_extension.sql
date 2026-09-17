-- ==============================================================================
-- Migration: 20260916000002_profiles_extension.sql
-- Description: Extend profiles table with baseline metrics & onboarding flags
-- ==============================================================================

alter table if exists profiles
  add column if not exists height_cm numeric,
  add column if not exists weight_kg numeric,
  add column if not exists sex text,
  add column if not exists dob date,
  add column if not exists goals text[] default '{}',
  add column if not exists onboarding_completed boolean default false,
  add column if not exists avatar_url text,
  add column if not exists emergency_notes text;
