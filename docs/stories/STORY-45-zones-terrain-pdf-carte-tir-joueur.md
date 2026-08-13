# STORY-45 — PDF : Carte tir joueur et Gardiens en mode zones (retire STORY-40)

**En tant que** Romain,
**Je veux** que le PDF affiche les tirs en zones sur le terrain, comme dans l'appli,
**Afin de** avoir un document cohérent avec ce que je consulte en direct, et plus lisible que la grille rectangulaire actuelle.

Dernière étape du chantier "zones sur le terrain" — dépend de STORY-43 (le modèle de zones doit être validé en conditions réelles côté appli avant d'être transposé en PDF, séquence explicitement demandée par Romain).

## Contexte technique
- Zone concernée : `app.js`, `generatePDF()` — nouvelle fonction `drawCourtZones()` (jsPDF), retrait de `drawOriginZone()`/`drawPlayerOriginZone()` (STORY-40, obsolètes)
- Référence architecture : `docs/arch/zones-terrain-et-tableau-joueurs.md` (section F7)
- Contrairement à l'appli, le PDF n'a pas de bouton — toujours en mode zones (document statique)

## Critères d'acceptation
- [ ] Page Gardiens ("LOCALISATION TIRS") : `drawCourt()` remplacé par `drawCourtZones()`, carte "ZONES D'IMPACT & D'ORIGINE" redevient "ZONES D'IMPACT" (le contenu Origine disparaît de cet emplacement)
- [ ] Page Carte tir joueur : `drawCourt()` remplacé par `drawCourtZones()` pour chaque carte joueur (FENIX et ADVERSAIRE)
- [ ] Les 8 zones (AilG/6mG/6mC/6mD/AilD/9mG/9mC/9mD) s'affichent avec uniquement leur ratio buts/tirs, sans code de zone — cohérent avec le modèle validé côté appli en STORY-43
- [ ] Repères visuels 6m (trait plein)/9m (pointillé)/4m/7m tracés en jsPDF sur ces terrains, mêmes coordonnées que `drawHandballZone()`
- [ ] Marqueur `7m` affiché sur ces deux terrains PDF (absent aujourd'hui), alimenté par `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` ; marqueur `Sans GB` prévu dans le modèle mais laissé vide (pas de capture disponible, hors scope)
- [ ] `drawOriginZone()`, `drawPlayerOriginZone()` retirées, aucune référence orpheline restante (cf. Risk R4 — recherche globale avant suppression)
- [ ] PDF généré sur effectif complet (14+14) : aucun débordement, pagination dynamique héritée de STORY-39 toujours cohérente
- [ ] PDF généré sur un jeu dédié couvrant les 8 zones + le marqueur 7m : classification et rendu corrects zone par zone, cohérent avec le rendu déjà validé côté appli en STORY-43

## Hors scope
Rien — dernière pièce du chantier, aucune extension supplémentaire.

## Dépend de
STORY-43 (modèle de zones validé côté appli).

## Taille
M
