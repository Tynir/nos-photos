-- =====================================================================
--  Nos photos : base de données Supabase (PROJET PRINCIPAL)
--  À coller en entier dans Supabase → SQL Editor → New query → Run
--  Pour le 2e projet (stockage seul), utilise schema-stockage.sql
-- =====================================================================

-- 1. Les membres autorisés (toi et ta copine). Seuls eux voient quelque chose.
create table if not exists public.members (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
);

-- Fonction utilisée par toutes les règles de sécurité :
-- « la personne connectée fait-elle partie des membres ? »
create or replace function public.is_member()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.members where user_id = auth.uid());
$$;

-- 2. Les albums
create table if not exists public.albums (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 80),
  created_by uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now()
);

-- 3. Les photos (le fichier est dans le Storage, ici on garde ses infos)
create table if not exists public.photos (
  id          uuid primary key default gen_random_uuid(),
  album_id    uuid not null references public.albums (id) on delete cascade,
  path        text not null,
  thumb_path  text not null,
  width       int,
  height      int,
  size_bytes  int not null default 0,
  caption     text check (char_length(caption) <= 200),
  uploaded_by uuid not null default auth.uid() references auth.users (id),
  created_at  timestamptz not null default now()
);
create index if not exists photos_album_idx on public.photos (album_id, created_at desc);

-- Dans quel projet Supabase est rangé le fichier : 0 = ce projet, 1 = le 2e projet de stockage
alter table public.photos add column if not exists storage_slot smallint not null default 0;

-- 4. Vues : résumé des albums (nombre de photos, couverture, poids) et place utilisée par espace
drop view if exists public.album_overview;
create view public.album_overview
with (security_invoker = true) as
select
  a.id, a.name, a.created_by, a.created_at,
  count(p.id)                              as photo_count,
  coalesce(sum(p.size_bytes), 0)           as bytes,
  coalesce(max(p.created_at), a.created_at) as last_activity,
  (select p2.thumb_path from public.photos p2
    where p2.album_id = a.id order by p2.created_at desc limit 1) as cover_thumb,
  (select p3.storage_slot from public.photos p3
    where p3.album_id = a.id order by p3.created_at desc limit 1) as cover_slot
from public.albums a
left join public.photos p on p.album_id = a.id
group by a.id;

create or replace view public.storage_usage
with (security_invoker = true) as
select storage_slot, coalesce(sum(size_bytes), 0) as bytes
from public.photos
group by storage_slot;

-- 5. Sécurité : seules les personnes de la table « members » ont accès
alter table public.members enable row level security;
alter table public.albums  enable row level security;
alter table public.photos  enable row level security;

drop policy if exists "membres : lecture" on public.members;
create policy "membres : lecture" on public.members
  for select to authenticated using (public.is_member());

drop policy if exists "albums : tout pour les membres" on public.albums;
create policy "albums : tout pour les membres" on public.albums
  for all to authenticated using (public.is_member()) with check (public.is_member());

drop policy if exists "photos : tout pour les membres" on public.photos;
create policy "photos : tout pour les membres" on public.photos
  for all to authenticated using (public.is_member()) with check (public.is_member());

-- 6. Stockage des fichiers : un « bucket » privé, JPEG uniquement, 10 Mo max par fichier
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

-- 7. Temps réel : prévenir l'autre téléphone quand une photo ou un album change
do $$
begin
  begin alter publication supabase_realtime add table public.albums; exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.photos; exception when duplicate_object then null; end;
end $$;


-- =====================================================================
--  ÉTAPE SÉPARÉE, À FAIRE APRÈS AVOIR CRÉÉ VOS DEUX COMPTES
--  (Authentication → Users → Add user). Remplace les e-mails et prénoms,
--  puis exécute seulement ces lignes.
-- =====================================================================
-- insert into public.members (user_id, display_name)
-- select id, 'Ton prénom' from auth.users where email = 'toi@exemple.fr';
--
-- insert into public.members (user_id, display_name)
-- select id, 'Son prénom' from auth.users where email = 'elle@exemple.fr';
