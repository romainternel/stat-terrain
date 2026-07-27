# Code Review — STORY-04 (Tokens d'ombre et polish des cartes hors-match)

*Produit par le Code Reviewer — squad de contrôle BMAD*

## Diff revu

`style.css` (+5 tokens `:root`, `.card` réécrite, `.gk-stat` étendue) + bump `sw.js` `v52`→`v53`.

## Vérifications

- **Conformité à la spec** : le Developer a identifié que la spec initiale du Visual Crafter (ombre noire `rgba(0,0,0,.25)`) était **inefficace sur ce fond quasi-noir** — c'est un constat juste et bien argumenté (une ombre portée a besoin de contraste avec un fond plus clair pour être visible ; ici le fond est déjà sombre). La technique de remplacement (dégradé interne + bordure + highlight inset) est la pratique standard pour simuler de l'élévation en dark mode. Bonne initiative de ne pas appliquer une spec inefficace telle quelle, et de documenter pourquoi.
- **DRY** : première version avait le même `linear-gradient(...)` dupliqué dans `.card` et `.gk-stat` — corrigé en cours de route via un token `--card-bg` partagé avant de livrer. Bon réflexe.
- **Scope** : strictement `:root`, `.card`, `.gk-stat` — conforme à la zone déclarée. Aucun changement HTML/JS.
- **Honnêteté sur le résultat** : le Developer signale que l'amélioration reste subtile sur Stats/Bilan (déjà bien traités) et que le vrai point faible visuel (`.player-card` sur Setup) est hors du scope de cette story — évite de sur-vendre le résultat ou de déborder du scope pour "compenser".
- **Pas de régression de contraste** : aucune couleur de texte touchée, uniquement fond/bordure/ombre des conteneurs — cohérent avec le critère d'acceptation correspondant.

## Remarques

**Bloquant** : aucun.

**Recommandé** :
- Le critère "comparaison validée par Romain" reste ouvert (subjectif, ne peut pas être auto-validé) — à faire trancher explicitement après déploiement plutôt que de le cocher par anticipation.
- Suivre la recommandation du Developer : cadrer une story dédiée à `.player-card` (Setup) si l'objectif "ça claque" n'est pas atteint après cette passe — c'est probablement là que se joue la perception globale de l'app, plus que sur les cartes Stats/Bilan qui étaient déjà correctes.

## Verdict

**APPROUVÉ**
