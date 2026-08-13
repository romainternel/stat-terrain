# PRD — Visualisation "zones sur le terrain" + révision tableau Joueurs PDF

## Objectif
Remplacer la représentation par points de localisation des tirs par une représentation par zones dessinées sur le terrain (façon référence Steazzi), disponible en bascule avec les points actuels, sur les écrans Joueurs et Gardiens de l'appli ainsi que sur le PDF — et ajouter le même visuel là où il manque (Comparaison). En parallèle, corriger le format du tableau Joueurs du PDF selon les attentes précises de Romain.

## Features

### F1 — Tableau Joueurs PDF : nouveau format de colonnes (Must)
`drawPlayerTable()` : colonnes `#, NOM, POSTE, BUT/TIR, EFF%, PO, PD, PB, 2M, MT1, MT2`. `BUT/TIR` et `MT1`/`MT2` au format combiné "buts/tirs" (pas de colonnes séparées). PO compté depuis les événements `PEN_OBT` déjà attribués à un `playerId`. `tableX` (centrage) recalculé en cohérence avec la nouvelle somme de largeurs — point de vigilance explicite (déjà oublié une fois en STORY-41).

### F2 — Fondation : géométrie des zones + classification partagée (Must)
Définition des zones de tir sur la forme réelle du terrain (suivant les arcs 6m/9m déjà tracés par `courtSvgMarkup()`/`drawHandballZone()`), et une fonction de classification (succède à `shotOriginZone()` de STORY-40, à faire évoluer plutôt que dupliquer) utilisable à la fois pour dessiner (SVG et jsPDF) et pour agréger buts/tirs par zone. Sans cette fondation commune, rien d'autre n'est possible sans dupliquer la géométrie 4 fois.

### F3 — Bascule points ↔ zones, réglage global (Must)
Un état persistant par appareil (même mécanisme que `S.mode` Simple/Expert, `localStorage`) contrôlant l'affichage sur tous les écrans concernés simultanément. Un bouton visible sur chaque écran concerné bascule ce réglage global (pas un état local par écran).

### F4 — Mode zones sur Stats → Joueurs (détail joueur, `renderPlayerDetail()`) (Must)
Remplace les points/croix SVG actuels par le rendu en zones (F2) quand le réglage global est sur "zones". La grille d'impact (HG/HC/etc., dans le but) n'est pas concernée — seule la représentation de la zone de départ du tir sur le terrain change.

### F5 — Mode zones sur Stats → Gardiens (`renderGkSheet()`) (Must)
Même bascule, sur le terrain du gardien (combiné ou individuel selon `S.gkFilter` déjà existant). Grille Impact (`goalZoneHeatmap()`) non concernée non plus.

### F6 — Nouveau visuel terrain+but dans Stats → Comparaison (Should)
Visuel qui n'existe pas aujourd'hui sur cet écran — terrain + but général par équipe, placé au-dessus du tableau comparatif existant, avec la même bascule points/zones. Priorité Should (pas Must) : c'est un ajout net, pas une correction d'un affichage existant jugé insatisfaisant — peut suivre dans un second temps sans bloquer le cœur de la demande (F1-F5, F7).

### F7 — PDF Carte tir joueur en mode zones (Must, dépend de F2-F5)
Remplace `drawCourt()` (points) par le rendu en zones (F2) sur la page "Carte tir joueur" du PDF — dernière étape, une fois le modèle de zones validé et éprouvé côté appli sur F4/F5. Retire à cette occasion `drawOriginZone()`/`drawPlayerOriginZone()` (STORY-40, grille rectangulaire) qui devient obsolète.

## Priorisation
- **Must** : F1 (indépendante, petite), F2 (fondation), F3 (infrastructure), F4, F5, F7
- **Should** : F6 — peut glisser à un cycle suivant sans bloquer le reste

## Critères de succès
- Romain peut basculer d'un tap entre points et zones, partout où c'était pertinent, et retrouve la même information qu'avec les points mais présentée sur la forme du terrain
- Le PDF Carte tir joueur, une fois basculé, n'a plus de grille détachée du terrain
- Aucune régression sur la grille Zones d'impact (dans le but), non concernée par ce chantier

## Hors scope
- Activité - Résumé (+/-, temps de jeu) — non concernée
- Grille Zones d'impact (HG/HC/etc.) — non concernée, reste inchangée
