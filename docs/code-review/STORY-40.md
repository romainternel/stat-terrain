# Code Review — STORY-40 (PDF : grille "Zones d'origine du tir")

## Portée revue
`app.js`, `generatePDF()` : nouvelle fonction pure `shotOriginZone(x,y)`, nouvelles `drawOriginZone()` (page Gardiens) et `drawPlayerOriginZone()` (Carte tir joueur), modification du bloc "ZONES D'IMPACT" (renommé, redimensionné, grille Origine ajoutée côte à côte) et du bloc Carte tir joueur (`scCellH` 46→62, empilement Impact/Origine). Comparé à `docs/stories/STORY-40-zones-origine-tir-pdf.md` et `docs/arch/zones-origine-tir-et-split-mitemps.md`.

## Conformité architecture
- `shotOriginZone()` implémentée exactement comme spécifiée (bandes x/y, pas de trigonométrie d'arc) — seuils identiques à l'Architect.
- `drawOriginZone()`/`drawPlayerOriginZone()` reproduisent fidèlement la structure de `drawGoalZone()`/`drawPlayerZoneGrid()` (même style de boucle, mêmes couleurs) — pas de système parallèle introduit, conforme à la préoccupation centrale du Risk Analyst (R régression sur fonctions déjà durcies).
- Placement Gardiens : carte existante réutilisée sans changement de hauteur, conforme à la décision du Designer de ne pas ajouter de risque de débordement sur une page sans `ensurePageSpace()`.
- Placement Carte tir joueur : empilement vertical Impact/Origine avec gestion propre du cas "pas de zone d'impact" (le code avance `rightY` seulement si le bloc Impact a été dessiné, évitant un espace vide orphelin) — c'est une amélioration par rapport à la spec Architect qui n'avait pas explicitement traité ce cas, et le comportement a été confirmé correct par test (`#4 Baron`, aucune zone d'impact, la grille Origine remonte à la position du haut au lieu de laisser un trou).

## Conventions de code
- Commentaires alignés sur la convention du fichier (le "pourquoi", pas le "quoi" — ex. le commentaire sur `shotOriginZone()` explique pourquoi une approximation par bandes est un choix assumé, pas une simplification par paresse).
- Couleurs RGB identiques à celles déjà utilisées (`[80,200,120]`, `[78,205,232]`, `[28,43,64]`/`[36,51,82]` neutres) — aucune nouvelle palette.
- Nommage cohérent (`drawX`/`shotX`, préfixe implicite partagé avec les fonctions Impact existantes).

## Réutilisation vs duplication
Aucune. `drawOriginZone()` et `drawPlayerOriginZone()` sont volontairement proches de leurs équivalents Impact (même structure de boucle sur zones), mais chacune a une géométrie de zones différente (6+1 vs 3×3) qui empêche une factorisation propre sans complexifier la signature — jugé acceptable, cohérent avec le style déjà en place où `drawGoalZone`/`drawPlayerZoneGrid` coexistent déjà sans être fusionnées.

## Scope
Aucun fichier hors `app.js` touché. Aucune fonction partagée hors PDF modifiée (`gkStats()`, `collectShotPlayers()`, `ACTIONS[].isGoal/isSave/isOff` consommés en lecture seule, convention STORY-37 respectée dans les deux nouvelles fonctions de bucketing).

## Audit glyphes
Labels de zone ("ALG","PVT","ALD","ARG","DC","ARD","AUTRE") et légendes ("Impact : ...", "Origine : ...") strictement ASCII — aucun risque du bug STORY-39 (★→&).

## Vérification visuelle (menée par le Developer avant cette revue)
Deux jeux de données distincts : le jeu volumineux STORY-39 (14v14, confirme absence de régression de pagination/centrage) et un jeu dédié à 7 événements (un par zone attendue : ALG/PVT/ALD/ARG/DC/ARD/AUTRE) qui confirme que `shotOriginZone()` classe chaque coordonnée exactement dans la zone attendue et que le rendu (couleur, ratio, bande AUTRE conditionnelle) est fidèle aux données. Cas limite couvert : gardien sans tir affronté (grille vide, pas de crash), joueur sans donnée `goalZone` (grille Origine seule, pas de trou visuel).

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Les seuils de `shotOriginZone()` sont une approximation assumée (cf. Risk R1) — pas un défaut de code, mais à garder en tête si Romain remonte un zonage qui lui semble faux après un vrai match.
- `scCellH` passé à 62mm réduit le nombre de cartes par page sur "Carte tir joueur" — comportement voulu, pagination dynamique déjà validée sur le jeu 14v14 (toujours centrage correct de la dernière carte impaire).

## Verdict
**APPROUVÉ**
