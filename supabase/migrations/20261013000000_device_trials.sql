-- One free Premium trial per device. Written only by the claim-device-trial function.
create table if not exists public.device_trials (
  device_hash text primary key,
  created_at timestamptz not null default now()
);

alter table public.device_trials enable row level security;
