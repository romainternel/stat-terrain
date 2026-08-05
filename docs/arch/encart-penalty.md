# Architecture — Encart Pénalty sur le terrain

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v6-encart-penalty.md`, `docs/visual/encart-penalty.md`*
*Concerne `clickActionPlayer()` (`app.js` 659-699), `validateAndClose()` (886-934), `autoValidatePending()`/`selectAction()`/`clickTeam()` (607-657), `renderMatchPanel()` (1612-1677), le badge `.ml-status` (1836-1840), `editEvent()` (1690-1703), `renderGkSheet()`/`allShots` (2996-3094), l'objet `ACTIONS` (19-33), et `style.css` (`.match-layout.is-readonly` 409-420, `.cp-player.shooter`/`.pd-sel` 215-218, `.goal-zone-grid`/`.gz-cell` 208-212)*

## Décision technique globale

Le mécanisme `shotMode`/grille de zone (`renderMatchPanel()`, 1640-1659) est **confirmé réutilisable tel quel**, à une condition : il doit être **extrait dans une fonction dédiée** (`renderShotCourt(ap, act)`) plutôt que dupliqué. Sans cette extraction, le nouvel encart et le chemin normal (tirs hors pénalty) finiraient par maintenir deux copies quasi identiques de ~15 lignes de SVG/grille — exactement le genre de divergence qui a permis au bug initial de passer inaperçu. Avec l'extraction, les deux chemins appellent la même fonction : toute correction future de la grille de zone profite automatiquement aux deux.

Le reste de la feature se construit en réutilisant l'état existant (`S.penMode`, `S.actionPanel`) sans lui ajouter aucune nouvelle clé — seule sa **séquence d'usage** change. Point clé qui débloque tout le design : `S.actionPanel` reste **non-null en continu** entre la validation du PO et la validation finale de l'issue (aujourd'hui il repasse à `null` entre les deux, ce qui oblige au retour vers `.ml-actions`). C'est ce non-null continu qui permet au terrain de rester réactif (réassignation de tireur) sans réinventer de mécanisme : `clickActionPlayer()` sait déjà réassigner un `shooterId` sur un `actionPanel` existant (branche `else if/else`, ligne 693-697), on ne fait que l'atteindre dans un nouveau contexte.

Zéro nouvelle dépendance, zéro changement de la structure d'événement (`goalZone` existe déjà), zéro nouvelle clé d'état persistant.

## 1. Restructuration du flux `clickActionPlayer()` / `validateAndClose()`

### 1.a — Le PEN_OBT reste un événement à part entière, créé immédiatement

Vérifié dans le code actuel (`clickActionPlayer()` 682-686) : au premier clic sur le joueur qui obtient le penalty, `ap.shooterId=playerId` puis `validateAndClose()` est déjà appelé **immédiatement**, exactement comme pour PB et Jet franc (`x`/`y` restent `null`, cf. convention documentée dans `CLAUDE.md`). **Ce comportement ne change pas.** Trois raisons convergentes :
- Le PRD Must Have #1 le dit explicitement : *"dès que le PEN_OBT est **validé** (`S.penMode=true`), un encart apparaît"* — l'encart est la conséquence de la validation, pas un remplacement de celle-ci.
- La décision actée #4 du PRD (sortie sans supprimer le PEN_OBT) **présuppose** que le PEN_OBT existe déjà au moment où l'encart est ouvert — sinon il n'y aurait rien à préserver.
- `gkStats()`/les compteurs "PO" du match dépendent de cet événement pour exister dès l'obtention, indépendamment de l'issue qui suivra (un PO obtenu reste un PO obtenu même si Romain ferme l'encart sans choisir d'issue).

Donc l'ambiguïté posée par l'Analyst est tranchée : **PEN_OBT n'est pas une étape intermédiaire du choix d'issue, c'est un événement indépendant et définitif** (au même titre que PB/JF). Ce que la feature change, c'est uniquement ce qui se passe **après**.

### 1.b — Nouvel état transitoire : `S.actionPanel` re-peuplé immédiatement après le PEN_OBT

Aujourd'hui, `validateAndClose()` (appelé pour le PEN_OBT) termine en mettant `S.actionPanel=null` (ligne 927). C'est ce `null` qui force le retour vers `.ml-actions`. Décision : **juste après cet appel, dans la branche PEN_OBT de `clickActionPlayer()`, reconstruire immédiatement un `S.actionPanel` frais** représentant "en attente du choix d'issue", pré-rempli avec le tireur par défaut :

```
if(ap.type==='PEN_OBT'){
  const team=ap.team;
  validateAndClose();              // enregistre le PEN_OBT, inchangé
  S.penMode=true;
  S.actionPanel={type:null, team, shooterId:playerId, pdId:null, mapX:null, mapY:null, goalZone:null};
  R(); return;
}
```

`type:null` est le seul écart par rapport à la forme documentée dans `freshState()` (`actionPanel:null, // {type, team, shooterId, pdId, mapX, mapY, goalZone}`) — il ne représente aucune issue choisie pour l'instant. C'est un objet transitoire, jamais écrit dans `S.events`, donc **aucune évolution de structure de donnée** n'en découle.

**Invariant à documenter et à ne jamais casser** : tant que `S.penMode===true`, `S.actionPanel` est garanti non-null et porte le tireur en cours de désignation. Les deux passent à `false`/`null` **ensemble**, dans un seul et même appel (`validateAndClose()` en cas de validation finale, ou `closePenPanel()` en cas de fermeture explicite — §2). Ne jamais les faire diverger : c'est cet invariant qui évite tout état bâtard.

### 1.c — Réassignation du tireur (b) : zéro code nouveau

Puisque `S.actionPanel` reste non-null et que `shooterId` est déjà rempli, un tap sur un **autre** joueur du terrain passe directement dans la branche déjà existante de `clickActionPlayer()` :
```
} else if(ap.shooterId===playerId){ ap.shooterId=null; }
else { ap.shooterId=playerId; }
```
Rien à modifier ici — cette branche gère déjà exactement le cas "reassigner sans fermer l'encart" pour n'importe quel tir en cours. **Portée précisée (point non totalement tranché par le PRD/Visual)** : la réassignation par tap n'est possible que pendant la sous-étape "3 boutons d'issue" (avant que BUT/ARRÊT/HC ne soit tapé). Une fois l'issue choisie, le flux entre dans `renderShotCourt()` (grille de zone ou validation immédiate) — exactement le même comportement que pour un tir normal, où le terrain n'est de toute façon plus cliquable une fois `shotMode` actif (aucun marqueur `.cp-player` n'est rendu dans le bloc `shotMode` aujourd'hui, pénalty ou pas). Ce n'est donc pas une régression ni une incohérence nouvelle : le point où "on peut encore changer le tireur" s'arrête au même moment que pour n'importe quel tir, pénalty ou non. À faire valider explicitement par le QA/Risk Analyst puisque le PRD dit "avant validation" sans preciser si "validation" inclut la présélection d'issue — je tranche que non, pour rester cohérent avec le comportement déjà existant du reste de l'app plutôt que d'inventer une exception.

### 1.d — Les 3 boutons d'issue + réutilisation de `showGZ`/`clickGoalZone()` (c, d) — comble le vide fonctionnel

Nouvelle fonction, remplace l'ancienne conversion sur clic joueur (qui devient obsolète, voir "Impact sur l'existant") :

```
function choosePenOutcome(kind){          // kind: 'GOAL' | 'SAVE' | 'OFF'
  if(S.readOnly) return;
  const ap=S.actionPanel; if(!ap||!ap.shooterId) return;
  const penMap={GOAL:'PEN_GOAL',SAVE:'PEN_SAVE',OFF:'PEN_OFF'};
  ap.type=penMap[kind];
  ap.mapX=50; ap.mapY=85;                 // position fixe, comme aujourd'hui
  const act=ACTIONS[ap.type];
  if(!S.trackGK || act.isOff){
    validateAndClose();                   // validation immédiate — même règle que pour un tir normal
  }
  R();
}
```
Bindée sur un nouvel attribut `data-pen-outcome="GOAL|SAVE|OFF"` (les 3 boutons `.ap-pen-btn` de la spec Visual), dans `bind()` juste après le bloc `[data-ap-player]` (~ligne 3827) :
```
document.querySelectorAll("[data-pen-outcome]").forEach(el=>{ el.onclick=()=>choosePenOutcome(el.dataset.penOutcome); });
```

**C'est ici précisément que le bug de synchronicité est corrigé** : contrairement à l'ancien code (qui appelait `validateAndClose()` inconditionnellement dès la conversion, ligne 676, avant que la grille n'ait la moindre chance de s'afficher), `choosePenOutcome()` ne valide immédiatement que si `!S.trackGK || act.isOff` — **exactement** la même condition que celle déjà utilisée par `clickCourtPosition()` pour les tirs normaux (ligne 719 : `if(!S.trackGK || act.isOff){ validateAndClose(); }`). Si `S.trackGK` est actif et que BUT/ARRÊT est choisi, on ne valide pas : on relâche le rendu (`R()`), et `renderMatchPanel()` (via la fonction extraite `renderShotCourt(ap,act)`, §"Décision technique globale") calcule `showGZ=S.trackGK&&ap.mapX!=null&&!act.isOff` → **true**, puisque `ap.mapX` vaut déjà 50. La grille de zone s'affiche, **sans modification de `clickGoalZone()`** — la grille appelle cette fonction exactement comme pour un tir normal, et `clickGoalZone()` valide déjà elle-même dès qu'une zone est tapée (ligne 706-708, condition `S.trackGK && ap.shooterId && (act.isGoal||act.isSave||act.isOff)`). `goalZone` est donc réellement enregistré : le vide fonctionnel identifié par le Brief est comblé sans toucher une seule ligne de `clickGoalZone()`.

**`S.penMode` doit repasser à `false` au moment exact où l'événement final est créé** — pas avant, pas après, et à un seul endroit pour ne pas le disperser sur 3 chemins d'appel (validation immédiate dans `choosePenOutcome()`, validation via `clickGoalZone()`, et — en théorie — validation via un futur chemin non encore écrit). Décision : centraliser dans `validateAndClose()` lui-même, à la toute fin, avant de nuller `S.actionPanel` :
```
if(act && act.isPen && (act.isGoal||act.isSave||act.isOff)) S.penMode=false;
```
Cette ligne unique couvre les 3 issues (BUT/ARRÊT/HORS CADRE) et les 2 chemins de validation (immédiate ou via zone), sans qu'aucun appelant n'ait à s'en souvenir individuellement. Elle est inoffensive pendant une **édition** d'un PEN_GOAL/SAVE existant depuis le feed (`editEvent()`, §"Impact sur l'existant") : `S.penMode` y vaut déjà `false` (l'édition ne le met jamais à `true`), la remettre à `false` est un no-op.

**Garde défensive à ajouter dans `validateAndClose()`** (et par cohérence dans `autoValidatePending()`) : `const act = ACTIONS[ap.type]; if(!act) return;` juste après le calcul de `act`. Elle protège contre le seul scénario qui ferait planter l'app (voir §2) : `ap.type` vaut `null` pendant la sous-étape "3 boutons" (avant que `choosePenOutcome()` ne soit appelé), et `act.isGoal` sur `undefined` lèverait une exception si `validateAndClose()` était invoqué à ce moment précis. Coût : une ligne. Bénéfice : élimine un crash silencieux si un futur appelant (aujourd'hui inexistant grâce à §2) venait à réutiliser ce chemin sans le savoir.

### `renderMatchPanel()` — nouvelle branche prioritaire, extraction de `renderShotCourt()`

```
function renderMatchPanel(){
  const ap=S.actionPanel;
  ...
  if(S.penMode && ap){ return renderPenaltyPanel(ap); }   // NOUVEAU — avant tout calcul de statusHtml
  ... (shotMode / default, inchangés) ...
}

function renderShotCourt(ap, act){
  // EXTRACTION PURE de l'actuel bloc <div class="court-pick">...</div> (lignes ~1645-1657)
  // Aucune logique changée pour les types non-pen.
  // Un seul ajout : le bouton "↩ Modifier la position" ne s'affiche que si !act.isPen (voir note Visual Crafter §7).
}

function renderPenaltyPanel(ap){
  const act = ap.type ? ACTIONS[ap.type] : null;
  const shooter = ap.shooterId ? S[ap.team].players.find(p=>p.id===ap.shooterId) : null;
  const headHtml = `<div class="ap-pen-panel">
    <button class="ap-pen-close" data-pen-close>✕ Fermer</button>
    <div class="ap-pen-head">
      <span class="ap-mode-badge-pen">🎯 MODE PENALTY</span>
      ${shooter?`<span class="ap-badge ap-badge-pen"><span class="dot"></span>#${shooter.number||""} ${shooter.name}</span>`:""}
    </div>
    ${!act ? renderPenOutcomeButtons() : ""}
  </div>`;
  const bodyHtml = !act ? renderPenRoster(ap) : renderShotCourt(ap, act);
  return `<div style="margin-top:2px;">${headHtml}${bodyHtml}</div>`;
}
```

`renderPenOutcomeButtons()` produit les 3 `.ap-pen-btn` (markup déjà entièrement spécifié par le Visual Crafter §6). `renderPenRoster(ap)` reprend la boucle `positioned.map(...)` déjà existante dans la branche "DEFAULT" (lignes 1666-1674), avec la classe conditionnelle `p.id===ap.shooterId?"pen-shooter":"pen-other"` au lieu de `isSh?"shooter":""` — extraction optionnelle, pas structurante (contrairement à `renderShotCourt`, qui elle est obligatoire pour éviter la divergence entre les deux chemins de grille).

**Pourquoi `renderShotCourt()` est non-négociable et `renderPenRoster()` ne l'est pas** : la grille de zone (`renderShotCourt`) est le composant dont la fidélité au comportement existant conditionne directement la correction des données (`goalZone` bien enregistré) — toute divergence entre les deux copies serait le même type de bug que celui qu'on corrige. Le rendu du roster, lui, ne produit aucune donnée — une petite duplication de template n'a aucun impact fonctionnel, seulement esthétique/maintenance.

### Nettoyage requis : suppression de l'ancienne branche de conversion

Une fois ce qui précède en place, la branche `clickActionPlayer()` lignes 671-679 (`if(S.penMode && (act.isGoal||act.isSave||act.isOff)){...}`) devient **totalement inatteignable** : elle ne s'exécutait que lorsque `S.actionPanel` était `null` au moment du clic ET que `S.penMode` était `true` — un état qui ne peut plus se produire puisque `S.actionPanel` est désormais repeuplé immédiatement après le PO (§1.b) et que la barre d'actions est verrouillée pendant ce laps de temps (§2). **Décision : la supprimer**, pas la garder en filet — du code mort qui ressemble à un chemin actif est plus dangereux qu'utile pour un futur mainteneur (il pourrait croire que c'est toujours ainsi que la conversion se fait).

## 2. Verrouillage de la barre d'actions pendant `S.penMode` — nécessaire, pas optionnel

**Risque identifié en traçant le code, absent du PRD/Visual** : `selectAction(type)` (615-622) et `clickTeam(team)` (625-657) appellent tous deux `autoValidatePending()` en premier geste. Tant que `S.actionPanel` reste non-null pendant la sous-étape "3 boutons" (`ap.type===null`), un tap sur **n'importe quel bouton de `.ml-actions`** (GOAL, PB, JF...) déclenche `autoValidatePending()` → `validateAndClose()` → `ACTIONS[null].isGoal` → **exception JS, rendu cassé**. C'est un risque réel introduit par le nouveau design (repeupler `S.actionPanel` en continu), pas un risque préexistant.

**Décision : verrouiller `selectAction()`** avec une garde `if(S.penMode) return;` juste après `if(S.readOnly) return;`. Conséquence directe et voulue : tant que l'encart pénalty est ouvert, la barre d'actions ne répond plus à aucun tap — cohérent avec l'objectif même du PRD ("sans que Romain ait à remonter son regard vers la barre d'actions"), et cela ferme le risque de crash à la source plutôt que de le contourner avec un simple garde-fou défensif. `clickTeam()` n'a pas besoin de sa propre garde : elle n'est atteignable que si `S.selectedAction` est déjà défini, ce qui ne peut plus arriver pendant `S.penMode` puisque `selectAction()` ne le modifie plus dans cette fenêtre — mais l'ajouter par symétrie/défense en profondeur ne coûte rien et est recommandé.

**Conséquence visuelle à prévoir (non couverte par le Visual Crafter, signalée ici car fonctionnellement nécessaire)** : sans indication visuelle, Romain pourrait taper un bouton de `.ml-actions` qui ne réagit plus, sans comprendre pourquoi. Recommandation : appliquer le même traitement que `.match-layout.is-readonly .act-h` (`opacity:.35;pointer-events:none`, déjà défini `style.css` 409-420) à `.ml-actions` quand `S.penMode` est actif — même pattern visuel déjà connu de Romain (mode lecteur), pas un nouveau vocabulaire à apprendre. Détail d'implémentation laissé au Developer ; la garde JS (`selectAction()`) est la partie non-négociable, le traitement visuel est une recommandation forte mais pas bloquante.

## 3. Le bouton "✕ Fermer" — état exact

```
function closePenPanel(){
  if(S.readOnly) return;
  S.actionPanel=null;
  S.selectedAction=null;
  S.penMode=false;
  R();
}
```
Bindé sur `data-pen-close` (nouvel attribut sur `.ap-pen-close`), fonctionne **identiquement** dans les deux sous-étapes (3 boutons, ou grille de zone déjà affichée après un premier choix BUT/ARRÊT) : puisque `validateAndClose()` n'a encore jamais été appelé à ce stade (aucune issue n'a été validée), **aucun événement PEN_GOAL/PEN_SAVE/PEN_OFF n'existe** — il n'y a donc rien à supprimer de ce côté. Le PEN_OBT, lui, a été enregistré dès le premier clic (§1.a) et n'est **jamais touché** par cette fonction — `S.events` n'apparaît nulle part dans son corps. C'est exactement la même logique que le `✕` générique déjà présent ligne 1636 (`onclick="S.actionPanel=null;S.selectedAction=null;S.penMode=false;R();"`) — on lui donne juste un nom de fonction et un style dédié (`.ap-pen-close`, déjà entièrement spécifié par le Visual Crafter §5), pas une nouvelle logique.

`if(S.readOnly) return;` en tête, par convention (`CLAUDE.md`), même si en pratique cette fonction n'est déjà atteignable que si `S.penMode` est vrai, ce qui ne peut arriver sur un appareil lecteur puisque `clickActionPlayer()` (le seul point d'entrée qui peut faire passer `S.penMode` à `true`) est lui-même gardé par `if(S.readOnly) return;` dès sa première ligne. La garde est donc redondante aujourd'hui mais reste requise par la convention du projet (robustesse face à un futur refactor qui romprait cette garantie).

## 4. Le badge "MODE PENALTY" dans `.ml-status`

Suppression pure et simple de la branche `S.penMode` dans le bloc `.ml-status` (`app.js` 1836-1840) :
```
${S.penMode||lastEvHtml?`<div class="ml-status">
  ${S.penMode?`<span ...>🎯 MODE PENALTY</span>`:""}
  ${lastEvHtml}
</div>`:""}
```
devient :
```
${lastEvHtml?`<div class="ml-status">${lastEvHtml}</div>`:""}
```
Pas une condition à affiner ("afficher le badge seulement si l'encart n'est pas affiché") — **l'invariant établi en §1.b garantit que `S.penMode===true` implique toujours que l'encart est affiché** (ils partagent le même cycle de vie, voir §1.b). Il n'existe donc aucun état où le badge autonome aurait une raison d'apparaître : sa condition d'affichage et celle de l'encart sont rigoureusement identiques depuis le début, la solution la plus simple est de ne plus jamais le construire à cet endroit, pas d'ajouter une deuxième condition qui recalculerait la même chose. Le texte/style exact (`🎯 MODE PENALTY`, mêmes couleurs) est simplement déplacé tel quel dans `.ap-pen-head` via `.ap-mode-badge-pen`, conformément à la spec Visual §2.2 — copier-coller du style inline existant vers une classe, aucune nouvelle couleur.

## 5. Protection défensive `renderGkSheet()` / `goalZoneHeatmap()`

Emplacement exact vérifié : `app.js` ligne 3038, dans `renderGkSheet(side)` :
```
const allShots = S.events.filter(e=>e.team===oppSide && (ACTIONS[e.type].needsMap) && e.x!=null && gkIds.includes(e.gkId));
```
devient :
```
const allShots = S.events.filter(e=>e.team===oppSide && (ACTIONS[e.type].needsMap) && !ACTIONS[e.type].isPen && e.x!=null && gkIds.includes(e.gkId));
```
Une seule condition ajoutée, sur la ligne qui définit `allShots` — **rien d'autre ne change** dans `renderGkSheet()`. Cette unique variable alimente en cascade tout ce qui doit être protégé : `goalZoneHeatmap(allShots,"88%")` (ligne 3050, la heatmap 3×3), et les compteurs `goals`/`saves`/`offs` affichés sous le terrain SVG (lignes 3045-3047) qui, eux, **incluent déjà aujourd'hui les tirs pénalty** (leur `x` vaut déjà 50 dès la conversion, indépendamment de `S.trackGK` — vérifié ligne 675 du code actuel) — ce filtre corrige donc au passage une incohérence déjà présente en production entre ces compteurs et les chiffres du haut de colonne (`gk.goals`/`gk.saves`/`gk.offs`, eux calculés via `gkStats()`/`gkStatsCombined()` qui excluent déjà `isPen`, ligne 1018-1020). Effet : après ce correctif, les pénaltys disparaissent des pastilles "ENCAISSÉS/ARRÊTÉS/H. CADRE" et des points sur le terrain SVG de `renderGkSheet()`, en plus de rester exclus de la heatmap — cohérent de bout en bout avec les chiffres du haut, et exactement ce que demande le PRD (décision #5, Must Have #7).

**Ne pas confondre avec** `teamShots(team)` (ligne 1056, utilisée uniquement par `renderShotOverlay()`, le flux legacy 2min/carton rouge) — hors scope, non mentionnée par le PRD, non touchée.

## 6. Couleurs `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` — vérification d'impact

Recherche exhaustive de tous les points qui lisent `ACTIONS[x].color` dans `app.js` :
- `actBtn()` (ligne ~1751-1752, boutons de `.ml-actions`) : lit `a.color` mais uniquement pour les entrées de `ACTION_BUTTONS` (`['GOAL','SAVE','OFF','TURNOVER','PEN_OBT','FREEKICK']`, ligne 34) — **`PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` n'y figurent jamais** (ce sont des types dérivés, jamais sélectionnables directement dans la barre). Zéro impact.
- Fil d'événements en direct (`.feed-item`, ligne ~1880, `f-type`) et fil en lecture seule d'un match sauvegardé (ligne ~3283, même structure) : les deux lisent `a.color` **génériquement** depuis `ACTIONS[ev.type]` — c'est précisément l'endroit où "But Pen"/"Arrêt Pen" sont aujourd'hui indiscernables (même hex `#5FA8D3`), et où le correctif produit l'effet recherché sans code additionnel.
- Le terrain SVG et la heatmap de `renderGkSheet()` (§5 ci-dessus) utilisent déjà des hex **codés en dur** (`#4ECDE8`/`#50C878`/`#E89A4E`, lignes ~3059/1069-1072) — **indépendants de `ACTIONS[type].color`**, donc déjà alignés sur la palette `--gk-*` avant même ce changement, et non affectés par lui.
- Toutes les autres occurrences de `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` dans le fichier (`gkStats()`, `teamStat()`, agrégats saison, export PDF — lignes 1021-1023, 2795, 3120-3122, 3348-3350, 4134) comparent des **chaînes de type**, jamais `.color` — aucune de ces lectures n'est affectée par le changement de couleur.

**Conclusion : le remplacement `var(--green)`/`var(--blue)`/`var(--orange)` → `var(--gk-goal)`/`var(--gk-save)`/`var(--gk-off)` dans l'objet `ACTIONS` (lignes 25-27) est strictement isolé** — il ne peut affecter que l'affichage du label dans les deux fils d'événements (l'effet recherché), et l'encart lui-même (qui utilisera directement les tokens `--gk-*`, cf. spec Visual, sans passer par `ACTIONS[type].color`). Aucune régression possible ailleurs. Effet secondaire positif confirmé et bonus non demandé par le Visual Crafter : le fil en lecture seule d'un match historique (ligne 3283, utilisé dans l'écran Bilan/revue de match) bénéficie lui aussi de la correction de lisibilité, gratuitement.

## Impact sur l'existant

- `clickActionPlayer()` : restructurée (§1.b/1.d) — branche PEN_OBT modifiée (repeuple `S.actionPanel`), ancienne branche de conversion (671-679) **supprimée** (code mort après le changement). Le reste (sélection de tireur pour un tir normal, réassignation) **inchangé**.
- `validateAndClose()` : deux ajouts (garde défensive `if(!act) return;`, et `S.penMode=false` centralisé quand `act.isPen`). Comportement pour tous les types non-pen **strictement inchangé**.
- `autoValidatePending()` : garde défensive symétrique (`ap.type && ACTIONS[ap.type]`), même raison.
- `selectAction()` : une garde ajoutée (`if(S.penMode) return;`). Comportement hors `S.penMode` **inchangé**.
- `clickGoalZone()`, `clickCourtPosition()` : **aucune modification** — réutilisées telles quelles, conformément à la dépendance #6 du PRD.
- `editEvent()` : **aucune modification**. Puisqu'elle ne met jamais `S.penMode` à `true`, le nouveau branchement prioritaire de `renderMatchPanel()` (`if(S.penMode && ap)`) ne l'intercepte jamais — le chemin d'édition d'un PEN_GOAL/PEN_SAVE existant continue de passer par le `shotMode` générique, exactement comme aujourd'hui. Effet de bord positif mineur : le bouton "↩ Modifier la position" (§ ci-dessous) sera désormais masqué aussi en édition d'un événement pénalty — cohérence renforcée, pas une régression (ce bouton n'avait de toute façon aucun sens pour une position fixe).
- `renderMatchPanel()` : une branche ajoutée en tête (`if(S.penMode && ap)`), une extraction (`renderShotCourt()`) du bloc `court-pick` du `shotMode` existant — bloc **byte-pour-byte identique** pour tout type non-pen, plus une condition supplémentaire (`!act.isPen`) pour masquer "↩ Modifier la position".
- Badge `.ml-status` : une branche supprimée (§4), déplacée dans l'encart.
- `renderGkSheet()` : une condition ajoutée sur une seule ligne (§5). Rien d'autre.
- `ACTIONS.PEN_GOAL/PEN_SAVE/PEN_OFF.color` : 3 valeurs changées (§6), impact vérifié strictement isolé.
- `style.css` : ajout de `.ap-pen-panel`, `.ap-pen-head`, `.ap-mode-badge-pen`, `.ap-badge-pen`, `.cp-player.pen-shooter`, `.cp-player.pen-other`, `.ap-pen-close`, `.ap-pen-actions`, `.ap-pen-btn`, `@keyframes penShooterPulse` (déjà entièrement spécifiées par le Visual Crafter, aucune décision technique supplémentaire requise ici) + extension de la liste `.match-layout.is-readonly` (409-420) avec `.ap-pen-panel` et `[data-ap-player]` — cette dernière addition dimme visuellement **tous** les marqueurs joueurs du terrain en mode lecteur (pas seulement pendant un pénalty), comblant au passage un petit trou visuel préexistant (le terrain n'était pas dans cette liste) sans risque, puisque `clickActionPlayer()` bloque déjà l'écriture correspondante par `if(S.readOnly) return;`.
- Aucun changement de `S.gkFilter`, `gkStats()`, `gkStatsCombined()`, structure d'événement, schéma Supabase.

## Nouvelles structures de données

Aucune. `S.actionPanel` garde exactement la forme documentée dans `freshState()` — seul `type` peut transitoirement valoir `null` en mémoire, jamais persisté dans `S.events` ni synchronisé vers Supabase (`queueEventForSync()` n'est appelé que depuis `validateAndClose()`/`validateActionPanel()`, jamais pendant la phase de sélection d'issue).

## Nouvelles fonctions / modules

- `choosePenOutcome(kind)` — enregistre l'issue choisie sur `S.actionPanel`, position fixe, validation immédiate si pas de suivi GB ou HORS CADRE (§1.d).
- `closePenPanel()` — sortie explicite sans écriture d'événement (§3).
- `renderPenaltyPanel(ap)` — nouvelle fonction de rendu, orchestre les deux sous-étapes (3 boutons / grille de zone) de l'encart.
- `renderShotCourt(ap, act)` — **extraction obligatoire** (pas une option) du bloc terrain+grille déjà existant dans `shotMode`, partagée entre le chemin normal (tir hors pénalty, inchangé) et le nouvel encart. Point d'ajout unique pour masquer "↩ Modifier la position" quand `act.isPen`.
- `renderPenOutcomeButtons()` / `renderPenRoster(ap)` — extractions mineures, optionnelles (pas structurantes, cf. §"pourquoi renderShotCourt est non-négociable et renderPenRoster ne l'est pas").
- Pas de nouveau fichier JS, pas de découpage d'`app.js` — hors de proportion avec l'ampleur du changement (cf. critère de bascule).

## Risques (vue technique)

- **Risque de crash identifié pendant l'analyse, absent du PRD/Risk brief initial** : sans la garde `if(S.penMode) return;` dans `selectAction()` (§2), un tap sur `.ml-actions` pendant la sous-étape "3 boutons" ferait planter le rendu (`ACTIONS[null].isGoal`). Ce n'est pas théorique : la barre reste visuellement présente à l'écran pendant tout l'encart, rien n'empêche Romain de la taper par réflexe. **Cette garde est la mitigation principale, pas la garde défensive dans `validateAndClose()` — cette dernière n'est qu'un filet de sécurité secondaire.** Le Risk Analyst doit vérifier explicitement que le Developer a bien implémenté les deux (verrou + filet), pas seulement l'un des deux.
- **Divergence entre les deux copies de la grille de zone si `renderShotCourt()` n'est pas réellement extrait** (si le Developer duplique le bloc au lieu de le factoriser) : reproduirait à terme le même type de bug que celui qu'on corrige aujourd'hui, mais silencieusement, le jour où quelqu'un modifiera un des deux chemins sans penser à l'autre. Test explicite recommandé au Code Reviewer : vérifier qu'il n'existe qu'une seule définition de ce bloc dans le fichier.
- **Régression silencieuse sur Stats → Gardiens si le filtre `isPen` (§5) est oublié** : déjà signalée par le PRD/PM, confirmée exacte après lecture du code — `allShots` est déjà non filtré aujourd'hui, la seule chose qui empêche un changement de chiffres pour l'instant est que `goalZone` est toujours `null` pour les pénaltys (donc ignoré par le bucketing de la heatmap). Dès que ce cycle capture un `goalZone` réel, cette protection devient active immédiatement — un test de non-régression doit comparer les chiffres de `renderGkSheet()` avant/après sur un jeu de données incluant au moins un penalty avec zone capturée.
- **Confusion sortie vs annulation** : mitigée par construction — `closePenPanel()` et `undoLast()` n'ont aucune ligne de code en commun (l'un ne touche jamais `S.events`, l'autre ne fait que ça) ; seule la distinction **visuelle** (déjà spécifiée par le Visual Crafter) reste à vérifier par QA.
- **Reassignation limitée à la sous-étape "3 boutons"** (§1.c, ma clarification de portée) : à faire valider explicitement par Romain en conditions réelles — si dans la pratique il a besoin de changer le tireur *après* avoir tapé BUT/ARRÊT mais *avant* de taper la zone, ce serait un fast-follow ciblé (élargir la fenêtre de réassignation), pas une remise en cause de cette architecture.
- Aucun risque identifié côté données/sync (Supabase, IndexedDB) — cette feature ne crée aucun nouveau champ ni nouvelle table, `queueEventForSync()` n'est appelée qu'aux mêmes points qu'aujourd'hui (dans `validateAndClose()`).

## Critère de bascule

`app.js` reste un fichier unique. Cette feature ajoute 3 fonctions (`choosePenOutcome`, `closePenPanel`, `renderPenaltyPanel`), en extrait une (`renderShotCourt`, pure extraction sans changement de logique pour les types non-pen), et modifie 4 fonctions existantes de quelques lignes chacune (`clickActionPlayer`, `validateAndClose`, `autoValidatePending`, `selectAction`). Aucun changement d'organisation générale du fichier, aucun nouveau module. Le jour où l'écran Match accumulerait plusieurs encarts contextuels de ce type (pas seulement le pénalty — par exemple un futur encart pour un autre cas spécial du jeu), ce serait le signal pour extraire un mécanisme générique de "panneau de saisie contextuel sur le terrain" plutôt que d'empiler des branches `if(S.xxxMode && ap)` dans `renderMatchPanel()` une par une — pas justifié par cette seule feature.
