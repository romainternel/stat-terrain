-- FENIX Stats — Setup Supabase (STORY-10)
-- À exécuter dans Supabase : SQL Editor → New query → coller tout → Run

create table matches (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'in_progress',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  home_name text, away_name text,
  home_roster jsonb,
  away_roster jsonb,
  home_gk_id text, away_gk_id text,
  period int, time_offset_seconds int, running boolean, last_start_at timestamptz,
  timeouts jsonb
);

create table match_events (
  id uuid primary key,
  match_id uuid references matches(id),
  type text, team text, time int, raw_time int, period int,
  x real, y real, gk_id text,
  player_id text, player_name text, player_number text,
  assist_id text, assist_name text, assist_number text,
  goal_zone text,
  created_at timestamptz default now()
);

-- Sécurité : RLS activée EXPLICITEMENT sur les deux tables (ne pas sauter cette étape)
alter table matches enable row level security;
alter table match_events enable row level security;

create policy "authenticated full access"
on matches for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "authenticated full access"
on match_events for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');
