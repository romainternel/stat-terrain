# STORY-14 — Reprendre un match en cours sur un autre appareil

**En tant que** Romain (ou la personne qui m'aide),
**Je veux** pouvoir ouvrir un match déjà commencé depuis un nouvel appareil,
**Afin de** passer la main pendant le match sans avoir à ressaisir quoi que ce soit.

## Contexte technique

- Zone concernée : nouvel écran "Matchs" (maquette `docs/design/acces-partage-et-reprise-match.md`), nouvelles fonctions `fetchInProgressMatches()`, `resumeMatch(matchId)`.
- Au chargement (après connexion), requêter `matches` où `status='in_progress'`.
- `resumeMatch()` charge le snapshot `matches` (score, GK, timer, roster) + tous les `match_events` liés, reconstitue `S`, puis appelle `subscribeMatchEvents()` (STORY-13) pour continuer à recevoir les événements suivants.

## Critères d'acceptation

- [x] Si un match est en cours (statut `in_progress`), l'app le propose clairement avec un bouton "Reprendre" — implémenté comme un écran dédié affiché juste après connexion (pas seulement dans l'onglet "Matchs"), pour qu'un aidant qui ouvre l'app tombe dessus sans avoir à chercher.
- [x] Reprendre un match restaure l'état où il en était : équipes + effectifs + sélection, gardiens, période, chrono (recalculé si le timer tournait), tous les événements déjà saisis — testé avec des données simulées (mock du client Supabase), reconstruction vérifiée champ par champ.
- [x] Si aucun match n'est en cours, le comportement actuel reste identique — `checkForResumableMatch()` ne modifie rien si `fetchInProgressMatches()` ne retourne rien.
- [x] Après reprise, les nouveaux événements sont synchronisés (STORY-12/13) — `resumeMatch()` appelle `subscribeMatchEvents(matchId)` et pose `S.currentMatchId`, donc `queueEventForSync` utilise le même id que l'appareil d'origine.
- [ ] **Non vérifiable par mes soins** : test réel de bout en bout (créer un match sur l'appareil A, le reprendre sur l'appareil B, vérifier que le score/l'effectif/les événements correspondent exactement) — nécessite une vraie session. À faire par Romain.

## Hors scope

- Migration des matchs déjà en local avant ce cycle (décision de Romain : seuls les nouveaux matchs utilisent Supabase).

## Dépend de

STORY-10, STORY-13.

## Taille

M

## Notes Developer

- **Retrofit nécessaire, découvert en implémentant** : STORY-12 n'écrivait qu'une ligne `matches` minimale (id, status, noms d'équipe) pour satisfaire la contrainte de clé étrangère — insuffisant pour une vraie reprise (pas de roster, pas de GK, pas d'état du chrono). `ensureMatchRegistered()` a été transformée en `upsertMatchSnapshot()`, qui écrit désormais l'état complet, appelée à chaque changement significatif (démarrage/arrêt du chrono, changement de mi-temps, changement de gardien, changement de sélection de roster), pas seulement une fois à la création.
- **Le match est maintenant créé dès "Lancer le match"**, pas seulement au premier événement saisi (comme c'était le cas depuis STORY-12) — sinon un aidant ouvrant l'app dans les premières minutes d'un match (avant le premier but) ne trouverait aucun match "en cours" à reprendre.
- L'écran de proposition de reprise s'affiche **juste après la connexion** (dans `checkAuthSession()`/`signInShared()`), pas seulement dans l'onglet "Matchs" comme suggéré par la maquette initiale — plus fiable pour qu'un aidant tombe dessus sans avoir à deviner où chercher. Ne se déclenche que si `S.currentMatchId` est encore `null` sur cet appareil (pas de proposition si cet appareil a déjà son propre match actif).
- `resumeMatch()` recalcule le temps écoulé si le chrono tournait au moment du snapshot (`time_offset_seconds + (maintenant - last_start_at)`), conformément au principe déjà posé par l'Architecture (pas de write Supabase à chaque seconde).
- **Ajout non demandé explicitement mais nécessaire** : `markMatchFinished()`, appelée à la sauvegarde du match (`saveMatch()`) et au démarrage d'un nouveau match (`newMatch()`) — sans ça, un match resterait "en cours" indéfiniment sur Supabase et continuerait à apparaître comme "reprenable" bien après la fin réelle du match.
- Testé (CDP, client Supabase mocké pour simuler les réponses réseau) : reconstruction complète d'un match (équipes, effectifs, période, chrono, événements triés chronologiquement) à partir de données simulées — vérifiée champ par champ, pas juste "ça ne plante pas". Écran de proposition testé visuellement et fonctionnellement (bouton Reprendre, bouton Nouveau match/dismiss). Aucune régression détectée sur le parcours Expert complet ni sur les 5 écrans de l'app.
- **Non testable par mes soins** : le vrai scénario bout-en-bout (créer sur A, reprendre sur B) nécessite une vraie session Supabase.
