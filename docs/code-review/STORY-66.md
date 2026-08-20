# Code Review — STORY-66 (correctif synchronisation : match archivé rechargé puis modifié)

## Portée revue
Diff complet (4 lignes ajoutées dans `app.js`, `sw.js` v110→v111). Comparé à `docs/arch/fix-sync-match-recharge.md`.

## Développeur
Correctif implémenté conformément à la décision d'architecture, sans écart.

## Conformité et cohérence
`await upsertMatchSnapshot();` ajouté exactement à l'endroit prescrit dans `queueEventForSync()` (`app.js:459`), dans le même ordre que la séquence déjà utilisée par le bouton "▶ Lancer le match" (`gid()` → `subscribeMatchEvents()` → `upsertMatchSnapshot()`) — aucune réorganisation inventée. `upsertMatchSnapshot()` est déjà définie plus haut dans le fichier (`app.js:441`) et son propre garde (`if(!client||!S.currentMatchId) return;`) est trivialement satisfait au point d'appel puisque `S.currentMatchId` vient d'être assigné deux lignes au-dessus — aucun risque d'appel no-op accidentel.

**Vérification de non-régression par lecture** (les 2 chemins que la story demande de ne pas casser) :
- Flux normal (`▶ Lancer le match`) : `S.currentMatchId` déjà non-null et `upsertMatchSnapshot()` déjà appelée par le handler du bouton avant qu'aucun événement ne puisse être enregistré (l'écran de saisie n'existe pas avant ce clic, STORY-54) — la branche `if(!S.currentMatchId)` corrigée ne s'exécute donc jamais dans ce flux, confirmé par lecture, pas seulement supposé.
- `resumeMatch()` (`app.js:328-356`) : assigne `S.currentMatchId=matchId` avec un id déjà vérifié existant (`select().single()` avant), toujours non-null avant tout événement — la branche corrigée n'y est pas non plus atteignable.

Seul chemin réellement traversé par le nouveau code : `loadMatchAsCurrent()` suivi d'un nouvel événement sans relance — exactement le bug ciblé.

## Finding
Aucun.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** : aucune.

## Verdict
**APPROUVÉ**
