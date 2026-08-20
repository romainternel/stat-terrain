# QA — STORY-66 (correctif synchronisation : match archivé rechargé puis modifié)

## Ce que j'ai lu avant de tester
`docs/code-review/STORY-66.md` (APPROUVÉ), `docs/stories/STORY-66-fix-sync-match-recharge.md`, `docs/arch/fix-sync-match-recharge.md`.

## Méthode
CDP contre le vrai backend Supabase de production, avec inspection directe des requêtes réseau (`browser_network_requests`) en plus des vérifications d'état — pas seulement "ça n'affiche pas d'erreur", mais confirmation que la ligne `matches` existe réellement côté serveur et que les requêtes se produisent dans le bon ordre.

## Critères d'acceptation vérifiés

- [x] **Reproduction exacte du bug original, puis correctif confirmé** : match sauvegardé → rechargé via "📂 Charger" (`S.currentMatchId` repasse bien à `null`, confirmé) → nouvel événement ajouté → `S.currentMatchId` régénéré → requête réseau `POST /matches` → `201 Created` **avant** `POST /match_events` → `201 Created` (zéro 409). Ligne `matches` confirmée existante par une requête `select` directe sur le nouvel id, avec le bon `away_name` et `status:'in_progress'`.
- [x] **Sur plusieurs événements consécutifs, pas seulement le premier** : un 2e événement ajouté juste après → toujours `201`, zéro erreur console. Le nouvel appel `upsertMatchSnapshot()` ne se déclenche qu'une fois (à la régénération de l'id), les événements suivants passent directement par `match_events` comme prévu.
- [x] **Flux normal non affecté** : match lancé via "▶ Lancer le match", un événement enregistré — inspection du journal réseau : exactement 2 `POST /matches` pendant la séquence de lancement (déjà le comportement existant : un appel du handler du bouton, un de `startTimer()` qu'il déclenche) et **aucun 3e appel** après l'événement — confirme que la nouvelle branche de `queueEventForSync()` ne s'exécute jamais dans ce flux, comme prévu par l'Architecture.
- [x] `resumeMatch()` — non re-testé en direct (nécessiterait un scénario à deux appareils simultanés), conformément à ce que la story elle-même autorise sur la base de la lecture de code déjà faite par le Code Reviewer (`S.currentMatchId` toujours déjà défini avant tout événement dans ce chemin).
- [x] `new Function()` passe sur `app.js` modifié (déjà vérifié par le Developer, revérifié ici).

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune.

## Nettoyage
Match de test ("STORY66 TEST") et sa ligne `matches` régénérée (avec ses `match_events`) supprimés manuellement de Supabase après test — vérifiés absents par requête directe. Aucune donnée réelle de Romain concernée (2 matchs "Rodez" jamais touchés).

## Verdict
**PASSED**
