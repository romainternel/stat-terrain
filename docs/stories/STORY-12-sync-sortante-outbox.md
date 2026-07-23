# STORY-12 — Synchronisation sortante (outbox)

**En tant que** Romain,
**Je veux** que chaque action saisie soit envoyée vers Supabase dès que possible, sans jamais bloquer la saisie si le réseau est mauvais,
**Afin de** avoir mes données centralisées et sauvegardées sans risquer de perdre le fil du match en cas de coupure réseau au gymnase.

## Contexte technique

- Zone concernée : `app.js` — `recordEvent()`, nouvelle fonction `queueEventForSync(event)` et `flushOutbox()`.
- Chaque événement reçoit un `id` généré côté client (uuid v4) dès sa création locale (probablement déjà le cas via `gid()` — à adapter en uuid v4 si le format actuel ne convient pas pour Supabase).
- La file d'attente (`pendingSync`) est elle-même persistée en IndexedDB — pas seulement en mémoire — pour survivre à un reload.
- `flushOutbox()` déclenchée : après chaque nouvel événement, sur l'événement navigateur `online`, et par un intervalle de rattrapage (~15s) tant que la file n'est pas vide.
- Insert idempotent côté Supabase (id déjà existant = ignoré, pas de doublon).

## Critères d'acceptation

- [ ] Une action saisie sans réseau est bien enregistrée localement (comportement inchangé, aucune erreur visible pour Romain).
- [ ] Dès que le réseau revient, les événements en attente sont envoyés vers `match_events` automatiquement, sans action de Romain.
- [ ] Rejouer un envoi déjà réussi (retry après un succès mal détecté) ne crée pas de doublon dans `match_events`.
- [ ] La file d'attente survit à un rechargement complet de la page (testé : couper le réseau, saisir 3 actions, recharger la page, rétablir le réseau → les 3 actions finissent par arriver sur Supabase).
- [ ] Aucune régression de vitesse de saisie perceptible (la synchronisation ne doit jamais ralentir le clic).

## Hors scope

- La réception des événements des autres appareils (traitée dans STORY-13).
- Toute interface de gestion manuelle de la file d'attente.

## Dépend de

STORY-10, STORY-01 (cycle 1 — autosave local, base nécessaire avant d'ajouter la couche réseau par-dessus).

## Taille

M
