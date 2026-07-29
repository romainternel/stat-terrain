# STORY-10 — Configuration Supabase sécurisée (fondation)

**En tant que** Romain,
**Je veux** un projet Supabase correctement configuré et sécurisé dès le départ,
**Afin de** avoir une base fiable avant d'y faire transiter la moindre donnée de match réelle.

## Contexte technique

- Nouveau fichier `config.js` (chargé avant `app.js` dans `index.html`) contenant `SUPABASE_URL` et `SUPABASE_ANON_KEY` — isolé pour permettre un clonage futur (cf. `docs/architecture-supabase.md` F9).
- Création des tables `matches` et `match_events` selon le schéma défini par l'Architect (`docs/architecture-supabase.md`).
- Un seul compte Supabase Auth créé manuellement (email + mot de passe choisis par Romain), aucune inscription en self-service.

## Critères d'acceptation

- [x] `config.js` existe, séparé de `app.js`, et contient uniquement URL + clé anon (jamais de clé `service_role`).
- [x] Les tables `matches` et `match_events` sont créées conformément au schéma de `docs/architecture-supabase.md`.
- [x] **RLS est explicitement activée** sur `matches` ET `match_events` — vérifié individuellement dans le Table Editor (badge "1 RLS policy" affiché sur les deux tables), pas supposé.
- [x] Les policies `for all using/with check auth.role()='authenticated'` sont en place sur les deux tables.
- [x] **L'inscription publique (self-signup) est désactivée** — toggle "Allow new users to sign up" désactivé et sauvegardé dans Authentication → Sign In / Providers.
- [x] Test de vérification obligatoire : requêter les tables sans authentification (clé anon seule, sans session) → **confirmé refusé** : `sbClient.from('matches').select('*')` sans session retourne `{data:[], error:null}` — 0 ligne, comportement RLS correct.
- [x] Un seul compte utilisateur existe dans le projet (celui de Romain, `romain.ternel@fenix-toulouse.fr`), aucun compte de test oublié.
- [x] Test complémentaire : tentative de connexion avec des identifiants invalides → refusée proprement (`"Invalid login credentials"`), confirme que l'auth Supabase répond correctement.

**Non testé dans cette story** : connexion réussie avec les vrais identifiants du compte partagé (mot de passe connu seulement de Romain) — sera vérifié naturellement lors du test de l'écran de connexion (STORY-11).

## Hors scope

- L'écran de connexion côté app (traité dans STORY-11).
- La logique de synchronisation elle-même (traitée dans STORY-12/13).

## Dépend de

Aucune.

## Taille

S

## Notes Developer
- Projet créé dans l'organisation `FENIXCF` (Free plan), nommé `stat-terrain` — séparé du projet existant `fenix-eval-cf` (autre app), conformément à la contrainte "un projet par app/déploiement".
- Client `supabase-js` chargé via CDN jsdelivr (`@supabase/supabase-js@2`, build UMD) dans `index.html`, avant `config.js` et `app.js` — cohérent avec le principe "pas de build step" déjà en place pour `jsPDF`.
- `initSupabaseClient()` ajoutée dans `app.js` juste avant la section IndexedDB existante ; variable de client nommée `sbClient` (pas `supabase`) pour ne pas entrer en conflit avec le namespace global de la librairie CDN.
- Clé API récupérée est au format `sb_publishable_...` (nouveau format de clé Supabase, remplace progressivement l'ancien format JWT `eyJ...`) — fonctionne normalement avec `supabase-js@2`, aucune adaptation de code nécessaire.
- Étapes manuelles (création du projet, exécution du script SQL, création du compte, désactivation de l'auto-inscription) effectuées par Romain directement sur le dashboard Supabase, guidées pas à pas — voir `docs/stories/STORY-10-checklist-manuelle.md`.
- **Déviation assumée par rapport à l'Architecture** : celle-ci recommandait d'ajouter le CDN `supabase-js` à la précache explicite du service worker pour fiabiliser le tout premier lancement en réseau faible. Pas fait : `caches.addAll(ASSETS)` est atomique — si la ressource cross-origin échoue au moment de l'install (gymnase, wifi faible), **tout** le précache échoue, y compris les fichiers locaux critiques (`index.html`, `style.css`, `app.js`). Risque jugé plus grand que le bénéfice. `config.js` (local, fiable) a été ajouté à la précache à la place ; le CDN reste couvert par la stratégie fetch existante (network-first + fallback cache), qui le met en cache après un premier chargement réussi — déjà le comportement pour `jsPDF`, pas une régression.
