# STORY-38 — Disposition Pivot à 3 et 4 joueurs sur le terrain

**En tant que** Romain,
**Je veux** que les encarts joueurs au poste Pivot ne se chevauchent plus quand 3 ou 4 pivots sont sélectionnés pour le match,
**Afin de** pouvoir composer un effectif réaliste (14-16 joueurs sur 7 postes implique souvent 3+ joueurs à un même poste) sans avoir à contourner l'affichage.

## Contexte technique
- Zone concernée : `app.js`, `POS_XY` (const, ~ligne 9-18) et `courtPlayerPositions()` (~ligne 2270)
- Nouveau mode `spread:"grid"` dans `POS_XY.PVT` (remplace `spread:"h"` + `hSpread:26` déjà en place), avec table de layouts relatifs `{dx,dy}` par effectif (1, 2, 3, 4) et fallback générique en grille 2 colonnes pour 5+
- Fonctions **inchangées, ne pas toucher** : `cpBoxStyle()` (~ligne 2264), les 4 sites d'appel de `courtPlayerPositions()` (`renderMatchPanel`, `renderPenRoster`, `renderPdSelect`, `renderPlayerSelect`) — ils consomment `{cx,cy,anchor}` sans connaître le mode de spread
- Autres postes (GB, ALG/ALD, ARG/ARD, DC) : **non concernés**, restent sur leur mécanisme actuel (spread vertical linéaire ou ancrage bord), aucune régression attendue mais à vérifier (cf. Regression)
- Référence design : `docs/design/terrain-postes-multiples-et-pdf-v2.md` (mockups triangle/carré), `docs/arch/terrain-postes-multiples-et-pdf-v2.md` (code exact du mode `"grid"`)

## Critères d'acceptation
- [ ] 3 pivots sélectionnés → 1 encart centré au-dessus (plus proche du but), 2 encarts en dessous de part et d'autre — aucun chevauchement visuel
- [ ] 4 pivots sélectionnés → 2 encarts de chaque côté (un devant, un derrière par côté) — aucun chevauchement visuel
- [ ] 1 et 2 pivots : rendu visuellement identique à avant cette story (pas de régression sur le cas déjà validé)
- [ ] Vérifié à au moins 2 largeurs d'écran (large ~1000px+ et étroite ~370-400px type iPhone portrait)
- [ ] 5 pivots ou plus (test manuel, cas non réaliste) : aucune exception JS, aucun encart ne sort du cadre visuel du terrain — pas de disposition dédiée exigée, juste l'absence de crash
- [ ] Les autres postes (GB, ALG/ALD, ARG/ARD, DC) affichent un rendu identique à avant cette story sur un effectif à 1 et 2 joueurs

## Hors scope
- Disposition dédiée pour 5+ joueurs à un même poste (fallback générique suffisant)
- Application du mode `"grid"` à un autre poste que PVT (mécanisme réutilisable mais non activé ailleurs dans cette story)

## Dépend de
Aucune

## Taille
S
