-- FENIX Stats — Extension du schéma pour la synchronisation de l'historique (STORY-48),
-- le champ Championnat/Amical (STORY-49) et le scoping deux équipes -18/CF (STORY-50)
-- À exécuter dans Supabase : SQL Editor → New query → coller tout → Run
-- Idempotent (if not exists) : sans risque de le réexécuter même si déjà lancé une 1ère fois
-- pour season/journee/coach_notes/championnat — seule la ligne team_profile s'ajoutera.

alter table matches add column if not exists season text;
alter table matches add column if not exists journee text;
alter table matches add column if not exists coach_notes text;
alter table matches add column if not exists championnat text;
-- not null + default 'cf' : tous les matchs déjà en base (forcément d'avant l'existence de
-- l'équipe -18) sont automatiquement rattachés à l'équipe CF, sans étape supplémentaire.
alter table matches add column if not exists team_profile text not null default 'cf';
