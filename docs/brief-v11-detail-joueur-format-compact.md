# Brief — Détail joueur (Stats → Joueurs) au format compact

## Origine
Retour direct de Romain, capture d'écran de Stats → Gardiens à l'appui, après avoir testé STORY-44 (bloc terrain Comparaison, v92) en conditions réelles et être passé par Stats → Joueurs dans la foulée.

## Constat
Cliquer sur la cible 🎯 d'un joueur (Stats → Joueurs) ouvre `renderPlayerDetail()` : un **overlay plein écran** (`position:fixed;top:0;left:0;width:100vw;height:100vh`), avec un grand terrain SVG centré, une grille Impact au-dessus. Romain le juge **"beaucoup trop grand"** — hors de proportion avec le reste de l'app, où chaque bloc d'information vit dans une carte de taille normale au milieu des autres.

La référence qu'il donne : Stats → Gardiens (`renderGkSheet()`), où chiffres + terrain tiennent dans **une carte compacte** insérée dans le flux normal de la page, aux côtés des autres cartes — pas un plein écran. Sa demande explicite : "même taille" et "il faut charger stat avec BUT/TIR... etc" — c'est-à-dire reprendre le format visuel de la carte Gardien (disposition, taille), mais avec le contenu Joueur (Buts, PD, Tirs, Efficacité — au lieu de Arrêts/Encaissés/Hors cadre).

## Besoin réel
Ce n'est pas une demande de nouvelle fonctionnalité — tout ce qu'affiche `renderPlayerDetail()` aujourd'hui (stats du joueur, grille Impact, terrain points/zones, sélection d'un tir individuel, bascule points/zones) reste voulu. Le besoin est un changement de **format de présentation** : passer d'un overlay qui monopolise tout l'écran à une fenêtre modale de taille comparable à une carte `.gk-sheet` existante, pour que consulter le détail d'un joueur reste un geste léger, pas une interruption complète du contexte visuel (le reste de l'écran Stats).

## Ce qui ne change pas
- Le contenu affiché (stats, grille Impact, terrain, sélection de tir)
- Le déclenchement (clic sur 🎯 dans la liste des joueurs)
- La bascule points/zones (STORY-43), partagée avec Joueurs/Gardiens/Comparaison
- Stats → Gardiens elle-même (sert uniquement de référence visuelle)
- Le bloc Comparaison livré juste avant (STORY-44/46, v92)

## Périmètre de la décision restant à trancher
Comment referme-t-on le détail si ce n'est plus un plein écran (bouton ✕ toujours nécessaire, contrairement à Gardiens qui est une carte permanente sans fermeture) — tranché par le Designer, pas deviné.
