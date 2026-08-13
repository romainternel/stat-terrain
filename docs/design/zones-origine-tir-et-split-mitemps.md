# Design — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

## F1 — Grille "Zones d'origine du tir"

### Décision de zonage : réutiliser le vocabulaire des postes, pas un quadrillage générique
La référence Steazzi découpe le terrain en 7 zones génériques sans lien avec le reste de son outil. FENIX Stats a mieux à disposition : `POS_XY` définit déjà 6 zones de terrain nommées et positionnées (ALG, ARG, DC, ARD, ALD, PVT) pour placer les joueurs — Romain les connaît et les utilise déjà tous les jours en saisie. Le zonage des tirs doit reprendre **ces mêmes 6 zones** plutôt qu'un quadrillage abstrait :

```
        ALG          DC          ALD
         │      ARG  │  ARD       │
   (aile │  (9m gauche│9m droit) │aile
   gauche)│           │          │droite)
         │      PVT (6m, centre) │
```
(schéma indicatif — la géométrie réelle est portée par l'Architect, cf. `docs/arch/`)

- **PVT** : zone proche (6m), au centre
- **ARG / DC / ARD** : bande 9m, découpée en tiers gauche/centre/droit
- **ALG / ALD** : ailes, angle fermé près de la ligne de touche
- Un tir hors de ces bandes (rare, contre-attaque longue distance, jet franc lointain) tombe dans une 7e case **"Autre"** plutôt que d'être silencieusement perdu ou de forcer une zone qui ne correspond pas à la réalité du tir

Un lecteur qui connaît déjà la disposition des joueurs sur le terrain Match reconnaît immédiatement les mêmes zones dans le PDF — c'est plus fort que la cohérence "réponds à la même question" visée par le PRD, c'est une cohérence de **vocabulaire** à travers toute l'app.

### Rendu visuel
Même langage que la grille Zones d'impact existante (STORY-39) : cellules colorées vert (>50% buts) / cyan (sinon) / neutre (aucun tir), ratio `buts/total` affiché en blanc au centre de chaque cellule. Disposition non plus en grille 3×3 régulière mais en forme de terrain simplifiée (les 6-7 zones citées plus haut, tailles de cellule proportionnelles à leur zone réelle plutôt qu'uniformes) — assez proche visuellement de `drawHandballZone()` pour rester reconnaissable comme "un terrain", sans reproduire tout le tracé exact (inutile à cette échelle).

### Placement — décision clé : ne PAS ajouter de hauteur de page
La page Gardiens n'a aucune protection anti-débordement (`ensurePageSpace()` n'y est pas utilisé, contrairement aux pages retravaillées en STORY-39) — z'ajouter une carte de plus dans la colonne déjà pleine (Stats GB → Zones d'impact → Localisation tirs, 3 cartes empilées) est un risque de débordement inutile pour une fonctionnalité qui n'en a pas besoin.

**Décision : élargir la carte "ZONES D'IMPACT" existante pour accueillir les deux grilles côte à côte**, à la même position `y=58`, même hauteur de carte (30mm). Grille Impact à gauche (taille réduite, ~35mm au lieu de 50mm), grille Origine à droite (~35mm), toutes deux dans la largeur `halfW` déjà disponible (~87mm) — aucun ajout de hauteur de page, donc aucun risque de collision avec "LOCALISATION TIRS" ni "TIMELINE GARDIEN" en dessous. Titre de carte renommé "ZONES D'IMPACT & D'ORIGINE" avec deux sous-légendes courtes.

Pour la page **Carte tir joueur**, la carte par joueur est déjà tendue en largeur (grille Impact actuelle : 25.5mm de large, police déjà à 5pt). Loger une seconde grille à côté rendrait les deux illisibles à l'impression. **Décision : empiler les deux grilles verticalement** (Impact au-dessus, Origine en dessous) plutôt que côte à côte, ce qui augmente légèrement la hauteur de chaque carte joueur (donc moins de cartes par page, mais `ensurePageSpace()`/pagination dynamique de STORY-39 absorbe déjà ce cas sans risque de débordement — juste une page de plus si besoin).

## F2 — Split mi-temps sur le tableau Joueurs
Le tableau `drawPlayerTable()` a de la marge (130mm de colonnes sur ~180mm de largeur utile, cf. STORY-39). **Décision : remplacer la colonne unique "BUTS" par deux sous-colonnes compactes "MT1"/"MT2"**, avec le total qui reste déductible par simple addition visuelle (pas besoin d'une 3e colonne "Total" redondante) — ou, si la largeur réelle après implémentation le justifie, garder "BUTS" (total) et ajouter une seule colonne "Répartition" avec notation `X-Y` (ex. "5-2"). Choix final laissé à l'Architect selon la largeur réellement disponible une fois les 9 colonnes existantes mesurées avec du texte réel.

## Ce qui ne change pas
Couleurs, légendes existantes (vert/cyan/neutre), position et contenu de "LOCALISATION TIRS", "TIMELINE GARDIEN", "NOTES DU COACH" — aucune de ces sections n'est touchée par ce lot.
