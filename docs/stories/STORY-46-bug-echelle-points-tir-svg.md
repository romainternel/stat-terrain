# STORY-46 — Bug : mise à l'échelle des points de tir jamais appliquée (mode "points")

**Découvert pendant** le développement de STORY-44 (nouveau bloc terrain Comparaison), pas rapporté par Romain — trouvé en vérifiant visuellement le rendu des nouveaux marqueurs PB, en comparant à un jeu de test réparti sur toute la largeur du terrain.

## Constat

`S.events[].x`/`.y` sont enregistrés en **pourcentage (0-100)** par `clickCourtPosition()` (`e.clientX/rect.width*100`, cf. commentaire déjà présent ligne ~4770 : *"Tirs — x/y enregistrés en % (0-100)"*). Le SVG des terrains Stats utilise un `viewBox="0 0 350 208"`. `shotZoneCourt()` (mode "zones", STORY-43) convertit correctement (`xPct/100*350`), tout comme le PDF (`drawCourt()` : `s.x/100*cw`). **Le rendu "points" (mode historique, antérieur à STORY-43) ne faisait jamais cette conversion** — il plaçait `cx="${s.x}"` directement, une valeur 0-100 dans un repère 0-350×0-208.

**Effet réel** : en mode "points", tous les tirs d'un match — quel que soit l'endroit réel du terrain où le tir a été tapé — s'affichaient compressés dans le coin haut-gauche du terrain (≈29% de la largeur, ≈48% de la hauteur), au lieu d'occuper tout le terrain. Un tir à l'aile droite ou proche de la ligne des 9m loin sur la droite apparaissait donc visuellement près du but/du centre, jamais vers la droite ou vers le bas.

**Sites affectés** (mode "points" uniquement — le mode "zones" n'a jamais eu ce problème) :
- `renderShotOverlay()` (~ligne 2536) — écran Match, aperçu des tirs déjà pris par l'équipe pendant la sélection d'une nouvelle position
- `renderPlayerDetail()` (~ligne 2706) — Stats → Joueurs
- `renderGkSheet()` (~ligne 3453) — Stats → Gardiens
- `renderCompareCourt()` (nouveau, STORY-44) — aurait hérité du même bug s'il n'avait pas été corrigé avant livraison

**Non affecté** : mode "zones" (STORY-43, conversion déjà correcte dans `shotZoneCourt()`), export PDF (conversion déjà correcte dans `drawCourt()`), les données brutes elles-mêmes (`S.events[].x/.y` ne sont pas altérées — c'est un bug d'affichage pur, aucune donnée de match n'est perdue ni faussée).

## Correctif

Ajout de `const sx=s.x/100*350, sy=s.y/100*208;` (même formule que `shotZoneCourt()`) avant chaque usage de `s.x`/`s.y` comme coordonnée SVG, aux 4 sites listés ci-dessus. Aucun changement de structure de données, aucune migration nécessaire — un match déjà sauvegardé affichera immédiatement ses tirs à la bonne position dès rechargement de la page (le fix est purement dans le code de rendu, pas dans le stockage).

## Impact visible pour Romain

Les points de tir vont désormais apparaître **répartis sur tout le terrain** au lieu d'être regroupés près du but/du centre — un changement de rendu visible sur des matchs déjà enregistrés, sans aucune perte ni modification de données. À signaler explicitement pour ne pas surprendre lors de la prochaine consultation de Stats → Joueurs/Gardiens.

## Hors scope
Aucun changement de `S.events[].x/.y` ni de la logique de capture (`clickCourtPosition()`) — uniquement le rendu SVG en mode "points".

## Taille
S — correctif mécanique, même formule déjà éprouvée (utilisée par `shotZoneCourt()` et le PDF depuis STORY-43/PDF historique), appliqué à l'identique à 4 endroits.
