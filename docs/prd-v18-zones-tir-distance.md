# PRD — Zones de tir : vraie distinction 6m / 6-9m / 9m

## Objectif
Les zones de tir (écran live "zones" ET rapport PDF) distinguent réellement trois profondeurs (moins de 6m, 6-9m, plus de 9m) dans les secteurs gauche/centre/droit, au lieu de confondre aujourd'hui "6m" avec "tout ce qui est à moins de 9m". Portée confirmée par Romain : **live + PDF**, pas seulement le rapport.

## Features

### F1 — Troisième bande de profondeur sur le système de zones partagé (`shotZoneCourt`)
`shotZoneCourt()` (et les fonctions qui en dépendent : `buildCourtZones()`, `COURT_ZONE_ORDER`, `COURT_ZONE_LABEL_POS`, `aggregateCourtZones()`, `renderCourtZones()`) distinguent désormais trois profondeurs pour les secteurs Gauche/Centre/Droit : `6M*` (vrai rayon 6m, `R6=105` unités, déjà tracé visuellement mais jamais utilisé comme frontière de classification jusqu'ici), `69M*` (nouvelle bande, entre 6m et 9m), `9M*` (au-delà de 9m, `R9=157.5`, inchangé). Passe de 8 à 11 zones au total.

### F2 — Les ailes restent inchangées
`AILG`/`AILD` restent des zones uniques, non subdivisées par profondeur — cohérent avec la demande de Romain ("garder les secteurs gauche à droite") et avec la limite déjà documentée dans le code (le rayon 6m n'atteint pas la ligne de touche dans cette zone, donc une subdivision par profondeur n'y a pas de sens géométrique).

### F3 — Le PDF réutilise la même classification
`shotOriginZone()` (grille PDF actuelle, `ALG/PVT/ALD/ARG/DC/ARD` + `AUTRE`, jamais géométrique) est retiré et remplacé par la même classification que le live (`shotZoneCourt`). Élimine la divergence entre les deux systèmes — un match affiché en direct puis exporté en PDF montre désormais exactement les mêmes zones.

### F4 — Représentation PDF adaptée à l'espace disponible
L'espace PDF (34×14mm pour la carte gardien, plus petit encore pour la carte tir joueur) ne permet pas d'afficher fidèlement 11 zones en polygones comme sur le terrain live. Le PDF peut regrouper/simplifier l'affichage (ex: grille compacte) tant que la donnée sous-jacente utilise la même classification à 11 buckets que le live — la fidélité visuelle au terrain n'est pas requise dans le PDF, la cohérence de classification l'est.

### F5 — Revalidation visuelle avec Romain
L'écran terrain "zones" (`S.shotViewMode==="zones"`, Stats Comparaison/Gardiens/Joueurs) a déjà été validé visuellement par Romain après 8 itérations de prototype (`docs/arch/zones-terrain-et-tableau-joueurs.md`). Cette feature modifie sa forme (zones plus fines, 11 au lieu de 8) — critère d'acceptation explicite : Romain doit revoir et valider le rendu réel avant que la story soit considérée terminée, pas seulement un accord sur le principe.

## Priorités
- **Must Have** : F1, F2, F3, F5 — le cœur de la demande (vraie distinction 6m/6-9m/9m, partout où Romain regarde les zones) plus le garde-fou de revalidation visuelle, non négociable vu l'historique de validation de cet écran.
- **Should Have** : F4 — nécessaire en pratique dès que F3 est fait (le PDF ne peut pas afficher 11 polygones dans 14mm de haut), mais la façon exacte de simplifier reste une décision de Design, pas un point bloquant du PRD.
- **Nice to Have** : uniformiser le libellé "6m/6-9m/9m" dans toutes les légendes visibles (live + PDF) — cohérence terminologique, pas fonctionnel.

## Critères d'acceptation
- [ ] Un tir tiré à moins de 6m (mesuré depuis le poteau le plus proche ou perpendiculairement à la ligne de but dans le couloir central) est classé dans une zone `6M*`, jamais dans `69M*` ou `9M*`.
- [ ] Un tir entre 6m et 9m est classé dans une zone `69M*` — c'est la correction directe du symptôme signalé par Romain (un tir à 8m n'est plus compté comme un tir à 6m).
- [ ] Un tir au-delà de 9m reste classé dans une zone `9M*`, comportement inchangé.
- [ ] Les tirs d'aile restent classés `AILG`/`AILD`, sans subdivision par profondeur.
- [ ] L'écran "zones" (Stats Comparaison, Gardiens, Joueurs) affiche visuellement les 11 zones avec les bonnes couleurs/comptages (`but/tir`) par zone.
- [ ] Le PDF (page Gardiens, page Carte tir joueur) n'affiche plus jamais `shotOriginZone()`/`ALG/PVT/ALD/ARG/DC/ARD` — la même classification à 11 buckets que le live est utilisée, même si regroupée visuellement pour l'espace disponible.
- [ ] Un même match donne des comptages de zone identiques entre l'écran live et le PDF exporté (même source de classification).
- [ ] Le mode "points" (`S.shotViewMode==="points"`) n'est pas affecté — seul le mode "zones" et le PDF changent.
- [ ] Romain a explicitement revu et validé le rendu réel de l'écran "zones" modifié avant que la story soit close.

## Hors scope
- Subdivision par profondeur des zones d'aile (F2).
- Toute nouvelle donnée capturée à la saisie (les événements ont déjà `x`/`y`, suffisant pour cette classification).
- Modification du mode "points" ou de tout autre écran ne montrant pas de zones.
- Rendu PDF strictement identique (polygones fidèles) à l'écran live — la fidélité de la donnée prime sur la fidélité visuelle dans le PDF (F4).

## Dépendances
Aucune — s'appuie sur `x`/`y` déjà présents dans chaque événement.

## Risques
Détaillés par le Risk Analyst (`docs/risks/zones-tir-distance.md`) — notamment le risque de dégrader la lisibilité d'un écran déjà validé (zones plus fines) et la contrainte d'espace du PDF.
