# Architecture — Corrections Audit Final + Mode Simple à équipe unique

## F1 — Sauvegarde idempotente

### Décision technique
`dbSaveMatch()` (`app.js:638`) fait déjà un `objectStore.put(match)` sur un store `keyPath:"id"` (`app.js:626`) — `put()` est déjà un upsert par clé côté IndexedDB, aucune migration de schéma nécessaire. Le seul problème est que `saveMatch()` (`app.js:1605`) génère un `id:Date.now()` **neuf à chaque appel**, donc `put()` insère toujours une nouvelle ligne au lieu d'en écraser une.

**Correctif** : ajouter `S.savedMatchId` (nouveau champ d'état, `null` par défaut) qui mémorise l'`id` local de la sauvegarde en cours de session :
```javascript
async function saveMatch(){
  if(S.readOnly) return;
  const match={
    id: S.savedMatchId || Date.now(),
    ...
  };
  try{
    await dbSaveMatch(match);
    S.savedMatchId = match.id; // mémorise pour le prochain saveMatch() de cette session
    ...
```
Réinitialisation de `S.savedMatchId=null` :
- Dans `newMatch()` (`app.js:1691-1696`, à ajouter dans le même bloc de reset que `S.launchWarningsCollapsed=false; ...`)
- Dans `loadMatchAsCurrent()` (`app.js:1709+`) — mais avec une nuance : plutôt que `null`, on fixe `S.savedMatchId = m.id` (l'identifiant du match archivé qu'on vient de charger), pour que si le coach modifie ce match repris puis re-sauvegarde, ça **mette à jour la même entrée archivée** plutôt que d'en créer une troisième. Cohérent avec l'intention déjà documentée de cette fonction ("Le match en cours sera remplacé").

### Pourquoi (alternatives rejetées)
- **Dédupliquer après coup côté Bilan → Saison** (filtrer les matchs "trop similaires" à l'affichage) : rejeté — complexe, source de faux positifs (deux vrais matchs au même score le même jour existent), et ne corrige pas la cause, seulement le symptôme.
- **Un id stable dès la création du match** (au moment de `newMatch()`/lancement, pas au premier `saveMatch()`) : rejeté — aurait nécessité de toucher le flux de lancement (STORY-54) pour un gain nul ; le premier `saveMatch()` est un point de repère suffisant et plus simple à raisonner (id = "quand ça a été sauvegardé pour la première fois", pas "quand le match a démarré").

### Impact sur l'existant
- Aucun changement de schéma IndexedDB (`DB_VER` reste à 2).
- Aucun changement au comportement Supabase (`S.currentMatchId`, `upsertMatchSnapshot()`, `markMatchFinished()`) — `S.savedMatchId` est un concept strictement local, distinct et indépendant de `S.currentMatchId` (identifiant Supabase du match, pas de la sauvegarde locale).
- `S.matchHistory` (utilisé par `loadMatchAsCurrent()`) doit rester rechargé après chaque `saveMatch()` réussi comme aujourd'hui (déjà le cas via le compteur `count` recalculé à la ligne 1621) — aucun changement requis là.

### Nouvelles structures de données
- `S` gagne un champ `savedMatchId: null` (initialisation dans l'objet d'état, à côté de `launchWarningsCollapsed` par exemple).

### Critère de bascule
Si un jour la sauvegarde devient automatique/périodique (au lieu d'un clic explicite), ce mécanisme reste valable tel quel — aucune refonte nécessaire, `S.savedMatchId` continuerait de jouer le même rôle.

---

## F2 — Historique des alertes critiques

### Décision technique
Centraliser l'historique dans `showToast()` (`app.js:1359`) plutôt que de modifier individuellement les ~8 points d'appel `showToast(msg, true)` dispersés dans le fichier (demi-temps `:797`, TM conseillé ×3 variantes `:1007/:1024/:1050`, changez de GB ×2 variantes `:1052/:1054`, plus de TM `:955`, tireur indisponible `:1122`, PDF non chargée `:5097`) :
```javascript
function showToast(msg, isAlert){
  if(isAlert){
    S.alertHistory.unshift({time:fmtTime(S.time), msg});
    if(S.alertHistory.length>3) S.alertHistory.length=3;
  }
  // ... reste inchangé (création du toast DOM)
}
```
Un seul point de modification, aucun risque d'oublier un site d'appel existant ou futur — tout `showToast(msg, true)` alimente automatiquement l'historique, exactement le même filtre que celui qui distingue déjà visuellement une alerte critique (bordure rouge, taille de police) d'un toast informatif neutre (`isAlert` falsy : "TM pris", "notes sauvegardées", "PDF téléchargé", ...). Le classement "alerte critique = digne d'un historique" est donc déjà encodé dans le code existant, pas une nouvelle taxonomie à inventer.

**Rendu** : nouveau bloc `alertHistoryBannerHtml`, calqué sur `launchWarningBannerHtml` (`app.js:2256`) — même composant visuel (voir Design/Visual), affiché juste en dessous s'il y a au moins une entrée (`S.alertHistory.length>0`), avec son propre couple `S.alertHistoryCollapsed`/`S.alertHistoryDismissed` (indépendant du bandeau GB — un coach peut vouloir garder l'un ouvert et l'autre réduit) et ses propres handlers (`ahb-collapse`/`ahb-dismiss`/`ahb-reopen`, même pattern que `lwb-collapse`/`lwb-dismiss`/`lwb-reopen` en `app.js:4948-4950`).

### Pourquoi (alternatives rejetées)
- **Modifier chaque site d'appel individuellement** (ajouter le push à chacun des ~8 `showToast(...,true)`) : rejeté — fragile, un futur appel à `showToast(msg, true)` oublierait naturellement le push si ce n'est pas centralisé ; la centralisation dans `showToast()` rend le comportement automatique et impossible à oublier.
- **Un nouveau composant "centre de notifications" séparé** (icône cloche dans le header, panneau dédié) : rejeté — hors scope PRD, réinvente un pattern (bandeau réductible) qui existe déjà et fonctionne, alors que `CLAUDE.md` documente déjà `launchWarnings()` comme le pattern de référence pour ce type d'information non-bloquante.

### Impact sur l'existant
- `showToast()` reste utilisée à l'identique partout ailleurs (paramètres inchangés, comportement DOM inchangé) — seul un effet de bord supplémentaire (push en mémoire) est ajouté quand `isAlert` est vrai.
- Le bandeau GB (`launchWarnings()`) n'est pas touché — nouveau bloc frère, pas une fusion des deux (garde leur logique de collapse/dismiss strictement indépendante, comme documenté au Design).
- `newMatch()` doit réinitialiser `S.alertHistory=[]` (nouvel historique par match, pas de fuite d'un match à l'autre) — même bloc de reset que `S.savedMatchId` (F1) et `S.launchWarningsCollapsed` déjà présents.

### Nouvelles structures de données
- `S.alertHistory: []` — tableau d'objets `{time:string, msg:string}`, 3 entrées maximum, le plus récent en premier (`unshift`).
- `S.alertHistoryCollapsed: false`, `S.alertHistoryDismissed: false`.

---

## F3 — Garde-fou volume d'événements (Analyse)

### Décision technique
`autoAnalysis()` (`app.js:3207`) calcule déjà `hTotal`/`aTotal` (tirs cadrés+non cadrés confondus) en tout début de fonction. Ajouter une constante de seuil et gater les insights qualitatifs identifiés par le PRD :
```javascript
const MIN_EVENTS_FOR_INSIGHTS = 10; // tirs cumulés des deux équipes, seuil arbitraire mais raisonnable
const enoughData = (hTotal+aTotal) >= MIN_EVENTS_FOR_INSIGHTS;
```
Puis entourer d'un `if(enoughData)` les blocs suivants (identifiés par lecture du code, `app.js:3226-3266`) :
- `Efficacité faible (...) - travail du tir nécessaire` (ligne 3226)
- Analyse PB (lignes 3229-3230)
- Série de buts encaissés (lignes 3234-3239)
- Analyse mi-temps (lignes 3244-3245)
- Analyse PD (lignes 3249-3250)
- Blocs d'efficacité par tranche de 10 min (lignes 3253+)

Les lignes "Résultat" (3220-3222) et "Efficacité FENIX X% vs Adversaire Y%" (3225, factuelle et neutre, pas un jugement) restent **toujours** affichées, quel que soit le volume — cohérent avec le PRD ("le résultat/score reste toujours en première ligne").

### Pourquoi (alternatives rejetées)
- **Seuil par insight** (ex. seuil différent pour PD vs pertes de balle) : rejeté pour cette itération — complexité inutile, un seuil global unique sur le volume total de tirs est un signal suffisant de "match représentatif" pour tous les insights concernés à la fois.
- **Message explicite "pas assez de données"** : rejeté (voir Design) — une liste plus courte est déjà auto-explicite.

### Impact sur l'existant
- `matchAnalysis(m)` (jumeau scoped-match de `autoAnalysis()` pour Bilan, cf. STORY-35 dans `CLAUDE.md`) doit recevoir le même garde-fou — à vérifier si c'est une fonction dupliquée ou si les deux partagent déjà une base commune ; si dupliquée, le Developer applique le même seuil aux deux pour ne pas créer d'incohérence entre Stats → Analyse (match en cours) et Bilan → Analyse (match archivé).
- Aucun changement de structure de données, aucune migration.

### Nouvelles structures de données
Aucune — une constante locale suffit.

---

## F4 — Mode Simple à équipe unique

### Décision technique
`renderMatchSimple()` (`app.js:1218-1248`) appelle actuellement `teamRow()` deux fois (une fois par équipe, empilées). Remplacer par un seul appel, sur l'équipe en possession :
```javascript
function renderMatchSimple(){
  const team = S.possession; // "home" ou "away"
  const accent = team==="home" ? "var(--fenix-sky)" : "var(--red)";
  const name = S[team].name;
  const simpleBtn=(type,label,icon)=>{
    const flashed=S.simpleFlash&&S.simpleFlash.team===team&&S.simpleFlash.type===type;
    return `<button class="act-h ${flashed?"simple-flash":""}" data-simple="${type}" style="flex:1;">
      <span class="ah-icon" style="color:${accent}">${icon}</span>
      <span class="ah-label" style="color:${accent}">${label}</span>
    </button>`;
  };
  return `
    <div style="background:rgba(240,199,94,.12);border:1.5px solid var(--yellow);border-radius:6px;padding:5px 10px;text-align:center;font-size:10px;font-weight:700;color:var(--yellow);letter-spacing:.06em;margin-bottom:10px;">⚡ MODE SIMPLE ACTIF</div>
    <div>
      <div style="font-size:11px;font-weight:700;color:${accent};text-transform:uppercase;letter-spacing:.05em;margin-bottom:5px;">● ${name}</div>
      <div style="display:flex;gap:5px;">
        ${simpleBtn("GOAL","BUT","⚽")}
        ${simpleBtn("SAVE","ARRÊT","🧤")}
        ${simpleBtn("OFF","NON CADRÉ","↗")}
      </div>
      <div style="display:flex;gap:5px;margin-top:5px;">
        ${simpleBtn("TURNOVER","PB","↩")}
        ${simpleBtn("FREEKICK","JET FRANC","🔄")}
      </div>
    </div>`;
}
```
`data-simple` n'encode plus que le `type` (le `team` est implicite : toujours `S.possession` au moment du clic, lu directement dans le handler). Binding à mettre à jour en conséquence (`app.js:4612-4627`) :
```javascript
document.querySelectorAll("[data-simple]").forEach(el=>{ el.onclick=()=>{
  const type=el.dataset.simple;
  const team=S.possession; // plus de vérification team!==S.possession : impossible désormais, un seul bloc existe
  const flashRef=S.simpleFlash={team,type};
  recordEvent(type,team);
  setTimeout(()=>{ if(S.simpleFlash===flashRef){ S.simpleFlash=null; R(); } }, 400);
}; });
```
Le garde `if(team!==S.possession){showToast(...); return;}` (`app.js:4617-4619`, STORY-59) est **supprimé** — il ne peut structurellement plus se déclencher (voir Impact sur l'existant ci-dessous), le laisser en l'état créerait du code mort trompeur pour un futur lecteur qui pourrait croire qu'il est encore atteignable.

### Pourquoi (alternatives rejetées)
- **Garder les deux blocs mais masquer celui inactif en CSS (`display:none`)** : rejeté — ne résout pas le vrai problème (Romain veut regagner l'espace vertical, pas juste cacher visuellement ce qui prend déjà de la place dans le flux du DOM ; `display:none` le retire bien du flux en réalité, mais cette approche garde deux blocs de markup dupliqués à maintenir en synchronisation avec `S.possession`, plus fragile que ne générer qu'un seul bloc directement dans `renderMatchSimple()`).
- **Garder `team` dans `data-simple`** ("toujours `S.possession|type`") : rejeté — inutile puisqu'un seul bloc existe désormais, `S.possession` est déjà lisible directement dans le handler ; simplifier l'attribut réduit la surface de code à maintenir.

### Impact sur l'existant
- **STORY-59 (verrou de possession) devient sans objet en Mode Simple** : le scénario qu'elle corrigeait ("cliquer l'équipe qui n'a pas la balle") ne peut plus se produire une fois qu'un seul bloc de boutons existe. La classe CSS `.simple-inactive{opacity:.4;}` (`style.css:702`) devient inutilisée — à supprimer par le Developer en même temps (pas de raison de la garder), ou à laisser si le Developer préfère minimiser le diff ; sans impact fonctionnel dans les deux cas.
- **Le bouton "◉ POSSESSION" du scoreboard (`.mlt-poss-btn`) reste la seule façon de changer manuellement d'équipe active** — totalement inchangé, F4 n'y touche pas.
- **`recordEvent()`, `checkGkConsecutiveAlert()`, `checkTimeoutAdvisor()`** (branchés depuis STORY-60) restent appelés exactement pareil — `recordEvent(type, team)` reçoit toujours les deux mêmes paramètres qu'avant, seule la façon dont `team` est déterminé au clic change (avant : lu depuis `data-simple`, encodé au render ; après : lu depuis `S.possession` au moment du clic, plus robuste puisqu'il ne peut jamais désynchroniser du bloc affiché).
- **Mode Expert non concerné** — `renderMatchSimple()` est une fonction dédiée au Mode Simple, aucun chemin partagé avec le rendu Mode Expert.

### Nouvelles structures de données
Aucune — réutilise `S.possession`/`S.simpleFlash` déjà existants.

### Critère de bascule
Si un jour Romain demande à voir les DEUX scores simultanément avec les boutons (et pas seulement dans le scoreboard déjà présent au-dessus), cette structure à bloc unique resterait valable — il suffirait d'ajouter un rappel de score inline dans le libellage, pas de refonte.

---

## Risques transverses identifiés (à détailler par le Risk Analyst)
- F1 : un match repris sur un **autre appareil** n'a pas le même `S.savedMatchId` en mémoire (state local, jamais synchronisé) — resauvegarder depuis ce second appareil créerait une nouvelle entrée locale sur CET appareil. Comportement acceptable (chaque appareil a son propre historique local, déjà le cas aujourd'hui pour toute l'app) mais à documenter explicitement pour ne pas surprendre.
- F4 : vérifier qu'aucun autre code ne dépend du format `data-simple="team|type"` (recherche exhaustive faite : seul le binding `app.js:4612` le lit) avant de le simplifier en `data-simple="type"`.
