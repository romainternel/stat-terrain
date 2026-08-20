# PRD — Correctif synchronisation : match archivé rechargé puis modifié

## Objectif
Garantir que tout événement saisi après rechargement d'un match archivé se synchronise fiablement vers Supabase, sans erreur en boucle.

## Features

### F1 — Créer la ligne `matches` avant de synchroniser un événement sur un `currentMatchId` fraîchement régénéré (Must Have)
`queueEventForSync()` doit appeler `upsertMatchSnapshot()` immédiatement après avoir généré un nouveau `S.currentMatchId` (branche `if(!S.currentMatchId)`), avant de continuer vers l'écriture de l'événement lui-même. Symétrique au bouton "▶ Lancer le match", qui fait déjà exactement cet enchaînement.

## Priorités
Must Have unique — c'est un correctif de bug, pas une nouvelle fonctionnalité à prioriser parmi d'autres.

## Critères d'acceptation
- [ ] Recharger un match archivé (`📂 Charger`), ajouter un nouvel événement → une ligne `matches` existe côté Supabase pour ce `currentMatchId`, avant ou en même temps que la synchronisation de l'événement.
- [ ] Plus d'erreur 409 répétée sur `match_events` dans ce scénario.
- [ ] Le flux normal (`▶ Lancer le match` → saisie) reste strictement inchangé — pas de double appel à `upsertMatchSnapshot()`, pas de régression de latence perceptible à la première action.
- [ ] `resumeMatch()` (reprise d'un match `in_progress` depuis un autre appareil) non affecté — `S.currentMatchId` y est déjà toujours non-null, ce chemin ne passe jamais par la branche corrigée.

## Hors scope
- Nettoyage de données Supabase existantes.
- Tout changement de schéma ou de contrat entre `matches` et `match_events`.

## Dépendances
Aucune — s'appuie uniquement sur `upsertMatchSnapshot()` déjà existante et déjà utilisée ailleurs exactement de la même façon.

## Risques
Voir `docs/risks/fix-sync-match-recharge.md`.
