# Brief — Visualisation "zones sur le terrain" (points ↔ zones) + révision tableau Joueurs PDF

## Origine
Retour direct de Romain après livraison de STORY-40/41 (v89, ce matin). Deux demandes distinctes, l'une petite (révision de colonnes PDF), l'autre structurante (nouveau mode d'affichage partagé appli+PDF).

## A — Tableau Joueurs PDF : le format actuel ne convient pas
STORY-41 a livré des colonnes MT1/MT2 séparées affichant uniquement le nombre de buts. Romain veut :
- Une colonne `BUT/TIR` combinée (ex "6/8"), pas deux colonnes but/tirs séparées comme avant STORY-41
- L'ordre : BUT/TIR, EFF%, PO, PD, PB, 2M, puis MT1, MT2
- MT1/MT2 aussi au format "but/tir de la mi-temps" (ex "3/5"), pas juste un compte de buts

C'est une correction de format, pas un nouveau besoin fonctionnel — la donnée existe déjà (buts, tirs, PD, PB, 2M) sauf PO (pénalty obtenu) qui n'est pas encore agrégé dans cette table mais dont l'événement `PEN_OBT` est déjà capturé avec `playerId`.

## B — Le vrai sujet : remplacer les points par des zones, partout, avec un bouton
Romain a vu dans un PDF concurrent (Steazzi) des zones de tir dessinées **sur la forme réelle du terrain** (suivant les lignes 6m/9m/7m), avec le ratio buts/tirs écrit dans chaque zone. Il juge ça plus lisible et plus proche de la réalité du jeu qu'une grille rectangulaire détachée du terrain.

**Ce que ça remplace** : la grille rectangulaire "Zones d'origine" livrée ce matin en STORY-40 (jugée insatisfaisante, cf. capture envoyée par Romain montrant une cellule isolée peu parlante) — remplacement complet, pas de coexistence (décision actée).

**Ce que ça introduit de nouveau** : un mode d'affichage optionnel des tirs, disponible partout où l'appli montre aujourd'hui des points de localisation sur un terrain :
1. Stats → Joueurs → détail d'un joueur (carte 🎯)
2. Stats → Gardiens → terrain du gardien (combiné ou individuel)
3. Stats → Comparaison → **visuel qui n'existe pas encore**, à créer (terrain+but général par équipe)
4. PDF → page Carte tir joueur (remplace `drawCourt()` par le rendu zones, une fois le modèle validé côté appli)

Avec un **bouton unique, réglage global** pour basculer "points" ↔ "zones" — un seul état, pas un choix indépendant par écran.

## Pourquoi ce n'est pas juste "refaire STORY-40 en mieux"
STORY-40 était un ajout PDF isolé. Ce que demande Romain touche 3 écrans de l'appli en **direct usage sideline** (pas seulement l'export post-match) et introduit un nouveau concept d'état partagé (comme `S.mode` Simple/Expert). C'est un changement d'ampleur différente, à traiter comme tel — probablement plusieurs stories, pas une.

## Contrainte non négociable
Les zones doivent suivre la géométrie réelle déjà en place (`courtSvgMarkup()` côté appli, `drawHandballZone()` côté PDF — deux quarts de cercle centrés sur chaque poteau, pas des demi-cercles). Pas de nouvelle géométrie inventée à côté.

## Hors scope
- Idée "Activité - Résumé" (+/-, temps de jeu) — toujours mise de côté, non concernée
- La grille "Zones d'impact" (dans le but, HG/HC/etc.) — non concernée, reste comme aujourd'hui, ce n'est pas elle que Romain critique

## Parties prenantes
Romain, seul utilisateur/décideur.
