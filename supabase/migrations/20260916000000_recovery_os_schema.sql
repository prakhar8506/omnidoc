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
