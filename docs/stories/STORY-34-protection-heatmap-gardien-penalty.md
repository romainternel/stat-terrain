# STORY-34 — Protection défensive des stats Gardiens contre les zones pénalty

**En tant que** Romain,
**Je veux** que l'écran Stats → Gardiens (`renderGkSheet()`, chiffres et heatmap de zone) continue d'afficher exactement les mêmes valeurs qu'aujourd'hui,
**Afin de** ne jamais voir un écran déjà validé (STORY-30/brief-v5) changer de chiffres silencieusement le jour où les zones d'impact des penaltys commencent à être réellement capturées (STORY-32).

## Contexte

Vérification faite dans le code actuel : `renderGkSheet()` et `goalZoneHeatmap()` **n'excluent pas** les événements pénalty (`isPen`) — ils sont déjà inclus dans le calcul de zone dès qu'ils ont un `x` non-nul (déjà le cas aujourd'hui, position fixe `mapX:50`) et compteraient dès que `goalZone` cesse d'être `null`. Sans ce correctif, le premier penalty capturé avec zone via STORY-32 changerait silencieusement les chiffres de cet écran, sans qu'aucun code visible de l'écran Gardiens n'ait été modifié pour ça.

Note : les stats numériques `gkStats()`/`gkStatsCombined()` (arrêts/total, %) excluent **déjà** correctement les pénaltys (`!ACTIONS[e.type].isPen`, ~1018-1020) — seul le calcul de zone/heatmap a ce trou.

## Contexte technique

`app.js` ~3038, dans `renderGkSheet(side)` :
```js
const allShots = S.events.filter(e=>e.team===oppSide && (ACTIONS[e.type].needsMap) && e.x!=null && gkIds.includes(e.gkId));
```
devient :
```js
const allShots = S.events.filter(e=>e.team===oppSide && (ACTIONS[e.type].needsMap) && !ACTIONS[e.type].isPen && e.x!=null && gkIds.includes(e.gkId));
```
Une seule condition ajoutée. `allShots` alimente en cascade :
- `goalZoneHeatmap(allShots,"88%")` (~3050) — la heatmap 3×3.
- Les compteurs `goals`/`saves`/`offs` affichés sous le terrain SVG (~3045-3047) — ceux-ci **incluent déjà aujourd'hui** les tirs pénalty (leur `x` vaut déjà 50 dès la conversion, indépendamment de `S.trackGK`), contrairement aux chiffres du haut de colonne (`gk.goals`/`gk.saves`/`gk.offs`, calculés via `gkStats()`, qui excluent déjà `isPen`). Ce correctif aligne donc ces compteurs sur le reste de l'écran — c'est un effet secondaire voulu, pas une régression.

**Ne pas toucher** `teamShots(team)` (~1056, utilisée uniquement par `renderShotOverlay()`, le flux legacy 2min/carton rouge) — hors scope, non mentionnée par le PRD, non concernée par ce correctif.

## Critères d'acceptation

1. Sur un match contenant déjà des `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` (position fixe `x=50`, `goalZone=null` comme c'est le cas pour tout penalty enregistré avant ce cycle), `renderGkSheet()` affiche, avant et après ce changement :
   - la même heatmap de zone (aucune variation),
   - les mêmes compteurs `ENCAISSÉS`/`ARRÊTÉS`/`H. CADRE` sous le terrain SVG **après correctif** qu'avant — sauf que les événements pénalty en disparaissent (comportement attendu, voir note ci-dessus : aligne ces compteurs sur les chiffres du haut de colonne qui les excluaient déjà).
2. Une fois STORY-32 déployée et un nouveau `PEN_GOAL` enregistré avec un `goalZone` réel via l'encart : ce `goalZone` n'apparaît **jamais** dans la heatmap de zone de `renderGkSheet()` ni dans les compteurs sous le terrain SVG — vérifié en comparant les chiffres de l'écran Gardiens strictement avant/après cet enregistrement (doivent être identiques).
3. `gkStats()`/`gkStatsCombined()` (arrêts/total pénalty, ~1018-1020) restent inchangés — aucune modification requise ni attendue sur ces fonctions.
4. `teamShots()`/`renderShotOverlay()` restent inchangés.
5. `new Function()` (ou équivalent) valide `app.js` sans erreur après la modification.

## Hors scope

- L'affichage éventuel des zones pénalty ailleurs dans les stats/heatmaps/PDF (Nice to Have du PRD, reporté — décision de présentation distincte, à ouvrir seulement si Romain le demande après avoir vu les nouvelles données captées en direct).
- Toute modification de `teamShots()`/`renderShotOverlay()` (flux legacy 2min/carton rouge, non concerné).
- Le mécanisme de capture de l'encart pénalty lui-même — couvert par STORY-32.

## Dépend de

Aucune — story techniquement indépendante, réalisable à tout moment (avant, pendant, ou après STORY-32/STORY-33).

**Contrainte de déploiement (pas une dépendance de développement)** : doit être **en production au plus tard en même temps que STORY-32** — la protection ne sert à rien si un premier penalty avec zone est capturé avant qu'elle ne soit en place. Peut être développée et livrée en premier sans attendre STORY-32.

## Taille

S
