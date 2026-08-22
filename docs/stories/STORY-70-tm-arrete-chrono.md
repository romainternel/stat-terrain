# STORY-70 — Le temps mort arrête le chrono

**En tant que** Romain (ou tout aidant occasionnel) en train de saisir un match,
**Je veux** que cliquer sur "⏸ TM" arrête réellement le chrono,
**Afin de** ne pas fausser le temps de jeu affiché pendant toute la durée du temps mort.

Demande directe de Romain — bug confirmé par lecture de code (`docs/brief-v17-chrono-mi-temps.md`, point 1).

## Contexte technique
- Zone concernée : `recordTM(team)` (`app.js:963-980`) — c'est la fonction réellement câblée sur le bouton `.mlt-btn-tm` du timer (celle décrite dans `CLAUDE.md`, pas l'ancien chemin `clickTeam()` qui, lui, appelle déjà `stopTimer()`).
- Nouvelles structures : aucune.
- Impact sur l'existant : aucun autre point d'appel de `recordTM()` dans le code — modification isolée à cette seule fonction.
- Détail exact du correctif : `docs/architecture/chrono-mi-temps.md` section F1.

## Critères d'acceptation
- [ ] Cliquer "⏸ TM" pour FENIX (`recordTM('home')`) arrête visiblement le chrono — le bouton ▶/⏸ (`t-toggle`) passe à l'état pause, le temps affiché cesse d'avancer.
- [ ] Cliquer "⏸ TM" pour l'adversaire (`recordTM('away')`) arrête également le chrono — le comportement ne dépend pas de l'équipe qui prend le temps mort.
- [ ] Un temps mort refusé (plus de TM disponible pour FENIX, toast "Plus de temps mort disponible !") ne touche pas le chrono — il continue de tourner normalement si déjà en cours.
- [ ] Le chrono ne redémarre pas tout seul à la fin du temps mort — reprise manuelle via le bouton ▶/⏸ existant, comme n'importe quelle pause.
- [ ] Comportement vérifié en Mode Simple **et** Mode Expert (le bouton TM du timer est partagé entre les deux modes).
- [ ] `new Function()` passe sur `app.js` modifié.

## Hors scope
- Le compteur de temps morts par mi-temps (`S.tmUsed`, max 2/mi-temps, 3 au total) — logique inchangée.
- Le fait que le compteur `S.tmUsed` ne suit aujourd'hui que les TM de l'équipe `home` (pas de limite/compteur pour l'adversaire) — comportement pré-existant, hors scope de cette story.
- Le changement de mi-temps (`per-btn`) — traité séparément dans STORY-71.

## Dépend de
Aucune

## Taille
S
