# PRD — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

## Objectif
Donner au PDF FENIX Stats une réponse chiffrée à "d'où marque-t-on / d'où perd-on des tirs ?", symétrique à la grille Zones d'impact déjà livrée (STORY-39), et enrichir le tableau Joueurs d'une répartition par mi-temps — en réutilisant au maximum le système de rendu/couleur déjà en place plutôt qu'en introduisant un nouveau langage visuel.

## Features

### F1 — Grille "Zones d'origine du tir" (Must)
Nouvelle grille agrégeant les tirs par zone du **terrain d'où ils sont partis** (pas la zone du but où ils ont atterri), avec un ratio buts/total par zone et la même convention de couleur que la grille Zones d'impact existante (vert si buts/total > 0.5, cyan sinon, jamais rouge, cellule neutre si aucun tir).
- **Zonage** : à définir par le Designer/Architect à partir de la géométrie réelle du terrain (`courtSvgMarkup()`, 6m/9m en quarts de cercle) — piste à évaluer en priorité : réutiliser le découpage par poste déjà existant dans `POS_XY` (ALG/ARG/DC/ARD/ALD/PVT), familier de Romain puisque déjà utilisé pour positionner les joueurs sur le terrain, plutôt qu'un quadrillage générique arbitraire calqué sur la référence externe.
- **Placement** :
  - Page Gardiens : une grille par gardien, sur le même jeu d'événements que la grille Zones d'impact déjà affichée pour ce gardien (`e.gkId===gkId`), juste bucketée par `e.x`/`e.y` au lieu de `e.goalZone`.
  - Page Carte tir joueur : une grille par joueur, en complément de la grille Impact déjà présente sur sa carte, sur le même jeu de tirs déjà collecté par `collectShotPlayers()`.
- **Légende** : texte explicatif sous le titre, sur le modèle de l'existant ("Stat des tireurs par zone de terrain (ex : 1/1 = 1 but, pas d'arrêt)" ou équivalent adapté).

### F2 — Split 1ère/2e mi-temps sur le tableau Joueurs (Should)
Le tableau Joueurs (`drawPlayerTable()`) affiche la répartition des buts par mi-temps (`event.period`), en plus du total déjà affiché. Format exact (colonnes séparées vs notation compacte dans la colonne BUTS existante) laissé à l'appréciation du Designer selon les contraintes de largeur réelles de la page.

## Priorisation
- **Must** : F1 (c'est la vraie trouvaille de cette évaluation, répond à un manque réel)
- **Should** : F2 (utile mais mineur, ne doit pas complexifier F1 si contrainte de temps)

## Critères de succès
- Romain peut répondre, PDF en main, à "d'où mon équipe/tel joueur marque le plus efficacement ?" sans recalcul mental.
- La nouvelle grille se lit sans explication supplémentaire pour quelqu'un qui connaît déjà la grille Zones d'impact (même codes couleur, même format de ratio).
- Aucune régression sur les pages Gardiens et Carte tir joueur déjà validées en STORY-39 (v88).

## Hors scope (rappel du Brief)
Activité - Résumé (+/-, temps de jeu), timeline de tirs possession par possession. Non traités dans ce PRD.
