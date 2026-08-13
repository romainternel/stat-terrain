# Risques — Visualisation "zones sur le terrain" + tableau Joueurs PDF

## R1 — Géométrie des polygones : le risque technique central de ce chantier (P0→P1 selon vérification)
`buildCourtZones()` combine échantillonnage d'arc et points droits pour fermer 7 polygones qui doivent **tuiler parfaitement** le terrain (pas de trou visible, pas de chevauchement) et rester corrects quel que soit le ratio largeur/hauteur du conteneur (le SVG est étiré non-uniformément selon l'écran — mobile portrait vs paysage vs iPad —, le PDF a un ratio fixe mm). Une erreur de sens d'angle ou de point de fermeture produit un polygone qui se replie sur lui-même ou laisse un espace neutre visible à l'œil.
**Mitigation obligatoire avant tout passage QA** : rendu visuel à au moins 3 largeurs de conteneur différentes (repris de la méthode STORY-38) **et** en PDF, avec un jeu de tirs couvrant explicitement les 7 zones + le marqueur 7M (même méthode que la vérification STORY-40 qui avait révélé que les données par défaut ne couvraient qu'une seule zone) — vérifier qu'aucune zone ne se chevauche ni ne laisse de trou visuellement.

## R2 — `S.shotViewMode` ne doit PAS être réinitialisé par `newMatch()`/`loadMatchAsCurrent()`
C'est une préférence d'affichage par appareil (comme `S.mode` Simple/Expert), pas une donnée de match. Contrairement à `S.gkFilter`/`S.gkShotFilter` (STORY-30) qui, eux, DOIVENT être réinitialisés à chaque nouveau match/chargement (ce sont des filtres d'affichage scopés à un match précis), `S.shotViewMode` doit survivre au changement de match. Risque si le Developer applique par réflexe le même pattern de reset que `gkFilter`.
**Mitigation** : vérifier explicitement qu'aucun des 2 points d'entrée (`newMatch()`, `[data-load-match]`) ne touche `S.shotViewMode`.

## R3 — Le bouton de bascule ne doit pas être bloqué par le mode lecteur
`S.readOnly` bloque toute écriture de données de match — `S.shotViewMode` n'en est pas une (pure préférence d'affichage locale). Risque que le Developer ajoute par réflexe une garde `if(S.readOnly) return;` sur `setShotViewMode()` en copiant un pattern vu ailleurs dans le fichier. À vérifier explicitement dans le sens inverse : le bouton doit rester actif même en mode lecteur.

## R4 — Nettoyage complet de STORY-40 (P2)
`drawOriginZone()`, `drawPlayerOriginZone()`, et leurs 2 points d'appel sont retirés (F7). Vérifier qu'aucune référence orpheline ne subsiste (fonction déclarée mais plus jamais appelée, ou inversement un appel vers une fonction supprimée) — ces fonctions ont moins de 24h d'existence, faible risque de dépendance cachée ailleurs, mais à confirmer par une recherche globale avant de les supprimer.

## R5 — MT1/MT2 au format "but/tir" : double comptage à ne pas rater (P1)
STORY-41 ne trackait que le nombre de **buts** par mi-temps (`mt1`/`mt2`). Le nouveau format `BUT/TIR` par mi-temps exige aussi le nombre de **tentatives totales** par mi-temps (`mt1Tirs`/`mt2Tirs` = but+arrêt+hors-cadre de cette mi-temps, pas seulement les buts). C'est une extension de l'agrégation existante, pas une réécriture, mais facile à rater partiellement (ex. incrémenter `mt1Tirs` seulement sur but, oubliant arrêt/hors-cadre) — vérifier explicitement sur un cas réel qu'un joueur avec un tir arrêté en MT1 affiche bien "0/1" et pas "0/0" ou une omission.

## R6 — Lisibilité du nouveau bloc Comparaison (P3, mineur)
Terrain agrégé sur tout un match (potentiellement 20-30 tirs par équipe) dans un format "mini-terrain" — texte à 2 chiffres dans des zones étroites (AILG/AILD, 9MG/9MD) à surveiller visuellement, sans être bloquant (cohérent avec la taille déjà pratiquée sur les cartes joueur PDF).

## Synthèse pour le Scrum Master
F2 (fondation géométrie) est un **prérequis strict** de F4/F5/F6/F7 — aucune de ces features ne peut être développée ni vérifiée indépendamment de F2. F1 (tableau PDF) est totalement indépendante (autre fonction, aucun partage de code). F6 est un ajout net (Should) qui peut suivre après coup sans bloquer le reste. F7 dépend de F2 **validée en conditions réelles** sur F4/F5 avant d'être transposée en PDF — c'est explicitement l'ordre demandé par Romain lui-même ("une fois qu'on a ce modèle implanté [...] c'est ça que je veux sur le PDF").

Recommandation : 4 stories plutôt qu'une seule ou deux — une pour F1 (indépendante, petite), une bundlant F2+F3+F4+F5 (couplage fort, aucune ne peut être testée sans les autres), une pour F6 (Should, séquencée après), une pour F7 (dépend de la précédente).
