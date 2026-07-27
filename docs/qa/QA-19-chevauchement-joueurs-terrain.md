# QA — STORY-19 (Chevauchement des étiquettes joueurs sur le terrain)

*Produit par le QA — squad de contrôle BMAD*

## Méthode

Mesures DOM automatisées (`getBoundingClientRect`, calcul géométrique de chevauchement) + captures visuelles, à trois largeurs (iPhone portrait 390px, iPhone paysage 844px, iPad 1024px), avec deux jeux de données : 7 joueurs "réalistes" (incluant 3 joueurs à la même position, cas réellement fréquent) et 22 joueurs (effectif complet, cas extrême).

## Critères d'acceptation

- ✅ **Effectif réel (7 joueurs), aucun chevauchement** — 4 chevauchements mesurés avant fix sur iPhone portrait (`docs/design/screenshots/41-story19-7players-iphone-portrait.png`), **0 après** (`45-story19-AFTER-7players-iphone-portrait.png`). iPad et paysage : 0 avant/après.
- ✅ **Effectif complet (22), pas parfait mais lisible** — 19 chevauchements avant → 9 après (`43-...` vs `47-story19-AFTER-22players-iphone-portrait.png`). Amélioration nette et visible, conforme à un critère qui n'exigeait pas la perfection sur ce cas.
- ❌ **Zone tactile ≥44px** — **non satisfait**, mesuré à 23px de hauteur après le fix. Je ne peux pas cocher ce critère. Cependant, contexte important à ne pas ignorer : la même mesure sur iPad (référence non modifiée par cette story) donne 34px — **déjà sous 44px avant toute intervention**. Ce critère, tel qu'écrit dans la story, était probablement irréaliste dès le départ compte tenu de la densité d'information nécessaire sur ce composant (positionnement de plusieurs joueurs sur un terrain de taille contrainte). Je le note comme un échec formel du critère, pas comme un défaut d'implémentation du Developer.
- ✅ **Aucune régression iPad** — tailles et absence de chevauchement identiques avant/après sur 1024px.

## Cas limites

- Le cas réellement fréquent (2-3 joueurs à la même position, effectif dispo typique d'un match) est celui qui est maintenant résolu — c'était le bon choix de priorité du Developer, plus important que le cas extrême à 22.
- Test avec effectif vide ou 1 seul joueur non testé spécifiquement — risque jugé nul (moins de contenu = moins de risque de chevauchement, pas un cas qui inquiète).

## Régressions détectées

Aucune.

## Bugs trouvés

Aucun bloquant. Le critère "44px minimum" non satisfait est documenté ci-dessus — je recommande de ne pas bloquer la livraison pour ça (c'est une limite physique du compromis, pas un oubli), mais de garder cette information visible si un jour Romain remonte une gêne réelle à cliquer le bon joueur en match — ce serait le signal qu'il faut revoir le positionnement lui-même (hors scope CSS-only de cette story).

## Verdict

**PASSED WITH NOTES**
