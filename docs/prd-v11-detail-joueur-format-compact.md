# PRD — Détail joueur au format compact

## Objectif
Remplacer le conteneur plein écran de `renderPlayerDetail()` par une fenêtre modale de taille comparable à une carte `.gk-sheet` (Stats → Gardiens), sans changer le contenu ni les interactions déjà en place.

## Must (cette version)
1. **M1** — Le détail joueur s'ouvre dans une fenêtre modale centrée, de largeur comparable à une carte `.gk-sheet` (pas `100vw`/`100vh`), avec un fond assombri derrière (cohérent avec les autres modales de l'app — `.overlay`, déjà utilisé pour `renderShotOverlay()`).
2. **M2** — La disposition interne reprend le modèle **2 colonnes** de `renderGkSheet()` (`.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court`) : chiffres du joueur d'un côté (BUTS en grand comme ARRÊTS, EFF% comme le %, PD/TIRS en pills comme les 2 pills existantes), grille Impact + terrain de l'autre côté — mêmes classes CSS réutilisées, pas une nouvelle mise en page inventée.
3. **M3** — Fermeture explicite conservée (bouton "✕ Fermer" dans l'en-tête) — contrairement à Gardiens (carte permanente sans fermeture), le détail joueur reste une vue à la demande pour UN joueur choisi dans la liste, donc il faut un moyen d'y revenir.
4. **M4** — Aucune régression sur : la bascule points/zones (STORY-43), la sélection d'un tir individuel pour filtrer la grille Impact (`data-pd-shot`), le mode lecteur, l'affichage sur iPad (usage principal terrain) et iPhone (déjà testé étroit pour Gardiens en STORY-43).

## Won't (hors scope explicite)
- Aucun changement de `renderGkSheet()` elle-même (référence visuelle uniquement).
- Aucun changement du bloc Comparaison (STORY-44/46).
- Aucune fusion Joueurs/Gardiens en un seul écran — deux écrans distincts, seul le format du détail Joueur change.
- Aucun changement du contenu des stats affichées (pas de nouvelle donnée ajoutée).
- Ne pas transformer le détail joueur en carte **permanente** affichée pour tous les joueurs à la fois (contrairement à Gardiens qui n'a que 2 GB max par équipe, un effectif Joueurs peut compter 15+ joueurs — rester en "à la demande, un seul à la fois").

## Contrainte de compatibilité
`renderPlayerDetail()` est déclenchée uniquement depuis la cible 🎯 de `renderStatPlayers()` (`data-player-detail`, un seul point d'entrée confirmé par recherche de code) — aucun autre écran n'en dépend, donc aucun risque de casser un usage ailleurs en changeant son conteneur.

## Priorité
Seule story de ce cycle — taille contenue (changement de conteneur + réutilisation de classes CSS existantes), pas de découpage nécessaire.
