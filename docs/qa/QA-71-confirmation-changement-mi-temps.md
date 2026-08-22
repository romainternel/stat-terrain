# QA — STORY-71 : confirmation et garde-fous au changement de mi-temps

*Produit par le QA — squad de contrôle BMAD*
*S'appuie sur `docs/code-review/STORY-71.md` (APPROUVÉ AVEC RÉSERVES)*

## Méthode
Trace de code pour les critères logiques (état, calculs, garde-fous), délégation à l'E2E Tester pour le point soulevé par le Code Reviewer (la distinction entre les deux dialogues repose entièrement sur le texte du message, `window.confirm()` ne permettant pas de personnaliser les boutons — à vérifier en conditions de lecture réelle, pas sur le papier).

## Critères validés
- ✅ Clic "MT 1" ouvre une confirmation (`safeConfirm`) demandant si la mi-temps 1 est terminée.
- ✅ Annuler : `return` immédiat avant toute mutation de `S.period`/`S.time`/`S.running` — aucun changement d'état, aucun toast.
- ✅ Confirmer : `S.period=2`, `S.time=0`, `startTimer()` → `S.running=true` avec un nouvel `setInterval` propre (précédé d'un `stopTimer()` qui coupe l'éventuel intervalle en cours — pas de risque de double-intervalle), toast alerte gardiens (`isAlert:true`, donc tracé dans `S.alertHistory`).
- ✅ Clic "MT 2" ouvre une confirmation demandant de revenir à la mi-temps 1, avec le temps de retour affiché explicitement dans le message (`fmtTime(restoreTime)` interpolé, pas un texte générique).
- ✅ Annuler : `return` immédiat, aucun changement d'état, aucun toast — même garantie que dans l'autre sens.
- ✅ Confirmer : `S.period=1`, `S.time` restauré au `rawTime` du plus récent événement `period===1` de `S.events` (le tableau est unshift-ordonné, `.find()` retourne donc bien le plus récent) ; `stopTimer()` appelé avant la mutation → `S.running=false` garanti, aucune alerte gardien dans ce sens.
- ✅ Fallback `1800` (30:00) si aucun événement `period===1` n'existe — testé par lecture directe de l'expression ternaire, cas couvert sans exception.
- ✅ `S.tmUsed` (compteur de temps morts) : aucune ligne de `switchPeriod()` n'y touche, dans aucune des deux branches — un aller-retour MT1→MT2→MT1 laisse les compteurs strictement intacts.
- ✅ Mode Simple et Expert : `per-btn` vit dans le bloc scoreboard/timer partagé (`renderMatch()`, au-dessus du branchement `S.mode`, déjà confirmé lors de la QA de STORY-70) — un seul point de liaison, pas deux implémentations à recouper.
- ✅ `new Function()` passe sur `app.js` modifié.

## Point signalé par le Code Reviewer — statut
Le risque #1 (`docs/risks/chrono-mi-temps.md`) prescrivait une distinction par le **texte des boutons** ("Oui, MT2"/"Oui, MT1") — techniquement impossible avec `window.confirm()` (boutons toujours "OK"/"Annuler", non personnalisables). L'implémentation compense en mettant toute l'information distinctive dans le **corps du message**. Les deux textes réels :
- MT1→MT2 : *"La mi-temps 1 est-elle terminée ? Le chrono va repasser à 0:00 et redémarrer automatiquement en mi-temps 2."*
- MT2→MT1 : *"Revenir à la mi-temps 1 ? Le chrono va reprendre à MM:SS et rester en pause."*

Les deux messages nomment explicitement la mi-temps cible dès la première phrase et ne partagent aucune formulation commune — jugé suffisamment distinct à la lecture. **Reste à confirmer en conditions réelles** (vrai dialogue natif, pas un texte lu dans le code) — délégué à l'E2E Tester, cf. section dédiée du risque P1.

## Régression
- `checkHalfTimeReminder()` : logique de seuil (`S.period===1 && S.time>=1800`) non modifiée — un retour en MT1 avec `restoreTime>=1800` réactivera normalement le rappel dès que le chrono est relancé manuellement, comportement attendu, pas une régression.
- `upsertMatchSnapshot()` (sync multi-appareil) : toujours appelé dans les deux branches (via `startTimer()` ou explicitement), la propagation de la période/du chrono aux autres appareils connectés reste fonctionnelle.
- Alertes TM conseillé/changez de GB, rappel de mi-temps : aucun de ces mécanismes n'est appelé depuis `switchPeriod()`, comportement inchangé.

## Bugs trouvés
Aucun.

## Verdict
**PASSED**

Recommandation pour l'E2E Tester : exécuter les deux sens du changement de mi-temps avec Annuler ET Confirmer (4 scénarios), lire réellement le texte des deux dialogues natifs affichés par le navigateur (pas seulement vérifier qu'ils s'ouvrent), et confirmer que le chrono atterrit bien sur les valeurs attendues (0:00 en cours d'exécution / temps du dernier tag en pause).
