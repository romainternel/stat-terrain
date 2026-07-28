# Risques — Terrain et affichage des joueurs

*Produit par le Risk Analyst — squad build BMAD*
*S'appuie sur `docs/architecture/terrain-joueurs.md`*

## Tableau des risques

| # | Risque | Probabilité | Impact | Recommandation |
|---|---|---|---|---|
| 1 | **Changement de comportement immédiatement visible** (F11) : Romain (ou un aidant) qui ouvre l'app sans avoir sélectionné de roster verra un terrain vide au lieu de "tout le monde par défaut" — exactement le cas de la capture d'écran fournie. Risque de penser que l'app est cassée plutôt que de comprendre le nouveau comportement voulu. | Élevée (déjà son cas actuel) | Moyen | Le message d'état vide (`docs/design/terrain-joueurs.md`) doit être explicite et visible dès le premier chargement après déploiement — pas une simple absence silencieuse. À mentionner clairement dans le message de livraison de la story, pas juste dans le changelog technique. |
| 2 | **Imprécision géométrique du terrain redessiné** (F10) : reproduire à la main les proportions réglementaires (zone 6m, ligne 9m, penalty 7m, 4m) dans un référentiel SVG 350×208 est fastidieux — une erreur de rayon/position donnerait un terrain visuellement "faux" aux yeux d'un coach de hand qui connaît les proportions exactes. | Moyenne | Moyen | Test visuel comparatif obligatoire (ancien rendu vs nouveau, côte à côte) avant de considérer F10 terminé, et validation explicite de Romain (lui-même expert du domaine) avant mise en production définitive — ne pas se fier uniquement à "ça a l'air correct" du point de vue Developer. |
| 3 | **Suppression incomplète de `COURT_IMG`** : la constante est utilisée à au moins 3-4 endroits distincts du code (`.court-pick` en Match, SVG de tir en Stats, éventuellement `renderPlayerDetail`/heatmap). Si un site d'usage est oublié lors du remplacement, cet écran affichera une image cassée ou une erreur JS après suppression de la constante. | Moyenne | Élevé (écran cassé visible immédiatement) | Recherche exhaustive de toutes les références à `COURT_IMG` avant suppression (`grep -n "COURT_IMG"` sur tout `app.js`), et test visuel de **chaque** écran qui affiche un terrain (Match, Stats Gardiens, Stats Joueurs si applicable, PD/2min) avant de livrer — pas seulement l'écran Match. |
| 4 | **Friction sur les sélecteurs PD/2min** (F11 appliqué uniformément) : si Romain veut assigner une passe décisive ou un carton à un joueur qu'il n'a pas sélectionné pour le match (oubli), le terrain de sélection sera vide et il sera bloqué tant qu'il n'aura pas ajouté ce joueur dans Équipes. | Faible à moyenne | Moyen | Risque accepté (cohérence du comportement jugée plus importante par l'Architecte), mais à surveiller après déploiement — si Romain remonte cette friction concrètement, un correctif différencié (fallback conservé uniquement sur ces 2 écrans-là) pourra être ajouté rapidement. |
| 5 | **Performance du SVG dessiné** vs image raster | Faible | Faible | Non significatif — quelques éléments `<path>`/`<line>` statiques sont moins coûteux à rendre qu'une image JPEG décodée. Pas d'action nécessaire. |

## Classement

- **P0** : aucun — rien ici ne doit bloquer le développement.
- **P1 (critères d'acceptation obligatoires)** : #1 (message d'état vide clair et communication explicite à la livraison), #2 (validation visuelle de Romain avant clôture de F10), #3 (recherche exhaustive + test de chaque écran avant suppression de `COURT_IMG`).
- **P2** : #4 (à surveiller, pas à corriger préventivement).
- **P3** : #5 (accepté, non significatif).

## Stories de mitigation recommandées

- **#1, #2, #3 → critères d'acceptation** ajoutés directement aux stories concernées par le Scrum Master, pas des stories séparées.
- **#4 → pas de story maintenant**, juste une ligne de vigilance dans la checklist de régression une fois livré.
