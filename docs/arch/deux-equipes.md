# Architecture — Deux équipes distinctes (-18 et CF/N1)

## Fichiers touchés
`app.js` (état, init, scoping localStorage/IndexedDB/Supabase, nouveau rendu de l'écran de choix, réglage de changement d'équipe), `docs/supabase-migration-season-journee-notes.sql` (déjà étendu — 1 ligne de plus, `team_profile`, à réexécuter par Romain, idempotent).

## État
```js
// freshState() — nouveau champ
teamProfile:null, // "cf" | "u18" — null tant qu'aucun choix n'a été fait sur cet appareil
```
Chargé depuis `localStorage` **avant** le chargement de l'effectif (ordre important, cf. ci-dessous) :
```js
try { S.teamProfile = localStorage.getItem("hb2_team_profile"); if(S.teamProfile!=="cf"&&S.teamProfile!=="u18") S.teamProfile=null; } catch(e){ S.teamProfile=null; }
```

## Effectifs — `hb2_teams` devient scopé par profil
```js
function teamsStorageKey(){ return "hb2_teams_"+(S.teamProfile||"cf"); }
function saveTeams(){ localStorage.setItem(teamsStorageKey(), JSON.stringify({home:S.home,away:S.away})); }
function loadTeamsForActiveProfile(){
  try{
    const saved=JSON.parse(localStorage.getItem(teamsStorageKey()));
    if(saved){
      if(saved.home?.players?.length>0) S.home=saved.home; else S.home={name:defaultTeamName(),photo:null,players:[],gkId:null};
      if(saved.away) S.away=saved.away; else S.away={name:"Adversaire",photo:null,players:[],gkId:null};
    } else {
      S.home={name:defaultTeamName(),photo:null,players:[],gkId:null};
      S.away={name:"Adversaire",photo:null,players:[],gkId:null};
    }
    S.home.players.forEach(p=>{ if(p.selected===undefined) p.selected=false; });
  }catch(e){}
}
function defaultTeamName(){ return S.teamProfile==="u18" ? "FENIX Toulouse -18" : "FENIX Toulouse"; }
```
**Migration de compatibilité (M5, roster)** : la clé historique `hb2_teams` (sans suffixe) contient l'effectif CF actuel de Romain — au premier chargement, si `hb2_teams_cf` n'existe pas encore mais que `hb2_teams` (ancienne clé) existe, la copier vers `hb2_teams_cf` une fois :
```js
try{
  if(!localStorage.getItem("hb2_teams_cf") && localStorage.getItem("hb2_teams")){
    localStorage.setItem("hb2_teams_cf", localStorage.getItem("hb2_teams"));
  }
}catch(e){}
```
À exécuter une seule fois avant `loadTeamsForActiveProfile()`, dans le bloc d'init au chargement du script (remplace l'actuel bloc `try{ const saved=JSON.parse(localStorage.getItem("hb2_teams"))... }` ~ligne 93-104).

## Matchs locaux (IndexedDB) — champ `teamProfile`
`saveMatch()` (~ligne 1401-1413) : ajouter `teamProfile:S.teamProfile,` dans l'objet `match`.
Tous les consommateurs de `dbGetAll()` (`renderHistory()` ~ligne 4167, `renderBilanSaison()` ~ligne 3904, le chargement pour Bilan ~ligne 4246) filtrent désormais sur l'équipe active :
```js
const matches = allMatches.filter(m => (m.teamProfile||"cf") === S.teamProfile);
```
`||"cf"` couvre M5 : les matchs déjà sauvegardés avant cette story (sans `teamProfile`) apparaissent quand le profil actif est `"cf"`, jamais quand il est `"u18"`.

## Supabase — écriture
`upsertMatchSnapshot()` (~ligne 265-280, appelée en continu pendant tout match en cours) : ajouter `team_profile:S.teamProfile,` **dans le payload principal**, pas dans l'appel "confort" séparé de STORY-48 — contrairement à season/journee/championnat/coach_notes (utiles seulement à l'archivage), `team_profile` doit être correct dès le tout début du match pour que le filtrage des matchs "en cours" (ci-dessous) fonctionne pendant la partie, pas seulement une fois sauvegardée.

## Supabase — lecture, 2 points à filtrer
1. **`fetchInProgressMatches()`** (~ligne 185-193, STORY-14) : ajouter `.eq('team_profile', S.teamProfile)` à la requête — un appareil sur le profil -18 ne doit jamais se voir proposer de reprendre un match CF en cours, et inversement.
2. **`fetchMissingArchivedMatches()`** (STORY-48, pas encore codée) : même ajout, `.eq('team_profile', S.teamProfile)` — le rapatriement de l'historique ne ramène que les matchs de l'équipe active.

Colonne Supabase `team_profile` avec `default 'cf'` (cf. migration) : les lignes déjà existantes en base (matchs CF d'avant cette story) sont automatiquement correctes sans script de backfill séparé.

## Écran de choix d'équipe — point d'insertion dans le rendu
Dans la fonction de rendu principale (~ligne 1564-1583, la même zone qui gère `S.authOk===false`/`S.authOk===null`/`S.resumePrompt`) :
```js
if(S.authOk===false){ /* ...déjà existant... */ }
if(S.authOk===null){ /* ...déjà existant... */ }
if(S.authOk && !S.teamProfile){
  const clone=app.cloneNode(false);
  clone.innerHTML=renderTeamPicker();
  app.parentNode.replaceChild(clone,app);
  bind();
  return;
}
if(S.resumePrompt){ /* ...déjà existant... */ }
```
**Important** : `checkForResumableMatch()` (appelée dans le flux d'init async, ~ligne 169, `if(S.authOk) await checkForResumableMatch();`) doit être conditionnée à `S.teamProfile` déjà connu — sinon, au tout premier lancement (aucun profil choisi), cette requête partirait sans filtre d'équipe valide. Modifier en `if(S.authOk && S.teamProfile) await checkForResumableMatch();`, et déclencher un appel équivalent **après** le choix de profil (dans le handler de sélection du picker, cf. ci-dessous).

## Fonction `chooseTeamProfile(profile)`
```js
async function chooseTeamProfile(profile){
  S.teamProfile=profile;
  try{ localStorage.setItem("hb2_team_profile", profile); }catch(e){}
  loadTeamsForActiveProfile();
  R();
  if(S.authOk) await checkForResumableMatch(); // rattrape l'appel sauté à l'init si 1er choix
  R();
}
```

## Changer d'équipe (réglages, M8)
```js
function switchTeamProfile(){
  if(S.readOnly) return;
  if(S.events.length>0 && !safeConfirm("Changer d'équipe ? Le match en cours sur cet appareil sera abandonné (déjà sauvegardable via 💾 avant de changer).")) return;
  markMatchFinished(); // comme newMatch(), le match en cours ne doit plus apparaître "reprenable"
  S.currentMatchId=null;
  unsubscribeMatchEvents();
  S.teamProfile=null;
  try{ localStorage.removeItem("hb2_team_profile"); }catch(e){}
  R(); // ramène sur l'écran de choix (S.teamProfile est de nouveau null)
}
```

## Championnat — saisie libre scopée par équipe (reprend STORY-49, révisé)
```js
function championnatStorageKey(){ return "hb2_championnats_"+(S.teamProfile||"cf"); }
function championnatHistory(){ try{ return JSON.parse(localStorage.getItem(championnatStorageKey()))||[]; }catch(e){ return []; } }
function rememberChampionnat(value){
  if(!value) return;
  const list=championnatHistory().filter(v=>v!==value);
  list.unshift(value);
  try{ localStorage.setItem(championnatStorageKey(), JSON.stringify(list.slice(0,10))); }catch(e){}
}
```
`edit-championnat` (`<input list="championnat-suggestions">`, cf. Design) : `onchange` appelle `rememberChampionnat(el.value.trim())` puis `S.championnat=el.value.trim()`. `S.championnat` **réinitialisé à `""`** par `newMatch()` (pas de valeur par défaut hasardeuse portée d'un match à l'autre — cohérent avec le risque R1 déjà identifié en STORY-49 : forcer une re-sélection volontaire, rapide grâce aux suggestions mémorisées, protège contre un "Amical" oublié qui contaminerait le match suivant).
Écriture Supabase inchangée par rapport à STORY-49 (2e appel `update()` "confort" de `markMatchFinishedById()`, déjà spécifié dans `docs/arch/sync-historique-multi-appareil.md`).

## Aucun changement sur
Le reste du fonctionnement de Match/Stats/Bilan une fois `S.teamProfile` défini — tout continue de lire `S.home`/`S.away`/`S.events` exactement comme avant, sans savoir qu'un scoping existe en amont.

## Sécurité
Confirmé par le Brief : pas de nouvelle frontière RLS, le compte partagé unique voit toujours toutes les données des deux équipes au niveau base — cette story ajoute un filtre de confort côté appli/requêtes, pas une isolation cryptographique ou de policy. À noter explicitement pour le Risk Analyst.
