# STORY-40 — PDF : grille "Zones d'origine du tir"

**En tant que** Romain,
**Je veux** voir, dans le PDF, de quelle zone du terrain partent les tirs de mon équipe/de l'adversaire/de chaque joueur, avec leur taux de réussite,
**Afin de** pouvoir juger d'où mon équipe marque efficacement, sans me limiter à la zone d'impact dans le but déjà disponible.

Née de l'évaluation par le squad BMAD d'un PDF de référence (outil concurrent Steazzi) partagé par Romain — cf. `docs/brief-v9-zones-origine-tir-et-split-mitemps.md`.

## Contexte technique
- Zone concernée : `app.js`, `generatePDF()` — nouvelle fonction pure `shotOriginZone(x,y)`, nouvelles fonctions de rendu `drawOriginZone(gx,gy,gw,gh,gkId)` (page Gardiens) et `drawPlayerOriginZone(gx,gy,gw,gh,shots)` (page Carte tir joueur)
- Référence architecture complète (code exact, seuils, formes de zone) : `docs/arch/zones-origine-tir-et-split-mitemps.md`
- Référence design (placement, disposition 2×3 + bande "AUTRE") : `docs/design/zones-origine-tir-et-split-mitemps.md`
- Référence visuelle (couleurs RGB exactes, textes de légende) : `docs/visual/zones-origine-tir-et-split-mitemps.md`
- Zonage réutilise le vocabulaire des postes déjà connu (`POS_XY` : ALG/ARG/DC/ARD/ALD/PVT) + une zone "AUTRE" pour les tirs lointains, plutôt qu'un quadrillage générique

## Critères d'acceptation

**Page Gardiens**
- [ ] Carte "ZONES D'IMPACT" existante renommée "ZONES D'IMPACT & D'ORIGINE", même position/taille (`card(g.x,58,halfW,30)` inchangée) — aucun ajout de hauteur de page
- [ ] Grille Impact existante redimensionnée (34×14mm) à gauche, nouvelle grille Origine (34×14mm) à droite, dans la même carte
- [ ] Légende à 2 lignes (Impact / Origine) tient visuellement entre le titre de carte et le haut des grilles, sans chevauchement
- [ ] Grille Origine : disposition ALG/PVT/ALD (rang 1) + ARG/DC/ARD (rang 2), bande "AUTRE" affichée uniquement si au moins 1 tir y est classé
- [ ] Couleurs identiques à la grille Impact (vert si buts/total>0.5, cyan sinon, neutre si aucun tir) — jamais de rouge
- [ ] Basé sur le même jeu d'événements que la grille Impact du même gardien (`e.gkId===gkId`), bucketé par `shotOriginZone(e.x,e.y)` au lieu de `e.goalZone`
- [ ] Utilise `ACTIONS[e.type]?.isGoal`/`isSave`/`isOff` (pas de comparaison exacte de type) — convention STORY-37

**Page Carte tir joueur**
- [ ] Chaque carte joueur (FENIX et ADVERSAIRE) affiche une grille Origine sous la grille Impact existante, même largeur, avec son propre label court
- [ ] `scCellH` porté de 46 à 62mm ; grille Origine visible uniquement si le joueur a au moins un tir avec zone d'origine (toujours vrai si le joueur a des tirs, `x`/`y` étant systématiquement capturés contrairement à `goalZone` qui dépend de `S.trackGK`)
- [ ] PDF généré avec un effectif complet des deux côtés (14+14, comme le test STORY-39) : aucune carte coupée, pagination dynamique toujours cohérente (nombre de pages peut augmenter, aucune casse)
- [ ] Dernière carte à ligne impaire toujours centrée (comportement STORY-39 non régressé par le changement de `scCellH`)

## Hors scope
- Version live de cette grille sur l'écran Gardiens de l'app (probable demande future, cf. `docs/risks/` R6 — pas traitée ici)
- Correction de l'absence générale de `ensurePageSpace()` sur la page Gardiens (risque pré-existant, pas aggravé par cette story mais pas corrigé non plus)
- Ajustement fin des seuils de zone après retour terrain de Romain (à itérer plus tard si besoin, pas un blocage de livraison)

## Dépend de
Aucune (indépendante de STORY-41)

## Taille
M
