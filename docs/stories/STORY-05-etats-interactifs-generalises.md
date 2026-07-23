# STORY-05 — États interactifs généralisés (active/focus/disabled)

**En tant que** Romain,
**Je veux** que tous les boutons de l'app (pas seulement ceux de l'écran Match) réagissent de façon cohérente au toucher,
**Afin de** avoir une app qui donne un retour satisfaisant partout, avec la même qualité de finition.

## Contexte technique

- Zone concernée : `style.css` — `.btn`, `.nav-b`, `.st-tab` (Stats), boutons Setup, boutons Bilan.
- Aujourd'hui, l'état `:active` avec `transform:scale()` n'est cohérent que sur les boutons de l'écran Match (`.act-h`, `.btn`) — à généraliser aux onglets Stats (`.st-tab`), à la nav (`.nav-b`), aux boutons Setup.
- Ajout d'un état `focus` visible (`outline:2px solid var(--accent)`) — aujourd'hui `outline:none` global sur `button`/`input` sans remplacement (point d'accessibilité relevé par le Visual Crafter).
- Formalisation d'une classe utilitaire `.is-disabled` (`opacity:.35;pointer-events:none`) réutilisant le pattern déjà vu sur `.player-card.dimmed`.

## Critères d'acceptation

- [ ] Tous les boutons cliquables de l'app ont un état `:active` visible (scale + changement de fond), pas seulement ceux du Match.
- [ ] Un état `focus` visible existe (utile notamment si Romain navigue au clavier/VoiceOver, même si l'usage principal reste tactile).
- [ ] La classe `.is-disabled` est utilisée de façon cohérente partout où un bouton peut être désactivé (ex : bouton d'export sans données).
- [ ] Aucune régression sur les interactions actuelles du Match (déjà bien traitées, ne pas les casser en généralisant).

## Hors scope

- Les ombres de carte (traitées dans STORY-04).

## Dépend de

STORY-04 (réutilise les mêmes tokens de base pour rester cohérent).

## Taille

S
