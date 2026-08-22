# PRD — Chrono : temps mort et changement de mi-temps

## Objectif
Le chrono affiché reflète toujours le temps réellement joué, et le changement de mi-temps devient un geste volontaire et réversible plutôt qu'un clic instantané sans garde-fou.

## Features

### F1 — Le temps mort arrête le chrono
`recordTM()` (le bouton "⏸ TM" du timer, celui réellement utilisé en match) doit arrêter le chrono au moment où le temps mort est enregistré, pour les deux équipes (pas seulement FENIX). Le chrono ne redémarre pas tout seul à la fin du temps mort — l'utilisateur reprend la main via le bouton ▶/⏸ existant, comme pour n'importe quelle pause.

### F2 — Confirmation avant tout changement de mi-temps, dans les deux sens
Le clic sur le bouton "MT" ne bascule plus jamais la période sans confirmation explicite (`safeConfirm`, déjà utilisé ailleurs dans l'app pour la bascule Expert→Simple).
- **MT1 → MT2** : "La mi-temps 1 est-elle terminée ?" (formulation exacte laissée au Designer). Annulé → aucun changement d'état. Confirmé → passage en MT2.
- **MT2 → MT1** : "Revenir à la mi-temps 1 ?". Annulé → aucun changement d'état. Confirmé → retour en MT1.

### F3 — Chrono remis à 0 et relancé automatiquement en MT2 validée
Une fois le passage MT1→MT2 confirmé : chrono remis à 00:00 **et relancé automatiquement** (running), sans action supplémentaire de l'utilisateur — contrairement au comportement actuel qui remettait à 0 mais laissait le chrono à l'arrêt.

### F4 — Chrono restauré au dernier tag de MT1 en cas de retour validé
Une fois le retour MT2→MT1 confirmé : le chrono ne repart pas à 0 et ne garde pas le temps de MT2 — il se repositionne sur le temps du **dernier événement réellement tagué pendant MT1** (le plus récent événement avec `period===1`). S'il n'existe aucun événement en MT1 (mi-temps changée avant le moindre tag), le chrono se repositionne sur 30:00 (durée réglementaire d'une mi-temps), qui est déjà la référence utilisée ailleurs dans l'app (`checkHalfTimeReminder()`, seuil des 1800s).

### F5 — Alerte "vérifier les gardiens" au passage validé vers MT2 uniquement
Immédiatement après un passage MT1→MT2 confirmé (F2+F3), un message alerte l'utilisateur de vérifier que les gardiens sélectionnés pour chaque équipe sont toujours les bons — simple rappel visuel, aucune vérification automatique de `gkId`. Ce message n'apparaît jamais au retour MT2→MT1.

## Priorités
- **Must Have** : F1, F2, F3, F4, F5 — les cinq forment un seul comportement cohérent demandé explicitement par Romain, aucune n'a de valeur isolée sans les autres (une confirmation sans reset automatique, ou un reset sans confirmation, seraient tous les deux incomplets par rapport à la demande).
- **Should Have** : aucun — scope volontairement resserré à ce qui a été demandé.
- **Nice to Have** : détection automatique d'un changement de gardien (comparer le `gkId` avant/après plutôt qu'un simple rappel) — explicitement reporté, cf. Hors scope.

## Critères d'acceptation
- [ ] Cliquer "⏸ TM" arrête visiblement le chrono (bouton ▶/⏸ passe à l'état "en pause"), pour FENIX comme pour l'adversaire.
- [ ] Cliquer "MT" en MT1 ouvre une confirmation ; annuler laisse la période, le chrono et l'état running strictement inchangés.
- [ ] Confirmer ce même clic : période passe à 2, chrono affiche 00:00, chrono en cours d'exécution sans action supplémentaire, message de rappel gardiens affiché.
- [ ] Cliquer "MT" en MT2 ouvre une confirmation ; annuler laisse la période, le chrono et l'état running strictement inchangés.
- [ ] Confirmer ce même clic : période repasse à 1, chrono affiche le temps du dernier événement tagué en MT1 (ou 30:00 si aucun événement en MT1), aucun message gardiens affiché.
- [ ] Le compteur de temps morts par mi-temps (`S.tmUsed`) n'est pas affecté par un aller-retour MT1↔MT2.
- [ ] Comportement vérifié dans les deux modes de saisie (Simple et Expert) — le bouton MT et le timer sont partagés entre les deux.

## Hors scope
- Détection automatique d'un changement de gardien réel (comparaison technique de `gkId`) — l'alerte reste un rappel humain, pas une vérification.
- Toute nouvelle segmentation des zones de tir (6m / 6-9m / 9m) mentionnée par Romain en passant — pas cadrée ici, à reprendre dans un futur brief si confirmée.
- Redémarrage automatique du chrono après un retour confirmé vers MT1 — tranché en Architecture (cf. question en suspens du Brief) : le chrono se repositionne mais **reste à l'arrêt**, cohérent avec le fait que ce sens du changement est une correction d'erreur, pas un vrai début de mi-temps (voir Architecture pour le raisonnement complet).
- Modification du rappel automatique de fin de MT1 réglementaire (toast + bouton pulsant à 30min) — comportement inchangé.

## Dépendances
Aucune — s'appuie uniquement sur du code déjà existant (`startTimer()`, `stopTimer()`, `safeConfirm()`, `showToast()`, `S.events`).

## Risques
Détaillés par le Risk Analyst (`docs/risks/chrono-mi-temps.md`) — notamment le risque de confondre les deux sens de confirmation (messages trop similaires) et l'impact d'un `window.confirm()` bloquant en plein match si le geste est déclenché par erreur pendant une phase de jeu active.
