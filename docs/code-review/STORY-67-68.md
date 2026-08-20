# Code Review — STORY-67 (grille DC) + STORY-68 (raccourcis en-tête)

## Portée revue
Diff complet (`app.js` +19/-6, `style.css` +9, `sw.js` v111→v112). Comparé à `docs/arch/dc-grid-et-raccourcis-header.md`.

## Développeur
Les deux stories implémentées conformément à l'Architecture, sans écart de fond.

## Conformité et cohérence

**STORY-67 (grille DC)** — `POS_XY.DC` reçoit exactement `spread:"grid", hSpread:30, vSpread:10` comme prescrit. Le layout à 5 ajouté à `layouts` correspond au calcul de l'Architecture (3 en rangée haute, 2 en rangée basse). **Vérification indépendante des bornes** (recalculée, pas seulement relue) : pour 2/3/4/5 joueurs, tous les `cx`/`cy` résultants tombent dans `[20,80]`/`[83,93]` respectivement — jamais aux limites du clamp `[6,94]`/`[4,96]`, donc aucune collision entre joueurs à aucun des 4 comptes testés. Le commentaire du bloc `grid` mis à jour de façon cohérente ("5+" → "6+" pour refléter que 5 a maintenant sa propre disposition).

**STORY-68 (raccourcis en-tête)** — Point le plus sensible identifié par le Risk Analyst (R3, déplacement de `margin-left:auto`) : vérifié que `#settings-btn` a bien perdu son `margin-left:auto` inline (`style="border-color:...;white-space:nowrap;"`, sans la marge) et que `.hdr-shortcuts` (toujours rendu, avant `#settings-btn` dans le flux) porte désormais cette marge en CSS. Un seul point d'ancrage de marge automatique sur la ligne — cohérent avec l'analyse de risque, pas de double marge. Binding des deux nouveaux boutons ajouté au bon endroit dans `bind()`, réutilise `setMode()` telle quelle pour le raccourci Mode (la confirmation bloquante existante n'est pas contournée) et le même pattern `S.trackGK=!S.trackGK;R();` que les 2 sites existants pour le raccourci GB. Aucun conflit d'id DOM (vérifié par recherche : `hdr-mode-btn`/`hdr-trackgk-btn` chacun défini une seule fois).

## Finding — Note (non bloquant)
Le raccourci Suivi GB utilise `font-size:12px` (hérité de `.btn-xs`) plutôt que le `11px` indiqué dans `docs/visual/dc-grid-et-raccourcis-header.md`. Écart d'1px, invisible en pratique — et réutiliser tel quel le token `.btn-xs` déjà existant plutôt que d'introduire une valeur ad hoc est arguablement plus cohérent avec le design system que de suivre la spec à la lettre. Aucune action requise.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Écart cosmétique de 1px sur le raccourci Suivi GB (voir ci-dessus) — sans conséquence, pas à corriger.

## Verdict
**APPROUVÉ**
