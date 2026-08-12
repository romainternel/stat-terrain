# Code Review — STORY-38 (Disposition Pivot à 3 et 4 joueurs)

## Conformité architecture
Conforme à `docs/arch/terrain-postes-multiples-et-pdf-v2.md` — le mode `spread:"grid"` implémenté reprend le code proposé quasi verbatim (table de layouts `{dx,dy}` par effectif, fallback générique 2 colonnes pour 5+, clamps `Math.max/min` identiques à l'existant).

## Scope
Strictement contenu à `POS_XY.PVT` et `courtPlayerPositions()` (app.js). Aucun fichier hors périmètre touché, aucun des 4 sites d'appel (`renderMatchPanel`, `renderPenRoster`, `renderPdSelect`, `renderPlayerSelect`) modifié — conforme à la story.

## Réutilisation vs duplication
`cpBoxStyle()` inchangée, consomme `{cx,cy,anchor}` sans connaître le mode de spread — bonne séparation des responsabilités déjà en place, respectée.

## Lisibilité et maintenabilité
La table `layouts` (objet littéral indexé par effectif) est plus lisible qu'une cascade de `if(n===3){...}else if(n===4){...}`. Le fallback 5+ est clairement commenté comme non prioritaire (cohérent avec le PRD).

## Remarques

**Note (non-bloquant)** — Le mode `spread:"h"` (branche juste au-dessus de `"grid"` dans `courtPlayerPositions()`) n'est désormais référencé par aucune entrée de `POS_XY` : PVT était son seul consommateur avant cette story. Ce n'est pas du code mort au sens strict (la branche reste fonctionnelle et testée par construction, ce n'est pas une fonction orpheline jamais appelée type `renderMiniCompare()`), mais une option de configuration actuellement inutilisée. L'Architecture justifie explicitement de garder ce type de mécanisme générique disponible pour un poste futur — décision respectée, pas de changement demandé ici. À surveiller si elle reste inutilisée sur plusieurs cycles.

**Note** — Les clamps `Math.max(6,Math.min(94,...))` / `Math.max(4,Math.min(96,...))` sont dupliqués à l'identique dans les 3 branches (`h`, `grid`, spread vertical par défaut). Pas un problème introduit par cette story (déjà présent avant), mais un candidat naturel à factoriser si `courtPlayerPositions()` reçoit une 4e branche un jour.

## Vérification manuelle (rapporté par le Developer)
Testé à 3 et 4 pivots sélectionnés, à 3 largeurs de viewport (1600px, 1000px, 800px landscape) — aucun chevauchement observé, y compris au point le plus contraint (800px, boîtes adjacentes mais non chevauchantes). 1 et 2 pivots : formule strictement identique à l'ancien mode `"h"` pour n=1,2 (vérifié par lecture — `layouts[2]` reproduit exactement `(i-(n-1)/2)*hSpread`), aucune régression attendue sur les autres postes (non touchés).

## Verdict
**APPROUVÉ**
