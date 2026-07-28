# STORY-22 — Refonte SVG du terrain

**En tant que** Romain,
**Je veux** que le terrain affiché (Match et Stats) ait un rendu visuel cohérent avec le reste de l'app,
**Afin de** ne plus avoir l'impression d'une image rapportée qui jure avec le design sombre de l'app.

## Contexte technique

- `COURT_IMG` (image JPEG encodée en base64, ~700 lignes dans `app.js`) actuellement utilisée en `background-image` sur `.court-pick` (Match, sélecteurs PD/2min) **et** via `<image href>` dans les SVG de tir (Stats). Remplacée par un SVG dessiné nativement (spec complète : `docs/visual/terrain-joueurs.md`, décision technique : `docs/architecture/terrain-joueurs.md`).
- Nouvelle fonction `renderCourtSvg()`, viewBox `0 0 350 208` conservé (compatibilité avec les coordonnées `x`/`y` des événements déjà enregistrés).
- Éléments à dessiner : ligne de but, zone 6m (arc), ligne 9m (arc pointillé), point de penalty 7m, marque 4m — proportions réglementaires réelles à respecter, pas approximatives.
- `COURT_IMG` supprimée une fois **tous** les usages remplacés (rechercher exhaustivement avant de supprimer, cf. risque #3 `docs/risks/terrain-joueurs.md`).

## Critères d'acceptation

- [ ] Le terrain (Match, Stats, sélecteurs PD/2min) utilise le nouveau SVG, plus aucune référence à `COURT_IMG` dans `app.js`.
- [ ] Les proportions réglementaires (6m, 9m, 7m, 4m) sont respectées à l'échelle du viewBox 350×208 — comparaison visuelle avec un terrain de hand réel, pas une estimation à l'œil.
- [ ] Les positions de tir déjà enregistrées (coordonnées `x`/`y` historiques) restent cohérentes avec le nouveau fond (même référentiel de coordonnées).
- [ ] **Validation visuelle explicite de Romain** avant de considérer cette story terminée (il est expert du domaine, un rendu "à peu près correct" ne suffit pas).
- [ ] Chaque écran affichant un terrain a été testé individuellement (pas seulement l'écran Match) — Match, Stats Gardiens (cartes de tir), sélecteurs PD/2min.
- [ ] Le rendu reste lisible en conditions de forte luminosité (test visuel, cf. risque déjà noté en cycle 1 sur la lisibilité extérieure).

## Hors scope

- Le comportement de sélection des joueurs (traité dans STORY-20).
- L'affichage du numéro de maillot (traité dans STORY-21).
- Toute interactivité nouvelle sur le terrain (zoom, replay) — cf. critère de bascule de l'Architecte, pas pour cette story.

## Dépend de

Aucune (recommandé après STORY-20 et STORY-21 pour limiter les conflits de merge sur les mêmes zones de `app.js`, mais pas un blocage strict).

## Taille

M
