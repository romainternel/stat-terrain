# STORY-73 — Le PDF réutilise la vraie classification de zone (6m/6-9m/9m)

**En tant que** Romain, en train de consulter un rapport PDF exporté après un match,
**Je veux** que les zones "Origine" (page Gardiens, cartes tir joueur) montrent les mêmes zones et les mêmes chiffres que l'écran en direct,
**Afin de** ne pas avoir deux lectures différentes de la même donnée selon que je regarde l'app ou le PDF.

Demande directe de Romain (`docs/brief-v18-zones-tir-distance.md`) — dépend de la classification étendue livrée par STORY-72.

## Contexte technique
- Zone concernée : `shotOriginZone()` (`app.js:5358`, supprimée), `drawOriginZone()` (`app.js:5375`) et `drawPlayerOriginZone()` (`app.js:5408`) — fusionnées en une seule fonction `drawZoneGridPdf()`, appelée depuis les 2 sites existants (`app.js:5746` carte tir joueur, `app.js:5814` page Gardiens).
- Nouvelles structures : aucune. Nouvelles fonctions : `drawZoneGridPdf(gx,gy,gw,gh,data)`, `collectGkZoneData(gkId)`, `collectShotsZoneData(shots)` — cf. Architecture pour le détail.
- Impact sur l'existant : `drawGoalZone()` (zone d'impact, système différent) n'est pas touchée — continue de s'afficher côte à côte avec la nouvelle grille d'origine sur la page Gardiens, sans changement.
- Disposition de la grille compacte (11 zones dans 34×14mm, ailes en cellules pleine hauteur de part et d'autre d'une grille 3×3) : `docs/design/zones-tir-distance.md` section F3+F4.
- Tailles de police recommandées pour la grille compacte : `docs/visual/zones-tir-distance.md`.

## Critères d'acceptation
- [ ] `shotOriginZone()` n'existe plus dans le code, aucun appelant résiduel.
- [ ] La page Gardiens du PDF affiche la grille "Origine" avec les 11 zones (ou la version repliée à 9 si le test d'impression réel impose la fusion `69M*`/`9M*`, cf. risque #3) — mêmes libellés de zone que l'écran live.
- [ ] La carte tir joueur (page "CARTE TIR JOUEUR") affiche la même grille, mêmes zones, cohérente avec la page Gardiens.
- [ ] Pour un même match, le comptage `but/tir` par zone dans le PDF correspond exactement à celui affiché sur l'écran "zones" en direct (même source de classification, `shotZoneCourt`).
- [ ] **Export PDF réel généré et ouvert en entier après la modification** (pas seulement `new Function()`, qui ne détecte pas les erreurs runtime spécifiques à jsPDF) — toutes les pages (Comparatif, Cartes tir joueur, Gardiens) s'affichent sans erreur.
- [ ] **Test de lisibilité à taille réelle d'impression** (100%, pas zoomé à l'écran) — si le texte à 4-4.5pt s'avère illisible, appliquer le repli déjà prévu (fusionner `69M*`/`9M*` uniquement dans l'affichage PDF, classification sous-jacente inchangée).
- [ ] `new Function()` passe sur `app.js` modifié.

## Hors scope
- Le rendu du terrain live — traité dans STORY-72, dont cette story dépend.
- La zone d'impact PDF (`drawGoalZone()`) — système différent, non concerné.
- Toute modification de la mise en page générale du PDF (pagination, autres sections) — seule la grille "Origine" change.

## Dépend de
STORY-72 (nécessite `shotZoneCourt()`/`COURT_ZONE_ORDER` déjà étendus à 11 zones)

## Taille
M
