# STORY-58 — PB/Jet franc taguables sur le terrain + surbrillance possession plus prononcée

**En tant que** Romain,
**Je veux** pouvoir taguer l'emplacement d'un PB sur le terrain en Mode Expert, et voir plus nettement quelle équipe a la possession,
**Afin de** fiabiliser la saisie et suivre le jeu d'un coup d'œil.

"Quand je clique sur PB en mode expert je peux pas taguer l'endroit sur le terrain." + "J'aimerais que la surbrillance de l'équipe en possession soit plus prononcée."

## Bug PB/Jet franc — root cause
`TURNOVER` (PB) et `FREEKICK` (Jet franc) ont toujours eu `needsMap:true` dans `ACTIONS`, mais 4 endroits du code ne vérifiaient que `act.isGoal||act.isSave||act.isOff` pour décider de passer à l'étape terrain — TURNOVER/FREEKICK n'ayant aucun de ces 3 flags, ils tombaient systématiquement dans la branche "validation instantanée après le tap joueur", sans jamais atteindre la surface de tag (`clickActionPlayer()`). Confirmé par un commentaire déjà présent dans le code de STORY-44 ("marqueurs PB, needsMap déjà vrai mais jamais dessiné") — ce bug empêchait la capture de position depuis l'introduction du PB, aucun événement PB n'a donc jamais eu de vraies coordonnées x/y avant ce correctif.

**4 points corrigés, tous généralisés de `isGoal||isSave||isOff` vers une logique explicite couvrant aussi TURNOVER/FREEKICK :**
1. `clickActionPlayer()` — passe à l'étape terrain si `act.needsMap` (au lieu de la liste des 3 types de tir), sans quoi le clic joueur validait tout de suite.
2. `renderMatchPanel()` (`shotAction`) — même généralisation, sinon l'UI n'affiche jamais la surface de tag même si `clickActionPlayer()` la propose.
3. `clickCourtPosition()` — valide immédiatement le tap si `!(act.isGoal||act.isSave)` (pas seulement `act.isOff`) : PB et jet franc n'ont pas de zone de but, donc pas d'étape supplémentaire après le tag de position.
4. `renderShotCourt()` (`showGZ`) — la grille "zone d'impact dans le but" ne s'affiche que pour un vrai tir cadré (`isGoal||isSave`), jamais pour PB/jet franc.

## Vérifié par CDP (vrais clics, Mode Expert)
PB : sélection action → clic joueur → panneau reste ouvert, surface de tag terrain affichée (`[data-court-position]`, capture d'écran) → clic sur le terrain → événement enregistré avec `x:30,y:40` (coordonnées réelles, plus jamais `null`), panneau fermé, possession basculée. Jet franc : même parcours vérifié indépendamment, `x:60,y:50` capturés correctement.

## Surbrillance possession
`.ml-team-active` (bordure 2px→3px, fond 9%→18% opacité, glow renforcé) et `.mlt-poss-btn.mlt-poss-active` (bordure 1.5px→2px, fond 15%→22%, glow élargi) — les deux mécanismes qui composent la mise en avant de l'équipe en possession, amplifiés ensemble pour un contraste net avec l'équipe inactive (vérifié visuellement par capture d'écran, `box-sizing:border-box` déjà global donc aucun décalage de mise en page au changement d'épaisseur de bordure).

## Taille
S — 4 points de code coordonnés pour le bug (même risque de cohérence que M6/STORY-53 en plus petit), + 2 blocs CSS pour la surbrillance.
