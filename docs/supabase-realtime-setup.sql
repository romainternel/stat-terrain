-- FENIX Stats — Activation du Realtime pour STORY-13/14 (sync entrante + chrono)
-- À exécuter dans Supabase : SQL Editor → New query → coller → Run
-- Sans cette étape, les abonnements postgres_changes ne recevront jamais rien,
-- silencieusement (pas d'erreur) — cf. risque #2, docs/risks/supabase-multiuser.md
-- Si déjà exécuté une fois pour match_events seul, ré-exécuter juste la ligne "matches"
-- (une erreur "already a member" sur la ligne match_events est normale, sans conséquence).

alter publication supabase_realtime add table match_events;
alter publication supabase_realtime add table matches;
