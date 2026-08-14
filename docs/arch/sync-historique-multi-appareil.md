# Architecture — Synchronisation de l'historique des matchs entre appareils

## Fichiers touchés
`app.js` (nouvelles fonctions + un point d'appel + extension de `markMatchFinishedById()`), `docs/supabase-migration-season-journee-notes.sql` (nouveau, migration manuelle par Romain — prérequis strict, cf. PRD).

## Migration Supabase (prérequis)
`alter table matches add column if not exists season text; ... journee text; ... coach_notes text;` — colonnes nullable, aucun impact sur les lignes existantes ni sur `upsertMatchSnapshot()` (qui continue de ne pas les écrire, cf. ci-dessous). Fichier complet : `docs/supabase-migration-season-journee-notes.sql`.

## Écriture : où `season`/`journee`/`coach_notes` sont poussés vers Supabase
**Pas** dans `upsertMatchSnapshot()` (appelée en continu pendant le match, ~ligne 265) — inutile de la complexifier puisque ces 3 champs ne sont utiles qu'au moment où le match devient consultable en historique sur un autre appareil, c'est-à-dire à la sauvegarde. Extension ciblée de `markMatchFinishedById()` (~ligne 1424), déjà appelée par `saveMatch()` au moment exact de la sauvegarde :
```js
async function markMatchFinishedById(matchId){
  const client=initSupabaseClient();
  if(!client||!matchId) return;
  try{ await client.from('matches').update({status:'finished'}).eq('id',matchId); }catch(e){}
  // Appel séparé, volontairement : si la migration season/journee/coach_notes n'a pas encore
  // été exécutée par Romain, PostgREST rejette tout l'appel pour une colonne inconnue — en le
  // séparant du statut 'finished' ci-dessus, un oubli de migration dégrade seulement l'enrichissement
  // (pas de saison/journée sur un match rapatrié) sans jamais casser le comportement déjà en
  // production (le match arrêtant de s'afficher comme "reprenable" sur les autres appareils).
  try{ await client.from('matches').update({season:S.season, journee:S.journee, coach_notes:S.coachNotes||"", championnat:S.championnat||""}).eq('id',matchId); }catch(e){}
}
```
`championnat` ajouté à ce même appel par STORY-49 (champ développé juste après STORY-48, même colonne déjà incluse dans la migration SQL commune) — un seul appel "confort" à maintenir, pas un 3e `update()` séparé.
`scoreH`/`scoreA` restent non stockés (comme aujourd'hui) — reconstruits à la lecture depuis les événements (cf. import ci-dessous), cohérent avec M3 du PRD.

## Lecture : nouvelles fonctions de rapatriement
Ajoutées à côté de `fetchInProgressMatches()`/`resumeMatch()` (~ligne 184-229), même style, même tolérance aux pannes (`if(!client) return`, `try/catch` silencieux — fail-open, jamais bloquant) :

```js
async function fetchMissingArchivedMatches(localMatches){
  const client=initSupabaseClient();
  if(!client) return [];
  const known=new Set(localMatches.map(m=>m.supabaseMatchId).filter(Boolean));
  try{
    const {data,error}=await client.from('matches').select('*').eq('status','finished').order('updated_at',{ascending:false});
    if(error||!data) return [];
    return data.filter(row=>!known.has(row.id));
  }catch(e){ return []; }
}

async function importArchivedMatch(row, idOffset){
  const client=initSupabaseClient();
  if(!client) return null;
  try{
    const {data:events}=await client.from('match_events').select('*').eq('match_id',row.id);
    const evts=(events||[]).map(supabaseRowToEvent).sort((a,b)=>(b.period-a.period)||(b.rawTime-a.rawTime));
    const scoreH=evts.filter(e=>e.team==="home"&&ACTIONS[e.type]?.isGoal).length;
    const scoreA=evts.filter(e=>e.team==="away"&&ACTIONS[e.type]?.isGoal).length;
    return {
      id:Date.now()+idOffset, // évite toute collision si plusieurs imports dans la même boucle synchrone
      date:row.updated_at?new Date(row.updated_at).toLocaleDateString("fr-FR",{day:"numeric",month:"short",year:"numeric",hour:"2-digit",minute:"2-digit"}):"",
      season:row.season||"", journee:row.journee||"", championnat:row.championnat||"", // championnat ajouté par STORY-49, même colonne migrée ensemble
      home:{name:row.home_name||"FENIX Toulouse", players:row.home_roster||[], gkId:row.home_gk_id||null},
      away:{name:row.away_name||"Adversaire", players:row.away_roster||[], gkId:row.away_gk_id||null},
      events:evts, time:row.time_offset_seconds||0, period:row.period||2,
      scoreH, scoreA, coachNotes:row.coach_notes||"",
      supabaseMatchId:row.id,
    };
  }catch(e){ return null; }
}

async function syncArchivedMatchesIntoLocal(){
  const local=await dbGetAll().catch(()=>[]);
  const missing=await fetchMissingArchivedMatches(local);
  if(missing.length===0) return 0;
  let imported=0;
  for(let i=0;i<missing.length;i++){
    const m=await importArchivedMatch(missing[i], i);
    if(m){ await dbSaveMatch(m).catch(()=>{}); imported++; }
  }
  return imported;
}
```
Boucle séquentielle (`for` + `await`), pas `Promise.all` — volontaire, évite une rafale de requêtes simultanées vers Supabase si beaucoup de matchs sont à rapatrier (première ouverture de l'écran sur un nouvel appareil, potentiellement toute une saison) ; ordre de grandeur attendu (quelques dizaines de matchs par saison pour un CF) ne pose pas de problème de performance perceptible en séquentiel.

## Point d'appel : ouverture de l'écran Matchs
`app.js` a déjà un point d'entrée `if(S.view==="history"||S.view==="bilan"){ try{S.matchHistory=await dbGetAll();}catch(e){S.matchHistory=[];} }` (~ligne 4246, dans la fonction qui gère les transitions de vue asynchrones). Extension au même endroit :
```js
if(S.view==="history"||S.view==="bilan"){
  try{ S.matchHistory=await dbGetAll(); }catch(e){ S.matchHistory=[]; }
  if(S.view==="history" && !S._historySyncedThisLoad){
    S._historySyncedThisLoad=true; // une seule tentative par chargement de page, pas à chaque re-render
    S.historySyncing=true; R();
    const n=await syncArchivedMatchesIntoLocal();
    S.historySyncing=false;
    if(n>0){ S.matchHistory=await dbGetAll().catch(()=>S.matchHistory); showToast(`+${n} match(s) récupéré(s) depuis un autre appareil`); }
    R();
  }
}
```
`S._historySyncedThisLoad` (nouveau flag, jamais réinitialisé) évite de relancer le rapatriement à **chaque** re-render déclenché par `R()` pendant qu'on reste sur l'écran Matchs (l'app re-render fréquemment) — une seule tentative par chargement de page, cohérent avec "automatique à l'ouverture" du PRD (pas "en continu"). `S.historySyncing` piloté par le Design pour l'indicateur `🔄 Recherche de matchs...`.

## Aucun changement sur
`resumeMatch()`/`fetchInProgressMatches()` (in_progress, logique séparée, non touchée), `saveMatch()` (appelle déjà `markMatchFinished()`, seule cette dernière est étendue), suppression de match (STORY-27, `supabaseMatchId` déjà utilisé de la même façon), export/import CSV.

## Sécurité
Aucune nouvelle table, aucun nouveau rôle, réutilise la policy `authenticated full access` déjà auditée en STORY-10 sur `matches`/`match_events` (même modèle compte unique partagé). Pas de nouvelle surface d'exposition de données — un utilisateur authentifié pouvait déjà lire tous les matchs `in_progress` via `fetchInProgressMatches()`, cette story étend la même capacité de lecture aux matchs `finished`, sur la même table, avec la même policy. Security Auditor non convoqué pour cette raison (pas de nouvelle ressource ni de changement de rôle) — à confirmer par le Risk Analyst.
