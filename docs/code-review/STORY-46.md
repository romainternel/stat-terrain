# Code Review — STORY-46 (Bug : mise à l'échelle des points de tir jamais appliquée)

## Portée revue
`app.js`, 4 sites de rendu SVG en mode "points" : `renderShotOverlay()` (~ligne 2536), `renderPlayerDetail()` (~ligne 2706), `renderGkSheet()` (~ligne 3453), `renderCompareCourt()` (~ligne 3126, nouveau STORY-44). Comparé à `docs/stories/STORY-46-bug-echelle-points-tir-svg.md`.

## Analyse du bug
Confirmé par lecture de code, pas seulement par le rendu visuel :
- `clickCourtPosition(x,y)` (~ligne 737) reçoit `x`/`y` déjà en % (calculés en amont, ligne ~4489 : `(e.clientX-rect.left)/rect.width*100`), et les stocke tels quels (`ap.mapX=x`) sans conversion.
- `validateAndClose()` (~ligne 953) copie `ev.x=ap.mapX` — aucune conversion à l'écriture non plus.
- `shotZoneCourt(xPct,yPct)` (~ligne 2277, STORY-43) **convertit explicitement** : `X=xPct/100*350, Y=yPct/100*208` — commentaire à l'appui : *"x/y en %, meme repere que S.events[].x/.y"*.
- `drawCourt()` (PDF, ~ligne 4772) **convertit explicitement** : `s.x/100*cw` — commentaire à l'appui : *"Tirs — x/y enregistrés en % (0-100) par clickCourtPosition()"*.
- Les 4 sites listés dans la story ne faisaient **aucune** conversion : `cx="${s.x}"` direct dans un `viewBox="0 0 350 208"`, ce qui revient à placer un point à 0-100% de la largeur dans une boîte de 0-350 — donc dans les 28,6% gauches et 48,1% hauts du terrain seulement, jamais au-delà.

Conclusion : diagnostic exact, pas une fausse piste. Reproduit par un test direct avant correctif (`shotZoneCourt` n'est pas en cause, seul le rendu brut des points l'est) : 5 tirs à x=5/25/50/75/95% produisaient `cx="5" cy="10"` ... `cx="95" cy="90"` au lieu de `cx="17.5"` ... `cx="332.5"`.

## Correctif
Formule identique aux 4 sites : `const sx=s.x/100*350, sy=s.y/100*208;` puis usage de `sx`/`sy` à la place de `s.x`/`s.y` dans les attributs SVG (`cx`, `cy`, `x1`, `y1`, `x2`, `y2`, et le `<path>` losange PB de `renderCompareCourt`). Même constante que `shotZoneCourt()` — pas de nouvelle valeur inventée, pas de risque de divergence entre les deux formules.

**Non touché, à raison** :
- `S.events[].x/.y` (stockage) — le bug est uniquement dans le rendu, pas dans la donnée ; aucune migration de données nécessaire, un match déjà sauvegardé se corrige tout seul au rechargement.
- Le crosshair de sélection pendant la saisie (ligne ~1768, `left:${ap.mapX}%;top:${ap.mapY}%`) — celui-ci utilise du positionnement CSS `%` sur un `div` en `inset:0`, pas un `viewBox` SVG ; il était déjà correct et n'a pas besoin de conversion.
- Mode "zones" partout — déjà correct via `shotZoneCourt()`.

## Scope
Strictement les 4 sites listés, aucune autre ligne modifiée. Pas de nouvelle fonction, pas de nouvelle abstraction (une constante partagée façon `COURT_WING_AY`/`COURT_WING_AX` aurait été possible mais aurait ajouté de l'indirection pour un calcul à une ligne déjà répété ailleurs dans le fichier sous cette forme exacte — cohérent avec le style existant, pas un problème).

## Vérification (menée par le Developer avant cette revue)
Avant/après comparés par appel direct de fonction (`renderPlayerDetail()` avec un jeu de test à 5 points répartis de 5% à 95%) : coordonnées `cx`/`cy` du SVG retourné vérifiées numériquement correctes après correctif (`17.5`→`332.5` sur 350, `20.8`→`187.2` sur 208, progression linéaire conforme aux % d'entrée). Confirmation visuelle par capture d'écran réelle sur `renderCompareCourt()` (STORY-44) : marqueurs répartis sur toute la largeur du mini-terrain, plus regroupés dans un coin.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Changement de rendu visible sur des matchs déjà enregistrés (les tirs vont "bouger" à l'écran au prochain chargement, sans que la donnée change) — signalé explicitement à Romain dans le rapport final, pas juste dans ce document, pour éviter toute confusion au premier coup d'œil sur un match archivé.

## Verdict
**APPROUVÉ**
