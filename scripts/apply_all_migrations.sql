-- ===== 20260916000000_recovery_os_schema.sql =====
-- ==============================================================================
-- Migration: 20260916000000_recovery_os_schema.sql
-- Description: Recovery OS core tables adhering to canonical event schema
-- ==============================================================================

-- 1. profiles: one row per authenticated user
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  blood_type text default 'Unknown',
  locale text default 'en',
  timezone text default 'Asia/Kolkata',
  created_at timestamptz default now()
);

-- 2. health_events: canonical event schema with deterministic deduplication
create table if not exists health_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  metric text not null,
  value numeric not null,
  unit text not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  source text not null,
  source_record_id text not null,
  quality numeric default 1.0,
  model_version text default 'recovery-0.1.0',
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (user_id, source, source_record_id)
);

-- Indices for rapid range queries by metric & timestamp
create index if not exists idx_health_events_user_metric on health_events (user_id, metric, start_time desc);
create index if not exists idx_health_events_time_range on health_events (user_id, start_time, end_time);

-- 3. scores: daily derived outputs (Recovery, Sleep, Load, Stress)
create table if not exists scores (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score_type text not null, -- 'recovery' | 'sleep' | 'load' | 'stress'
  value numeric,
  confidence numeric,
  drivers jsonb default '[]'::jsonb,
  inputs jsonb default '{}'::jsonb,
  model_version text not null,
  computed_for_date date not null,
  created_at timestamptz default now(),
  unique (user_id, score_type, computed_for_date)
);

create index if not exists idx_scores_user_date on scores (user_id, computed_for_date desc);

-- 4. habit_logs: Habit Impact Lab one-tap tracking entries
create table if not exists habit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  behavior_key text not null,
  value boolean not null,
  logged_at timestamptz not null default now()
);

create index if not exists idx_habit_logs_user_date on habit_logs (user_id, logged_at desc);

-- 5. journal_entries: subjective reflections and feeling logs
create table if not exists journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  content text,
  entry_type text not null default 'text', -- 'text' | 'voice' | 'photo'
  mood text,
  tags text[] default '{}',
  created_at timestamptz default now()
);

create index if not exists idx_journal_user_created on journal_entries (user_id, created_at desc);

-- 6. check_ins: morning / evening physiological check-ins
create table if not exists check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  check_in_type text not null, -- 'morning' | 'evening'
  energy int,
  soreness int,
  illness_flag boolean default false,
  stress int,
  sleep_quality int,
  created_at timestamptz default now()
);

create index if not exists idx_check_ins_user_date on check_ins (user_id, created_at desc);

-- ===== 20260916000001_row_level_security.sql =====
-- ==============================================================================
-- Migration: 20260916000001_row_level_security.sql
-- Description: Strict Row Level Security policies guaranteeing user data isolation
-- ==============================================================================

-- 1. profiles RLS
alter table profiles enable row level security;

create policy "Users can manage their own profile"
  on profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 2. health_events RLS
alter table health_events enable row level security;

create policy "Users can manage their own health_events"
  on health_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3. scores RLS
alter table scores enable row level security;

create policy "Users can manage their own scores"
  on scores for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. habit_logs RLS
alter table habit_logs enable row level security;

create policy "Users can manage their own habit_logs"
  on habit_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 5. journal_entries RLS
alter table journal_entries enable row level security;

create policy "Users can manage their own journal_entries"
  on journal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 6. check_ins RLS
alter table check_ins enable row level security;

create policy "Users can manage their own check_ins"
  on check_ins for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Auto-provision profile on user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, blood_type)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'User'),
    coalesce(new.raw_user_meta_data->>'blood_type', 'Unknown')
  )
  on conflict (id) do update set
    display_name = coalesce(excluded.display_name, profiles.display_name),
    blood_type = coalesce(excluded.blood_type, profiles.blood_type);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== 20260916000002_profiles_extension.sql =====
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

-- ===== 20260918000000_production_domain_tables.sql =====
-- ==============================================================================
-- Migration: 20260918000000_production_domain_tables.sql
-- Description: Production domain tables (Medical ID, family, labs, wellness)
--              with RLS: user_id = auth.uid() (profiles: id = auth.uid())
-- ==============================================================================

-- ---------------------------------------------------------------------------
-- profiles: extend with onboarding / body metrics (idempotent)
-- ---------------------------------------------------------------------------
alter table if exists profiles
  add column if not exists height_cm numeric,
  add column if not exists weight_kg numeric,
  add column if not exists sex text,
  add column if not exists dob date,
  add column if not exists onboarding_completed boolean default false,
  add column if not exists avatar_url text,
  add column if not exists emergency_notes text;

-- ---------------------------------------------------------------------------
-- medical_id
-- ---------------------------------------------------------------------------
create table if not exists medical_id (
  user_id uuid primary key references auth.users(id) on delete cascade,
  allergies text[] default '{}',
  conditions text[] default '{}',
  emergency_medications text[] default '{}',
  blood_type text,
  updated_at timestamptz default now()
);

alter table medical_id enable row level security;

create policy "Users can manage their own medical_id"
  on medical_id for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- family_members
-- ---------------------------------------------------------------------------
create table if not exists family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  relation text,
  access_level text,
  permissions jsonb default '{}'::jsonb,
  invite_status text default 'pending',
  invite_token text,
  phone text,
  email text,
  avatar_url text,
  created_at timestamptz default now()
);

create index if not exists idx_family_members_user on family_members (user_id, created_at desc);

alter table family_members enable row level security;

create policy "Users can manage their own family_members"
  on family_members for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  doctor_name text,
  specialty text,
  clinic_name text,
  starts_at timestamptz,
  location_text text,
  video_url text,
  status text default 'scheduled',
  preparation_note text,
  is_video boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_appointments_user_starts on appointments (user_id, starts_at desc);

alter table appointments enable row level security;

create policy "Users can manage their own appointments"
  on appointments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- medications
-- ---------------------------------------------------------------------------
create table if not exists medications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  dosage text,
  schedule_time text,
  instruction text,
  is_taken boolean default false,
  updated_at timestamptz default now()
);

create index if not exists idx_medications_user on medications (user_id, updated_at desc);

alter table medications enable row level security;

create policy "Users can manage their own medications"
  on medications for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- lab_documents
-- ---------------------------------------------------------------------------
create table if not exists lab_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  file_name text,
  status text default 'uploaded',
  ocr_text text,
  structured_json jsonb,
  ai_summary text,
  doctor_questions jsonb default '[]'::jsonb,
  confidence numeric,
  clinician_verified boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_lab_documents_user on lab_documents (user_id, created_at desc);

alter table lab_documents enable row level security;

create policy "Users can manage their own lab_documents"
  on lab_documents for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- biomarker_results
-- ---------------------------------------------------------------------------
create table if not exists biomarker_results (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references lab_documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  value numeric,
  unit text,
  ref_low numeric,
  ref_high numeric,
  flag text
);

create index if not exists idx_biomarker_results_user_doc
  on biomarker_results (user_id, document_id);

alter table biomarker_results enable row level security;

create policy "Users can manage their own biomarker_results"
  on biomarker_results for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- nutrition_logs (kind: meal | hydration)
-- ---------------------------------------------------------------------------
create table if not exists nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('meal', 'hydration')),
  title text,
  ml int,
  calories numeric,
  metadata jsonb default '{}'::jsonb,
  logged_at timestamptz not null default now()
);

create index if not exists idx_nutrition_logs_user on nutrition_logs (user_id, logged_at desc);

alter table nutrition_logs enable row level security;

create policy "Users can manage their own nutrition_logs"
  on nutrition_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- cycle_logs
-- ---------------------------------------------------------------------------
create table if not exists cycle_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  log_date date not null,
  flow text,
  symptoms text[] default '{}',
  notes text,
  unique (user_id, log_date)
);

create index if not exists idx_cycle_logs_user on cycle_logs (user_id, log_date desc);

alter table cycle_logs enable row level security;

create policy "Users can manage their own cycle_logs"
  on cycle_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- pregnancy_profiles
-- ---------------------------------------------------------------------------
create table if not exists pregnancy_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  due_date date,
  pre_pregnancy_weight_kg numeric,
  current_weight_kg numeric,
  enabled boolean default false
);

alter table pregnancy_profiles enable row level security;

create policy "Users can manage their own pregnancy_profiles"
  on pregnancy_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- pregnancy_logs (kind: kick | weight | scan)
-- ---------------------------------------------------------------------------
create table if not exists pregnancy_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('kick', 'weight', 'scan')),
  payload jsonb default '{}'::jsonb,
  logged_at timestamptz not null default now()
);

create index if not exists idx_pregnancy_logs_user on pregnancy_logs (user_id, logged_at desc);

alter table pregnancy_logs enable row level security;

create policy "Users can manage their own pregnancy_logs"
  on pregnancy_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- chronic_readings (kind: glucose | bp)
-- ---------------------------------------------------------------------------
create table if not exists chronic_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('glucose', 'bp')),
  value_primary numeric,
  value_secondary numeric,
  status text,
  recorded_at timestamptz not null default now()
);

create index if not exists idx_chronic_readings_user on chronic_readings (user_id, recorded_at desc);

alter table chronic_readings enable row level security;

create policy "Users can manage their own chronic_readings"
  on chronic_readings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- workouts
-- ---------------------------------------------------------------------------
create table if not exists workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  category text,
  duration_text text,
  calories numeric,
  avg_hr numeric,
  logged_at timestamptz not null default now()
);

create index if not exists idx_workouts_user on workouts (user_id, logged_at desc);

alter table workouts enable row level security;

create policy "Users can manage their own workouts"
  on workouts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- consent_settings
-- ---------------------------------------------------------------------------
create table if not exists consent_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  settings jsonb default '{}'::jsonb,
  updated_at timestamptz default now()
);

alter table consent_settings enable row level security;

create policy "Users can manage their own consent_settings"
  on consent_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- wearable_connections
-- ---------------------------------------------------------------------------
create table if not exists wearable_connections (
  user_id uuid primary key references auth.users(id) on delete cascade,
  platform text,
  device_display_name text,
  last_sync_at timestamptz,
  connected boolean default false
);

alter table wearable_connections enable row level security;

create policy "Users can manage their own wearable_connections"
  on wearable_connections for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- ai_messages
-- ---------------------------------------------------------------------------
create table if not exists ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null,
  content text not null,
  created_at timestamptz default now()
);

create index if not exists idx_ai_messages_user on ai_messages (user_id, created_at desc);

alter table ai_messages enable row level security;

create policy "Users can manage their own ai_messages"
  on ai_messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ===== 20260918000001_storage_buckets.sql =====
-- Storage buckets for Health Companion (run after core tables exist)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('lab-uploads', 'lab-uploads', false, 52428800, array['image/jpeg','image/png','image/webp','application/pdf']),
  ('avatars', 'avatars', false, 5242880, array['image/jpeg','image/png','image/webp']),
  ('exports', 'exports', false, 52428800, array['application/pdf','application/json','application/fhir+json'])
on conflict (id) do nothing;

-- Lab uploads: users can manage only their own folder (user_id as first path segment)
drop policy if exists "lab_uploads_select_own" on storage.objects;
create policy "lab_uploads_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_insert_own" on storage.objects;
create policy "lab_uploads_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_update_own" on storage.objects;
create policy "lab_uploads_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "lab_uploads_delete_own" on storage.objects;
create policy "lab_uploads_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'lab-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_select_own" on storage.objects;
create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "exports_select_own" on storage.objects;
create policy "exports_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "exports_insert_own" on storage.objects;
create policy "exports_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'exports' and (storage.foldername(name))[1] = auth.uid()::text);

-- ===== 20260918000002_auth_profile_trigger.sql =====
-- Auto-create profile row when a new auth user signs up
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, blood_type)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'blood_type', 'Unknown')
  )
  on conflict (id) do update
    set display_name = excluded.display_name,
        blood_type = excluded.blood_type;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

