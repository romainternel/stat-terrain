# QA — STORY-40 (PDF : grille "Zones d'origine du tir")

## Ce que j'ai lu avant de tester
`docs/stories/STORY-40-zones-origine-tir-pdf.md`, `docs/code-review/STORY-40.md` (APPROUVÉ), `docs/design/` et `docs/visual/zones-origine-tir-et-split-mitemps.md`.

## Méthode
Deux PDF générés via CDP (appel direct de `generatePDF()`, capture du buffer sans déclencher le téléchargement natif) :
1. `pdf-story39-test.pdf` — jeu volumineux hérité de STORY-39 (14 FENIX + 14 IVRY, 43 événements) : vérifie l'absence de régression de pagination/centrage sur un volume réaliste.
2. `pdf-story40-zones.pdf` — jeu dédié (7 événements, un par zone attendue : ALG/PVT/ALD/ARG/DC/ARD/AUTRE, coordonnées x/y choisies précisément pour chaque zone) : vérifie que la classification et le rendu sont corrects zone par zone, ce que le jeu STORY-39 ne pouvait pas prouver (tous ses tirs sont proches du but par construction, donc tous classés PVT).

## Critères d'acceptation

**Page Gardiens**
- [x] Carte renommée "ZONES D'IMPACT & D'ORIGINE", position/taille de carte inchangées (`card(g.x,58,halfW,30)`) — confirmé, aucun ajout de hauteur de page
- [x] Grille Impact réduite (34×14mm) à gauche, grille Origine (34×14mm) à droite, même carte — confirmé visuellement
- [x] Légende 2 lignes tient sans chevaucher les grilles — confirmé
- [x] Disposition ALG/PVT/ALD puis ARG/DC/ARD, bande AUTRE seulement si tir(s) classé(s) — confirmé sur le jeu dédié : les 6 cellules + la bande AUTRE affichent chacune exactement la valeur attendue (1/1, 1/1, 0/1 / 1/1, 0/1, 1/1, AUTRE 0/1), aucune zone manquante ni surnuméraire
- [x] Couleurs identiques à Impact (vert >50%, cyan sinon, neutre si vide, jamais rouge) — confirmé, correspondance exacte avec les ratios affichés sur les 7 zones test
- [x] Même jeu d'événements que la grille Impact du même gardien, bucketé par zone d'origine — confirmé (mêmes 7 tirs, deux angles de lecture cohérents entre eux)
- [x] `ACTIONS[e.type]?.isGoal/isSave/isOff` utilisés (pas de comparaison exacte) — confirmé par lecture de code (Code Review)

**Page Carte tir joueur**
- [x] Grille Origine sous la grille Impact existante, même largeur, label court — confirmé
- [x] `scCellH`=62mm, grille Origine toujours visible (x/y toujours présents) — confirmé
- [x] Effectif complet (14+14) : aucune carte coupée, pagination cohérente — confirmé (toujours 6 pages sur ce jeu, dernières cartes impaires centrées des deux côtés)
- [x] Dernière carte à ligne impaire centrée — confirmé sur les deux jeux de test (#8 Simon/#8 Vidal sur le jeu volumineux, carte seule #2 Lemoine sur le jeu dédié)

## Cas limites testés
- **Gardien sans tir affronté** (Koch côté GB Adversaire dans le jeu dédié, 0 tir) : carte "0/0", grilles Impact et Origine entièrement neutres, aucun crash, aucune division par zéro visible.
- **Joueur avec tirs mais sans donnée `goalZone`** (#4 Baron, jeu volumineux STORY-39) : le bloc Impact est absent (comportement hérité, correct — `S.trackGK` non homogène dans ce jeu de test), et la grille Origine **remonte automatiquement** à la position qu'aurait occupée Impact, sans laisser d'espace vide orphelin — comportement au-delà de la spec initiale de l'Architect, ajouté par le Developer et confirmé correct visuellement.
- **Bande AUTRE** : présente et correctement dimensionnée uniquement quand au moins un tir lointain existe (confirmée présente sur le jeu dédié où un tir cible explicitement y=90%, absente sur le jeu STORY-39 où aucun tir n'atteint cette distance).

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune — page Gardiens (stats GB, Localisation tirs, Timeline, Notes du coach) et Carte tir joueur (rendu FENIX, centrage) visuellement conformes à leur état post-STORY-39, en dehors des changements prévus par cette story.

## Verdict
**PASSED**
