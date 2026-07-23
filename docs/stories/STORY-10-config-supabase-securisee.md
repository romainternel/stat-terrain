# STORY-10 — Configuration Supabase sécurisée (fondation)

**En tant que** Romain,
**Je veux** un projet Supabase correctement configuré et sécurisé dès le départ,
**Afin de** avoir une base fiable avant d'y faire transiter la moindre donnée de match réelle.

## Contexte technique

- Nouveau fichier `config.js` (chargé avant `app.js` dans `index.html`) contenant `SUPABASE_URL` et `SUPABASE_ANON_KEY` — isolé pour permettre un clonage futur (cf. `docs/architecture-supabase.md` F9).
- Création des tables `matches` et `match_events` selon le schéma défini par l'Architect (`docs/architecture-supabase.md`).
- Un seul compte Supabase Auth créé manuellement (email + mot de passe choisis par Romain), aucune inscription en self-service.

## Critères d'acceptation

- [ ] `config.js` existe, séparé de `app.js`, et contient uniquement URL + clé anon (jamais de clé `service_role`).
- [ ] Les tables `matches` et `match_events` sont créées conformément au schéma de `docs/architecture-supabase.md`.
- [ ] **RLS est explicitement activée** sur `matches` ET `match_events` (`enable row level security`) — vérifié individuellement table par table, pas supposé.
- [ ] Les policies `for all using/with check auth.role()='authenticated'` sont en place sur les deux tables.
- [ ] **L'inscription publique (self-signup) est désactivée** dans les réglages Supabase Auth du projet.
- [ ] Test de vérification obligatoire (finding Critique du Security Auditor, `docs/security/supabase-multiuser.md`) : tenter de créer un compte via l'API/console sans passer par un accès admin → doit échouer.
- [ ] Test de vérification obligatoire : requêter les tables sans authentification (clé anon seule, sans session) → doit être refusé.
- [ ] Un seul compte utilisateur existe dans le projet (celui de Romain), aucun compte de test oublié.

## Hors scope

- L'écran de connexion côté app (traité dans STORY-11).
- La logique de synchronisation elle-même (traitée dans STORY-12/13).

## Dépend de

Aucune.

## Taille

S
