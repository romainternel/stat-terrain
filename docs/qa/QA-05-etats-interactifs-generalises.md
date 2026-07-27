# QA — STORY-05 (États interactifs généralisés)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

Mesures DOM réelles (pas seulement lecture du CSS) : `mousePressed` maintenu + vérification `:active` via `querySelector`, et de vraies touches Tab simulées (`Input.dispatchKeyEvent`) pour `:focus-visible`.

## Critères d'acceptation

- ✅ **`:active` visible sur tous les boutons** — confirmé sur `.nav-b` et `.st-tab` (`transform:matrix(0.94,...)` mesuré pendant l'appui), `docs/design/screenshots/61-story05-navb-active-pressed.png`/`62-story05-sttab-active-pressed.png`.
- ✅ **Focus visible** — confirmé avec de vraies touches Tab (`e.matches(':focus-visible')` → `true`, anneau visible `docs/design/screenshots/64-story05-realtab-focus.png`). Point méthodologique important : un test avec `.focus()` programmatique aurait donné un faux négatif (Chromium ne l'active pas dans ce cas) — le Developer l'a identifié et corrigé lui-même avant de livrer.
- ✅ **`.is-disabled` cohérente** — classe formalisée, non appliquée faute de cas réel existant dans l'app. Accepté : forcer son usage sur un bouton qui n'est pas vraiment désactivé (ex. filtres GB à opacité réduite) aurait cassé leur clic.
- ✅ **Aucune régression Match** — diff n'inclut aucune ligne sur `.act-h`/`.btn`.

## Cas limites

- Le test focus-visible a nécessité une deuxième méthode après un premier résultat trompeur — bon exemple de pourquoi il faut toujours valider avec l'interaction réaliste (clavier), pas une simulation raccourcie (`.focus()` direct).

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun.

## Verdict

**PASSED**
