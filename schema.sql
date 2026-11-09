-- Study Tracker database schema for Supabase.
-- Run this once in your project: Dashboard > SQL Editor > New query > paste > Run.

create table public.study_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  constraint study_state_data_is_object check (jsonb_typeof(data) = 'object'),
  constraint study_state_data_size check (pg_column_size(data) < 262144)
);

comment on table public.study_state is 'One row per user: that user''s whole Study Tracker state (class, subjects, chapters, ticks) as JSON.';

alter table public.study_state enable row level security;

create policy "Users read own study state"
  on public.study_state for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users insert own study state"
  on public.study_state for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users update own study state"
  on public.study_state for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users delete own study state"
  on public.study_state for delete to authenticated
  using ((select auth.uid()) = user_id);

create function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger study_state_set_updated_at
  before update on public.study_state
  for each row execute function public.set_updated_at();
