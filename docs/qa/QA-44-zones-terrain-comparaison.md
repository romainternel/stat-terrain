# QA — STORY-44 (Zones sur le terrain : nouveau visuel dans Comparaison)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-44-zones-terrain-comparaison.md` (révisée), `docs/code-review/STORY-44.md` (APPROUVÉ), `docs/design/` et `docs/arch/zones-terrain-et-tableau-joueurs.md` (section F6 révisée).

## Méthode
CDP sur Chrome headless. La requête DOM (`document.querySelectorAll`) reste indisponible après navigation cross-origin sur cette machine (bug d'outillage déjà documenté en STORY-43, sans lien avec le code applicatif) — vérification par appel direct de `renderCompareCourt('home'|'away')` via `Runtime.evaluate`, rendu du HTML retourné dans une page autonome avec la vraie feuille de style, capture d'écran réelle. Jeux de données dédiés : (1) un jeu réparti sur toute la largeur du terrain pour les deux équipes, points et zones, avec buts/arrêts/hors-cadre/PB ; (2) un jeu à 0 événement pour le cas vide.

## Critères d'acceptation

- [x] Bloc placé entre le tableau comparatif+évolution et "🎯 Tirs par poste" — confirmé par lecture du `return` de `renderStatCompare()` (`${compareCourtSvg}${posSvg}`) et par la capture d'écran (bloc terrain visible, à la position attendue dans le flux)
- [x] Agrège tous les tirs de l'équipe, pas un joueur en particulier — jeu de test avec 2 tireurs différents côté FENIX (Lemoine, Dupont), les deux apparaissent sur le même mini-terrain
- [x] En-tête `Buts/Tirs` et `PB` — confirmé cohérent avec le jeu de données (FENIX 1/3 + 2 PB, IVRY 1/1 + 1 PB) sur la capture
- [x] Bouton de bascule partagé — `S.shotViewMode` piloté globalement, testé en changeant l'état puis en ré-appelant `renderCompareCourt()` : reflète bien le nouveau mode, aucun état local propre à cet écran
- [x] Mode "points" : but/arrêt/hors-cadre + marqueurs PB distincts (losange rouge) — confirmé visuellement, légende affichée sous le terrain
- [x] Mode "zones" : 8 zones + marqueur 7m, ratio buts/tirs uniquement, **aucune trace de PB dans les zones** — confirmé sur la capture (le total PB reste seulement dans la stat d'en-tête)
- [x] Aucune régression sur le tableau comparatif, l'évolution du score et "Tirs par poste" — ces 3 blocs n'ont subi aucune modification de code, seule une nouvelle chaîne est insérée entre eux dans le retour de la fonction

## Cas limites testés
- **Aucun événement** (`S.events=[]`) : `renderCompareCourt('home')` ne lève aucune exception en mode points ni en mode zones, en-tête affiche "0/0" et "0" PB, terrain neutre sans marqueur.
- **Bug d'échelle découvert en cours de vérification** (cf. STORY-46) : le premier jeu de test (valeurs proches de l'origine, dans la continuité des tests STORY-43) ne permettait pas de détecter un problème de mise à l'échelle. Un second jeu volontairement réparti sur 5%-95% de la largeur a révélé que tous les marqueurs se regroupaient dans le coin haut-gauche — corrigé avant cette validation (cf. QA-46), re-testé avec succès après correctif (marqueurs répartis sur toute la largeur, cf. capture `compare-court-points-render.png` en scratchpad de session).

## Bugs trouvés
Aucun dans le périmètre strict de STORY-44 — le bug de mise à l'échelle découvert pendant cette vérification est traité comme un défaut pré-existant séparé, cf. `docs/qa/QA-46-bug-echelle-points-tir-svg.md`.

## Régressions détectées
Aucune — tableau comparatif, graphique d'évolution du score et carte "Tirs par poste" visuellement inchangés en dehors du nouveau bloc inséré entre eux.

## Verdict
**PASSED**
