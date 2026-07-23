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

- [ ] Les nouveaux tokens d'ombre sont déclarés dans `:root` de `style.css`.
- [ ] Toutes les cartes des onglets Stats, Bilan et Setup utilisent `var(--shadow-card)` (ou `--shadow-card-hover` en interaction).
- [ ] Aucun changement de structure HTML/JS — uniquement des ajustements CSS.
- [ ] Comparaison visuelle avant/après validée par Romain (subjectif mais vérifiable : "ça a l'air plus fini").
- [ ] Aucune régression de lisibilité (contraste inchangé sur le texte).

## Hors scope

- Les micro-animations et états interactifs (traités dans STORY-05).
- Tout changement de palette de couleur (on garde les couleurs existantes).

## Dépend de

Aucune.

## Taille

S
