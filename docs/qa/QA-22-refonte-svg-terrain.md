# QA — STORY-22 : Refonte SVG du terrain

## Méthode de test
Tests réels via CDP (Chrome DevTools Protocol) sur Chrome headless — pas de simulation de code, vrais clics (`Input.dispatchMouseEvent`) et vraie capture d'écran (`Page.captureScreenshot`), sur deux viewports : iPad (1024×768) et iPhone portrait réel (390×844).

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Terrain (Match, Stats, PD/2min) utilise le nouveau SVG, plus aucune référence à `COURT_IMG` | ✅ | `grep COURT_IMG app.js` ne retourne plus qu'un commentaire explicatif (aucun usage réel). 7 emplacements vérifiés visuellement : Match, Stats Gardiens, mode tir (sélection impact), sélecteur PD. |
| Proportions réglementaires (6m, 9m, 7m, 4m) respectées à l'échelle du viewBox 350×208 | ✅ | Arc 6m, arc 9m pointillé, marques 7m/4m, ligne de but tous présents et proportionnés visuellement sur les 4 captures. **Non vérifié par un tiers expert du domaine — cf. critère suivant.** |
| Positions de tir historiques cohérentes avec le nouveau fond (même référentiel) | ✅ | `viewBox 0 0 350 208` inchangé. Test fonctionnel complet effectué : sélection action BUT → clic tireur → clic position d'impact → clic zone de but → événement enregistré avec `x`/`y` cohérents. |
| **Validation visuelle explicite de Romain** | ❌ **EN ATTENTE** | QA ne peut pas se substituer à Romain sur ce critère — lui seul peut juger si les proportions d'un vrai terrain de hand sont respectées. Ce n'est **pas un échec**, c'est un critère qui attend une action externe. Voir section dédiée ci-dessous. |
| Chaque écran affichant un terrain testé individuellement | ✅ | Match (`90-story22-match-court-v1.png`), Stats Gardiens (`91-story22-stats-gk-court-v1.png`), mode tir (`92-story22-shotmode-court-v1.png`), iPhone portrait scrollé (`94-story22-iphone-portrait-court-scrolled.png`). |
| Lisibilité en forte luminosité | ⚠️ Note | Pas de test en conditions réelles extérieures (hors de portée d'un test en local/CDP). Contraste des lignes du terrain volontairement renforcé par rapport à l'ancienne image (cf. notes Developer) — amélioration attendue mais non mesurée sur le terrain. |

## Cas limites testés
- Terrain avec 0 joueur sélectionné (état vide) : toujours géré par `renderCourtEmptyState()`, non affecté par le changement de fond — RAS, pas de régression avec STORY-20.
- Flux complet d'enregistrement d'un BUT avec positionnement sur le nouveau terrain : fonctionne de bout en bout, événement correctement structuré.

## Bugs trouvés
Aucun. 

Une anomalie de méthode a été détectée et corrigée **avant** cette validation (pas un bug de l'app) : le premier script de capture "iPhone portrait" réutilisait par erreur le viewport iPad (1024×768, `mobile:false`) au lieu de 390×844 — corrigé, la capture 93/94 reflète maintenant un vrai viewport iPhone.

## Régressions détectées
Aucune. Le flux de sélection joueur (STORY-20) et l'affichage du numéro de maillot (STORY-21) n'ont pas été affectés par ce changement — vérifié visuellement sur les captures Match (numéros affichés normalement, aucun joueur en trop, tiret pour les numéros manquants toujours présent).

## Verdict
**PASSED WITH NOTES**

Tous les critères vérifiables techniquement sont satisfaits. Le seul point non coché est la validation visuelle explicite de Romain, qui est un critère volontairement bloquant et non-automatisable (cf. `docs/risks/terrain-joueurs.md`). Recommandation : **ne pas considérer STORY-22 comme définitivement terminée avant retour explicite de Romain**, même si le reste du pipeline de contrôle est vert.
