# Code Review — STORY-21 (Numéro de maillot manquant sur le terrain)

*Produit par le Code Reviewer — squad de contrôle BMAD*

## Diff revu

`app.js` (consolidation de 3 `dn()` locales en une `displayNumber()` module, + classe conditionnelle), `style.css` (+`.cp-num-missing`), `sw.js` (v55→v56).

## Vérifications

- **Diligence avant modification** : le Developer a vérifié l'existence d'un 4e `dn` potentiellement concerné (`renderTeamSetup`) avant de toucher au code, a confirmé que c'est un cas différent (basé sur le nom, pas le numéro) et l'a laissé intact. C'est exactement la vérification qu'il fallait faire avant de généraliser un renommage/une consolidation.
- **Réutilisation propre** : une seule fonction `displayNumber()` remplace 3 copies identiques — réduction de duplication nette, zéro changement de comportement pour les autres call sites.
- **Scope** : strictement les 3 fonctions déclarées + le nouvel helper. Rien sur `renderTeamSetup`.
- **Découverte utile documentée** : le Developer a noté que `DEFAULT_FENIX` a `number:""` pour tous les joueurs par défaut — explique pourquoi la capture d'écran de Romain montrait des "?" partout, pas un cas isolé. Bonne contextualisation pour QA.

## Remarques

**Bloquant** : aucun.

**Note** : aucune.

## Verdict

**APPROUVÉ**
