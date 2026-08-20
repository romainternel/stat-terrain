# Architecture — Grille DC sur le terrain + Raccourcis en-tête

## F1 — Disposition en grille pour DC

### Décision technique
1. **`POS_XY.DC`** (`app.js:48`) reçoit un `spread:"grid"` avec des pas propres à sa position (pas les valeurs de PVT, qui ne conviennent pas à sa marge verticale réduite) :
```javascript
DC: {x:50, y:88, spread:"grid", hSpread:30, vSpread:10}, // centré, en retrait derrière l'alignement ARG/ARD — pas propres (hSpread/vSpread) plus resserres que PVT, marge verticale reduite a cette position basse du terrain
```

2. **`courtPlayerPositions()`** (`app.js:2781`), branche `spread==="grid"` — ajouter une disposition dédiée pour 5 joueurs dans l'objet `layouts` existant (aujourd'hui seulement 2/3/4), **3 en rangée haute, 2 en rangée basse** (symétrique, la plus compacte verticalement pour ce compte) :
```javascript
const layouts={
  2:[{dx:-hStep/2,dy:0},{dx:hStep/2,dy:0}],
  3:[{dx:0,dy:-vStep/2},{dx:-hStep/2,dy:vStep/2},{dx:hStep/2,dy:vStep/2}],
  4:[{dx:-hStep/2,dy:-vStep/2},{dx:hStep/2,dy:-vStep/2},{dx:-hStep/2,dy:vStep/2},{dx:hStep/2,dy:vStep/2}],
  5:[{dx:-hStep,dy:-vStep/2},{dx:0,dy:-vStep/2},{dx:hStep,dy:-vStep/2},
     {dx:-hStep/2,dy:vStep/2},{dx:hStep/2,dy:vStep/2}],
};
```
Aucune autre ligne de `courtPlayerPositions()` à toucher — `hStep`/`vStep` sont déjà calculés au-dessus (`base.hSpread||26, base.vSpread||13`) et donc déjà les valeurs propres à DC (30/10) grâce au point 1.

### Vérification des bornes (calcul, pas supposition)
Avec `y:88`, `vStep:10` : rangée haute à `88-5=83`, rangée basse à `88+5=93` — toutes deux dans `[4,96]` (le clamp existant), aucune collision avec le plafond. `83` reste sous la ligne ARG/ARD (`y:76`), pas de chevauchement visuel avec ces deux postes. Avec `hStep:30` : rangée haute à `50±30` (`20`/`80`) et `50` — tous dans `[6,94]`. Cas à 1/2/3/4 joueurs DC : réutilisent les layouts déjà existants (2/3/4) ou le centre seul (1), avec les nouveaux pas 30/10 — vérifié que le cas 3 (`dy:±5`) et le cas 4 (`dy:±5`) restent également dans les bornes.

### Pourquoi (alternatives rejetées)
- **Réutiliser tel quel le fallback générique "2 par rangée"** (déjà codé pour 5+ joueurs sans layout dédié) : rejeté — produirait 3 rangées (2/2/1) pour 5 joueurs, plus haut verticalement que la marge disponible à cette position ; le layout dédié 3+2 (2 rangées) tient mieux dans l'espace réel.
- **Réutiliser les pas de PVT (26/13)** : rejeté — testés par le calcul ci-dessus, `vStep:13` sur 2 rangées donnerait `88±6.5` = `81.5`/`94.5`, encore dans les bornes en réalité, mais avec moins de marge de sécurité qu'avec `10` ; `hSpread:30` (vs 26 de PVT) profite de la place horizontale disponible en plus pour compenser des noms de joueurs plus longs à cette densité.
- **Déplacer le `y` de base de DC** (ex. `88`→`84`) plutôt que de resserrer `vSpread` : rejeté — changerait la position visuelle de DC même à 1 seul joueur sélectionné (déjà correcte aujourd'hui, pas de raison de la déplacer), alors que resserrer `vSpread` ne change rien au cas à 1 joueur (`layout` à 1 élément ignore `vSpread`).

### Impact sur l'existant
- Aucun autre poste touché (`ALG`/`ARG`/`ARD`/`ALD`/`GB` gardent leur config actuelle, `PVT` garde `26/13`).
- Tous les écrans qui appellent `courtPlayerPositions()` (Match Mode Expert `app.js:2005`, sélecteur PD `:2099`, sélecteur 2min/carton `:2581`, un 4e site `:2850`) héritent automatiquement du correctif — aucun de ces sites n'a besoin d'être modifié individuellement.

### Nouvelles structures de données
Aucune.

---

## F2 — Raccourcis Mode et Suivi GB dans l'en-tête

### Décision technique
`renderHeader()` (`app.js:1893`) : ajouter un groupe `.hdr-shortcuts` juste après `.logo`, **toujours affiché** (pas conditionné par `inLiveMatch`, contrairement à `#settings-btn`) :
```javascript
function renderHeader(){
  const views=[...]; // inchangé
  const inLiveMatch=...; // inchangé
  const showWarnDot=...; // inchangé
  const showAlertDot=...; // inchangé
  return `<div class="hdr">
    <div class="logo" id="home-logo-btn" ...>...</div>
    <div class="hdr-shortcuts">
      <button id="hdr-mode-btn" class="btn btn-xs hdr-shortcut" title="${S.mode==="simple"?"Mode Simple actif — tap pour passer en Expert":"Mode Expert actif — tap pour passer en Simple"}">${S.mode==="simple"?"⚡":"🎯"}</button>
      <button id="hdr-trackgk-btn" class="btn btn-xs hdr-shortcut-gk ${S.trackGK?"on":""}" title="Suivi gardien">🧤<span class="hdr-shortcut-label">${S.trackGK?" ON":" OFF"}</span></button>
    </div>
    ${inLiveMatch?`<button id="settings-btn" class="btn btn-sm" style="border-color:var(--border);color:var(--t2);white-space:nowrap;">⚙ Réglages</button>${showWarnDot?`...`:""}${showAlertDot?`...`:""}`:""}
    <div class="nav">...</div>
  </div>`;
}
```
**Changement important** : `margin-left:auto` retiré du style inline de `#settings-btn` et déplacé sur `.hdr-shortcuts` (CSS, voir `docs/visual/dc-grid-et-raccourcis-header.md`) — c'est désormais `.hdr-shortcuts`, toujours présent, qui crée l'écart avec le logo par la technique de la marge automatique flex ; `#settings-btn` et les pastilles qui le suivent n'ont plus besoin de leur propre marge automatique, ils suivent simplement `.hdr-shortcuts` dans le flux (`gap` du conteneur `.hdr` déjà en place). Sans ce changement, avoir DEUX marges automatiques dans la même ligne flex (une sur `.hdr-shortcuts`, une sur `#settings-btn`) pousserait `#settings-btn` bien plus loin de `.hdr-shortcuts` que voulu (chaque marge automatique absorbe l'espace libre indépendamment).

Binding (`bind()`, à côté des autres handlers d'en-tête) :
```javascript
const hdrMode=document.getElementById("hdr-mode-btn");
if(hdrMode) hdrMode.onclick=()=>setMode(S.mode==="simple"?"expert":"simple");
const hdrGk=document.getElementById("hdr-trackgk-btn");
if(hdrGk) hdrGk.onclick=()=>{S.trackGK=!S.trackGK;R();};
```
Réutilise `setMode()` telle quelle — la confirmation bloquante (Expert→Simple avec événements déjà saisis) se déclenche automatiquement, aucune logique dupliquée.

### Pourquoi (alternatives rejetées)
- **Dupliquer `S.trackGK=!S.trackGK;R();` inline dans le HTML** (`onclick="..."`, comme les 2 sites existants) : rejeté pour ce nouveau site précisément — les 2 sites existants sont un pattern plus ancien pas forcément à reproduire une 3e fois ; un binding classique dans `bind()` reste cohérent avec la majorité des handlers du fichier (dont tous ceux ajoutés lors des cycles récents, STORY-62 à 66).
- **Un seul bouton combiné Mode+GB** (ex. un menu déroulant) : rejeté — Romain a explicitly demandé "en raccourci", donc un tap direct sans sous-menu ; deux boutons séparés restent plus rapides d'accès qu'un menu à ouvrir puis choisir.

### Impact sur l'existant
- `renderModeToggle()` (Équipes) et les 2 toggles `trackGK` existants (Équipes, Réglages match) restent strictement inchangés — mêmes `S.mode`/`S.trackGK`, donc automatiquement synchronisés avec les nouveaux raccourcis (pas une copie d'état).
- `.hdr{justify-content:space-between}` : avec `.hdr-shortcuts` toujours présent et portant désormais la marge automatique, le comportement à 2 "groupes" (logo | reste) reste identique dans tous les cas (avec ou sans `#settings-btn` visible) — pas de changement visuel sur les écrans qui n'affichaient déjà que logo+nav.
- Écran d'accès et écran de choix de profil : `renderHeader()` n'y est pas appelée aujourd'hui (vérifié par lecture) — les raccourcis n'y apparaissent donc pas, cohérent avec l'absence de sens à changer de mode avant même d'avoir choisi une équipe.

### Nouvelles structures de données
Aucune — réutilise `S.mode`/`S.trackGK` déjà existants.

## Critère de bascule
Si un jour l'en-tête accueille un 3e raccourci, le pattern `.hdr-shortcuts` (groupe `flex` avec une seule marge automatique en tête) reste valable tel quel — ajouter un bouton de plus dans ce conteneur, aucune refonte de layout nécessaire.
