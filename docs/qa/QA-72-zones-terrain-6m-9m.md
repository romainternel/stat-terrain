# QA — STORY-72 : vraie distinction 6m / 6-9m / 9m sur le terrain de zones

*Produit par le QA — squad de contrôle BMAD*
*S'appuie sur `docs/code-review/STORY-72.md` (APPROUVÉ)*

## Méthode
Vérification programmatique de la classification (points de test à distance réelle connue) + vérification visuelle des polygones rendus (captures d'écran isolant chaque zone avec des couleurs contrastées, comparées avant/après le correctif de débordement trouvé en Code Review).

## Critères validés
- ✅ `shotZoneCourt()` retourne `6MC`/`69MC`/`9MC` correctement pour 3 points à distance réelle connue dans le couloir central (5m→6MC, 7.5m→69MC, 11m→9MC) — vérifié programmatiquement, les 3 correspondent exactement.
- ✅ Même distinction vérifiée pour les couloirs Gauche et Droit (6MG/69MG/9MG et 6MD/69MD/9MD), 6 points de test supplémentaires, tous corrects.
- ✅ Les zones d'aile (`AILG`/`AILD`) restent non subdivisées par profondeur — vérifié programmatiquement (2 points de test) et visuellement (la forme triangulaire d'origine est inchangée).
- ✅ **Méthode de vérification incrémentale respectée** (critère explicite de la story) : l'Architecture imposait de valider l'arc R6 avant de construire des polygones remplis. Le Code Review confirme que cette méthode a été suivie et a intercepté un vrai défaut (débordement de `6MG`/`6MD` sur le territoire `AILG`/`AILD`) avant d'atteindre cette étape QA.
- ✅ Le terrain "zones" affiche les 11 zones sans trou ni chevauchement visible — confirmé sur les captures de vérification (couleurs contrastées volontairement pour rendre tout chevauchement immédiatement visible ; aucun résidu de couleur inattendu constaté après le correctif).
- ✅ Le mode "points" (`S.shotViewMode==="points"`) n'est pas affecté — vérifié par inspection : aucun site d'appel de `shotZoneCourt()`/`buildCourtZones()`/`renderCourtZones()` n'est touché par ce diff, et ces fonctions ne sont invoquées que lorsque `S.shotViewMode==="zones"` (comportement déjà établi, non modifié ici).
- ✅ `_courtZonesCache` continue de fonctionner (calcul une seule fois) — le mécanisme de mémoïsation (`if(_courtZonesCache) return _courtZonesCache;`) n'a pas été touché.
- ✅ `new Function()` passe sur `app.js` modifié.

## Critère non vérifiable par le QA — statut explicite
- ⏳ **Revalidation visuelle explicite par Romain** (PRD F5, critère non négociable) : non satisfaisable par le QA lui-même — cet écran a déjà demandé 8 itérations de prototype avant sa première validation, et le PRD exige spécifiquement l'œil de Romain, pas seulement une vérification technique. Les captures produites pendant le développement (Code Review) donnent une base solide pour cette revue, mais **ne la remplacent pas**.

## Régression
- Aucune régression trouvée sur les zones déjà en production (`AILG`/`AILD`/`9MG`/`9MC`/`9MD` gardent exactement leur géométrie d'origine, seuls leurs "voisins internes" changent).
- `renderCourtZones()`/`aggregateCourtZones()` non modifiées, comportement d'agrégation par équipe/GB/joueur inchangé pour les 3 écrans consommateurs (Comparaison, Gardiens, Joueurs).

## Bugs trouvés
Aucun restant — le seul défaut identifié pendant le cycle (débordement `6MG`/`6MD` sur `AILG`/`AILD`) a été trouvé et corrigé **avant** cette étape QA (cf. Code Review), pas remonté ici.

## Verdict
**PASSED AVEC RÉSERVES**

La réserve porte exclusivement sur le critère F5 du PRD (revalidation visuelle par Romain), qui reste ouvert par construction — aucun désaccord technique, juste une étape humaine qui ne peut pas être cochée par le squad de contrôle lui-même. Recommandation : montrer le rendu réel à Romain avant de considérer cette story définitivement close, même après un éventuel feu vert E2E.
