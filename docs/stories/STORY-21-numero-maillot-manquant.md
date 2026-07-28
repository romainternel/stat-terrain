# STORY-21 — Numéro de maillot manquant sur le terrain

**En tant que** Romain,
**Je veux** qu'un joueur sans numéro de maillot enregistré n'affiche pas un "?" sur le terrain,
**Afin de** ne pas confondre une absence d'info avec un symbole d'erreur ou d'action à faire.

## Contexte technique

- Zone concernée : `app.js` — fonction `dn(p)` dupliquée 3 fois (`~ligne 1131, 1554, 1620`), à consolider en une seule fonction `displayNumber(p)` réutilisée partout.
- `displayNumber(p){ return p.number ? p.number : "–"; }` — tiret au lieu de "?", avec la classe `cp-num-missing` (opacité réduite, spec `docs/visual/terrain-joueurs.md` section 3) quand le numéro est absent.
- **Ne touche pas** au "?"/✏️ de `renderTeamSetup` (nom de joueur non renseigné, écran Équipes) — logique différente, à laisser intacte.

## Critères d'acceptation

- [ ] Un joueur sans numéro affiche un tiret discret (pas un "?") sur toutes les vues de terrain (Match, sélection PD, sélection 2min/carton).
- [ ] Le style du tiret (opacité réduite) le distingue visuellement d'un vrai numéro.
- [ ] Le "?"/✏️ de l'écran Équipes (nom de joueur non renseigné) reste inchangé.
- [ ] Une seule fonction `displayNumber()` existe désormais (plus de duplication à 3 endroits).

## Hors scope

- Tout changement sur l'écran Équipes.

## Dépend de

Aucune.

## Taille

XS
