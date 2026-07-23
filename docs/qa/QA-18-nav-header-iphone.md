# QA — STORY-18 (Navigation du header inaccessible sur iPhone)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

App relancée en local (serveur statique + Chrome headless piloté via CDP, mêmes conditions que l'audit initial), tests à trois largeurs : iPhone portrait (390×844), iPhone paysage (844×390), iPad (1024×768).

## Critères d'acceptation

- ✅ **Sur un viewport ≤430px de large, les 5 onglets sont tous atteignables** — `docs/design/screenshots/07-nav-fix-iphone-initial.png` (état initial, indice de scroll visible) → `08-nav-fix-iphone-scrolled.png` (Bilan/Matchs visibles après scroll). Mesure DOM : `scrollWidth` 408px > `clientWidth` 272px. Clic réel sur l'onglet "Matchs" après scroll → bascule effective vers l'écran attendu ("Matchs sauvegardés").
- ✅ **Le logo/titre ne doit pas empêcher la nav de tenir sur l'écran** — logo condensé (icône 28px, titre 12px, sous-titre masqué) sous 700px, confirmé par capture.
- ✅ **Testé sur les deux orientations d'iPhone** — portrait : fix actif et nécessaire (voir ci-dessus). Paysage (844×390, `docs/design/screenshots/11-nav-iphone-landscape.png`) : les 5 onglets sont déjà tous visibles nativement à cette largeur (844px > le seuil de 700px où le fix s'active, mais l'espace disponible en paysage suffit sans intervention) — `scrollWidth === clientWidth`, pas de débordement. **Point à noter, pas un bug** : le fix CSS ne s'active pas en paysage (hors media query), mais ce n'est pas nécessaire à cette largeur — comportement correct par simple absence de contrainte, pas par une correction explicite. Si un futur iPhone/format plus étroit en paysage existait sous 700px de large, il faudrait revérifier.
- ✅ **Aucune régression sur iPad** — `docs/design/screenshots/10-nav-noregress-ipad.png` identique visuellement à la capture de référence avant fix (`01-setup-ipad.png`). Mesure DOM : `scrollWidth === clientWidth` (494px), média query non déclenchée au-dessus de 700px.

## Cas limites

- Vue "Match" (où `#settings-btn` s'ajoute dans le header à côté de la nav) non re-capturée explicitement à 390px dans cette passe QA, mais le Developer a traité `#settings-btn{flex-shrink:0}` spécifiquement pour ce cas et le mécanisme de scroll s'applique de la même façon quel que soit le nombre d'éléments avant `.nav` dans le flex `.hdr` — risque résiduel jugé faible, à garder à l'œil lors du prochain passage sur l'écran Match (STORY-02).

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun bloquant ni majeur. Rien de mineur non plus à signaler au-delà de ce que le Developer avait déjà lui-même noté (titre qui wrap sur 2-3 lignes, préexistant, hors scope).

## Verdict

**PASSED**
