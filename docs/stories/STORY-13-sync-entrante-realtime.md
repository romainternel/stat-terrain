# STORY-13 — Synchronisation entrante (temps réel)

**En tant que** Romain,
**Je veux** voir apparaître les actions saisies depuis un autre appareil sur le même match,
**Afin de** pouvoir passer la main (ou la partager ponctuellement) sans perdre le fil de ce qui a déjà été saisi ailleurs.

## Contexte technique

- Zone concernée : `app.js` — nouvelle fonction `subscribeMatchEvents(matchId)` (abonnement Supabase Realtime sur `match_events`, filtré par `match_id`), `mergeRemoteEvent(event)`.
- Un événement reçu est fusionné dans `S.events` (par `id` — ignoré s'il existe déjà, évite les doublons avec les événements déjà présents localement), puis `R()` est appelé pour rafraîchir l'affichage.
- **Test explicite obligatoire** (finding du Risk Analyst, `docs/risks/supabase-multiuser.md` #2) : ouvrir le même match sur deux appareils/onglets réels et vérifier la réception en quelques secondes — pas seulement en local/localhost.

## Critères d'acceptation

- [ ] **Non vérifiable par mes soins** : une action saisie sur l'appareil A apparaît dans le feed et les stats de l'appareil B en quelques secondes. Nécessite une vraie session (identifiants de Romain) et idéalement deux appareils/onglets réels — cf. section dédiée à faire par Romain.
- [x] Aucun doublon visuel/statistique quand un événement arrive à la fois localement et via l'abonnement temps réel — testé directement sur la logique de fusion (`mergeRemoteEvent`) : un écho d'un événement déjà connu (même id) est mis à jour en place, jamais dupliqué.
- [x] La déconnexion/reconnexion réseau ne casse pas l'abonnement de façon permanente — un ré-abonnement défensif est déclenché sur l'événement navigateur `online`, en plus de la reconnexion automatique déjà gérée par la librairie `supabase-js` elle-même.
- [ ] **Non vérifiable par mes soins** : test sur le vrai déploiement (pas seulement localhost) confirmant que RLS n'empêche pas silencieusement la réception. **Point critique découvert en implémentant** : Supabase nécessite en plus d'**activer explicitement le Realtime** sur la table `match_events` (réplication PostgreSQL), une étape absente du script SQL initial de STORY-10. Sans ça, aucune erreur ne serait levée — l'abonnement semblerait fonctionner mais ne recevrait jamais rien, exactement le scénario silencieux redouté par le Risk Analyst. Script fourni : `docs/supabase-realtime-setup.sql`, à exécuter par Romain avant tout test.

## Hors scope

- Résolution de conflit avancée en cas de double saisie réelle de la même action (accepté comme risque mineur, corrigible via le feed éditable existant).

## Dépend de

STORY-10, STORY-12.

## Taille

M

## Notes Developer
- `subscribeMatchEvents(matchId)` : crée un canal Supabase Realtime filtré sur `match_id`, écoute `postgres_changes` (INSERT/UPDATE/DELETE confondus, `event:'*'`). Un seul canal actif à la fois (`realtimeChannel` global) — se désabonne proprement de l'ancien avant d'en recréer un nouveau, pour éviter d'accumuler des abonnements fantômes si `subscribeMatchEvents` est rappelée (ex : reconnexion réseau).
- `mergeRemoteEvent(row)` : reconvertit la ligne Supabase (snake_case) vers le format local (camelCase) via `supabaseRowToEvent` (symétrique de `eventToSupabaseRow` de STORY-12), puis fusionne dans `S.events` — mise à jour en place si l'id existe déjà (déduplique naturellement l'écho de ses propres écritures), sinon insertion à la **bonne position chronologique** (comparaison période puis temps de jeu), pas juste ajouté en tête — nécessaire car `S.events[0]` est utilisé ailleurs dans l'app comme "le dernier événement".
- Le canal s'abonne dès que `S.currentMatchId` est créé (premier événement du match, dans `queueEventForSync`), et se désabonne explicitement dans `newMatch()`.
- **Point trouvé en implémentant, absent du texte de la story** : Supabase exige d'ajouter la table à la publication `supabase_realtime` (`alter publication supabase_realtime add table match_events;`) en plus de RLS — sans ça, le risque #2 du Risk Analyst se matérialiserait exactement comme redouté (silencieux, pas d'erreur). Script séparé fourni (`docs/supabase-realtime-setup.sql`) plutôt que de modifier le script STORY-10 déjà exécuté.
- Testé directement (CDP) : mapping snake_case→camelCase correct, insertion chronologique correcte (événement inséré entre deux existants selon `rawTime`), dédoublonnage par id vérifié (écho d'un événement connu → mise à jour en place, pas de doublon), suppression distante simulée retire le bon événement, `subscribeMatchEvents`/`unsubscribeMatchEvents` ne lèvent aucune exception.
- **Non testable par mes soins** : réception réelle d'un événement inséré par un autre appareil/session (nécessite deux sessions authentifiées réelles). C'est le cœur même de cette story — la vérification par Romain n'est pas optionnelle ici, c'est le critère d'acceptation obligatoire posé par le Risk Analyst (`docs/risks/supabase-multiuser.md` #2).
