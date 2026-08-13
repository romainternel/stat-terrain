# Architecture — Visualisation "zones sur le terrain" + tableau Joueurs PDF

## F2 — Géométrie des zones (fondation partagée SVG + PDF)

**Modèle final validé par Romain via un prototype visuel réel (SVG interactif, 8 itérations) avant tout code applicatif** — remplace complètement le modèle initial à 7 zones (PVT/AILG/AILD/9MG/9MC/9MD/AUTRE) de la première version de cette page. Le prototype a permis de détecter et corriger plusieurs erreurs géométriques et de calibrer les tailles avant d'écrire une seule ligne de code applicatif — cf. artefact de validation partagé avec Romain (8 révisions).

### Constantes réutilisées (déjà en place, ne pas redéfinir)
`postL=148.75, postR=201.25, R6=105, R9=157.5` (viewBox 350×208, but en haut) — exactement celles de `courtSvgMarkup()`/`drawHandballZone()`.

### 8 zones de terrain + 2 marqueurs hors-terrain
`AilG, 6mG, 6mC, 6mD, AilD` (rang proche du but), `9mG, 9mC, 9mD` (au-delà de la ligne des 9m) — **6mG/6mC/6mD couvrent tout depuis la ligne de but jusqu'à la ligne des 9m** (le vrai cercle des 6m n'est plus une zone séparée, juste un repère visuel dedans), c'est la convention "tir de 6m" au sens coach validée par Romain. Plus `7m` (marqueur pénalty, pas une zone de terrain) et `Sans GB` (marqueur cage vide/contre-attaque — **nécessite une nouvelle capture en direct, hors scope de STORY-43/44/45**, cf. section dédiée plus bas).

### Constantes de calibrage (issues du prototype validé, ne pas re-deviner)
```js
const AY=56, AX=88; // portee des ailes AilG/AilD (viewBox 350x208) — validees Romain
const centerHalfW = postR-postL; // 52.5 -> colonne centrale doublee et centree sur l'axe (175)
const splitL = 175-centerHalfW, splitR = 175+centerHalfW; // 122.5 / 227.5
```
La largeur de la colonne centrale (6mC/9mC) n'est **pas** celle du but (`postL`/`postR`) mais volontairement doublée et centrée sur l'axe (175) — retour explicite de Romain, à ne pas "corriger" vers la largeur du but qui semblerait plus logique au premier abord.

### Classification d'un point en zone
```js
function shotZoneCourt(xPct, yPct){
  const X=xPct/100*350, Y=yPct/100*208;
  const postL=148.75, postR=201.25, R9=157.5;
  const AY=56, AX=88;
  const centerHalfW=postR-postL, splitL=175-centerHalfW, splitR=175+centerHalfW;
  if(Y<=0) return X<AX?"AILG":(X>350-AX?"AILD":"6MC");
  if(X<AX && Y < AY*(1-X/AX)) return "AILG";
  if(X>350-AX && Y < AY*(1-(350-X)/AX)) return "AILD";
  if(X>=splitL && X<=splitR){
    let boundary;
    if(X>=postL && X<=postR) boundary=R9;
    else { const post=X<postL?postL:postR, dx=Math.abs(X-post); boundary=Math.sqrt(Math.max(0,R9*R9-dx*dx)); }
    return Y<boundary ? "6MC" : "9MC";
  }
  const post=X<splitL?postL:postR, dir=X<splitL?-1:1;
  const dx=Math.abs(X-post), r=Math.hypot(dx,Y);
  if(r<R9) return dir<0?"6MG":"6MD";
  return dir<0?"9MG":"9MD";
}
```
Remplace `shotOriginZone()` de STORY-40 (même rôle, même signature d'entrée `(xPct,yPct)`) — utilise la vraie géométrie d'arc plutôt que des bandes x/y approximatives. Note : les ailes (`AILG`/`AILD`) sont testées par un triangle simple (comparaison linéaire), pas par rayon/angle depuis le poteau — comportement volontaire, validé visuellement.

**Erreur de conception trouvée et corrigée via le prototype** (avant tout code applicatif) : une première version testait l'angle **avant** le rayon (`r<R6 → angle<WING_ANGLE ? aile : centre`), ce qui plaçait les ailes juste à côté des poteaux au lieu de près de la ligne de touche — la totalité du cercle des 6m est en fait **trop proche des poteaux** pour qu'un point de la ligne de touche y tombe (distance poteau→touche = 148.75 > R6 = 105). Le modèle validé ci-dessus évite ce piège en ne raisonnant plus du tout sur `R6` pour la classification (seul `R9` sert de frontière 6m/9m, la ligne des 6m réelle n'étant plus qu'un repère visuel).

### Génération des 8 polygones de zone (une fois, ne dépend d'aucune donnée de match)
```js
function buildCourtZones(){
  const VBW=350, VBH=208, postL=148.75, postR=201.25, R6=105, R9=157.5;
  const AY=56, AX=88;
  const toPct=(X,Y)=>({x:X/VBW*100, y:Y/VBH*100});
  function arcPoints(post, dir, radius, angleFrom, angleTo, steps=24){
    const pts=[];
    for(let i=0;i<=steps;i++){
      const a=(angleFrom+(angleTo-angleFrom)*i/steps)*Math.PI/180;
      const X=post+dir*radius*Math.cos(a), Y=radius*Math.sin(a);
      pts.push(toPct(X, Y));
    }
    return pts;
  }
  const touchAngle = Math.acos(postL/R9)*180/Math.PI; // angle ou l'arc 9m croise la touche (~19.15°)
  const touchY = R9*Math.sin(touchAngle*Math.PI/180);
  const farY = 205;
  const centerHalfW = postR-postL, splitL = 175-centerHalfW, splitR = 175+centerHalfW;
  function angleAtX(post, X, radius){ return Math.acos(Math.abs(post-X)/radius)*180/Math.PI; }
  const angleSplitL = angleAtX(postL, splitL, R9), angleSplitR = angleAtX(postR, splitR, R9);
  const ySplit = R9*Math.sin(angleSplitL*Math.PI/180);

  const z={};
  z.AILG = [toPct(0,0), toPct(0,AY), toPct(AX,0)];
  z.AILD = [toPct(VBW,0), toPct(VBW,AY), toPct(VBW-AX,0)];
  z['6MG'] = [toPct(AX,0),toPct(splitL,0),toPct(splitL,ySplit), ...arcPoints(postL,-1,R9,angleSplitL,touchAngle), toPct(0,AY)];
  z['6MC'] = [toPct(splitL,0),toPct(splitR,0), ...arcPoints(postR,1,R9,angleSplitR,90), toPct(postR,R9),toPct(postL,R9), ...arcPoints(postL,-1,R9,90,angleSplitL)];
  z['6MD'] = [toPct(VBW-AX,0),toPct(splitR,0),toPct(splitR,ySplit), ...arcPoints(postR,1,R9,angleSplitR,touchAngle), toPct(VBW,AY)];
  z['9MG'] = [toPct(0,touchY), ...arcPoints(postL,-1,R9,touchAngle,angleSplitL), toPct(splitL,farY),toPct(0,farY)];
  z['9MC'] = [toPct(splitL,ySplit), ...arcPoints(postL,-1,R9,angleSplitL,90), toPct(postL,R9),toPct(postR,R9), ...arcPoints(postR,1,R9,90,angleSplitR), toPct(splitR,ySplit),toPct(splitR,farY),toPct(splitL,farY)];
  z['9MD'] = [toPct(VBW,touchY), ...arcPoints(postR,1,R9,touchAngle,angleSplitR), toPct(splitR,farY),toPct(VBW,farY)];
  return z;
}
```
Points en **pourcentage (0-100)**, même repère que `S.events[].x/.y` — la conversion vers viewBox SVG (`×3.5, ×2.08`) ou coordonnées mm PDF (`×cw/100, ×ch/100`, comme `drawCourt()` le fait déjà pour les points) se fait au moment du rendu, pas dans `buildCourtZones()`. Calculée une seule fois (constante module-level ou mémoïsée), pas recalculée à chaque render. Vérifié par prototype visuel réel (rendu SVG, thème clair et sombre, 2 jeux de données d'exemple) : les 8 polygones tuilent le terrain sans trou ni chevauchement, y compris après 3 recalibrages de taille.

### Repères visuels du vrai terrain (obligatoires, pas juste décoratifs — retour explicite de Romain)
En plus des 8 polygones de zone, dessiner par-dessus, avec la couleur de ligne déjà utilisée (`var(--line)` / `[123,167,194]`) :
- **Ligne des 6m** (trait plein) : `arcPoints(postL,-1,R6,0,90)` + segment `(postR,R6)` + `arcPoints(postR,1,R6,90,0)` — même tracé que `drawHandballZone()`, pur repère (ne borne aucune zone).
- **Ligne des 9m** (pointillé) : déjà utilisée comme frontière `6m*/9m*`, à tracer explicitement aussi côté SVG app (elle ne l'était pas avant le prototype).
- **Marque des 4m** (retrait gardien) : petit trait `X:170→180, Y:70`.
- **Marque/marqueur 7m** : `X:168→182, Y:122.5` pour le trait ; le marqueur `7m` lui-même (badge rond avec ratio) est positionné à `{x:50, y:58.9}` en pourcentage — cf. section dédiée ci-dessous.

### Aucun code de zone affiché sur le terrain (retour explicite de Romain)
Contrairement à une première intuition, **ne pas** afficher "6mG"/"AilG"/etc. en texte dans chaque zone — seul le ratio `buts/tirs` (ex "5/9") apparaît dans l'espace de la zone, centré sur une position pré-calculée par zone (pas le centroïde géométrique brut, qui tombe mal sur les zones concaves/en arc — positions à définir à la main comme dans le prototype). Le nom des zones n'a besoin d'être écrit nulle part dans l'UI live (pas de légende non plus, contrairement au prototype qui en avait une pour l'explication) — la forme du terrain suffit à les identifier visuellement pour un coach.

### Marqueur 7m (pas une zone de terrain)
Position fixe au point de penalty déjà marqué visuellement (`courtSvgMarkup()` ligne 168-182, Y=122.5 viewBox) → `{x:50, y:58.9}` en pourcentage. Alimenté par un comptage séparé des événements `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` (déjà filtrable par `playerId`/`gkId` exactement comme les tirs de champ) — **jamais** par `x`/`y` (ces événements n'en capturent pas, l'origine d'un 7m est toujours le même point). Couleur dédiée (or/jaune, `--z-7m`), distincte des zones, pour bien marquer "ce n'est pas une zone de terrain".

### Marqueur "Sans GB" — HORS SCOPE de STORY-43/44/45, nécessite une nouvelle capture
Romain a confirmé (question posée explicitement) qu'un tir "sans gardien" (cage vide / contre-attaque) **n'est pas déductible des données actuelles** — ça suppose une nouvelle façon de le marquer pendant la saisie du tir en direct, pas juste un nouvel affichage. **Aucune story de ce lot ne couvre cette capture.** Ce que F2 doit prévoir : le marqueur `Sans GB` existe dans le modèle visuel (badge distinct, position fixe en bas du terrain, même famille que le marqueur 7m) mais **n'affichera jamais de ratio réel tant que la capture n'existe pas** — soit masqué si aucune donnée (`t===0`), soit affiché à "0/0"/vide selon ce que Design décide, sans bloquer la livraison de F2/F4/F5/F6/F7. Une story séparée, non cadrée ici, sera nécessaire pour la capture live.

### Rendu — une fonction de calcul, deux fonctions de dessin
`aggregateZones(shots)` : reçoit une liste de tirs `{x,y,goal}` (même format que déjà utilisé par `drawCourt()`/les points SVG existants), retourne `{AILG:{g,t}, "6MG":{g,t}, ...}` en appliquant `shotZoneCourt()` à chacun. Fonction pure, partagée SVG+PDF.
- **SVG** (`renderCourtZones(shots, penData)`) : génère les `<polygon points="...">` (conversion `%→viewBox`) + `<text>` du ratio à une position pré-calculée par zone (pas le centroïde), couleur de remplissage via `aggregateZones()`, plus le marqueur 7m et le marqueur Sans GB (vide pour l'instant) en surimpression, plus les repères visuels 6m/9m/4m/7m.
- **PDF** (`drawCourtZones(cx,cy,cw,ch,shots,penData)`) : même logique, `doc.lines()` (conversion `%→mm` comme `drawCourt()`) pour chaque polygone, `doc.text()` pour les ratios, mêmes repères visuels et marqueurs en surimpression.

## F3 — État global de bascule
```js
const savedShotView = localStorage.getItem("hb2_shotview");
S.shotViewMode = savedShotView === "zones" ? "zones" : "points"; // défaut points, comportement actuel préservé tant que Romain n'a pas basculé
function setShotViewMode(mode){ S.shotViewMode = mode; localStorage.setItem("hb2_shotview", mode); R(); }
```
Un seul composant HTML réutilisé aux 3 emplacements live (Joueurs/Gardiens/Comparaison) — pas de prop par écran, lit/écrit toujours `S.shotViewMode`.

## F4 — `renderPlayerDetail()` (~ligne 2485)
Le bloc `${shots.map(...)}` (points/croix SVG) devient conditionnel sur `S.shotViewMode` : `"points"` → comportement actuel inchangé, `"zones"` → `renderCourtZones(shots)`. La grille Impact (`pd-goalzone`, HG/HC/etc.) n'est pas touchée. Bouton de bascule ajouté dans l'en-tête de l'overlay, à côté du bouton "✕ Fermer".

## F5 — `renderGkSheet()` (~ligne 3179)
Même bascule sur le bloc SVG de `courtHtml` (`shots.map()`). `goalZoneHeatmap()` (grille Impact) non touchée. Bouton de bascule dans l'en-tête de la carte, à côté du sélecteur de GB.

## F6 — `renderStatCompare()` (~ligne 3106) — ajout net, révisé après retour Romain post-STORY-43
Nouveau bloc **entre `stats`+évolution du score et le bloc `posSvg` ("🎯 Tirs par poste")** — pas avant le tableau `stats` comme prévu initialement (placement corrigé sur retour direct de Romain). Deux mini-terrains (réutilisent `courtSvgMarkup()` + `renderCourtZones()`/points existants), un par équipe, agrégeant **tous** les tirs de l'équipe (`S.events.filter(e=>e.team===side&&(ACTIONS[e.type]?.isGoal||isSave||isOff)&&e.x!=null)`, même filtre que `posShots` juste en dessous utilise déjà). Même bouton de bascule (état partagé `S.shotViewMode`, pas de nouvel état local).

**En-tête de carte** : `Buts/Tirs` réutilise `hGoals`/`hTotal`/`aGoals`/`aTotal` déjà calculés en haut de `renderStatCompare()` pour la ligne "Buts/Tirs" du tableau `stats` — ne pas recalculer. `PB` réutilise `teamStat(side,"TURNOVER")`, déjà appelé pour la ligne "PB" du même tableau.

**Marqueurs PB (mode "points" uniquement)** : `TURNOVER` a `needsMap:true` (x/y capturé) mais n'est filtré dans aucun rendu de terrain existant (`shots` dans `renderPlayerDetail()`/`renderGkSheet()` ne retient que `isGoal||isSave||isOff`). Pour F6, construire une liste séparée `pbShots = S.events.filter(e=>e.team===side&&e.type==="TURNOVER"&&e.x!=null)` et la dessiner en plus des points existants **seulement quand `S.shotViewMode==="points"`** — marqueur visuellement distinct (couleur `ACTIONS.TURNOVER.color` = `var(--red)`, forme différente des cercles but/arrêt/hors-cadre pour rester lisible, ex. petit losange ou triangle), jamais ajouté à `zoneShots`/`renderCourtZones()` (mode "zones" reste inchangé : ratio buts/tirs uniquement, pas de 3e chiffre par zone). Ne touche à aucun rendu existant sur Joueurs/Gardiens — capacité nouvelle, strictement locale à F6.

## F7 — PDF : `generatePDF()` bascule en zones (dépend de F2)
- **Retiré** : `drawOriginZone()`, `drawPlayerOriginZone()` (STORY-40) et leurs deux points d'appel (carte "ZONES D'IMPACT & D'ORIGINE" page Gardiens, section "Origine" des cartes joueur) — obsolètes, remplacés.
- **`drawCourt()`** (page Gardiens "LOCALISATION TIRS" + Carte tir joueur) : remplacé par `drawCourtZones()`. Contrairement au live app, **le PDF n'a pas de bouton** — il utilise toujours le rendu zones (document statique, Romain a été explicite : "c'est ça que je veux sur le détail", pas un choix à la génération).
- Le titre de carte "ZONES D'IMPACT & D'ORIGINE" (STORY-40) redevient simplement "ZONES D'IMPACT" (le contenu Origine disparaît de cet emplacement, remplacé par les zones directement sur "LOCALISATION TIRS").
- Marqueur `7m` ajouté sur ces mêmes terrains PDF (absent aujourd'hui) ; marqueur `Sans GB` prévu dans le modèle mais toujours vide (cf. section dédiée F2, pas de capture disponible).
- Repères 6m (trait plein)/9m (pointillé)/4m/7m tracés en jsPDF sur ces mêmes terrains, mêmes coordonnées que `drawHandballZone()`/`courtSvgMarkup()`.

## F1 — Tableau Joueurs PDF (`drawPlayerTable()`, ~ligne 4834)
```
cols = ["#","NOM","POSTE","BUT/TIR","EFF%","PO","PD","PB","2M","MT1","MT2"]
colW = [10,  28,   15,     16,       13,    10, 10, 10, 10,  14,  14]   // total 150mm
```
`tableX` (site d'appel, ~ligne 4879) recalculé sur `150` (point de vigilance déjà signalé en STORY-41 — les deux doivent rester synchronisés). Agrégation `playerStats` (~ligne 4770) : ajoute `po` (compte `PEN_OBT` par `playerId`, même pattern que `pd`/`pb`/`excl` déjà présents) ; `goals`/`tirs` déjà là servent au format combiné `BUT/TIR` (`${p.goals}/${p.tirs}`) ; `mt1`/`mt2` (déjà ajoutés en STORY-41) étendus pour aussi tracker les tirs par mi-temps (`mt1Tirs`/`mt2Tirs`), pas seulement les buts, afin d'afficher `${p.mt1}/${p.mt1Tirs}`.

## Découpage suggéré (à trancher par le Risk Analyst / Scrum Master)
F2 (fondation géométrie) est un prérequis strict de F4/F5/F6/F7 — ne peut pas être développée indépendamment. F1 est totalement indépendante (autre fonction, autre partie du fichier). F6 est un ajout net (Should au PRD) qui peut suivre après F4/F5/F7 sans les bloquer.
