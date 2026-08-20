# PRD — Chevauchement DC sur le terrain + Raccourcis Mode/Suivi GB dans l'en-tête

## Objectif
Corriger un défaut d'affichage réel (DC) et réduire la friction pour deux réglages fréquemment changés (Mode de saisie, Suivi GB), sans toucher au reste de l'application.

## Features

### F1 — Disposition en grille pour le poste Demi-Centre (Must Have)
`POS_XY.DC` reçoit une configuration `spread` qui répartit jusqu'à 5 joueurs sans chevauchement ni collision avec le plafond bas du terrain à cette position, en réutilisant `courtPlayerPositions()` (aucune nouvelle fonction). S'applique automatiquement partout où le terrain est rendu avec des joueurs positionnés (Match Mode Expert, sélecteurs PD/2min/carton, Stats Joueurs/Gardiens/Comparaison) puisque tous ces écrans appellent la même fonction.

### F2 — Raccourcis Mode Simple/Expert et Suivi GB dans l'en-tête (Must Have)
`renderHeader()` affiche, sur tous les écrans, juste à droite du logo "CF FENIX STAT" et avant les 5 onglets de navigation :
- Un raccourci pour basculer `S.mode` entre "simple" et "expert" (réutilise `setMode()`, donc la confirmation bloquante existante si des événements sont déjà saisis en Mode Expert reste déclenchée).
- Un raccourci pour basculer `S.trackGK` (activé/désactivé).

Les deux emplacements existants (Équipes, panneau Réglages) restent inchangés — ce sont des points d'accès supplémentaires, pas un remplacement.

## Priorités
Les deux features sont Must Have, indépendantes l'une de l'autre (aucune dépendance croisée), livrables dans n'importe quel ordre.

## Critères d'acceptation

**F1**
- [ ] Les 5 joueurs DC du roster FENIX CF réel, tous sélectionnés en même temps, s'affichent avec 5 étiquettes visuellement distinctes (pas de superposition) sur le terrain, viewport tablette (paysage et portrait) et téléphone.
- [ ] 1, 2, 3 et 4 joueurs DC sélectionnés restent également sans chevauchement (pas seulement le cas à 5).
- [ ] La position de DC reste cohérente avec l'intention de design existante (repli derrière l'alignement ARG/ARD, pas mélangé avec eux).
- [ ] Aucune régression sur les autres postes (ALG/ARG/ARD/ALD/PVT/GB), dont la disposition n'est pas modifiée par cette story.
- [ ] S'applique sur tous les écrans qui rendent le terrain avec positions (Match Mode Expert, sélecteurs PD/2min/carton, Stats Joueurs/Gardiens/Comparaison) — vérifié sur au moins 2 de ces écrans, pas seulement Match.

**F2**
- [ ] Un raccourci Mode (Simple/Expert) et un raccourci Suivi GB sont visibles dans l'en-tête sur tous les écrans (Équipes, Match, Stats, Bilan, Matchs), pas seulement en match actif.
- [ ] Cliquer le raccourci Mode change bien `S.mode`, redessine l'écran Match en conséquence si un match est actif, et déclenche la confirmation bloquante existante si on bascule Expert→Simple avec des événements déjà saisis (comportement de `setMode()` non dupliqué, juste réutilisé).
- [ ] Cliquer le raccourci Suivi GB change bien `S.trackGK`, reflété immédiatement partout où cette valeur est déjà utilisée (workflow de saisie GOAL/SAVE avec ou sans zone d'impact).
- [ ] Les deux emplacements existants (toggle sur Équipes, toggle dans Réglages) continuent de fonctionner et restent synchronisés avec l'état changé depuis l'en-tête (c'est le même `S.mode`/`S.trackGK`, pas une copie).
- [ ] Sur iPhone étroit (≤700px), l'ajout des raccourcis ne rend pas les 5 onglets de navigation illisibles ou inatteignables — la nav continue de défiler horizontalement comme avant (STORY-18), testé visuellement.

## Hors scope
- Toute disposition dédiée pour un poste autre que DC.
- Suppression des emplacements existants des deux réglages.
- Personnalisation de l'ordre/emplacement des raccourcis par l'utilisateur.

## Dépendances
- F1 s'appuie sur `courtPlayerPositions()`/le mécanisme `spread:"grid"` déjà construit pour PVT (STORY-38) — aucune nouvelle infrastructure.
- F2 s'appuie sur `setMode()`/`S.trackGK` déjà existants — aucune nouvelle donnée.

## Risques
Voir `docs/risks/dc-grid-et-raccourcis-header.md`.
