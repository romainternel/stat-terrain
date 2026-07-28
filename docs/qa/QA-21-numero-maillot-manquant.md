# QA — STORY-21 (Numéro de maillot manquant sur le terrain)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

Mesures DOM réelles (contenu texte + classe CSS de `.cp-num`) avec un roster de test reproduisant fidèlement le cas réel (roster par défaut, numéros vides).

## Critères d'acceptation

- ✅ **Tiret au lieu de "?"** — confirmé sur les 3 joueurs testés (`docs/design/screenshots/80-story21-missing-number.png`), texte "–" et classe `cp-num-missing` présents.
- ✅ **Style distinct** — opacité réduite (0.4) et poids de police normal (vs 800 pour un vrai numéro), visuellement bien différencié.
- ✅ **`renderTeamSetup` non affecté** — vérifié explicitement que son "?" concerne le nom du joueur, pas le numéro ; code non touché par le diff.
- ✅ **Une seule fonction `displayNumber()`** — confirmé par le diff, 3 duplications supprimées.

## Cas limites

- Test avec un roster où **tous** les joueurs manquent de numéro (cas réel du roster par défaut) plutôt qu'un seul isolé — plus représentatif du cas réel de Romain, bonne couverture.

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun.

## Verdict

**PASSED**
