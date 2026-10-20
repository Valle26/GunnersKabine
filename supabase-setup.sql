-- =====================================================================
--  Gunners Kabine – Einrichtung in Supabase
--  Gleiches Projekt wie Kasse und Shot Map. Eigene Tabellen mit kb_,
--  Kasse und Shot Map bleiben unberührt.
--  Supabase -> SQL Editor -> New query -> alles einfügen -> Run
--  Vorher unten bei Punkt 7 deine E-Mail eintragen.
-- =====================================================================

-- 1. Zugänge zur Kabinen-App (wer darf was)
create table if not exists public.kb_members (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  email      text,
  name       text,
  role       text not null default 'trainer' check (role in ('admin','trainer','view','tv')),
  status     text not null default 'wait'    check (status in ('wait','ok','off')),
  created_at timestamptz not null default now()
);

-- 2. Alle Inhalte: Spieler, Spiele, Trainings, Übungen, Kategorien, TV-Einstellung
--    Ein Eintrag pro Spieler/Spiel/Training/Übung (key z. B. "player:p12")
create table if not exists public.kb_docs (
  key        text primary key,
  kind       text not null,
  data       jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid()
);

-- 3. Hilfsfunktion: Rolle des angemeldeten Benutzers (nur wenn freigeschaltet)
create or replace function public.kb_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.kb_members where user_id = auth.uid() and status = 'ok'
$$;
grant execute on function public.kb_role() to authenticated;

create or replace function public.kb_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;
drop trigger if exists kb_docs_touch on public.kb_docs;
create trigger kb_docs_touch before update on public.kb_docs
  for each row execute function public.kb_touch();

-- 4. Zugriffsregeln
alter table public.kb_members enable row level security;
alter table public.kb_docs    enable row level security;

-- Inhalte: lesen alle Freigeschalteten inkl. TV, ändern nur Admin und Trainer
drop policy if exists kb_docs_read   on public.kb_docs;
drop policy if exists kb_docs_insert on public.kb_docs;
drop policy if exists kb_docs_update on public.kb_docs;
drop policy if exists kb_docs_delete on public.kb_docs;
create policy kb_docs_read   on public.kb_docs for select to authenticated
  using (public.kb_role() in ('admin','trainer','view','tv'));
create policy kb_docs_insert on public.kb_docs for insert to authenticated
  with check (public.kb_role() in ('admin','trainer'));
create policy kb_docs_update on public.kb_docs for update to authenticated
  using (public.kb_role() in ('admin','trainer')) with check (public.kb_role() in ('admin','trainer'));
create policy kb_docs_delete on public.kb_docs for delete to authenticated
  using (public.kb_role() in ('admin','trainer'));

-- Zugänge: jeder sieht sich selbst, der Admin sieht und verwaltet alle.
-- Neue Benutzer dürfen nur eine wartende Anfrage für sich selbst anlegen.
drop policy if exists kb_members_read   on public.kb_members;
drop policy if exists kb_members_join   on public.kb_members;
drop policy if exists kb_members_update on public.kb_members;
drop policy if exists kb_members_delete on public.kb_members;
create policy kb_members_read   on public.kb_members for select to authenticated
  using (user_id = auth.uid() or public.kb_role() = 'admin');
create policy kb_members_join   on public.kb_members for insert to authenticated
  with check (user_id = auth.uid() and status = 'wait' and role in ('trainer','view'));
create policy kb_members_update on public.kb_members for update to authenticated
  using (public.kb_role() = 'admin') with check (public.kb_role() = 'admin');
create policy kb_members_delete on public.kb_members for delete to authenticated
  using (public.kb_role() = 'admin');

-- 5. Live-Sync (Fernseher und andere Handys bekommen Änderungen sofort)
do $$ begin
  alter publication supabase_realtime add table public.kb_docs;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.kb_members;
exception when duplicate_object then null; end $$;

-- 6. Fotospeicher für Spielerfotos und Übungsbilder
--    Lesen über die Bild-Adresse (zufällige Dateinamen), hochladen nur Admin und Trainer
insert into storage.buckets (id, name, public)
values ('kabine', 'kabine', true)
on conflict (id) do update set public = true;

drop policy if exists kb_files_read   on storage.objects;
drop policy if exists kb_files_insert on storage.objects;
drop policy if exists kb_files_update on storage.objects;
drop policy if exists kb_files_delete on storage.objects;
create policy kb_files_read   on storage.objects for select to authenticated
  using (bucket_id = 'kabine');
create policy kb_files_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'kabine' and public.kb_role() in ('admin','trainer'));
create policy kb_files_update on storage.objects for update to authenticated
  using (bucket_id = 'kabine' and public.kb_role() in ('admin','trainer'));
create policy kb_files_delete on storage.objects for delete to authenticated
  using (bucket_id = 'kabine' and public.kb_role() in ('admin','trainer'));

-- 7. Dich als Admin eintragen (deine E-Mail vom Kassen-Login)
insert into public.kb_members (user_id, email, name, role, status)
select id, email, 'Daniel Valentini', 'admin', 'ok'
from auth.users where lower(email) = lower('DEINE-EMAIL@HIER.AT')
on conflict (user_id) do update set role = 'admin', status = 'ok';

-- 8. Kabinen-TV (erst ausführen, nachdem du den TV-Benutzer angelegt hast:
--    Authentication -> Users -> Add user -> Create new user,
--    z. B. kabine-tv@gunners-zirl.at, Passwort vergeben, "Auto Confirm User" an)
--    Danach die E-Mail unten eintragen und nur diesen Block nochmal ausführen.
insert into public.kb_members (user_id, email, name, role, status)
select id, email, 'Kabinen-TV', 'tv', 'ok'
from auth.users where lower(email) = lower('TV-EMAIL@HIER.AT')
on conflict (user_id) do update set role = 'tv', status = 'ok';

-- Kontrolle: hier sollte deine Zeile mit role = admin und status = ok stehen
select email, name, role, status from public.kb_members order by created_at;
