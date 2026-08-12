# PRD v8 — Terrain à effectif variable par poste + corrections PDF (itération 3)

## Objectif
Faire tenir le repositionnement du terrain et l'export PDF livrés cette session à l'épreuve d'un usage réel à effectif complet (14-16 joueurs par équipe), sans nouveau correctif ponctuel à la prochaine variation de volume de données.

## Features

### F1 — Disposition Pivot à 3 et 4 joueurs (Must Have)
`courtPlayerPositions()` ne dispose proprement que 1 ou 2 joueurs par poste (spread simple, horizontal ou vertical). Pour le poste PVT (le seul où Romain a un effectif > 2 dans son test), il faut :
- 3 joueurs → triangle : un joueur centré au-dessus (plus proche du but), deux joueurs en dessous de part et d'autre
- 4 joueurs → carré : deux joueurs de chaque côté, sur deux profondeurs
- Généraliser le point d'entrée (`courtPlayerPositions()`) pour que ce ne soit pas un `if/else` spécifique au poste PVT uniquement, au cas où un autre poste se retrouve un jour avec 3-4 joueurs sélectionnés (DC, ARG, ARD notamment, déjà en spread vertical à 2)
- 5+ joueurs à un même poste : comportement dégradé mais jamais cassé (pas d'objectif de disposition dédiée — cf. Hors scope)

### F2 — Pagination PDF robuste (Must Have)
Cause racine identifiée par Romain lui-même : la page Joueurs (2 tableaux à hauteur variable) et le graphique Évolution du score partagent la même page, dont la hauteur de contenu dépend directement de la taille des deux effectifs. Avec deux effectifs complets, ça déborde.
- Évolution du score déplacé sur sa propre page, indépendante de la longueur des tableaux Joueurs
- Revue de l'ensemble du document pour toute autre section dont la position dépend d'une hauteur non bornée (tableaux Joueurs eux-mêmes, cartes de tir) — l'Architect tranche si une protection générique (garde de débordement avant `doc.addPage()`) est nécessaire au-delà de ce cas précis
- Chevauchement page 1 (bandeau d'en-tête / carte score) : à reproduire avec un jeu de données chargé des deux côtés ; très probablement absorbé par le même correctif de fond, sinon traité comme bug distinct

### F3 — Glyphe Top 3 illisible (Must Have)
"★" s'affiche "&" (police standard jsPDF sans le glyphe Unicode). Remplacer par du texte ASCII sûr partout où un caractère non-standard a pu se glisser dans le PDF cette session (audit rapide de `generatePDF()` en plus du seul Top 3).

### F4 — Zones d'impact Gardiens : cohérence avec l'app (Must Have)
Le ratio affiché dans l'encart PDF (arrêts/total, perspective gardien) ne dit pas la même chose que le même encart dans l'app en direct (buts/total, perspective tireur, fonction `goalZoneHeatmap()`). Un coach qui compare les deux se trompe de lecture. Le PDF doit reproduire exactement la sémantique de l'app : même ratio, même seuil de couleur, même légende explicative. Les lettres de zone (HG/HC...) sous chaque cellule, jugées redondantes avec la position dans la grille, sont retirées.

### F5 — Top 3 : gardien qualifié affiché sur base "cadrés" (Should Have)
Actuellement `gkS.totalAll`/calcul maison (inclut les tirs hors-cadre). Bascule sur `gkS.total`/`gkS.pct`, déjà calculés par `gkStats()` sur la base arrêts/tirs cadrés — cohérent avec le reste de l'app (cf. CLAUDE.md, section Stats GB).

### F6 — Carte tir joueur : effectif adverse + centrage (Should Have)
La page ne documente que les tireurs FENIX. Ajouter les tireurs adverses, même format, sur le modèle de ce qui a déjà été fait pour le tableau Joueurs (FENIX puis ADVERSAIRE). Centrer la grille — visible aujourd'hui sur une dernière ligne à nombre impair de cartes, restée collée à gauche.

## Priorités
- **Must Have** : F1, F2, F3, F4 — bugs qui cassent visuellement un livrable (terrain illisible, PDF qui déborde, chiffre trompeur) dans un usage désormais réel, pas hypothétique
- **Should Have** : F5, F6 — améliorations de complétude/précision, pas de casse visible aujourd'hui

## Critères d'acceptation
- F1 : effectif à 3 puis 4 pivots sélectionnés, terrain affiché en mode Match, aucun chevauchement visuel à 2 largeurs d'écran différentes (large et étroite)
- F2 : PDF généré avec 14 joueurs FENIX + 14 joueurs adverses sélectionnés, chaque page inspectée individuellement, aucun élément coupé ou chevauchant un autre ou le pied de page
- F3 : Top 3 avec au moins 1 entrée, rang 1 affiché lisiblement (pas "&")
- F4 : Zones d'impact Gardiens PDF affiche le même ratio et la même couleur que l'écran Gardiens de l'app en direct pour un même jeu d'événements, légende présente
- F5 : un gardien qualifié en Top 3 affiche `saves/total_cadrés (pct%)`, vérifié contre un cas avec au moins un tir hors-cadre encaissé
- F6 : page Carte tir joueur avec des tirs des deux côtés affiche les deux sections ; dernière ligne à nombre impair de cartes centrée, pas collée à gauche

## Hors scope
- Disposition dédiée pour 5+ joueurs à un même poste
- Toute modification du fond blanc / encarts bleus / structure Top 3 mixte joueurs+GB / tableau ADVERSAIRE déjà livrés, non mentionnés dans les retours
- Idée "Steazzi" (graphique buts/minute) — discussion ultérieure, pas de développement

## Dépendances
- F2 (pagination) doit être traité avant ou en même temps que F6 (ajout de contenu sur la page Carte tir joueur) : ajouter des cartes adverses sans revoir la pagination reproduirait le même bug de débordement sur cette page
- F4 s'appuie sur `goalZoneHeatmap()` (app) existante comme référence de comportement — ne pas la modifier, seulement aligner le PDF dessus

## Risques
- Risque de régression sur les 3 itérations PDF déjà livrées cette session (fond blanc, Top 3, tableau ADVERSAIRE) si les correctifs de pagination touchent des coordonnées partagées — voir `docs/risks/`
- Risque que la disposition triangle/carré du terrain, une fois généralisée au-delà de PVT, change le rendu visuel de postes qui fonctionnaient déjà bien à 2 joueurs (ARG/ARD/DC) — à circonscrire précisément dans l'Architecture
