# Architecture — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

Zone concernée : `app.js`, `generatePDF()` et son écosystème (aucun fichier hors `app.js`).

## F1 — Classification de zone d'origine

### Décision : bandes simples (x/y), pas de géométrie d'arc exacte
`drawHandballZone()` trace les 6m/9m comme deux quarts de cercle centrés sur chaque poteau — exact pour le tracé visuel du terrain, mais inutilement coûteux (trigonométrie, cas particuliers aux bords) pour classer un point en zone à but de statistique agrégée. Un tir n'a pas une position ponctuelle "vraie" au sens du règlement (le joueur est en mouvement, saute, etc.) — une approximation par bandes est suffisante et plus simple à vérifier/tester qu'une classification par distance exacte au poteau le plus proche.

Seuils calibrés sur la géométrie réelle déjà en place (`courtSvgMarkup()`, viewBox 350×208, but en haut) : le segment droit du 6m est à Y=105 (y%≈50.5), celui du 9m à Y=157.5 (y%≈75.7).

```js
// x,y en % (0-100), même convention que S.events[].x/.y (clickCourtPosition()).
// Retourne une zone parmi celles de POS_XY (vocabulaire déjà connu de l'app,
// cf. docs/design/) plutôt qu'un quadrillage générique.
function shotOriginZone(x, y){
  const wing = x<20 || x>80;
  if(y<25 && wing) return x<50 ? "ALG" : "ALD";   // aile, angle fermé
  if(y<55) return "PVT";                           // zone 6m
  if(y<80){                                          // bande 9m
    if(wing) return x<50 ? "ALG" : "ALD";
    if(x<38) return "ARG";
    if(x>62) return "ARD";
    return "DC";
  }
  return "AUTRE";                                    // au-delà du 9m (contre-attaque, jet franc lointain)
}
```
Fonction pure, testable indépendamment du rendu (pas de dépendance à `doc`/jsPDF) — placée avant `drawGoalZone()` dans `generatePDF()`, au même niveau que les autres fonctions internes.

### Rendu — disposition 2 lignes × 3 colonnes + bande "AUTRE" conditionnelle
Reprend la disposition spatiale réelle des postes (ailiers/pivot près du but en haut, arrières/demi-centre plus loin en bas) plutôt qu'une grille 3×3 sans rapport avec le terrain :

```
┌──────┬──────┬──────┐
│ ALG  │ PVT  │ ALD  │   (rang 1 — proche du but)
├──────┼──────┼──────┤
│ ARG  │ DC   │ ARD  │   (rang 2 — bande 9m)
└──────┴──────┴──────┘
[ AUTRE : n/n ]            (bande fine, uniquement si total>0 pour cette zone)
```

```js
function drawOriginZone(gx, gy, gw, gh, gkId){
  const ZONES=["ALG","PVT","ALD","ARG","DC","ARD"];
  const data={}; ZONES.concat("AUTRE").forEach(z=>{data[z]={g:0,t:0};});
  S.events.filter(e=>e.gkId===gkId&&e.x!=null&&
    (ACTIONS[e.type]?.isGoal||ACTIONS[e.type]?.isSave||ACTIONS[e.type]?.isOff)).forEach(e=>{
    const z=shotOriginZone(e.x,e.y);
    data[z].t++; if(ACTIONS[e.type]?.isGoal) data[z].g++;
  });
  const hasAutre = data.AUTRE.t>0;
  const rowH = hasAutre ? gh*0.4 : gh*0.5, cellW=gw/3;
  ZONES.forEach((z,i)=>{
    const col=i%3, row=Math.floor(i/3);
    const x=gx+col*cellW, y=gy+row*rowH;
    const d=data[z];
    doc.setFillColor(...(d.t===0?[28,43,64]:(d.g/d.t>0.5?[80,200,120]:[78,205,232])));
    doc.rect(x,y,cellW-0.5,rowH-0.5,"F");
    if(d.t>0){ wh();doc.setFontSize(6);doc.setFont("helvetica","bold");
      doc.text(`${d.g}/${d.t}`,x+cellW/2-0.25,y+rowH/2+1,{align:"center"}); }
  });
  if(hasAutre){
    const ay=gy+rowH*2;
    doc.setFillColor(...(data.AUTRE.g/data.AUTRE.t>0.5?[80,200,120]:[78,205,232]));
    doc.rect(gx,ay,gw-0.5,gh-rowH*2-0.5,"F");
    wh();doc.setFontSize(5);doc.text(`AUTRE : ${data.AUTRE.g}/${data.AUTRE.t}`,gx+gw/2-0.25,ay+(gh-rowH*2)/2+0.8,{align:"center"});
  }
}
```
`drawPlayerOriginZone(gx,gy,gw,gh,shots)` : même logique, calquée sur `drawPlayerZoneGrid()` existante (filtre sur `shots` déjà collectés par `collectShotPlayers()`, pas de nouveau parcours de `S.events`) — mêmes tailles de police réduites (5pt) que `drawPlayerZoneGrid()` actuelle, cohérent avec l'échelle "carte compacte".

### Placement (reprend les décisions du Designer)
- Page Gardiens : `drawOriginZone(g.x+halfW-3-34, 70, 34, 14, g.gkId)`, à droite de `drawGoalZone(g.x+3, 70, 34, 14, g.gkId)` redimensionnée — même `y=70`, mêmes `card(g.x,58,halfW,30)` inchangée
- Carte tir joueur : `scCellH` porté de 46 à 62 ; `drawPlayerOriginZone()` appelée juste sous `drawPlayerZoneGrid()` existante, même largeur (`scZoneW`), hauteur similaire (`scZoneH`) — impact sur `drawShotCardsSection()` : uniquement la constante `scCellH`, aucune autre logique de pagination à toucher (la fonction générique gère déjà la casse "plus de hauteur par carte = moins de cartes par page" sans modification)

## F2 — Split MT1/MT2 dans `drawPlayerTable()`
Colonnes actuelles : `["#","NOM","POSTE","BUTS","PD","TIRS","EFF%","PB","2M"]`, largeurs `[10,28,15,13,12,13,15,12,12]` (total 130mm, page dispo ~180mm — marge confirmée suffisante pour l'ajout net).

Nouvelles colonnes : `["#","NOM","POSTE","MT1","MT2","PD","TIRS","EFF%","PB","2M"]`, largeurs `[10,28,15,9,9,12,13,15,12,12]` (total 135mm — +5mm, toujours largement dans la marge). `tableX` reste calculé dynamiquement depuis `totalW` (déjà générique dans le code existant), donc le centrage continue de fonctionner sans changement de formule.

Calcul des valeurs (à ajouter dans l'agrégation par joueur qui alimente `drawPlayerTable`, probablement dans la boucle qui construit `hPlayers`/`aPlayers` ou dans une passe équivalente) :
```js
const mt1 = S.events.filter(e=>e.playerId===p.id&&(e.period||1)===1&&ACTIONS[e.type]?.isGoal).length;
const mt2 = S.events.filter(e=>e.playerId===p.id&&(e.period||1)===2&&ACTIONS[e.type]?.isGoal).length;
```
`ACTIONS[e.type]?.isGoal` (pas de comparaison exacte à `"GOAL"`) — convention STORY-37 déjà actée dans `CLAUDE.md`, inclut les variantes `PEN_GOAL`.

## Réutilisation vs code nouveau
- `shotOriginZone()` : nouvelle fonction pure, aucun équivalent existant
- `drawOriginZone()`/`drawPlayerOriginZone()` : nouvelles, mais structure de code directement calquée sur `drawGoalZone()`/`drawPlayerZoneGrid()` (mêmes conventions de couleur, mêmes patterns de boucle) — pas de système parallèle
- `drawPlayerTable()` : modification in-place des tableaux `cols`/`colW`, pas de nouvelle fonction

## Non touché
`ensurePageSpace()`, `collectShotPlayers()`, `drawShotCardsSection()` (hors la constante `scCellH`), `drawCourt()`, `drawHandballZone()`, tout ce qui concerne le Top 3, la page Évolution, la structure de pagination livrée en STORY-39.
