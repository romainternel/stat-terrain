# QA — STORY-20 (Terrain vide si aucun joueur sélectionné)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

Mesures DOM réelles (comptage `.cp-player`, présence `.court-empty-msg`) + vrais clics simulés (badge 2min), pas seulement une relecture du code. Point de vigilance particulier : une première hypothèse ("PD et 2min partagent la même fonction") s'est révélée fausse à la vérification — corrigée en testant les deux indépendamment plutôt que de l'assumer.

## Critères d'acceptation

- ✅ **Terrain Match vide sans sélection** — confirmé, 0 `.cp-player`, message visible et lisible (`docs/design/screenshots/73-story20-empty-court-fixed.png`).
- ✅ **Sélecteurs PD et 2min/carton** — testés **indépendamment** l'un de l'autre (fonctions distinctes) : PD (`75-story20-pdselect-empty-fixed.png`), 2min via un vrai clic sur le badge `[data-badge="home|TWO_MIN"]` (`76-story20-2min-select-empty.png`). Les deux confirmés vides.
- ✅ **Sélection partielle respectée** — 3 joueurs sélectionnés sur 22 → exactement 3 affichés (`74-story20-3players-fixed.png`).
- ✅ **Message lisible** — un premier essai était illisible (contraste sur fond clair), corrigé par le Developer avant que je ne le teste — déjà bon à ma vérification.

## Cas limites

- Testé avec 0 et 3 joueurs sélectionnés sur un roster de 22 — pas testé avec la totalité (22/22) sélectionnée, mais ce cas ne pose pas de risque particulier différent du comportement déjà existant (chevauchement déjà connu et accepté, cf. STORY-19).
- Écran "shot mode" (position d'impact après avoir choisi un tireur) non affecté — vérifié qu'il ne dépend pas du roster filtré (code inchangé à cet endroit).

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun.

## Verdict

**PASSED**
