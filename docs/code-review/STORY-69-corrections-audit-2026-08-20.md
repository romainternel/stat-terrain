# Code Review — STORY-69 (corrections des 3 bugs Majeurs de l'audit du 2026-08-20)

## Contexte
Story née directement de `docs/regression/audit-complet-2026-08-20.md` (pas de PRD/Architecture dédiés — 3 correctifs ciblés, pas de nouvelle feature). Diff review : `app.js` (4 zones) + `sw.js` (bump cache v112→v113).

## Fix 1 — `loadMatchAsCurrent()` n'écrase plus l'effectif courant
Suppression de l'appel `saveTeams()` en fin de fonction (ligne ~1767), remplacé par un commentaire expliquant pourquoi. Une seule ligne touchée, scope minimal, aucun effet de bord détecté ailleurs (fonction 100% locale, aucun appel réseau).

**Verdict : APPROUVÉ.** Fix précis et suffisant pour le symptôme rapporté (persistance en `localStorage`). Note pour le QA : `S.home`/`S.away` en mémoire restent l'instantané du match archivé tant que la page n'est pas rechargée ou qu'un nouveau login n'a pas lieu — comportement volontairement laissé tel quel par le Developer (hors scope du bug rapporté, qui concernait la perte **persistante**, pas l'état temporaire en session). À vérifier côté QA que ça ne surprend pas en pratique (ex. retour sur l'onglet Équipes juste après un "Charger").

## Fix 2 — Bouton "🎯 PD" gated sur `isGoal`
Deux sites de rendu (`pdBtnHtml` ligne ~2256, `pdHtml` ligne ~2492) reçoivent la même garde `ACTIONS[S.events[0].type]?.isGoal`, cohérente avec le style déjà utilisé ailleurs dans le fichier (`ACTIONS[e.type]?.isGoal`, ex. ligne 5487). PEN_GOAL reste éligible (a `isGoal:true`) — comportement préexistant inchangé, pas une régression introduite par ce fix.

**Verdict : APPROUVÉ.** Les deux sites identifiés dans le rapport d'audit sont couverts, la condition est cohérente entre les deux, pas de duplication de logique problématique (juste une condition dupliquée deux fois, ce qui est déjà le pattern existant dans ce fichier pour d'autres gardes similaires — pas une dette nouvelle).

## Fix 3 — Ordonnancement `stopTimer()`/`markMatchFinished()` dans `newMatch()`

### ❌ BLOQUANT — viole le principe non négociable "fail-open" documenté dans `CLAUDE.md`

`CLAUDE.md` est explicite : *« **Principe non négociable** : la saisie locale ne doit jamais dépendre de la disponibilité de Supabase — fail-open partout (auth, sync, mode lecteur). »*

Le fix actuel rend `newMatch()` `async` et fait `await stopTimer(); ... await markMatchFinished();` **avant** tous les resets locaux (`S.events=[]`, etc.) et avant le `R()` final. Concrètement : cliquer "🆕 Nouveau match" **bloque désormais la remise à zéro locale de l'écran tant que deux allers-retours réseau vers Supabase ne sont pas résolus**. Sur le wifi de gymnase (le terrain d'usage réel documenté dans `CLAUDE.md` — iPad en bord de terrain), avec une connexion lente ou qui ne répond ni en succès ni en échec propre (pas de timeout par défaut sur `fetch`), ce clic peut rester "en attente" un temps arbitrairement long avant que l'interface ne réagisse. C'est exactement la classe de régression que ce principe est censé empêcher — et "Nouveau match" est un geste de fin de match fréquent, pas un cas rare.

**Ce qui doit être repris** : découpler le reset local (qui doit rester instantané, fire-and-forget vis-à-vis du réseau) de l'ordonnancement des deux écritures Supabase (qui, elles, doivent rester séquencées entre elles pour corriger la vraie course). Piste concrète, sans réintroduire le bug d'origine :

```js
function newMatch(){ // reste synchrone, pas de async/await ici
  if(S.readOnly) return;
  if(!safeConfirm("Nouveau match ? Les stats en cours seront perdues si non sauvegardées.")) return;
  const snapshotDone = stopTimer(); // stoppe le chrono localement tout de suite (sync), renvoie la promesse de l'upsert réseau
  // Chaîné plutôt qu'attendu ici : garantit que markMatchFinished() (status:'finished') arrive
  // toujours APRÈS l'upsert de stopTimer() (status:'in_progress') côté serveur, sans jamais
  // bloquer le reset local qui suit — fail-open respecté (CLAUDE.md).
  Promise.resolve(snapshotDone).then(()=>markMatchFinished());
  // ... reste de la fonction inchangé, resets synchrones puis R() ...
}
```
Et revenir `stopTimer()` à sa forme actuelle du fix (qui reste correcte et utile : elle expose désormais la promesse de l'upsert, nécessaire pour le `.then()` ci-dessus) — pas de changement supplémentaire nécessaire sur `stopTimer()`.

**Pourquoi ce n'est pas juste une "Recommandation"** : ce n'est pas une préférence de style, c'est une violation directe et concrète d'un principe explicitement marqué "non négociable" dans le contexte projet, sur un geste utilisateur fréquent, dans l'environnement d'usage réel documenté du produit.

## Reprise du Fix 3 — validée

`newMatch()` redevient synchrone. `finishingId`/`finishingMeta` (season/journee/coachNotes/championnat) sont capturés **avant** tout reset local, puis `stopTimer()` s'exécute (arrêt du chrono immédiat, en local) et sa promesse est chaînée — pas attendue — vers `markMatchFinishedById(finishingId, finishingMeta)`. `markMatchFinishedById()` gagne un paramètre `meta` optionnel (défaut : lecture live de `S.*`, comportement inchangé pour tous les autres appelants — `switchTeamProfile()`, `saveMatch()`, `discardResumableMatch()` — aucun n'est affecté par ce changement de signature).

Vérifié point par point :
- Le reset local (`S.events=[]`, `S.currentMatchId=null`, `R()`, etc.) s'exécute intégralement en synchrone, sans jamais attendre le réseau — **fail-open respecté**.
- L'upsert (`status:'in_progress'`) de `stopTimer()` est garanti de se terminer **avant** que `markMatchFinishedById` ne parte (chaînage `.then()`), donc le statut `'finished'` est toujours la dernière écriture — **course corrigée**.
- `finishingMeta` capturé en synchrone avant les resets → season/journee/championnat/coachNotes écrits sur l'ANCIEN match restent corrects même si l'écriture réseau n'a lieu qu'après que `S.journee`/`S.championnat` aient déjà pris les valeurs du PROCHAIN match — **pas de régression sur le comportement que le commentaire d'origine protégeait déjà (STORY-48/49/50)**.
- `upsertMatchSnapshot()` avale ses propres erreurs en interne (`try/catch`) → sa promesse ne rejette jamais → le `.then()` chaîné se déclenche toujours, pas de rejet non géré.
- `matchId` null (aucun match démarré) → `markMatchFinishedById` no-op immédiat via sa garde existante, rien de cassé sur un "Nouveau match" cliqué à froid.

`node -e "new Function(fs.readFileSync('app.js'))"` : syntaxe valide.

## Verdict global

**APPROUVÉ.** Les 3 fixes sont désormais conformes : scope minimal respecté, aucune régression identifiée sur les autres appelants des fonctions modifiées, principe fail-open non négociable respecté par le Fix 3 repris. Prêt pour le QA.
