# Architecture — Retours du premier match réel

## M1 — Chrono auto-démarré
`launch-match-btn` (`app.js` ~ligne 4403-4410) :
```js
const launchBtn=document.getElementById("launch-match-btn");
if(launchBtn) launchBtn.onclick=()=>{
  if(!S.currentMatchId) S.currentMatchId=gid();
  subscribeMatchEvents(S.currentMatchId);
  S.period=1; // securite explicite, meme si deja le defaut
  upsertMatchSnapshot();
  S.view="match";
  R();
  startTimer(); // demarre le chrono automatiquement — appele APRES R() pour que S.running=true soit deja reflete au premier rendu de l'ecran Match
};
```
`startTimer()` (déjà existante, ~ligne 732) gère déjà `if(S.running||S.readOnly)return;` — appel sans risque de double-démarrage.

## M2 — Variables CSS manquantes
`style.css`, sur `:root` (à côté des autres variables de palette) :
```css
--accent: var(--yellow);
--accent-rgb: 240,199,94;
```
Aucun changement dans `app.js` — `actBtn()` (~ligne 2065-2072) et `.act-h.selected` (`style.css` ~ligne 656-658) restent inchangés, ils fonctionneront simplement une fois les variables définies.

## M3 — Possession auto-switch en Mode Simple
`recordEvent()` (~ligne 1117-1138), juste avant `R()` :
```js
// Auto-switch possession apres tir/PB — meme regle que validateAndClose() (Mode Expert)
if(act.isGoal||act.isSave||act.isOff||type==="TURNOVER"){
  S.possession = team==="home"?"away":"home";
}
```

## M4 — Rappel de mi-temps
Nouvel état : `halfTimeLastAlert:0` dans `freshState()` (reset par `newMatch()`, comme `tmLastAlert`).
Nouvelle fonction, appelée depuis le tick du chrono (`startTimer()`, ~ligne 732 — pas depuis `recordEvent()`/`validateAndClose()`, volontairement, pour que le rappel fonctionne **indépendamment du mode** et même si aucun événement n'est saisi pendant un moment) :
```js
function checkHalfTimeReminder(){
  if(S.period!==1 || S.time<1800) return; // 1800s = 30min reglementaires
  const now=Date.now();
  if(now-S.halfTimeLastAlert<120000) return; // repete toutes les 2min, pas 30s comme TM (plus insistant)
  S.halfTimeLastAlert=now;
  showToast("⏰ Fin de la 1ère mi-temps réglementaire — pense à basculer sur MT2", true);
}
```
```js
timerInterval=setInterval(()=>{S.time++; checkHalfTimeReminder(); renderTimer();},1000);
```
`per-btn` (~ligne 2124/2251, rendu ; ~ligne 4689, handler) : classe `due` ajoutée conditionnellement (`S.period===1&&S.time>=1800`) pour le style pulsant (cf. Visual Crafter) — retirée automatiquement au prochain rendu une fois la bascule faite (`S.period` change).

## M5 — Bandeau de validation au lancement
Nouvel état : `launchWarningsCollapsed:false`, `launchWarningsDismissed:false` (reset par `newMatch()`).
Nouvelle fonction de détection (pure, pas d'effet de bord) :
```js
function launchWarnings(){
  const warnings=[];
  if(S.trackGK){
    if(!S.home.gkId) warnings.push(`GB non sélectionné pour ${S.home.name}`);
    if(!S.away.gkId) warnings.push(`GB non sélectionné pour ${S.away.name}`);
  }
  if(S.home.players.filter(p=>p.selected).length===0) warnings.push(`Aucun effectif sélectionné pour ${S.home.name}`);
  if(S.away.players.filter(p=>p.selected).length===0) warnings.push(`Aucun effectif sélectionné pour ${S.away.name}`);
  return warnings;
}
```
Rendu conditionnel en haut de l'écran Match (dans la fonction qui construit le layout Match, avant `.ml-actions`) :
```js
${(!S.launchWarningsDismissed && launchWarnings().length>0) ? (S.launchWarningsCollapsed ? renderLaunchWarningsBadge() : renderLaunchWarningsBanner(launchWarnings())) : ""}
```
`[–]` → `S.launchWarningsCollapsed=true` ; `[✕]` → `S.launchWarningsDismissed=true` ; clic sur la pastille repliée → `S.launchWarningsCollapsed=false`. Purement de l'affichage, aucun effet sur `S.events`/la validité du match.

## Mode équipe générale — abandonné
Romain a demandé d'abandonner cette piste (message de suivi après lecture du résumé du cycle) : pas de bypass de saisie sans joueur, juste l'alerte M5 ci-dessus. Aucun changement sur `ap.shooterId`, `renderCourtEmptyState()`, `clickGoalZone()`, `clickCourtPosition()`, `clickActionMap()`, `validateAndClose()` ou le calcul de `shotMode` — tous restent inchangés.
