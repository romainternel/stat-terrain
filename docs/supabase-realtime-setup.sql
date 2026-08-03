-- FENIX Stats — Activation du Realtime pour STORY-13 (sync entrante)
-- À exécuter dans Supabase : SQL Editor → New query → coller → Run
-- Sans cette étape, les abonnements postgres_changes ne recevront jamais rien,
-- silencieusement (pas d'erreur) — cf. risque #2, docs/risks/supabase-multiuser.md

alter publication supabase_realtime add table match_events;
