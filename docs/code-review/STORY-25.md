# Code Review — STORY-25 : Polish visuel de la carte joueur (Équipes)

## Périmètre revu
- `app.js` : `renderTeamSetup()` — ajout `accentRgb`, variable CSS `--pc-accent` sur le conteneur de liste, badge `.jersey`, classe `selected` explicite, icône sur `.gk-badge`.
- `style.css` : `.player-card` et enfants (`.jersey`, `.gk-badge`, `.del-btn`), `.sel-toggle`, `.player-card.dimmed`.

## Conformité architecture
- Respecte `docs/visual/polish-pass.md` : réutilise `--card-bg`/`--card-border`/`--shadow-card` (indirectement via le style `box-shadow` inline sur `.selected`) plutôt que d'introduire de nouveaux tokens globaux. Le seul ajout est `--pc-accent`, une variable **locale** (scope room-level via l'attribut `style` du conteneur), pas un token global — cohérent avec le fait que c'est une couleur contextuelle (équipe), pas une couleur de thème.
- Bonne réutilisation : `displayNumber(p)` (module-level depuis STORY-21) réutilisée telle quelle pour le badge numéro, au lieu de recréer une fonction locale `dn()` — élimine une des duplications que STORY-21 avait justement pour but de corriger. `dn()` local a été supprimé proprement (vérifié : plus aucune référence).

## Conventions de code
- Style cohérent avec le reste du fichier CSS (indentation, groupement par sélecteur).
- Utilisation de `rgb(var(--pc-accent))` / `rgba(var(--pc-accent),X)` — pattern déjà établi dans le projet pour `--accent-rgb` (Match), donc cohérent avec l'existant plutôt qu'un nouveau pattern.

## Réutilisation vs duplication
- RAS. Le passage de couleur d'équipe via une seule variable CSS posée une fois sur le conteneur (plutôt que répétée par ligne) est un bon choix — un seul point de vérité, pas de calcul répété par joueur.

## Scope
- Diff strictement contenu à `.player-card` et son contexte immédiat. Aucune touche sur le panneau d'ajout rapide adversaire, les boutons d'action bas de carte, ou tout autre écran.
- Point vérifié : `.del-btn` perd son `position:absolute` (qui causait un chevauchement visuel avec le contenu avant cette story) au profit d'un positionnement flex naturel — c'est un changement de layout implicite, mais positif et cohérent avec l'objectif de la story (meilleure visibilité du bouton supprimer), pas une dérive de scope.

## Gestion d'erreurs
- Non applicable — changements CSS/markup purs, pas de nouvelle logique conditionnelle risquée.

## Sécurité basique
- Aucune donnée utilisateur interpolée sans échappement au-delà de ce qui existait déjà (`p.name`, `p.number` via `displayNumber`). Pas de nouveau vecteur.

## Verdict
**APPROUVÉ**

Aucune remarque bloquante. Bon exemple de réutilisation de fonction existante (`displayNumber`) plutôt que de dupliquer une logique déjà résolue ailleurs.
