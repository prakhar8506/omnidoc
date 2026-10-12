-- Family invites keyed by the app's own user id (Google sign-in is not a
-- Supabase auth user). Only the family-circle edge function, using the
-- service role, reads or writes these tables.

create table if not exists family_invites (
  code text primary key,
  inviter_id text not null,
  inviter_name text not null,
  inviter_email text,
  relation text not null,
  status text not null default 'pending',
  accepter_id text,
  accepter_name text,
  accepter_email text,
  created_at timestamptz default now(),
  accepted_at timestamptz
);

create index if not exists idx_family_invites_inviter
  on family_invites (inviter_id, status);

create table if not exists family_links (
  id uuid primary key default gen_random_uuid(),
  user_id text not null,
  member_id text not null,
  member_name text not null,
  member_email text,
  relation text not null,
  invite_code text,
  created_at timestamptz default now(),
  unique (user_id, member_id)
);

create index if not exists idx_family_links_user on family_links (user_id);

alter table family_invites enable row level security;
alter table family_links enable row level security;
