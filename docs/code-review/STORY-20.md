# Code Review — STORY-20 (Terrain vide si aucun joueur sélectionné)

*Produit par le Code Reviewer — squad de contrôle BMAD*

## Diff revu

`app.js` (suppression du fallback dans 3 fonctions + nouvelle `renderCourtEmptyState()`), `style.css` (+`.court-empty-msg`), `sw.js` (v54→v55).

## Vérifications

- **Conformité à la story** : correspond exactement au diagnostic (3 sites identiques corrigés, pas 2 sur 3 oubliés — vérifié par grep sur le diff).
- **Vérification visuelle réelle, pas juste syntaxique** : le Developer a testé avec le navigateur et a détecté un problème de contraste que la spec initiale du Visual Crafter n'avait pas anticipé (couleur pensée pour le futur fond sombre de STORY-22, illisible sur le fond actuel encore clair) — corrigé avant de livrer plutôt que de livrer un message invisible. Exactement le comportement demandé après le retour de Romain sur STORY-04.
- **`new Function()` avant livraison** : respecté (convention explicite de `CLAUDE.md`).
- **Scope** : aucune touche à `dn()`/numéro (réservé à STORY-21), ni au fond du terrain lui-même (réservé à STORY-22) — bonne discipline de ne pas anticiper les stories suivantes.
- **Cohérence des 3 sites** : les 3 fonctions utilisent la même fonction `renderCourtEmptyState()` plutôt que 3 messages différents — bon réflexe de cohérence.

## Remarques

**Bloquant** : aucun.

**Recommandé** :
- Le message de livraison à Romain doit mentionner explicitement le changement de comportement (terrain vide par défaut) — déjà anticipé par le Developer dans ses notes, à répéter dans le résumé final de cette story pour ne pas que ça surprenne.

## Verdict

**APPROUVÉ**
