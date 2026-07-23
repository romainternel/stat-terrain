# STORY-07 — Message "un match = un appareil"

**En tant que** Romain,
**Je veux** être prévenu que changer d'appareil en cours de match n'est pas supporté,
**Afin de** ne pas être surpris de perdre des données si je bascule d'iPad à iPhone (ou inversement) en plein match.

## Contexte technique

- Zone concernée : `app.js`/`index.html` — écran d'accueil ou écran de démarrage d'un nouveau match (`newMatch()`).
- Mitigation du risque #4 identifié par le Risk Analyst (`docs/risks/iphone-polish.md`) — pas de correction technique (hors scope : pas de sync multi-appareil), uniquement de la communication claire.
- Un simple texte/tooltip suffit, pas de popup bloquant à chaque match (deviendrait vite ignoré/agaçant).

## Critères d'acceptation

- [ ] Un message discret (ex : petite note sous le bouton "Nouveau match" ou dans un écran d'aide) indique qu'un match doit être joué du début à la fin sur le même appareil.
- [ ] Le message n'interrompt pas le flux de démarrage d'un match (pas de clic supplémentaire obligatoire).

## Hors scope

- Toute synchronisation ou détection technique du changement d'appareil.

## Dépend de

Aucune.

## Taille

S
