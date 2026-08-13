# Visual — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

## Palette et style — rien de nouveau, réemploi strict de l'existant
Aucune nouvelle couleur introduite. Réutilisation exacte de :
- Vert `[80,200,120]` : zone où buts/total > 0.5
- Cyan `[78,205,232]` : zone où buts/total ≤ 0.5 (avec au moins 1 tir)
- Bleu foncé neutre `[28,43,64]` : zone sans tir enregistré
- Blanc `[232,232,232]` (fonction `wh()`) : texte du ratio, `helvetica bold`
- Bordure/accent équipe : `g.color` déjà porté par la boucle Gardiens (vert FENIX / rouge adversaire) pour les titres de section, comme partout ailleurs sur cette page

## Règle absolue reconduite (STORY-39)
Aucun caractère non-ASCII dans un appel `doc.text()` de `generatePDF()`. Les labels de zone ("ALG", "ARG", "DC", "ARD", "ALD", "PVT", "Autre") sont déjà purement ASCII — aucun risque de glyphe cassé comme le bug "★"→"&" corrigé en STORY-39.

## Page Gardiens — carte "ZONES D'IMPACT & D'ORIGINE"
Carte existante `card(g.x,58,halfW,30)` conservée telle quelle (position, taille). À l'intérieur :
- Titre renommé : `"ZONES D'IMPACT & D'ORIGINE"` (fontSize 8, bold, couleur `g.color`) — un seul titre pour les deux grilles, pas de doublon visuel
- Sous-titre légende sur 2 lignes courtes (fontSize 4, italique, `t3()`) :
  - `"Impact : stat des tireurs (0/1 = 1 but, pas d'arret)"`
  - `"Origine : zone de depart du tir, meme lecture"`
- Grille Impact (`drawGoalZone`, déjà existante) redimensionnée de 50×16mm à **34×14mm**, positionnée à gauche : `drawGoalZone(g.x+3, 70, 34, 14, g.gkId)`
- Nouvelle grille Origine (`drawOriginZone`, à créer) même hauteur, positionnée à droite : `drawOriginZone(g.x+halfW-3-34, 70, 34, 14, g.gkId)` — tailles de police internes à réduire en conséquence (fontSize 6 pour le ratio au lieu de 7, la cellule la plus petite du zonage à 6 zones étant plus large qu'une cellule 3×3 classique donc lisible malgré la réduction)

## Page Carte tir joueur — empilement vertical
Card existante `scCellW×(scCellH-3)`. Nouvelle disposition interne :
- `scCellH` augmenté de 46 à **62mm** (impact sur `drawShotCardsSection` : moins de cartes par page mais `ensurePageSpace`/pagination dynamique STORY-39 gère déjà ce cas sans risque)
- Terrain (`drawCourt`) inchangé en position/taille (haut-gauche de la carte)
- Grille Impact (`drawPlayerZoneGrid`, existante) conservée à sa position actuelle (haut-droite), taille inchangée
- Nouvelle grille Origine (`drawPlayerOriginZone`, à créer), même largeur que la grille Impact, positionnée juste en dessous d'elle (bas-droite de la carte), avec son propre petit label `"Origine"` (fontSize 5, `t3()`) au-dessus, sur le modèle du label `"Impact"` déjà existant

## Tableau Joueurs — colonnes MT1/MT2
Remplacement de la colonne `"BUTS"` par deux colonnes `"MT1"` / `"MT2"` dans `drawPlayerTable()`, même style d'en-tête (fontSize 7 bold `sky()`) et de cellule que les colonnes existantes (valeurs centrées, `wh()` normal). Largeur de chaque sous-colonne : la moitié de l'ancienne largeur "BUTS" (13mm → 2×6.5mm) — suffisant pour un chiffre à 1-2 chiffres. Le total reste lisible par somme visuelle des deux valeurs adjacentes ; pas de 3e colonne "Total" pour ne pas reprendre la largeur gagnée ailleurs.

## Ce qui ne bouge pas
Taille et police des titres de carte, épaisseur des bordures de grille (`cellW-0.5`/`cellH-0.5`, `cellW-0.3`/`cellH-0.3`), tout le reste des pages Gardiens et Carte tir joueur.
