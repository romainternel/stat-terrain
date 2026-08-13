# QA — STORY-41 (PDF : split 1ère/2e mi-temps sur le tableau Joueurs)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-41-split-mitemps-tableau-joueurs-pdf.md`, `docs/code-review/STORY-41.md` (APPROUVÉ, avec la correction `tableX` documentée).

## Méthode
PDF généré via CDP sur le jeu volumineux STORY-39 (14 FENIX + 14 IVRY, 43 événements répartis explicitement entre `period:1` et `period:2` dans le script de test).

## Critères d'acceptation
- [x] Colonne "BUTS" remplacée par "MT1"/"MT2", même style d'en-tête/cellule — confirmé visuellement
- [x] Valeurs calculées via `ACTIONS[e.type]?.isGoal` + `(e.period||1)` — confirmé par recoupement manuel : `H3` (Top 3 "2/3T (67%)") affiche MT1=2/MT2=0 dans le tableau, `A1` (Top 3 "4/10T (40%)") affiche MT1=0/MT2=4 — cohérent avec le total affiché ailleurs sur la même page
- [x] Centrage du tableau (`tableX`) correct avec la largeur totale 135mm — confirmé après la correction relevée par le Code Reviewer (le tableau était décalé de 2.5mm avant ce correctif, invisible à l'œil nu mais désormais exact)
- [x] Effectif complet (14+14) : tableaux FENIX puis ADVERSAIRE lisibles, sans chevauchement, colonnes MT1/MT2 lisibles même à 1-2 chiffres — confirmé
- [x] Aucune régression sur les autres colonnes ni sur la pagination Joueurs/Évolution héritée de STORY-39 — confirmé, page Évolution toujours sur sa propre page, footer "Page X/6" intact

## Bugs trouvés
Aucun (le décalage de centrage de 2.5mm a été trouvé et corrigé **avant** cette étape QA, pendant l'implémentation/revue — documenté dans `docs/code-review/STORY-41.md`, pas un bug résiduel).

## Régressions détectées
Aucune.

## Verdict
**PASSED**
