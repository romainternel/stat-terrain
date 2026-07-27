# QA — STORY-04 (Tokens d'ombre et polish des cartes hors-match)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

Comparaison visuelle avant/après sur Setup, Stats (Gardiens + Comparaison), Bilan (iPad 1024px). Vérification que le diff n'affecte que `.card`/`.gk-stat`.

## Critères d'acceptation

- ✅ **Tokens déclarés dans `:root`** — `--shadow-card`, `--shadow-card-hover`, `--shadow-accent`, `--card-border`, `--card-border-hover`, `--card-bg`.
- ✅ **Cartes Stats/Bilan/Setup utilisent les tokens** — `.card` (19 usages dans `app.js`) et `.gk-stat` couverts.
- ✅ **Aucun changement HTML/JS** — diff confirmé limité à `style.css`/`sw.js`.
- 🟡 **Comparaison visuelle "ça a l'air plus fini"** — **verdict mitigé, à faire trancher par Romain** : sur Stats (`docs/design/screenshots/59-story04-final-stats-gk.png`, `60-story04-final-stats-compare.png`), le rendu était déjà bon et l'amélioration est réelle mais discrète. Sur Setup (`58-story04-final-setup.png`), l'amélioration des grandes cartes conteneurs est visible mais **le ressenti global de l'écran reste plat**, car le problème principal de cet écran est la longue liste de `.player-card` identiques — hors du scope de cette story. Je ne peux pas cocher ce critère avec certitude sans le retour explicite de Romain sur "est-ce que ça claque maintenant".
- ✅ **Aucune régression de lisibilité** — aucun texte recoloré, contrastes inchangés.

## Cas limites

- Écran Bilan testé en état vide (aucun match sauvegardé) — pas de carte de contenu à évaluer dans cet état, non concluant pour ce critère spécifique mais pas un problème introduit par cette story.

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun. Point non-bloquant à faire remonter : le "claque" attendu par Romain dépend probablement plus de `.player-card` (Setup) que des cartes conteneurs traitées ici — recommandation déjà notée par le Developer et le Code Reviewer, à transformer en nouvelle story si Romain confirme.

## Verdict

**PASSED WITH NOTES**
