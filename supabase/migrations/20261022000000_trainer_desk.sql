-- Human trainer introductions. Google sign-in has no Supabase auth id,
-- so only the trainer-desk function (service role) reads or writes these tables.

create table if not exists trainer_profiles (
  id text primary key,
  display_name text not null,
  city text not null,
  tracks text[] not null,
  monthly_rate_inr integer not null check (monthly_rate_inr > 0),
  bio text not null,
  desk_code text not null unique,
  active boolean not null default true,
  created_at timestamptz default now()
);

create table if not exists trainer_requests (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  user_name text not null,
  user_email text,
  trainer_id text not null references trainer_profiles (id),
  tracks text[] not null,
  city text,
  note text,
  status text not null default 'requested',
  created_at timestamptz default now(),
  unique (user_id, trainer_id)
);

create index if not exists idx_trainer_requests_trainer
  on trainer_requests (trainer_id, status);

alter table trainer_profiles enable row level security;
alter table trainer_requests enable row level security;
