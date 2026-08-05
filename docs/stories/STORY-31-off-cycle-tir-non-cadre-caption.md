# STORY-31 — Corrections hors-cycle : zone de but pour tir non cadré + légende heatmap

## Origine
Deux retours directs de Romain le même jour, traités hors du cycle BMAD complet (corrections ciblées, faible risque, testées directement) :

1. « Quand il y a un tir non cadré, il ne faut pas demander la zone dans le but où il y a eu l'impact puisqu'il est non cadré. »
2. « Ajouter en italique à côté ou au-dessus du visuel d'impact "Stat des tireurs (ex : 1/1 = 1 but et non arrêt)" » — clarification demandée après avoir vu le ratio `1/1` dans la heatmap de zones (STORY-30) et craint une confusion avec un ratio d'arrêts du gardien.

## Comportement avant / après

### 1. Tir non cadré (OFF)
- **Avant** : après avoir sélectionné le joueur puis la position d'impact sur le terrain, l'app demandait aussi une zone dans le but (comme pour un But ou un Tir arrêté) — alors qu'un tir non cadré, par définition, n'atteint jamais le but.
- **Après** : la position d'impact reste demandée (utile pour la heatmap de zones de tir sur le terrain), mais l'événement se valide immédiatement après, sans jamais afficher le sélecteur de zone de but. Aucun changement pour But et Tir arrêté (et leurs variantes pénalty, qui bypassaient déjà tout le workflow terrain/zone).

### 2. Légende de la heatmap de zones
- **Avant** : la grille 3×3 affichait un ratio (`1/1`, `0/1`...) par zone sans aucune explication du sens de ce ratio.
- **Après** : une légende discrète en italique ("Stat des tireurs (ex : 1/1 = 1 but et non arrêt)") apparaît juste au-dessus de la grille, partout où `goalZoneHeatmap()` est utilisée (actuellement : la feuille gardien fusionnée de STORY-30). Clarifie que le ratio est but/tir du point de vue du tireur, jamais un ratio d'arrêts du gardien, même quand la heatmap est affichée dans le contexte d'une carte gardien.

## Notes d'implémentation
- `clickCourtPosition(x,y)` : condition de validation automatique étendue de `!S.trackGK` à `!S.trackGK || act.isOff`.
- `renderMatchPanel()` (rendu du panneau d'action) : `showGZ` (affichage du sélecteur de zone) exclut désormais explicitement `act.isOff`.
- `goalZoneHeatmap(shots, width)` : ajout d'un `<div>` de légende avant la grille — n'ajoute aucune occurrence de `grid-template-columns`, ne casse pas le contrat plein écran de STORY-30 (vérifié : toujours exactement 1 `grid-template-columns`/1 `svg`/1 `fs-btn` par feuille gardien).
- Vérifié par test réel CDP : workflow complet OFF (joueur → position → validation immédiate, `goalZone:null`), non-régression GOAL/SAVE (zone toujours demandée, toujours fonctionnelle), légende visible avec le bon texte, contrat plein écran intact.
- Pas de pipeline `/verifie` complet convoqué : corrections ciblées à faible risque (logique de workflow déjà bien testée + ajout de texte pur), testées directement, cohérent avec le traitement déjà appliqué à STORY-28.

## Taille
XS
