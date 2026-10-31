-- =====================================================================
--  Nos photos : DEUXIÈME PROJET SUPABASE (stockage des fichiers seulement)
--  À coller en entier dans le 2e projet → SQL Editor → New query → Run
--  Les albums et la liste des photos restent dans le projet principal.
-- =====================================================================

-- 1. Les membres autorisés à lire et déposer des fichiers ici
create table if not exists public.members (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
);
alter table public.members enable row level security;

create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.members where user_id = auth.uid());
$$;

drop policy if exists "membres : lecture" on public.members;
create policy "membres : lecture" on public.members
  for select to authenticated using (public.is_member());

-- 2. Le bucket privé et ses règles (identiques au projet principal)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 10485760, array['image/jpeg'])
on conflict (id) do nothing;

drop policy if exists "photos storage : lecture membres" on storage.objects;
create policy "photos storage : lecture membres" on storage.objects
  for select to authenticated using (bucket_id = 'photos' and public.is_member());

drop policy if exists "photos storage : ajout membres" on storage.objects;
create policy "photos storage : ajout membres" on storage.objects
  for insert to authenticated with check (bucket_id = 'photos' and public.is_member());

drop policy if exists "photos storage : suppression membres" on storage.objects;
create policy "photos storage : suppression membres" on storage.objects
  for delete to authenticated using (bucket_id = 'photos' and public.is_member());


-- =====================================================================
--  ÉTAPE SÉPARÉE, APRÈS AVOIR CRÉÉ VOS DEUX COMPTES DANS CE PROJET
--  (mêmes e-mails ET mêmes mots de passe que dans le projet principal)
-- =====================================================================
-- insert into public.members (user_id, display_name)
-- select id, 'Ton prénom' from auth.users where email = 'toi@exemple.fr';
--
-- insert into public.members (user_id, display_name)
-- select id, 'Son prénom' from auth.users where email = 'elle@exemple.fr';
