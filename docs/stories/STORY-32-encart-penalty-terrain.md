# STORY-32 — Encart pénalty sur le terrain (mécanique, rendu, visuel)

**En tant que** Romain (saisie en direct, mode Expert),
**Je veux** que l'obtention d'un penalty ouvre directement un encart sur le terrain (BUT / TIR ARRÊTÉ / TIR NON CADRÉ, tireur pré-désigné, zone d'impact si suivi GB actif),
**Afin de** ne jamais quitter le terrain des yeux pendant le moment de saisie le plus sensible au temps de l'app, et de capturer enfin la zone d'impact (`goalZone`) des penaltys — aujourd'hui toujours `null` car `validateAndClose()` s'exécute en synchrone avant que le sélecteur de zone n'ait la moindre chance de s'afficher.

Concerne exclusivement le mode Expert (`renderMatchPanel()`). Le mode Simple n'a pas de PO/PEN détaillé, non impacté.

## Contexte technique

### Bug actuel à corriger (rappel)
`clickActionPlayer()` (~659-699), branche PEN_OBT (~682-686) : au clic sur le joueur qui obtient le penalty, `ap.shooterId=playerId` puis `validateAndClose()` est appelé **immédiatement**. C'est ce court-circuit qui empêche `goalZone` d'être jamais capturé pour un penalty en direct (il fonctionne déjà correctement pour l'édition a posteriori via `editEvent()`, ~1690-1703, preuve que le composant de zone n'est pas en cause).

### Invariant central à respecter (ne jamais casser)
**Tant que `S.penMode===true`, `S.actionPanel` est garanti non-null** et porte le tireur en cours de désignation. Les deux passent à `false`/`null` **ensemble**, dans un seul et même appel. C'est ce non-null continu qui permet au terrain de rester réactif (réassignation de tireur) sans réinventer de mécanisme.

### 1. `clickActionPlayer()` — branche PEN_OBT modifiée

Remplacer la branche actuelle (~682-686) par :
```js
if(ap.type==='PEN_OBT'){
  const team=ap.team;
  validateAndClose();              // enregistre le PEN_OBT, inchangé — événement définitif, indépendant de l'issue qui suivra
  S.penMode=true;
  S.actionPanel={type:null, team, shooterId:playerId, pdId:null, mapX:null, mapY:null, goalZone:null};
  R(); return;
}
```
`type:null` est un écart transitoire par rapport à la forme documentée dans `freshState()` — jamais écrit dans `S.events`, jamais synchronisé vers Supabase (`queueEventForSync()` n'est appelé que depuis `validateAndClose()`).

**Supprimer** l'ancienne branche de conversion automatique sur clic joueur (~671-679, `if(S.penMode && (act.isGoal||act.isSave||act.isOff)){...}`) — devient totalement inatteignable une fois ce qui précède en place (vérifié par le Risk Analyst : aucun impact sur CSV import, chargement d'un match d'Historique, sync Supabase, ou `editEvent()`). Ne pas la garder en filet : du code mort qui ressemble à un chemin actif est trompeur pour un futur mainteneur.

**Réassignation de tireur — zéro code nouveau.** La branche déjà existante juste après (`else if(ap.shooterId===playerId){ap.shooterId=null;} else {ap.shooterId=playerId;}`) gère déjà "reassigner sans fermer l'encart" pour n'importe quel tir en cours. Un tap sur un **autre** joueur du terrain pendant l'étape "3 boutons" (avant tout choix d'issue) y passe automatiquement, sans rien à modifier. Portée : la réassignation n'est possible que pendant cette sous-étape — une fois une issue choisie (BUT/ARRÊT/HC tapé), le terrain n'affiche plus de joueurs cliquables (même comportement que pour un tir normal en `shotMode`).

### 2. Nouvelle fonction `choosePenOutcome(kind)`

```js
function choosePenOutcome(kind){          // kind: 'GOAL' | 'SAVE' | 'OFF'
  if(S.readOnly) return;
  const ap=S.actionPanel; if(!ap||!ap.shooterId) return;
  const penMap={GOAL:'PEN_GOAL',SAVE:'PEN_SAVE',OFF:'PEN_OFF'};
  ap.type=penMap[kind];
  ap.mapX=50; ap.mapY=85;                 // position fixe, comme aujourd'hui
  const act=ACTIONS[ap.type];
  if(!S.trackGK || act.isOff){
    validateAndClose();                   // validation immédiate — même règle que pour un tir normal (clickCourtPosition(), ~719)
  }
  R();
}
```
Bindée sur un nouvel attribut `data-pen-outcome="GOAL|SAVE|OFF"` (les 3 boutons `.ap-pen-btn`), dans `bind()` juste après le bloc `[data-ap-player]` (~ligne 3827) :
```js
document.querySelectorAll("[data-pen-outcome]").forEach(el=>{ el.onclick=()=>{ choosePenOutcome(el.dataset.penOutcome); }; });
```
Si `S.trackGK` est actif et que BUT/ARRÊT est choisi : pas de validation immédiate, `R()` seul — `renderMatchPanel()` calcule `showGZ=S.trackGK&&ap.mapX!=null&&!act.isOff` → `true` (`ap.mapX` vaut déjà 50), la grille de zone s'affiche. **Aucune modification de `clickGoalZone()`** : elle valide déjà elle-même dès qu'une zone est tapée (condition `S.trackGK && ap.shooterId && (act.isGoal||act.isSave||act.isOff)`), donc `goalZone` est réellement enregistré.

### 3. `validateAndClose()` — garde défensive + centralisation de `S.penMode=false`

Ajouter juste après le calcul de `act` :
```js
if(!act) return;
```
Protège contre le seul scénario qui ferait planter l'app : `ap.type` vaut `null` pendant la sous-étape "3 boutons" — `act.isGoal` sur `undefined` lèverait une exception si `validateAndClose()` était invoqué à ce moment (filet de sécurité, ne devrait normalement jamais être atteint grâce au verrou de `selectAction()`, point 6 ci-dessous).

Juste avant de nuller `S.actionPanel` (fin de fonction) :
```js
if(act && act.isPen && (act.isGoal||act.isSave||act.isOff)) S.penMode=false;
```
Cette ligne unique couvre les 3 issues et les 2 chemins de validation (immédiate via `choosePenOutcome()`, ou via `clickGoalZone()`), sans qu'aucun appelant n'ait à s'en souvenir individuellement. Elle est un no-op inoffensif pendant l'édition d'un `PEN_GOAL`/`PEN_SAVE` existant depuis le feed (`S.penMode` y vaut déjà `false`).

### 4. `autoValidatePending()` — garde défensive symétrique

Même raison qu'au point 3 : `if(!ap || !ap.type || !ACTIONS[ap.type]) return;` (ou équivalent) avant tout accès à `ACTIONS[ap.type]`.

### 5. `renderMatchPanel()` — nouvelle branche prioritaire + extraction `renderShotCourt()`

```js
function renderMatchPanel(){
  const ap=S.actionPanel;
  ...
  if(S.penMode && ap){ return renderPenaltyPanel(ap); }   // NOUVEAU — avant tout calcul de statusHtml
  ... (shotMode / default, inchangés) ...
}
```

**Extraction obligatoire** (pas une option — évite exactement le type de divergence qui a permis au bug initial de passer inaperçu) :
```js
function renderShotCourt(ap, act){
  // Extraction PURE du bloc <div class="court-pick">...</div> actuel (~1645-1657).
  // Aucune logique changée pour les types non-pen.
  // Seul ajout : le bouton "↩ Modifier la position" ne s'affiche que si !act.isPen
  // (n'a pas de sens pour une position fixe 50/85).
}
```
Utilisée à l'identique par le chemin normal (tir hors pénalty) et par le nouvel encart pénalty — une seule définition de ce bloc dans tout le fichier.

```js
function renderPenaltyPanel(ap){
  const act = ap.type ? ACTIONS[ap.type] : null;
  const shooter = ap.shooterId ? S[ap.team].players.find(p=>p.id===ap.shooterId) : null;
  const headHtml = `<div class="ap-pen-panel">
    <button class="btn btn-sm ap-pen-close" data-pen-close>✕ Fermer</button>
    <div class="ap-pen-head">
      <span class="ap-mode-badge-pen">🎯 MODE PENALTY</span>
      ${shooter?`<span class="ap-badge ap-badge-pen"><span class="dot"></span>#${shooter.number||""} ${shooter.name}</span>`:""}
    </div>
    ${!act ? renderPenOutcomeButtons() : ""}
  </div>`;
  const bodyHtml = !act ? renderPenRoster(ap) : renderShotCourt(ap, act);
  return `<div style="margin-top:2px;">${headHtml}${bodyHtml}</div>`;
}

function renderPenOutcomeButtons(){
  return `<div class="ap-pen-actions">
    <button class="ap-pen-btn" style="--pen-rgb:var(--pen-goal-rgb)" data-pen-outcome="GOAL"><span class="ah-icon">⚽</span><span class="ah-label">BUT</span></button>
    <button class="ap-pen-btn" style="--pen-rgb:var(--pen-save-rgb)" data-pen-outcome="SAVE"><span class="ah-icon">🧤</span><span class="ah-label">ARRÊT</span></button>
    <button class="ap-pen-btn" style="--pen-rgb:var(--pen-off-rgb)" data-pen-outcome="OFF"><span class="ah-icon">↗</span><span class="ah-label">HORS CADRE</span></button>
  </div>`;
}

function renderPenRoster(ap){
  // Reprend la boucle positioned.map(...) déjà existante (branche DEFAULT, ~1666-1674),
  // avec p.id===ap.shooterId ? "pen-shooter" : "pen-other" à la place de isSh?"shooter":"".
}
```

### 6. `selectAction()` — verrou pendant `S.penMode` (non optionnel)

**Risque de crash réel** : `selectAction()` (~615-622) et `clickTeam()` (~625-657) appellent `autoValidatePending()` en premier geste. Sans garde, un tap sur n'importe quel bouton de `.ml-actions` pendant la sous-étape "3 boutons" (`ap.type===null`) déclencherait `autoValidatePending()`→`validateAndClose()`→exception (filet du point 3 mis à part, on veut fermer ce risque à la source, pas seulement l'amortir).

Ajouter dans `selectAction()`, juste après `if(S.readOnly) return;` :
```js
if(S.penMode) return;
```
Recommandé par symétrie/défense en profondeur (pas strictement nécessaire) : la même garde dans `clickTeam()`.

**Traitement visuel obligatoire** (sans lui, un tap sans effet visible serait perçu comme un bug) : pendant que `S.penMode` est actif, `.ml-actions` reçoit le même traitement que `.match-layout.is-readonly .act-h` (`opacity:.35; pointer-events:none;` déjà défini `style.css` ~409-420) — ajouter une règle CSS équivalente conditionnée à une classe portée par le conteneur pendant `S.penMode` (ex. `.ml-actions.is-pen-locked`), calculée dans le rendu de la barre d'actions.

### 7. `closePenPanel()` — sortie explicite, non destructrice

```js
function closePenPanel(){
  if(S.readOnly) return;
  S.actionPanel=null;
  S.selectedAction=null;
  S.penMode=false;
  R();
}
```
Bindée sur `data-pen-close` :
```js
document.querySelectorAll("[data-pen-close]").forEach(el=>{ el.onclick=closePenPanel; });
```
Fonctionne identiquement dans les deux sous-étapes (3 boutons, ou grille de zone déjà affichée) : aucune issue n'a encore été validée à ce stade, donc aucun événement `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` n'existe — rien à supprimer de ce côté. Le PEN_OBT, enregistré dès le premier clic (point 1), n'est **jamais touché** par cette fonction.

### 8. Badge `.ml-status` — suppression de la branche `S.penMode`

Remplacer (~1836-1840) :
```js
${S.penMode||lastEvHtml?`<div class="ml-status">
  ${S.penMode?`<span ...>🎯 MODE PENALTY</span>`:""}
  ${lastEvHtml}
</div>`:""}
```
par :
```js
${lastEvHtml?`<div class="ml-status">${lastEvHtml}</div>`:""}
```
Aucune condition à affiner : `S.penMode===true` implique toujours que l'encart est affiché (même cycle de vie, point établi ci-dessus), donc le badge autonome n'a plus jamais de raison d'apparaître séparément.

### 9. Couleurs `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` (objet `ACTIONS`, ~19-33)

| Type | Avant | Après |
|---|---|---|
| `PEN_GOAL` | `color:"var(--green)"` | `color:"var(--gk-goal)"` (`#50C878`) |
| `PEN_SAVE` | `color:"var(--blue)"` | `color:"var(--gk-save)"` (`#4ECDE8`) |
| `PEN_OFF` | `color:"var(--orange)"` | `color:"var(--gk-off)"` (`#E89A4E`) |

Corrige une régression de lisibilité déjà en production : `--green`/`--blue` valent le même hex (`#5FA8D3`), donc "But Pen" et "Arrêt Pen" s'affichent aujourd'hui dans la même couleur dans le fil d'événements. Impact vérifié strictement isolé au fil d'événements (direct + lecture seule d'un match sauvegardé) — `ACTION_BUTTONS` (barre `.ml-actions`) ne référence jamais ces 3 types directement ; `renderGkSheet()` utilise déjà des hex codés en dur indépendants de `ACTIONS[type].color`. **Aucune couleur de `GOAL`/`SAVE`/`OFF`** (tirs normaux non-pénalty) ne change.

### 10. CSS à ajouter (`style.css`) — spécifié intégralement, aucune décision visuelle restante

```css
--pen-goal-rgb: 80,200,120;   /* = --gk-goal */
--pen-save-rgb: 78,205,232;   /* = --gk-save */
--pen-off-rgb:  232,154,78;   /* = --gk-off */

.ap-pen-panel{
  position:relative;
  display:flex; flex-direction:column; gap:8px;
  padding:8px 64px 8px 10px;
  margin-bottom:4px;
  border-radius:var(--r2);
  border:1.5px solid rgba(240,199,94,.35);
  background:rgba(240,199,94,.05);
  animation:fadeIn .25s ease;
}
.ap-pen-head{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; }

.ap-mode-badge-pen{
  background:rgba(240,199,94,.12); border:1.5px solid var(--yellow);
  border-radius:6px; padding:3px 10px; font-size:10px; font-weight:700;
  color:var(--yellow); letter-spacing:.06em;
}

.ap-badge.ap-badge-pen{
  background:rgba(240,199,94,.15); border:1px solid var(--yellow); color:var(--yellow);
  display:inline-flex; align-items:center; gap:6px;
}
.ap-badge-pen .dot{ width:7px; height:7px; border-radius:50%; background:var(--yellow); flex-shrink:0; }

.cp-player.pen-shooter{
  border:3px solid var(--yellow) !important;
  background:rgba(240,199,94,.85) !important;
  animation:penShooterPulse 1.8s ease-in-out infinite;
}
.cp-player.pen-shooter .cp-num, .cp-player.pen-shooter .cp-name{
  color:var(--bg) !important; font-weight:800;
}
@keyframes penShooterPulse{
  0%,100%{ box-shadow:0 0 0 3px var(--yellow), 0 0 10px rgba(240,199,94,.45); }
  50%{     box-shadow:0 0 0 3px var(--yellow), 0 0 20px rgba(240,199,94,.85); }
}

.cp-player.pen-other{ border-color:rgba(255,255,255,.25) !important; opacity:.7; }
.cp-player.pen-other .cp-num, .cp-player.pen-other .cp-name{ color:var(--t2) !important; }

.ap-pen-close{ position:absolute; top:6px; right:6px; border-color:var(--border); color:var(--t2); }

.ap-pen-actions{ display:flex; gap:6px; }
.ap-pen-btn{
  flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center;
  gap:4px; padding:12px 8px; border-radius:var(--r2);
  border:2px solid rgba(var(--pen-rgb),.4);
  background:rgba(var(--pen-rgb),.08);
  color:rgb(var(--pen-rgb));
  font-family:inherit; transition:all .15s ease;
}
.ap-pen-btn .ah-icon{ font-size:26px; line-height:1; }
.ap-pen-btn .ah-label{ font-size:13px; font-weight:800; text-transform:uppercase; letter-spacing:.04em; margin-top:2px; }
.ap-pen-btn:active{
  transform:scale(.95);
  background:rgba(var(--pen-rgb),.22);
  box-shadow:0 0 0 1px rgba(var(--pen-rgb),.5), 0 0 16px rgba(var(--pen-rgb),.35);
}

/* Responsive <700px */
@media (max-width:700px){
  .ap-pen-panel{ padding:6px 56px 6px 8px; }
  .ap-pen-btn .ah-icon{ font-size:20px; }
  .ap-pen-btn .ah-label{ font-size:11px; }
  /* .ap-pen-head passe déjà sur 2 lignes via flex-wrap défini plus haut */
  /* .ap-pen-close et l'épaisseur de .pen-shooter (3px) ne changent JAMAIS sous 700px */
}
```
`--pen-rgb` est fixé par bouton via `style="--pen-rgb:var(--pen-goal-rgb)"` etc. (cf. markup point 5).

**Mode lecteur** : ajouter `.ap-pen-panel` et `[data-ap-player]` à la liste de sélecteurs existante `.match-layout.is-readonly` (`style.css` ~409-420) — même traitement déjà défini (`opacity:.35;pointer-events:none;`), aucune nouvelle règle à écrire.

### 11. `editEvent()` — aucune modification dans cette story

`editEvent()` ne met jamais `S.penMode` à `true` : le nouveau branchement prioritaire de `renderMatchPanel()` (`if(S.penMode && ap)`) ne l'intercepte jamais quand on édite normalement (hors `S.penMode`). Seul effet de bord à vérifier : le bouton "↩ Modifier la position" masqué pour `act.isPen` (point 5) s'applique aussi en édition d'un `PEN_GOAL`/`PEN_SAVE` existant. **Le comportement d'`editEvent()` pendant qu'un encart pénalty est ouvert sur ce même appareil est traité dans STORY-33, pas ici.**

## Critères d'acceptation

1. Après validation du PEN_OBT (clic sur le joueur qui obtient le penalty), l'événement `PEN_OBT` est enregistré immédiatement dans `S.events` **et** un encart apparaît aussitôt à l'écran, sans retour nécessaire vers `.ml-actions`.
2. L'encart contient : badge `🎯 MODE PENALTY` (déplacé, même texte/couleur qu'avant), badge tireur `#{numéro} {nom}` du joueur qui a obtenu le PO, 3 boutons BUT/ARRÊT/HORS CADRE (couleurs `--gk-goal`/`--gk-save`/`--gk-off`), bouton `✕ Fermer` ancré en haut à droite.
3. Le badge `🎯 MODE PENALTY` autonome de `.ml-status` ne s'affiche plus jamais séparément une fois l'encart visible (vérifier : pendant `S.penMode===true`, `.ml-status` ne contient jamais ce badge, uniquement `lastEvHtml` le cas échéant).
4. Le joueur désigné comme tireur (`ap.shooterId`) porte la classe `.cp-player.pen-shooter` (anneau doré épais, fond quasi plein, pulsation) ; tous les autres joueurs cliquables du terrain portent `.cp-player.pen-other` (neutre, opacité .7). Le contour bleu `.shooter` habituel n'apparaît jamais pendant l'encart pénalty.
5. Un tap sur un autre joueur du terrain, pendant l'étape "3 boutons" uniquement, remplace `ap.shooterId` ; au re-rendu suivant, l'anneau doré est sur le nouveau joueur uniquement (jamais deux à la fois), le badge du header affiche le nouveau nom/numéro instantanément.
6. Si `S.trackGK` est actif et que BUT ou ARRÊT est tapé : aucune validation immédiate, le terrain n'est plus cliquable, la grille de zone 3×3 s'affiche (header inchangé, boutons remplacés par la grille) ; un tap sur une zone crée un événement `PEN_GOAL`/`PEN_SAVE` avec `goalZone` non-null, `mapX=50`, `mapY=85`.
7. Si HORS CADRE est tapé, ou si `S.trackGK` est désactivé : validation immédiate, aucune grille de zone n'est affichée à aucun moment ; l'événement créé a `goalZone=null`.
8. Après toute validation finale (point 6 ou 7) : `S.penMode=false`, `S.actionPanel=null`, `S.selectedAction=null` ; l'encart disparaît, la barre d'actions redevient active.
9. Un tap sur `✕ Fermer`, à n'importe quelle sous-étape, ferme l'encart (mêmes resets qu'au point 8) sans créer aucun événement `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` ; le `PEN_OBT` déjà enregistré reste intact, visible et éditable/supprimable normalement dans le feed.
10. Pendant que `S.penMode===true`, un tap sur n'importe quel bouton de `.ml-actions` ne produit aucun effet (pas d'exception, pas de changement d'état) et la barre apparaît visuellement grisée (`opacity:.35;pointer-events:none`).
11. En mode lecteur, l'encart ne peut jamais s'ouvrir (garde existante `if(S.readOnly) return;` en tête de `clickActionPlayer()`, non touchée) ; si un encart était déjà affiché avant l'activation du mode lecteur, il apparaît désaturé/non interactif comme les autres contrôles d'écriture.
12. `ACTIONS.PEN_GOAL.color`/`PEN_SAVE.color`/`PEN_OFF.color` valent respectivement `var(--gk-goal)`/`var(--gk-save)`/`var(--gk-off)` — un "But Pen" et un "Arrêt Pen" s'affichent dans deux couleurs visuellement distinctes dans le fil d'événements (direct et lecture seule). Aucune couleur de `GOAL`/`SAVE`/`OFF` (non-pénalty) n'a changé.
13. Le bouton "↩ Modifier la position" ne s'affiche jamais pour un type `PEN_*`, ni pendant l'encart en direct ni pendant l'édition d'un `PEN_GOAL`/`PEN_SAVE` existant depuis le feed.
14. La branche de code morte de `clickActionPlayer()` (ancienne conversion automatique, ~671-679) est supprimée.
15. Aucune régression sur le workflow non-pénalty : tir normal (terrain → zone si `trackGK` actif → validation), PB/PO/Jet franc (auto-validation immédiate, sans terrain ni zone) — comportement strictement identique à avant ce cycle.
16. Responsive <700px : padding/tailles réduits appliqués (§10), header en `flex-wrap`, bouton `✕ Fermer` toujours ancré en haut à droite, épaisseur de l'anneau `pen-shooter` jamais réduite (reste 3px).
17. `new Function()` (ou équivalent) valide `app.js` sans erreur de syntaxe après toutes les modifications.

## Hors scope

- Les 3 gardes de robustesse contre les actions concurrentes pendant que l'encart est ouvert (`undoLast()`, toggle POSSESSION, `editEvent()` sur un **autre** appareil ou plus tard dans le flux) — couvertes par **STORY-33**, qui dépend de celle-ci.
- La protection défensive de `renderGkSheet()`/`goalZoneHeatmap()` contre l'inclusion silencieuse des zones pénalty — couverte par **STORY-34**, indépendante.
- Le mode Simple (non impacté, pas de PO/PEN détaillé).
- L'affichage des zones pénalty dans les stats/heatmaps/PDF au-delà de la protection défensive (Nice to Have, reporté).
- Le rattrapage des penaltys déjà enregistrés sans zone d'impact dans les matchs passés (pas de backfill).
- La réassignation a posteriori du joueur ayant obtenu le PO lui-même (couverte marginalement par `editEvent()` existant si besoin).
- Toute évolution de la structure de données d'événement (`goalZone` existe déjà, seule son alimentation change).

## Dépend de

Aucune.

## Taille

L
