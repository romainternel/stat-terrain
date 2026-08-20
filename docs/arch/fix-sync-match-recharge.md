# Architecture — Correctif synchronisation : match archivé rechargé puis modifié

## Décision technique
Ajouter un appel à `upsertMatchSnapshot()` dans `queueEventForSync()` (`app.js:459`), juste après la génération d'un nouveau `S.currentMatchId` :

```javascript
async function queueEventForSync(event){
  if(!S.currentMatchId){
    S.currentMatchId=gid();
    subscribeMatchEvents(S.currentMatchId);
    await upsertMatchSnapshot(); // cree la ligne 'matches' correspondante avant tout evenement,
    // symetrique au bouton "Lancer le match" (bind(), #launch-match-btn) qui fait deja exactement
    // cet enchainement — sans ca, un evenement peut se synchroniser sur match_events sans ligne
    // matches parente (cas : loadMatchAsCurrent() remet currentMatchId a null, puis un nouvel
    // evenement regenere un id ici sans jamais creer la ligne matches, STORY-fix-sync)
  }
  try{
    await outboxPut(eventToSupabaseRow(event,S.currentMatchId));
  }catch(e){ /* la file d'attente est best-effort : ne jamais faire perdre l'événement local */ }
  flushOutbox();
}
```

`await` ajouté sur l'appel : nécessaire pour garantir que la ligne `matches` existe bien avant que `outboxPut()`/`flushOutbox()` ne tentent d'écrire l'événement (élimine la fenêtre de course qui causait le 409). `queueEventForSync()` est déjà `async`, l'appelante (`recordEvent()` et les autres sites d'appel) ne l'attendent déjà pas (fire-and-forget, cohérent avec le principe "la saisie locale ne doit jamais dépendre de la synchronisation") — ajouter un `await` interne à la fonction ne change donc rien à ce comportement pour l'appelant.

## Pourquoi (alternatives rejetées)
- **Corriger dans `loadMatchAsCurrent()`** (appeler `upsertMatchSnapshot()` dès le chargement, avant même qu'un nouvel événement existe) : rejeté — `upsertMatchSnapshot()` s'appuie sur `S.currentMatchId`, qui est justement `null` à ce moment précis (c'est voulu, cf. le P0 de STORY-36 : ne jamais rétablir de lien Supabase tant qu'aucune nouvelle saisie n'a eu lieu, pour ne pas relancer par erreur un vrai match "in_progress" juste en consultant un match archivé). Corriger dans `queueEventForSync()` respecte cette intention : la ligne `matches` n'est créée qu'au moment où un événement est **réellement** ajouté, jamais au simple chargement pour consultation/PDF.
- **Dupliquer la logique du bouton de lancement dans `queueEventForSync()`** (recréer `if(!S.currentMatchId) S.currentMatchId=gid(); subscribeMatchEvents(...); upsertMatchSnapshot();` comme un bloc autonome) : rejeté — `queueEventForSync()` a déjà cette logique presque à l'identique (il ne lui manque que l'appel à `upsertMatchSnapshot()`), pas besoin de dupliquer, juste de compléter l'existant.

## Impact sur l'existant
- **Flux normal (`▶ Lancer le match`)** : `S.currentMatchId` est déjà non-null avant tout événement (le bouton l'a déjà défini et a déjà appelé `upsertMatchSnapshot()`), donc la branche `if(!S.currentMatchId)` ne s'exécute jamais dans ce flux — **zéro changement de comportement**, `upsertMatchSnapshot()` n'est jamais appelée deux fois.
- **`resumeMatch()` (STORY-14)** : `S.currentMatchId` y est toujours déjà défini (sur l'id d'un match Supabase existant, vérifié par un `select().single()` avant assignation) — cette branche ne s'exécute jamais non plus dans ce flux.
- **Seul chemin réellement affecté** : `loadMatchAsCurrent()` (📂 Charger, et le raccourci PDF de Bilan STORY-36) suivi d'un nouvel événement sans relance — c'est exactement le chemin cassé que ce correctif répare.
- `upsertMatchSnapshot()` elle-même n'est pas modifiée — elle gère déjà correctement le cas où `S.currentMatchId` est défini (son seul garde est `if(!client||!S.currentMatchId) return;`, désormais toujours faux à ce point d'appel).

## Nouvelles structures de données
Aucune.

## Risques
Voir `docs/risks/fix-sync-match-recharge.md`.

## Critère de bascule
Aucun — ce correctif ferme définitivement le seul chemin identifié où `S.currentMatchId` pouvait être régénéré sans création de la ligne `matches` correspondante. Si un futur nouveau point d'entrée dans l'app venait à recorder un événement avec `S.currentMatchId` déjà `null` par un chemin encore différent, il bénéficierait automatiquement du même correctif puisque tous les événements passent par `queueEventForSync()` (chokepoint unique, déjà vérifié exhaustivement lors de STORY-63).
