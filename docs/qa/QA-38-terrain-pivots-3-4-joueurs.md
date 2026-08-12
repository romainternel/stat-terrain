# QA — STORY-38 (Disposition Pivot à 3 et 4 joueurs)

## Critères validés
- ✅ 3 pivots → triangle (1 devant centré, 2 derrière de part et d'autre) — vérifié visuellement, aucun chevauchement
- ✅ 4 pivots → carré (2 devant, 2 derrière) — vérifié visuellement, aucun chevauchement
- ✅ 1 et 2 pivots : formule mathématiquement identique à l'ancien mode `"h"` (vérifié par lecture de code, cf. Code Review) — pas de test visuel supplémentaire nécessaire
- ✅ Vérifié à 3 largeurs (1600px, 1000px, 800px landscape) — tient même au point le plus contraint (800px), encarts adjacents mais jamais chevauchants
- ✅ 5 pivots (17 joueurs sélectionnés au total, cas au-delà du hors-scope) : aucune exception JS (listener d'erreur global vérifié vide), fallback en grille 2 colonnes fonctionnel, et bonus non demandé mais agréable — le 5e joueur (ligne impaire) se centre automatiquement plutôt que de rester collé à gauche
- ✅ Autres postes (GB, ALG/ALD, ARG/ARD, DC) : positions numériques vérifiées sur un effectif complet (17 joueurs), toutes cohérentes avec le comportement attendu (ancrage bord pour ALG/ALD/ARG/ARD, profondeur DC > profondeur ARG/ARD) — aucune régression

## Cas limites testés
- Effectif maximal réaliste + au-delà (17 joueurs, 5 au même poste) : robuste
- Repositionnement en direct pendant une action en cours (BUT sélectionné, terrain en mode sélection joueur) : testé dans ce contexte précis, comportement correct

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune.

## Verdict
**PASSED**
