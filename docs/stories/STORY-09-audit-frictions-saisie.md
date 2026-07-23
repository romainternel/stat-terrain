# STORY-09 — Audit des frictions du workflow de saisie

**En tant que** Romain,
**Je veux** vérifier s'il reste des points de friction dans le workflow de saisie d'action (sélection action → équipe → joueur → terrain → zone de but → validation),
**Afin de** ne pas ajouter de polish visuel ou de responsive iPhone par-dessus un workflow qui aurait encore des irritants non résolus.

## Contexte technique

- Cette story est une **investigation**, pas une implémentation — elle peut ne déboucher sur aucun changement de code si rien n'est trouvé.
- Zone à revoir : `validateActionPanel()`, `clickActionPlayer()`, `clickGoalZone()`, `autoValidatePending()`, `selectAction()` dans `app.js`.
- Point de départ : l'historique git montre plusieurs correctifs récents sur ce workflow (terrain requis pour tirs Fenix, flow 2 étapes strict pour la zone de but, suppression d'événement avec confirmation) — vérifier que ces correctifs couvrent bien tous les cas, en conditions réelles de match si possible.

## Point de vigilance suite au test visuel du 2026-07-23

L'app a été lancée et pilotée réellement en local (captures dans `docs/design/screenshots/`) pour juger la densité visuelle et le responsive — voir les preuves ajoutées à STORY-02 et STORY-03. **Ce test n'a pas validé le workflow de saisie lui-même** : les écrans Match ont été obtenus par injection directe de l'état (`S.events`, `S.view`) via la console, pas en cliquant réellement sur le fil action → équipe → joueur → terrain → zone de but → validation. Cette story reste donc entière : aucun élément ci-dessus ne permet de dire que les frictions de saisie sont vérifiées ou absentes.

## Critères d'acceptation

- [ ] Romain (ou le Developer en simulant un match) passe en revue les cas suivants sans surprise : but normal, but sur pénalty, PD après but, tir arrêté, tir non cadré, PB/PO/jet franc (sans zone de but), 2min/carton rouge/TM.
- [ ] Une liste documentée des frictions trouvées est produite (fichier ou note), même si la conclusion est "rien à corriger".
- [ ] Si des frictions sont trouvées, elles sont reformulées en nouvelles stories par le Scrum Master avant d'être implémentées — cette story ne code rien elle-même.

## Hors scope

- Toute correction de code (sera une story séparée si besoin).

## Dépend de

Aucune. Recommandé avant STORY-02/STORY-03 (une friction trouvée ici pourrait changer l'approche du responsive), mais non bloquant si Romain préfère avancer en parallèle.

## Taille

S
