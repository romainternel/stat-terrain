# Code Review — STORY-27 : Suppression réelle d'un match sur Supabase

## Périmètre revu
`app.js`, diff non commité (`git diff -- app.js`, +15/-0 lignes) :
- `saveMatch()` (l.1339-1359) : ajout du champ `supabaseMatchId:S.currentMatchId||null` dans l'objet `match` persisté localement (l.1350).
- Nouvelle fonction `deleteSupabaseMatch(matchId)` (l.1368-1378), juste après `markMatchFinished()`.
- Handler `[data-del-match]` dans `bind()` (l.3890-3899) : ajout de `const m=S.matchHistory.find(...)` (l.3894) et de l'appel `deleteSupabaseMatch(m.supabaseMatchId)` (l.3896).

Aucun autre fichier touché. `new Function()` sur `app.js` complet : aucune erreur de syntaxe.

## Vérifications demandées

### 1. Ordre `match_events` avant `matches`, vis-à-vis du schéma réel
**Confirmé, ordre correct.** `docs/supabase-setup.sql` l.19 : `match_id uuid references matches(id)`, sans `on delete cascade`. Dans ce cas, une tentative de suppression de la ligne parente (`matches`) alors que des lignes `match_events` la référencent encore est rejetée par Postgres (violation de contrainte de clé étrangère) — la ligne `matches` resterait alors indéfiniment, et pire, si l'erreur avait été avalée silencieusement par le `catch` sans que `match_events` ait été supprimé avant, on se retrouverait effectivement avec des `match_events` orphelins pointant vers un match introuvable côté app locale.

`deleteSupabaseMatch()` (l.1374-1377) fait bien :
```js
await client.from('match_events').delete().eq('match_id',matchId);
await client.from('matches').delete().eq('id',matchId);
```
enfants d'abord, parent ensuite — dans le bon ordre vis-à-vis de la contrainte. Si l'un des deux appels échoue (hors-ligne, RLS, etc.), le `try/catch` englobant les deux avale l'erreur sans retry (documenté dans le commentaire l.1377), ce qui est cohérent avec le principe best-effort de la story. Un échec au premier `delete` (match_events) empêchera simplement d'atteindre le second, laissant la ligne `matches` intacte avec ses événements — pas de scénario d'orphelins créé par ce code.

### 2. Fail-open : suppression locale avant tentative Supabase
**Confirmé.** Dans le handler (l.3893-3897) :
```js
if(!safeConfirm("Supprimer ce match ?")) return;
const m=S.matchHistory.find(x=>x.id===id);
try{ await dbDelete(id); S.matchHistory=await dbGetAll(); }catch(e){ console.error(e); }
if(m?.supabaseMatchId) deleteSupabaseMatch(m.supabaseMatchId);
R();
```
`dbDelete(id)` (local, IndexedDB) s'exécute et se termine avant que `deleteSupabaseMatch()` ne soit même invoquée. De plus l'appel n'est pas `await`é — c'est un fire-and-forget, la fonction retourne une Promise que le handler n'attend pas, donc même une latence réseau longue côté Supabase ne retarde ni `R()` ni la suite de l'usage de l'app. Cohérent avec le principe non négociable documenté dans `CLAUDE.md` ("la saisie locale ne doit jamais dépendre de la disponibilité de Supabase").

### 3. `m` retrouvé avant ou après le rafraîchissement de `S.matchHistory` ?
**Confirmé, ordre correct — pas de bug.** `const m=S.matchHistory.find(x=>x.id===id)` est à la ligne 3894, **avant** le `try{ await dbDelete(id); S.matchHistory=await dbGetAll(); }` de la ligne 3895. `m` est donc capturé sur l'ancienne référence de `S.matchHistory` (celle qui contient encore le match sur le point d'être supprimé), avant que `dbGetAll()` ne réassigne `S.matchHistory` à la liste post-suppression. Si l'ordre avait été inversé, `m` serait resté `undefined` puisque le match n'existerait plus dans la liste rafraîchie, et `deleteSupabaseMatch` ne serait jamais appelée — ce n'est pas le cas ici.

### 4. Comportement si `S.currentMatchId` n'a jamais été défini (usage 100% local / Supabase non configuré)
**Confirmé, aucun risque de plantage, à toutes les étapes :**
- `saveMatch()` : `supabaseMatchId:S.currentMatchId||null` — si `S.currentMatchId` est `undefined` (jamais initialisé), l'opérateur `||` retombe proprement sur `null`. Aucune exception possible ici, c'est une simple valeur littérale.
- Pour les matchs sauvegardés **avant** cette story (déjà présents dans IndexedDB), le champ `supabaseMatchId` n'existe simplement pas sur l'objet — `m?.supabaseMatchId` vaut `undefined`, falsy, la condition `if(m?.supabaseMatchId)` échoue proprement et `deleteSupabaseMatch` n'est jamais appelée. Comportement voulu et documenté dans la story ("Limite acceptée").
- Cas plus subtil vérifié : même sur un match **nouvellement** sauvegardé sans Supabase configuré (`config.js` absent), `S.currentMatchId` peut tout de même finir non-`null` — `queueEventForSync()` (l.261-265) assigne `S.currentMatchId=gid()` dès le premier événement saisi, **indépendamment** de la disponibilité réelle de Supabase (l'outbox IndexedDB fonctionne même sans client). Le match sauvegardé aura donc un `supabaseMatchId` non-null qui n'a jamais correspondu à une vraie ligne Supabase. Mais à la suppression, `deleteSupabaseMatch(matchId)` (l.1372-1373) commence par `const client=initSupabaseClient(); if(!client||!matchId) return;` — si `config.js` est absent, `initSupabaseClient()` retourne `null` (`typeof SUPABASE_URL==="undefined"`, l.132) et la fonction sort immédiatement, sans appel réseau ni exception. Si `config.js` est présent mais que l'id n'a jamais existé côté serveur, les deux `delete().eq(...)` de Supabase suppriment simplement 0 ligne, sans lever d'erreur. Aucun chemin ne plante.

### 5. Style et conventions
**Conforme.**
- `const client=initSupabaseClient();` reprend exactement le même nommage local que `markMatchFinished()` et `dequeueEventSync()` déjà existants dans le fichier (convention `sbClient` réservée à la variable module-level cache dans `initSupabaseClient()` elle-même — RAS, cf. CLAUDE.md).
- Commentaires en français, ton et style identiques au reste du fichier (ex. commentaire au-dessus de `dequeueEventSync`, très proche dans l'esprit).
- Pattern `try{...}catch(e){ /* best-effort ... */ }` identique à `markMatchFinished()`, `dequeueEventSync()`, `flushOutbox()`.
- Pas de dépassement de scope : le diff touche exactement les 3 points annoncés dans la story (objet `match`, nouvelle fonction, handler), rien d'autre n'a bougé.

## Recommandé (non-bloquant)

1. **`sw.js` pas encore incrémenté.** `CACHE_NAME` est toujours à `fenix-stats-v71`, alors que `app.js` est modifié. La procédure de déploiement documentée dans `CLAUDE.md` ("Incrémenter la version dans `sw.js`" — étape 2, avant le commit/push) n'a pas encore été appliquée sur ce diff. Sans ce bump, un iPad ayant déjà mis l'app en cache ne recevra pas cette correction avant fermeture forcée de Safari + un cycle de cache supplémentaire fortuit. À faire au moment du commit, avant push — ne bloque pas la revue de la logique elle-même.

2. **Incohérence mineure si `dbDelete(id)` échoue.** Dans le handler (l.3895-3896), si `dbDelete(id)` lève une exception (échec IndexedDB local, rare), le `catch(e){ console.error(e); }` avale l'erreur mais **ne empêche pas** la ligne suivante de s'exécuter : `deleteSupabaseMatch(m.supabaseMatchId)` sera quand même appelée alors que la suppression locale a échoué. Résultat possible : le match reste visible dans l'historique local, mais sa copie Supabase est bel et bien supprimée — perte de la seule sauvegarde distante d'un match que l'utilisateur n'a en fait pas réussi à supprimer localement. Cas rare (échec IndexedDB local), et le comportement pré-existant (avant cette story) ne faisait de toute façon rien de plus robuste sur cet échec — mais la story ajoute une conséquence concrète (perte de la copie serveur) à un chemin d'erreur qui n'en avait aucune auparavant. Piste simple si retouché un jour : ne tenter `deleteSupabaseMatch` que dans le bloc `try` réussi, pas après un `catch`.

## Sécurité basique
RAS. Pas de clé/secret en dur, les deux `delete()` sont filtrés (`.eq('match_id',matchId)` / `.eq('id',matchId)`), protégés par la policy RLS `authenticated` déjà en place (`docs/supabase-setup.sql`) — aucune suppression non filtrée, aucun risque de suppression de masse. Rien à signaler au Security Auditor.

## Verdict
**APPROUVÉ**

Le point le plus sensible de la story — l'ordre des deux suppressions vis-à-vis de la contrainte de clé étrangère sans `ON DELETE CASCADE` — est correctement implémenté (`match_events` avant `matches`). Le principe fail-open est respecté à la lettre (suppression locale d'abord, tentative Supabase ensuite, jamais attendue). L'ordre de capture de `m` dans `S.matchHistory` est correct (avant le rafraîchissement post-suppression). Tous les cas de `supabaseMatchId` null/undefined (ancien match, config.js absent, id jamais enregistré côté serveur) sont couverts sans risque de plantage. Les deux points listés en Recommandé (bump `sw.js` avant push, et le petit gap de robustesse si `dbDelete` échoue) sont mineurs et non-bloquants — à traiter au fil de l'eau, pas de blocage avant QA.
