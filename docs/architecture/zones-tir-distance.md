# Architecture — Zones de tir : vraie distinction 6m / 6-9m / 9m

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v18-zones-tir-distance.md` et `docs/design/zones-tir-distance.md`*

## Décision technique
Deux parties bien séparées, de complexité très différente : **la classification** (quelle zone pour un x/y donné — pure logique, pas de rendu) et **la visualisation** (les polygones dessinés sur le terrain SVG). La première peut être spécifiée avec précision ici. La seconde touche une géométrie déjà reconnue comme délicate par le code existant lui-même (8 itérations de prototype visuel pour la version à 8 zones) — je donne l'approche et la technique à réutiliser, pas un algorithme de polygones final que je ne peux pas garantir sans un rendu réel, cf. section dédiée ci-dessous.

### F1 — Classification (`shotZoneCourt`, app.js:2670) — précis, prêt à coder
Constat vérifié dans le code : la fonction actuelle n'utilise **qu'un seul rayon, R9=157.5**, jamais R6=105 (pourtant déjà utilisé ailleurs pour *tracer* la ligne des 6m dans `courtSvgMarkup()`, jamais pour *classifier*). Tout ce qui est à moins de 9m d'un poteau est aujourd'hui étiqueté `6M*`. Correctif : ajouter `R6=105` et transformer chaque comparaison à 2 issues (`<R9` / `≥R9`) en comparaison à 3 issues (`<R6` / `<R9` / `≥R9`).

```javascript
const COURT_WING_AY=80, COURT_WING_AX=100;
function shotZoneCourt(xPct, yPct){
  const X=xPct/100*350, Y=yPct/100*208;
  const postL=148.75, postR=201.25, R6=105, R9=157.5;   // ← ajout R6
  const AY=COURT_WING_AY, AX=COURT_WING_AX;
  const centerHalfW=postR-postL, splitL=175-centerHalfW, splitR=175+centerHalfW;
  if(Y<=0) return X<AX?"AILG":(X>350-AX?"AILD":"6MC");   // inchangé : bord du but, toujours proche
  if(X<AX && Y < AY*(1-X/AX)) return "AILG";              // inchangé
  if(X>350-AX && Y < AY*(1-(350-X)/AX)) return "AILD";    // inchangé
  if(X>=splitL && X<=splitR){
    let b6, b9;
    if(X>=postL && X<=postR){ b6=R6; b9=R9; }
    else { const post=X<postL?postL:postR, dx=Math.abs(X-post); b6=Math.sqrt(Math.max(0,R6*R6-dx*dx)); b9=Math.sqrt(Math.max(0,R9*R9-dx*dx)); }
    if(Y<b6) return "6MC";
    if(Y<b9) return "69MC";                                // ← nouvelle bande
    return "9MC";
  }
  const post=X<splitL?postL:postR, dir=X<splitL?-1:1;
  const dx=Math.abs(X-post), r=Math.hypot(dx,Y);
  if(r<R6) return dir<0?"6MG":"6MD";
  if(r<R9) return dir<0?"69MG":"69MD";                     // ← nouvelle bande
  return dir<0?"9MG":"9MD";
}
```
`COURT_ZONE_ORDER` passe de 8 à 11 entrées : `["AILG","6MG","69MG","9MG","6MC","69MC","9MC","6MD","69MD","9MD","AILD"]` (ordre suggéré, aligné sur l'organisation profondeur-croissante par secteur — le Developer peut réordonner sans risque, cet array ne pilote que l'ordre d'itération pour l'agrégation/légende, pas la géométrie).

Cette partie est **directement implémentable telle quelle** — c'est une extension de comparaisons numériques, testable unitairement avec des couples (x,y) connus (ex: un tir pile entre les poteaux à Y correspondant à 6m/8m/10m réels) avant même de toucher au rendu visuel.

### F1 — Visualisation (`buildCourtZones`, app.js:2704) — approche, pas un algorithme figé
La fonction actuelle construit chaque polygone de zone par combinaison de segments droits et d'arcs paramétrés (`arcPoints(post, dir, radius, angleFrom, angleTo)`), calculés une seule fois et mis en cache. **Fait important découvert en marge de F1** : les polygones actuellement étiquetés `6MG`/`6MC`/`6MD` utilisent déjà des arcs à rayon **R9**, jamais R6 — cohérent avec la classification (même défaut, mêmes deux fonctions à corriger ensemble).

**Approche recommandée** : réutiliser exactement les mêmes primitives (`arcPoints`, `angleAtX`) avec un second rayon R6, pour :
1. Tronquer les polygones `6M*` actuels à la frontière R6 au lieu de R9 (ils deviennent plus petits, resserrés près du but).
2. Construire 3 nouveaux polygones `69M*` — l'anneau compris entre l'arc R6 et l'arc R9, sur chacun des 3 secteurs Gauche/Centre/Droit.
3. Les polygones `9M*` gardent leur frontière extérieure inchangée (R9 reste la même limite qu'aujourd'hui) — seule leur frontière intérieure ne change pas non plus (elle était déjà R9).

**Pourquoi je ne fournis pas le détail complet des sommets ici** : la jonction entre la zone d'aile (`AILG`/`AILD`, un triangle simple non lié à un rayon) et le nouvel arc R6 n'est pas géométriquement évidente à l'œil — l'arc R6 depuis un poteau n'atteint la ligne de but qu'à `postL-R6=43.75` (vérifiable dans `courtSvgMarkup()`, le tracé du 6m commence exactement à `M 43.75,1`), une valeur différente de la largeur d'aile actuelle (`AX=100`). Une dérivation à la main de tous les sommets ici risquerait de produire un polygone auto-intersectant ou un trou entre zones, invisible en le lisant mais visible immédiatement au rendu. C'est exactement le type d'erreur que les 8 itérations précédentes ont dû corriger à l'œil, pas sur le papier.

**Recommandation de méthode pour le Developer** : implémenter par petits pas visuellement vérifiables — générer d'abord uniquement le nouveau tracé de l'arc R6 en overlay de debug sur le terrain existant (juste une ligne, pas encore un polygone rempli), confirmer qu'il correspond visuellement à la ligne des 6m déjà dessinée par `courtSvgMarkup()`, **puis seulement** construire les polygones `6M*`/`69M*` à partir de cette frontière validée. Éviter d'écrire les 3 nouveaux polygones d'un coup sans étape de vérification intermédiaire.

### F3 — PDF réutilise `shotZoneCourt` (remplace `shotOriginZone`, app.js:5358-5429)
`shotOriginZone(x,y)` est supprimée. `drawOriginZone()` et `drawPlayerOriginZone()` sont aujourd'hui ~90% dupliquées (seule leur source de données diffère : événements filtrés par `gkId` vs. tableau `shots` déjà construit) — l'occasion de les fusionner en une seule fonction de rendu de grille, partagée :

```javascript
function drawZoneGridPdf(gx, gy, gw, gh, data){
  // data: {zone: {g,t}} déjà agrégé par shotZoneCourt, indépendant de la source
  // Layout : cf. docs/design/zones-tir-distance.md — grille 3×3 (6M/69M/9M × G/C/D)
  // encadrée par 2 cellules AILG/AILD pleine hauteur (11 zones au total).
  // ... implémentation de grille, cf. Design pour la disposition exacte
}
function collectGkZoneData(gkId){
  const data={}; COURT_ZONE_ORDER.forEach(z=>data[z]={g:0,t:0});
  S.events.filter(e=>e.gkId===gkId&&e.x!=null&&(ACTIONS[e.type]?.isGoal||ACTIONS[e.type]?.isSave||ACTIONS[e.type]?.isOff))
    .forEach(e=>{ const z=shotZoneCourt(e.x,e.y); data[z].t++; if(ACTIONS[e.type]?.isGoal) data[z].g++; });
  return data;
}
function collectShotsZoneData(shots){
  const data={}; COURT_ZONE_ORDER.forEach(z=>data[z]={g:0,t:0});
  shots.forEach(s=>{ const z=shotZoneCourt(s.x,s.y); data[z].t++; if(s.goal) data[z].g++; });
  return data;
}
```
Sites d'appel (`app.js:5746`, `app.js:5814`) mis à jour : `drawZoneGridPdf(x,y,w,h, collectGkZoneData(g.gkId))` et `drawZoneGridPdf(x,y,w,h, collectShotsZoneData(ps.shots))`. Le paramètre `"AUTRE"` disparaît — `shotZoneCourt()` couvre déjà tout le demi-terrain sans reliquat (contrairement à `shotOriginZone()` qui avait besoin d'un bucket fourre-tout pour `y>=80`).

## Pourquoi (alternatives considérées et rejetées)
- **Un nouveau système de zones dédié au PDF, indépendant de `shotZoneCourt`** (rejeté, cf. Brief) : aurait corrigé le symptôme dans le PDF sans le corriger sur les écrans que Romain regarde en direct pendant le match — Romain a explicitement choisi la portée "live + PDF" plutôt que "PDF uniquement" quand la question lui a été posée.
- **Garder R9 comme seule frontière et juste renommer les zones existantes** (rejeté) : ne résout rien, uniquement cosmétique — le symptôme exact décrit par Romain (un 8m compté comme un 6m) resterait entier.
- **Réécrire complètement `buildCourtZones()` avec une formule polygonale générique paramétrée par un tableau de rayons** (rejeté pour cette itération) : plus élégant sur le papier, mais une généralisation prématurée avant même d'avoir un premier rendu à 3 bandes qui fonctionne visuellement — cohérent avec le principe déjà appliqué au projet (le système à 8 zones actuel n'a lui-même jamais été généralisé au-delà de son cas d'usage réel). Rien n'empêche cette généralisation plus tard si un 4e cas d'usage apparaît (cf. critère de bascule).
- **Fusionner `69M*` et `9M*` uniquement sur le terrain live pour limiter le nombre de polygones à redessiner** (rejeté) : contredirait directement la demande de Romain, qui veut précisément voir cette distinction sur l'écran qu'il regarde le plus souvent. Rester à 8 zones sur le live et n'étendre qu'au PDF serait revenir à l'option "PDF uniquement" déjà écartée.

## Impact sur l'existant — vérifié dans le code, pas supposé
- `renderCourtZones()`, `aggregateCourtZones()` : itèrent déjà sur `COURT_ZONE_ORDER` sans logique conditionnelle sur le nombre de zones — passer de 8 à 11 entrées ne demande **aucune modification de ces deux fonctions**, seulement de la constante elle-même et de `COURT_ZONE_LABEL_POS` (3 nouvelles entrées `69MG`/`69MC`/`69MD` à positionner, cf. Design).
- `S.shotViewMode==="points"` (mode par défaut, marqueurs individuels) : n'appelle jamais `shotZoneCourt()` — strictement non affecté, vérifié aux 3 sites d'utilisation (`app.js:2778`, `3108`, `3541`, `3872` — tous conditionnés par `isZones`/`S.shotViewMode==="zones"`).
- `_courtZonesCache` (mémoïsation des polygones, calculée une fois) : continue de fonctionner à l'identique, juste avec 3 entrées de plus dans l'objet retourné — aucun changement du mécanisme de cache lui-même.
- PDF : `drawGoalZone()` (zone d'impact, `e.goalZone`, 9 zones HG/HC/HD/...) est un système **totalement différent et non concerné** — ne pas confondre avec `drawOriginZone()` (zone d'origine du tir, celle qui est modifiée ici). Les deux continuent de s'afficher côte à côte sur la page Gardiens (`app.js:5813-5814`) sans interaction entre elles.
- Aucun événement existant n'a besoin d'être re-catégorisé en base : la classification se fait à la volée à partir de `x`/`y` déjà stockés, jamais persistée — un match déjà archivé affichera automatiquement les nouvelles zones dès l'ouverture, sans migration.

## Nouvelles structures de données
Aucune. `COURT_ZONE_ORDER` et `COURT_ZONE_LABEL_POS` sont étendus (3 entrées de plus chacun), pas remplacés. Aucun nouveau champ sur un événement.

## Nouvelles fonctions/modules
- `drawZoneGridPdf(gx,gy,gw,gh,data)` — remplace `drawOriginZone`/`drawPlayerOriginZone`, fusionnées (élimine la duplication ~90% déjà présente entre les deux).
- `collectGkZoneData(gkId)` / `collectShotsZoneData(shots)` — extraction des deux logiques d'agrégation actuellement mélangées dans `drawOriginZone`/`drawPlayerOriginZone`, pour nourrir `drawZoneGridPdf()` de façon uniforme.
- `shotOriginZone()` — supprimée (plus aucun appelant après F3).
- `shotZoneCourt()`/`buildCourtZones()` — modifiées en place, pas remplacées.

## Risques
Détaillés par le Risk Analyst (`docs/risks/zones-tir-distance.md`) — notamment la complexité géométrique de `buildCourtZones()` et la contrainte d'espace du PDF.

## Critère de bascule
Si une future demande ajoute encore une distinction (ex: un 4e palier de distance, ou une distinction supplémentaire hors handball comme les 7m), la technique actuelle (radius codés en dur, polygones dérivés à la main par le Developer avec vérification visuelle) devra être remplacée par une fonction générique `buildZonesForRadii(radii[])` paramétrée. Pas nécessaire aujourd'hui — 3 bandes (6m/9m + la nouvelle intermédiaire) couvrent la totalité de la demande réelle de Romain, inventer la généralisation maintenant serait spéculatif.
