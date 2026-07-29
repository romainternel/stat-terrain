# STORY-25 — Polish visuel de la carte joueur (écran Équipes)

**En tant que** Romain,
**Je veux** que la liste de joueurs sur l'écran Équipes ait un vrai impact visuel,
**Afin de** ne plus avoir l'impression d'une liste de texte plate, cohérent avec le reste de l'app déjà retravaillé (STORY-04/05/22).

## Contexte technique
- Point resté en suspens depuis STORY-04 : le retour de Romain indiquait que le polish des cartes conteneurs (`.card`) ne suffisait pas, le vrai point faible visuel étant les listes répétitives (`.player-card`), pas encore traitées.
- Zone concernée : `.player-card` et enfants (`style.css`), markup dans `renderTeamSetup()` (`app.js`).
- Réutilise les tokens déjà posés (`--card-bg`, `--card-border`, `--shadow-card`) plutôt que d'en créer de nouveaux, conformément à `docs/visual/polish-pass.md`.

## Critères d'acceptation
- [x] Chaque ligne joueur a un badge numéro de maillot distinct (médaillon arrondi), pas juste un "#7" en texte inline.
- [x] L'état sélectionné est visuellement fort : bordure d'accent latérale (couleur d'équipe) + glow sur le badge numéro + fond légèrement éclairci — pas juste un changement de bordure sur le petit carré de sélection.
- [x] L'état non-sélectionné reste **lisible** (pas de simple `opacity` réduite qui floute le texte) — badge et bordure "éteints", texte légèrement assourdi mais net.
- [x] La couleur d'accent (bleu FENIX / rouge adversaire) s'applique correctement aux deux équipes, y compris le petit carré de sélection (`.sel-toggle`) qui utilisait toujours le bleu FENIX par erreur avant cette story.
- [x] Le badge Gardien (GB) est plus visible (icône 🧤 + meilleur contraste).
- [x] Le bouton supprimer est plus visible et a un vrai retour au tap.
- [x] Aucune régression fonctionnelle : sélection/désélection, suppression, édition nom/poste, ajout de joueur toujours opérationnels.
- [x] Testé sur iPad et iPhone portrait réel — lisible et à l'aise au doigt aux deux tailles.

## Hors scope
- Codage couleur par poste (ALG/ARG/DC/etc.) — non demandé, risquait de surcharger visuellement une liste déjà dense.
- Modification du panneau d'ajout rapide adversaire ou des boutons d'action en bas de carte.

## Dépend de
Aucune (s'appuie sur les tokens de STORY-04, `displayNumber()` de STORY-21).

## Taille
S

## Notes Developer
- Ajout d'une variable CSS `--pc-accent` (triplet RGB, ex. `95,168,211`) posée sur le conteneur de la liste dans `renderTeamSetup()`, propagée à `.player-card`, `.jersey`, `.sel-toggle` — un seul point de vérité pour la couleur d'équipe, pas de duplication.
- Réutilisation directe de `displayNumber(p)` (déjà module-level depuis STORY-21) pour le badge numéro, au lieu de réinventer une fonction locale `dn()` — supprime une duplication qui aurait recréé exactement le problème résolu en STORY-21.
- Testé fonctionnellement via CDP (clics réels) : toggle de sélection et suppression d'un joueur, tous deux vérifiés opérationnels après le changement de markup.
- Vérifié visuellement avant/après sur iPad (1024×768) et iPhone portrait (390×844) avant de considérer la story terminée, conformément à la leçon retenue en STORY-04 (l'impact doit vraiment se voir, pas juste être techniquement présent).
