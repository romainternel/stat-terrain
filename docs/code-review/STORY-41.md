# Code Review — STORY-41 (PDF : split 1ère/2e mi-temps sur le tableau Joueurs)

## Portée revue
`app.js` : `playerStats` (agrégation utilisée par le Top 3 et la page Joueurs, ~ligne 4770) enrichi de `mt1`/`mt2`, fallback objects mis à jour (2 sites), `drawPlayerTable()` (colonnes/largeurs), constante `tableX` de centrage. Comparé à `docs/stories/STORY-41-split-mitemps-tableau-joueurs-pdf.md` et `docs/arch/zones-origine-tir-et-split-mitemps.md`.

## Conformité architecture
- Colonnes `["#","NOM","POSTE","MT1","MT2","PD","TIRS","EFF%","PB","2M"]`, largeurs `[10,28,15,9,9,12,13,15,12,12]` (135mm) — exactement conformes à la spec Architect.
- Calcul `mt1`/`mt2` via `ACTIONS[e.type]?.isGoal` + `(e.period||1)===2` — respecte la convention STORY-37 (jamais de comparaison exacte de type), inclut donc correctement les variantes `PEN_GOAL`.

## Point trouvé et corrigé pendant l'implémentation (pas laissé pour le Code Reviewer)
La constante `tableX` (calcul de centrage du tableau, au site d'appel) était câblée en dur sur `130` — l'ancien total de `colW` — **indépendamment** du `totalW` recalculé à l'intérieur de `drawPlayerTable()`. La spec Architect supposait ce centrage "déjà dynamique", ce qui était inexact pour cette constante précise (elle l'est pour la largeur de la carte de fond, pas pour la position `x` de départ). Corrigé en même temps que le reste du changement (`135`, avec commentaire expliquant le lien), pas un residu — signalé ici pour traçabilité, puisque c'est le genre d'écart silencieux (tableau décalé de 2.5mm, pas cassé mais pas pixel-perfect) que STORY-39 avait justement pour objectif d'éliminer.

## Conventions de code
Style identique à l'existant (mêmes fonctions `grn()`/`t2()`/`red()` pour la coloration conditionnelle des cellules, mêmes tailles de police). Aucune nouvelle convention introduite.

## Réutilisation vs duplication
Aucune duplication — modification in-place de `drawPlayerTable()`, pas de nouvelle fonction créée (conforme à la story, taille S).

## Scope
Aucun fichier hors `app.js`. Aucune fonction partagée hors du périmètre touchée.

## Vérification visuelle
Jeu de données STORY-39 (14v14) : colonnes MT1/MT2 lisibles, cohérentes avec le Top 3 (ex. joueur à "2/3T" total apparaît bien "MT1=2, MT2=0"), tableau FENIX et ADVERSAIRE tous deux correctement centrés après la correction de `tableX`, aucun chevauchement, footer de pagination intact.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** : le correctif `tableX` ci-dessus mérite d'être gardé en tête pour un futur ajout de colonne — la centrage n'est pas automatiquement dérivé de `colW`, il faut mettre à jour les deux en parallèle.

## Verdict
**APPROUVÉ**
