# STORY-71 — Confirmation et garde-fous au changement de mi-temps

**En tant que** Romain (ou tout aidant occasionnel) en train de saisir un match,
**Je veux** qu'un changement de mi-temps (bouton "MT") demande toujours confirmation, remette le chrono dans un état cohérent selon le sens du changement, et me rappelle de vérifier les gardiens en passant en mi-temps 2,
**Afin de** ne jamais perdre le repère de temps de jeu sur un clic accidentel, et ne jamais oublier un changement de gardien à la pause.

Demande directe de Romain (`docs/brief-v17-chrono-mi-temps.md`, point 2).

## Contexte technique
- Zone concernée : handler de `per-btn` (`app.js:4981`), remplacé par une nouvelle fonction nommée `switchPeriod()`. Deux emplacements de rendu du bouton (`app.js:2343` et `app.js:2470`) partagent déjà le même `id="per-btn"` et sont re-bindés après chaque `R()` — aucun changement nécessaire à ces deux lignes de rendu elles-mêmes.
- Nouvelles structures : aucune — réutilise `S.period`, `S.time`, `S.running`, `S.events`, `S.tmLastAlert`, `S.halfTimeLastAlert` déjà existants.
- Impact sur l'existant : le compteur `S.tmUsed` (temps morts par mi-temps) n'est **jamais** modifié par cette story, dans aucun des deux sens.
- Détail exact du correctif (les deux branches, code complet) : `docs/architecture/chrono-mi-temps.md` section F2+F3+F4+F5.
- Maquette exacte des deux messages : `docs/design/chrono-mi-temps.md`.
- Choix de styles de toast (neutre vs alerte) : `docs/visual/chrono-mi-temps.md`.
- Risques à couvrir explicitement en critères d'acceptation : `docs/risks/chrono-mi-temps.md` (#1 lisibilité des deux messages, #4 comportement `safeConfirm()` sur vrai iPad).

## Critères d'acceptation
- [ ] Cliquer "MT 1" (période courante = 1) ouvre une confirmation demandant si la mi-temps 1 est terminée.
- [ ] Annuler cette confirmation : la période reste 1, le chrono et son état running (en cours ou en pause) restent strictement inchangés, aucun toast affiché.
- [ ] Confirmer cette confirmation : la période passe à 2, le chrono affiche `00:00` et est **en cours d'exécution** sans action supplémentaire (pas besoin de recliquer sur ▶), et un message d'alerte "vérifier les gardiens" s'affiche immédiatement après.
- [ ] Cliquer "MT 2" (période courante = 2) ouvre une confirmation demandant de revenir à la mi-temps 1, avec le temps de retour affiché explicitement dans le message (ex: "reprendre à 12:34").
- [ ] Annuler cette confirmation : la période reste 2, le chrono et son état running restent strictement inchangés, aucun toast affiché.
- [ ] Confirmer cette confirmation : la période repasse à 1, le chrono affiche le temps du **dernier événement tagué en mi-temps 1** (le plus récent événement avec `period===1` dans `S.events`) et reste **en pause** — aucune alerte gardien dans ce sens.
- [ ] Si aucun événement n'a été tagué en mi-temps 1 au moment d'un retour confirmé, le chrono se repositionne sur `30:00` et le message affiché reste cohérent avec cette valeur.
- [ ] Le compteur de temps morts par mi-temps (`S.tmUsed`) est identique avant et après un aller-retour MT1→MT2→MT1, quel que soit le nombre de temps morts déjà pris.
- [ ] **Vérification explicite sur iPad réel** (cf. risque #1) : les deux messages de confirmation sont lus côte à côte et sont sans ambiguïté sur leur destination (le texte des boutons nomme la mi-temps cible, jamais un "OK" générique).
- [ ] **Vérification explicite sur iPad réel** (cf. risque #4) : `safeConfirm()` se comporte comme une vraie boîte de dialogue bloquante dans Safari (pas de bascule silencieuse en `true` par défaut) avant de considérer la story terminée.
- [ ] Comportement vérifié en Mode Simple **et** Mode Expert (timer et bouton MT partagés entre les deux modes).
- [ ] `new Function()` passe sur `app.js` modifié.

## Hors scope
- Détection automatique d'un changement réel de gardien (comparaison technique de `gkId` avant/après) — l'alerte reste un simple rappel, pas une vérification (cf. PRD, Hors scope).
- Redémarrage automatique du chrono après un retour confirmé vers mi-temps 1 — reste en pause volontairement (cf. Architecture, alternative rejetée).
- Toute nouvelle segmentation des zones de tir (6m / 6-9m / 9m) mentionnée par Romain en passant — pas cadrée dans ce cycle.
- Modification du rappel automatique de fin de MT1 réglementaire (toast + bouton pulsant à 30min, `checkHalfTimeReminder()`) — comportement inchangé.
- Correction rétroactive des matchs déjà archivés dont des événements de "2e mi-temps" portent `period:1` à cause de l'ancien bug — aucune migration prévue (cf. Risques, #5).

## Dépend de
Aucune (indépendante de STORY-70, même si les deux touchent le même timer)

## Taille
M
