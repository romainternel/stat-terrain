# Brief — Chevauchement DC sur le terrain + Raccourcis Mode/Suivi GB dans l'en-tête

## Contexte
Deux retours de Romain en conditions réelles d'usage, à traiter dans le même cycle.

## Sujet 1 — Chevauchement des joueurs Demi-Centre (DC) sur le terrain, tablette

### Problème
Quand plusieurs joueurs au poste Demi-Centre (DC) sont sélectionnés pour un match, leurs étiquettes se chevauchent sur le terrain — repéré par Romain sur tablette. Le roster réel FENIX CF compte **5 joueurs enregistrés au poste DC** (Jules.G, Issa.S, Leni.A, Lucas.G, Antonin.V) — c'est le poste le plus peuplé de tout l'effectif, plus encore que Pivot (3 joueurs) qui avait pourtant déjà nécessité une disposition dédiée (STORY-38, triangle à 3 / carré à 4).

### Root cause (déjà identifiée par lecture de code)
`POS_XY.DC` (`app.js`) n'a aucune configuration `spread`, contrairement à `POS_XY.PVT` qui a `spread:"grid"`. DC tombe donc dans la branche par défaut de `courtPlayerPositions()` — un simple étalement vertical (`vSpread:13` par joueur) avec un plafond dur (`Math.min(96, ...)`). DC est déjà positionné bas sur le terrain (`y:88`, "en retrait derrière l'alignement ARG/ARD") — il ne reste que 8 unités de marge avant le plafond à 96. Avec 3 joueurs ou plus, l'étalement vertical dépasse cette marge et plusieurs joueurs se retrouvent collés au même point (`96`), d'où le chevauchement visuel.

### Utilisateurs
Romain sur iPad, en train de composer son effectif avant ou pendant un match — le terrain (Match Mode Expert, sélecteurs PD/2min/carton, Stats Joueurs/Gardiens/Comparaison) doit rester lisible quel que soit le nombre de joueurs sélectionnés à un poste donné.

## Sujet 2 — Raccourcis Mode Simple/Expert et Suivi GB dans l'en-tête

### Problème
Changer de mode de saisie (Simple/Expert) ou activer/désactiver le suivi du gardien (`S.trackGK`) nécessite aujourd'hui de naviguer vers l'onglet Équipes (tout en bas de l'écran) ou d'ouvrir le panneau ⚙ Réglages (visible seulement pendant un match actif). Romain veut ces deux réglages accessibles en un tap, depuis n'importe quel écran, sans naviguer.

### Utilisateurs
Romain (ou un aidant occasionnel), en bord de terrain, qui a besoin de basculer rapidement de mode ou d'activer le suivi GB sans interrompre ce qu'il est en train de regarder (Stats, Bilan, etc.).

## Vision
- DC (et tout poste futur qui recevrait un effectif aussi nombreux) s'affiche sans chevauchement sur le terrain, quel que soit le nombre de joueurs sélectionnés — en réutilisant l'infrastructure de disposition en grille déjà construite pour Pivot.
- Basculer le mode de saisie ou le suivi GB devient un geste immédiat depuis l'en-tête de l'app, sur n'importe quel écran — sans naviguer vers Équipes ni ouvrir les Réglages.

## Scope

**Dans le scope :**
1. Donner à DC une disposition qui absorbe jusqu'à 5 joueurs sans chevauchement, cohérente avec l'infrastructure existante (`courtPlayerPositions()`, déjà utilisée par PVT).
2. Ajouter, dans l'en-tête global (`renderHeader()`), juste à droite du logo "CF FENIX STAT" et avant les 5 onglets de navigation, un raccourci pour basculer `S.mode` (Simple/Expert) et un raccourci pour basculer `S.trackGK` (Suivi GB) — visibles et fonctionnels sur tous les écrans.

**Hors scope :**
- Toute autre disposition de poste que DC (ALG/ARG/ARD/ALD restent en spread vertical simple, leurs effectifs réels ne dépassent jamais 3 joueurs).
- Retirer les emplacements existants (Équipes, Réglages) de ces deux réglages — les raccourcis d'en-tête s'ajoutent, ils ne remplacent rien.
- Toute refonte plus large de l'en-tête ou de la navigation.

## Critères de succès
- Sélectionner les 5 joueurs DC du roster FENIX CF affiche 5 étiquettes distinctes et lisibles sur le terrain, sans chevauchement, sur tablette comme sur téléphone.
- Le mode de saisie et le suivi GB peuvent être changés en un tap depuis l'en-tête, sur n'importe quel écran (pas seulement Équipes/Réglages), sans dégrader la lisibilité des onglets de navigation sur iPhone étroit.

## Questions en suspens
- Réglage exact de la grille DC (pas horizontal/vertical, éventuel ajustement du `y` de base) : à trancher par l'Architect en tenant compte de la marge verticale limitée à cette position du terrain.
- Représentation exacte des raccourcis d'en-tête (icônes seules vs icône + état visuel) : à trancher par le Designer, avec la contrainte explicite de rester compact sur iPhone étroit (la nav défile déjà horizontalement, STORY-18).
