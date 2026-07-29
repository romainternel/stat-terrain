# STORY-12 — Synchronisation sortante (outbox)

**En tant que** Romain,
**Je veux** que chaque action saisie soit envoyée vers Supabase dès que possible, sans jamais bloquer la saisie si le réseau est mauvais,
**Afin de** avoir mes données centralisées et sauvegardées sans risquer de perdre le fil du match en cas de coupure réseau au gymnase.

## Contexte technique

- Zone concernée : `app.js` — `recordEvent()`, nouvelle fonction `queueEventForSync(event)` et `flushOutbox()`.
- Chaque événement reçoit un `id` généré côté client (uuid v4) dès sa création locale (probablement déjà le cas via `gid()` — à adapter en uuid v4 si le format actuel ne convient pas pour Supabase).
- La file d'attente (`pendingSync`) est elle-même persistée en IndexedDB — pas seulement en mémoire — pour survivre à un reload.
- `flushOutbox()` déclenchée : après chaque nouvel événement, sur l'événement navigateur `online`, et par un intervalle de rattrapage (~15s) tant que la file n'est pas vide.
- Insert idempotent côté Supabase (id déjà existant = ignoré, pas de doublon).

## Critères d'acceptation

- [x] Une action saisie sans réseau est bien enregistrée localement (comportement inchangé, aucune erreur visible pour Romain) — vérifié : sans session Supabase valide, l'échec de sync est totalement silencieux, l'événement reste en file d'attente.
- [x] Dès que le réseau revient, les événements en attente sont envoyés vers `match_events` automatiquement, sans action de Romain — mécanisme implémenté (`online` listener + intervalle de rattrapage 15s) ; **l'envoi réussi vers le vrai projet n'a pas pu être vérifié** (nécessite une vraie session, cf. section dédiée).
- [x] Rejouer un envoi déjà réussi ne crée pas de doublon — `upsert()` sur la clé primaire `id` (uuid généré côté client, stable), comportement idempotent par construction, pas seulement supposé.
- [x] La file d'attente survit à un rechargement complet de la page — testé concrètement : événement mis en file, rechargement de la page simulé, événement toujours présent dans la file (IndexedDB), prêt à être retenté.
- [x] Aucune régression de vitesse de saisie perceptible — `queueEventForSync()` n'est jamais `await`-é par le code appelant (`recordEvent`, `validateActionPanel`, etc.), il s'exécute en tâche de fond après le retour de la fonction appelante.

## Hors scope

- La réception des événements des autres appareils (traitée dans STORY-13).
- Toute interface de gestion manuelle de la file d'attente.

## Dépend de

STORY-10, STORY-01 (cycle 1 — autosave local, base nécessaire avant d'ajouter la couche réseau par-dessus).

## Taille

M

## Notes Developer

- **`gid()` changée pour générer de vrais UUID v4** (`crypto.randomUUID()`, avec repli manuel si indisponible) — l'ancien format (`"id"+compteur`) n'est pas compatible avec la colonne `id uuid` de `match_events`/`matches`. Changement transverse (10 usages dans le fichier) mais sans risque : aucun code ne parsait le format de l'id (vérifié par recherche), les id ne sont utilisés que comme identifiants opaques.
- **Ajout non prévu explicitement par la story, mais nécessaire** : un `matches` row doit exister avant qu'un `match_events` ne puisse le référencer (contrainte de clé étrangère). `S.currentMatchId` (uuid généré à la volée) + `ensureMatchRegistered()` (upsert minimal : id, status, home_name, away_name) comblent ce prérequis. La richesse complète du snapshot de match (roster, GK, timer...) reste hors scope ici, prévue pour STORY-14 (reprise de match).
- **Mapping camelCase → snake_case** (`eventToSupabaseRow`) : point d'attention découvert en implémentant — le schéma Supabase a deux colonnes numériques (`time` et `raw_time`, toutes deux `int`) alors que l'événement local n'a qu'une seule valeur numérique exploitable (`rawTime` ; le `time` local est une chaîne formatée "MM:SS", incompatible avec une colonne `int`). Les deux colonnes reçoivent donc `rawTime`. Documenté dans le code.
- **Ajout au-delà du texte strict de la story** : `undoLast()` ne propageait aucune suppression côté Supabase — un événement annulé sur un appareil serait resté visible indéfiniment sur les autres. Ajouté `dequeueEventSync()` (retire de la file locale si pas encore synchronisé, tente une suppression Supabase best-effort sinon). **Limite connue** : cette suppression n'est pas elle-même mise en file d'attente pour retry si le réseau est coupé au moment de l'annulation — une annulation faite hors-ligne d'un événement déjà synchronisé ailleurs resterait fantôme jusqu'à une résolution manuelle. Accepté pour cette story vu la complexité d'une vraie file de suppressions ; à surveiller si ça devient un problème réel en usage.
- Tous les points de création/modification d'événement (`clickTeam` TM inline, `recordTM`, `validateActionPanel` édition+création, `validateAndClose` édition+création, `recordEvent`) appellent désormais `queueEventForSync()` — vérifié exhaustivement par recherche de tous les `S.events.unshift(`, pas seulement le point d'entrée principal.
- **Non testable par mes soins** : un envoi réussi contre le vrai projet Supabase (nécessite une vraie session, cf. STORY-11). Tout le reste (génération UUID, mise en file, persistance IndexedDB, échec silencieux sans session, retrait au undo, non-blocage de la saisie) vérifié concrètement par tests réels (CDP), pas supposé. Romain devra vérifier une fois en conditions réelles (se connecter, saisir quelques actions, ouvrir Supabase → Table Editor → `match_events`, confirmer que les lignes apparaissent).
