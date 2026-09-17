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
