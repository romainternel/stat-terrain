# STORY-15 — Indicateur de statut de synchronisation

**En tant que** Romain,
**Je veux** un indicateur discret de l'état de synchronisation pendant le match,
**Afin de** savoir sans y penser si mes données sont bien centralisées, sans que ça me distraie du jeu.

## Contexte technique

- Zone concernée : `renderScoreboard()` ou équivalent dans `app.js`, `style.css` pour le style de l'indicateur.
- Trois états : `✓ sync` (à jour), `↻` (envoi en cours), `⚠ hors-ligne` (pas de réseau, la saisie continue normalement).
- Maquette : `docs/design/acces-partage-et-reprise-match.md` section 3.
- Cette story **remplace/absorbe** le bandeau de rappel d'export manuel du cycle 1 (STORY-06) : avec la sync automatique en continu, un rappel d'export manuel séparé perd sa raison d'être — l'indicateur "hors-ligne prolongé" en tient lieu. Le bouton d'export manuel existant (`exportAllMatches`) reste disponible en secours (ex : dans les réglages), mais sans bandeau dédié.

## Critères d'acceptation

- [ ] L'indicateur reflète correctement les trois états selon l'état réel de la file de synchronisation.
- [ ] Il n'est jamais alarmant ni intrusif (pas de popup, pas de son) — un simple élément visuel discret dans la scoreboard.
- [ ] `docs/stories/STORY-06-bandeau-rappel-sauvegarde.md` (cycle 1) est marquée comme superseded par cette story lors du passage en développement.

## Hors scope

- Toute action automatique déclenchée par l'état "hors-ligne" (pas de retry manuel exposé à l'utilisateur, ça reste automatique en arrière-plan).

## Dépend de

STORY-12.

## Taille

S
