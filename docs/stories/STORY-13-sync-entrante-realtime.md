# STORY-13 — Synchronisation entrante (temps réel)

**En tant que** Romain,
**Je veux** voir apparaître les actions saisies depuis un autre appareil sur le même match,
**Afin de** pouvoir passer la main (ou la partager ponctuellement) sans perdre le fil de ce qui a déjà été saisi ailleurs.

## Contexte technique

- Zone concernée : `app.js` — nouvelle fonction `subscribeMatchEvents(matchId)` (abonnement Supabase Realtime sur `match_events`, filtré par `match_id`), `mergeRemoteEvent(event)`.
- Un événement reçu est fusionné dans `S.events` (par `id` — ignoré s'il existe déjà, évite les doublons avec les événements déjà présents localement), puis `R()` est appelé pour rafraîchir l'affichage.
- **Test explicite obligatoire** (finding du Risk Analyst, `docs/risks/supabase-multiuser.md` #2) : ouvrir le même match sur deux appareils/onglets réels et vérifier la réception en quelques secondes — pas seulement en local/localhost.

## Critères d'acceptation

- [ ] Une action saisie sur l'appareil A apparaît dans le feed et les stats de l'appareil B en quelques secondes, quand les deux ont du réseau.
- [ ] Aucun doublon visuel/statistique quand un événement arrive à la fois localement (déjà présent) et via l'abonnement temps réel.
- [ ] La déconnexion/reconnexion réseau d'un appareil ne casse pas l'abonnement — il se rétablit automatiquement.
- [ ] Testé sur un vrai déploiement (pas uniquement localhost) pour confirmer que la RLS n'empêche pas silencieusement la réception (risque identifié par le Security Auditor).

## Hors scope

- Résolution de conflit avancée en cas de double saisie réelle de la même action (accepté comme risque mineur, corrigible via le feed éditable existant).

## Dépend de

STORY-10, STORY-12.

## Taille

M
