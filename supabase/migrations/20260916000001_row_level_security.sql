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
