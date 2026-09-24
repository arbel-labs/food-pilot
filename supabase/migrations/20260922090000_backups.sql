-- Tabel cadangan data (PRD F-14). Satu baris per pengguna.
create table if not exists public.backups (
  user_id uuid primary key references auth.users (id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.backups enable row level security;

-- Tiap pengguna hanya boleh menyentuh barisnya sendiri.
create policy "backup milik sendiri: baca"
  on public.backups for select
  using ((select auth.uid()) = user_id);

create policy "backup milik sendiri: tambah"
  on public.backups for insert
  with check ((select auth.uid()) = user_id);

create policy "backup milik sendiri: ubah"
  on public.backups for update
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
