# STORY-01 — Autosave du match en cours

**En tant que** Romain,
**Je veux** que le match en cours de saisie soit sauvegardé automatiquement au fil de l'eau,
**Afin de** ne jamais perdre les stats déjà saisies si l'app se recharge accidentellement (Safari qui décharge l'onglet, batterie faible, fermeture accidentelle) pendant un match.

## Contexte technique

- Zone concernée : `app.js` — `S` (state global), `recordEvent()`, `R()`, `freshState()`, `dbSaveMatch()`.
- Aujourd'hui, `S.events` et l'état du match en cours ne sont écrits en base (IndexedDB) qu'au moment de `saveMatch()`, en fin de match. Rien ne persiste pendant la saisie.
- Nouvelle mécanique : écrire l'état du match en cours (a minima `S.events`, `S.home`, `S.away`, `S.time`, `S.period`) dans IndexedDB (ou `localStorage` si le volume est raisonnable) après chaque `recordEvent()` / action validée — pas besoin de le faire à chaque frame, seulement à chaque événement enregistré.
- Au chargement de l'app (`freshState()` / init), détecter s'il existe un match "en cours" non finalisé et proposer à Romain de le reprendre (ou de l'ignorer/effacer s'il préfère repartir de zéro).

## Critères d'acceptation

- [ ] Après chaque action validée en match, l'état courant est écrit en stockage persistant (IndexedDB ou localStorage).
- [ ] Si l'app est rechargée en cours de match (simuler : reload navigateur pendant une saisie), rouvrir l'app propose de reprendre le match en cours avec tous les événements déjà saisis.
- [ ] Si Romain choisit d'ignorer/effacer le match en cours proposé, l'app repart sur un nouveau match vierge sans erreur.
- [ ] Aucune régression sur `saveMatch()` (fin de match) et l'historique des matchs déjà sauvegardés (`dbGetAll`, `dbDelete`).
- [ ] Pas de ralentissement perceptible de la saisie (l'écriture de l'autosave ne doit pas bloquer le rendu `R()`).

## Hors scope

- Synchronisation entre plusieurs appareils (un match reste lié à l'appareil sur lequel il a été commencé).
- Historique de versions du match en cours (on garde uniquement le dernier état, pas un journal des reprises).

## Dépend de

Aucune.

## Taille

M
