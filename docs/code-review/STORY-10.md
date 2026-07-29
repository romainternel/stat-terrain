# Code Review — STORY-10 : Configuration Supabase sécurisée (fondation)

## Périmètre revu
- `config.js` (nouveau) : `SUPABASE_URL` + `SUPABASE_ANON_KEY`.
- `index.html` : ajout du CDN `supabase-js`, `<script src="config.js">` avant `app.js`.
- `app.js` : `initSupabaseClient()`.
- Configuration côté dashboard Supabase (tables, RLS, policies, compte, auto-inscription) — non versionnée, vérifiée par capture d'écran/test live plutôt que par lecture de code.

## Conformité architecture
- Respecte exactement `docs/architecture-supabase.md` : config isolée dans un fichier séparé, chargé avant `app.js`, client `supabase-js` via CDN (cohérent avec `jsPDF` déjà en place, pas de bundler introduit).
- Nom de fonction (`initSupabaseClient`) conforme à la spec de l'Architect.
- Schéma SQL exécuté (`docs/supabase-setup.sql`) correspond exactement au schéma documenté par l'Architect — pas de dérive entre le plan et l'exécution.

## Conventions de code
- Cohérent avec le reste du fichier (déclarations `let`/`const`, pas de framework).
- Bon réflexe : variable de client nommée `sbClient` plutôt que `supabase`, pour ne pas ombrer le namespace global de la librairie CDN — évite un bug classique de ce genre d'intégration.

## Réutilisation vs duplication
- RAS, code neuf et minimal (fondation).

## Scope
- Diff strictement limité à la fondation (client + config). Aucune logique de synchronisation, d'écran de connexion, ou de reprise de match — conforme au découpage prévu (STORY-11 à 17 pour la suite).

## Gestion d'erreurs
- `initSupabaseClient()` retourne `null` proprement si `SUPABASE_URL` ou la librairie CDN ne sont pas chargés (`typeof` guard), plutôt que de lever une exception qui bloquerait le reste de l'app au chargement — bon choix défensif pour un service tiers en best-effort.

## Sécurité basique — point d'attention spécifique à cette story
- `config.js` contient une clé API en clair, commitée dans un dépôt **public**. Vérifié : c'est la clé `anon`/`publishable` (préfixe `sb_publishable_`), pas `service_role` — ce type de clé est **conçu pour être exposé côté client**, la vraie barrière de sécurité étant RLS (vérifiée séparément). Pas un incident, comportement attendu et documenté par l'Architecture.
- Point qui sort de mon mandat habituel (revue de code) mais critique ici : cette story touche l'authentification et une nouvelle ressource backend → je signale explicitement au **Security Auditor** de rejouer les deux findings Critiques de `docs/security/supabase-multiuser.md` sur le **vrai projet**, pas seulement sur le papier.

## Verdict
**APPROUVÉ**, sous réserve du passage du Security Auditor (obligatoire pour cette story, non skippable).
