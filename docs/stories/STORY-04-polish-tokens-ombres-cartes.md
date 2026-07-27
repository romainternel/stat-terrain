# STORY-04 — Tokens d'ombre et polish des cartes hors-match

**En tant que** Romain,
**Je veux** que les écrans Stats, Bilan et Setup aient le même niveau de finition visuelle que l'écran Match,
**Afin de** avoir une app qui paraît premium partout, pas seulement pendant la saisie.

## Contexte technique

- Zone concernée : `style.css` — `:root` (nouveaux tokens), `.card`, `.gk-stat`, cartes des onglets Stats/Bilan/Setup.
- Ajout des tokens définis par le Visual Crafter (`docs/visual/polish-pass.md`) : `--shadow-card`, `--shadow-card-hover`, `--shadow-accent`.
- Application de `box-shadow:var(--shadow-card)` sur `.card` et équivalents qui n'en ont pas aujourd'hui.
- Généralisation de `.card-t` (titre de carte, déjà cohérent sur certains écrans) partout où une carte a un titre.

## Critères d'acceptation

- [x] Les nouveaux tokens d'ombre sont déclarés dans `:root` de `style.css` (revus pour être visibles sur fond quasi-noir, voir notes Developer).
- [x] Toutes les cartes des onglets Stats, Bilan et Setup utilisent `var(--shadow-card)` (ou `--shadow-card-hover` en interaction) — `.card` (19 usages) et `.gk-stat` couverts.
- [x] Aucun changement de structure HTML/JS — uniquement `style.css`.
- [ ] Comparaison visuelle avant/après validée par Romain — **en attente de son retour explicite** ; mon évaluation intermédiaire : correct sur Stats/Bilan (déjà bons), insuffisant à lui seul sur Setup (voir note Developer, le vrai souci est `.player-card`, hors scope).
- [x] Aucune régression de lisibilité — aucune couleur de texte modifiée, uniquement fond/bordure/ombre des conteneurs.

## Hors scope

- Les micro-animations et états interactifs (traités dans STORY-05).
- Tout changement de palette de couleur (on garde les couleurs existantes).

## Dépend de

Aucune.

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-27)

**Premier essai insuffisant, corrigé avant de livrer** : la spec initiale du Visual Crafter (`box-shadow:var(--shadow-card)` avec une ombre noire `rgba(0,0,0,.25)`) est **optiquement invisible** sur ce fond — le body est déjà un dégradé quasi-noir (`#0A1520` → `#162030`), une ombre portée noire ne peut pas créer de contraste sur un fond déjà noir. Vérifié par capture : premier essai quasiment indiscernable de l'avant. Corrigé en repensant la technique d'élévation pour un thème sombre (celle qu'utilisent les dashboards premium en dark mode) : dégradé interne clair→sombre sur `.card`/`.gk-stat` (`linear-gradient(160deg, rgba(255,255,255,.07), rgba(255,255,255,.025))`), bordure plus contrastée (`--card-border`), et un highlight inset en haut de carte pour simuler un reflet — l'ombre portée noire est gardée en complément (utile si une carte se retrouve un jour sur un fond plus clair) mais n'est pas le signal visuel principal ici.

**Constat après vérification visuelle (captures Setup/Stats/Bilan)** : le résultat est **correct et conforme au scope de la story**, mais reste discret sur les écrans Stats/Bilan qui étaient déjà bien traités (bonne hiérarchie typographique, couleurs par métrique) — l'amélioration y est réelle mais peu spectaculaire. **Le vrai point faible visuel identifié est ailleurs** : l'écran Équipes (Setup), avec sa longue liste de `.player-card` quasi identiques (gris sur gris, aucun accent), qui n'est PAS dans le scope de cette story (la story ne couvre que `.card`/`.gk-stat`, pas `.player-card`). C'est probablement là que se joue le "ça claque" demandé par Romain — à signaler pour une story dédiée plutôt que de déborder du scope ici.

**Fichiers modifiés** : `style.css` (tokens `:root` + `.card` + `.gk-stat`), `sw.js` (v52→v53). Aucun changement HTML/JS, conforme au critère d'acceptation.
