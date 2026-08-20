# Design — Correctif synchronisation : match archivé rechargé puis modifié

## Aucune surface visuelle
Ce correctif touche exclusivement la couche de synchronisation (`queueEventForSync()`/`upsertMatchSnapshot()`) — rien à l'écran ne change, aucun nouvel état de chargement, message ou composant. Le coach ne voit jamais la différence : c'est précisément le but (la saisie sur un match rechargé doit se comporter, invisiblement, comme la saisie sur un match tout juste lancé).

Pas de maquette à produire pour cette story.
