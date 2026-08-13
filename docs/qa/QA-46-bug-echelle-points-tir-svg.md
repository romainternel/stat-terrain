# QA — STORY-46 (Bug : mise à l'échelle des points de tir jamais appliquée)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-46-bug-echelle-points-tir-svg.md`, `docs/code-review/STORY-46.md` (APPROUVÉ).

## Méthode
Comparaison avant/après par appel direct de fonction via CDP (`Runtime.evaluate`) — le bug et son correctif sont purement numériques (positions `cx`/`cy` dans le SVG retourné), donc vérifiables sans dépendre du rendu DOM du navigateur (contournement du bug d'outillage CDP déjà documenté). Complété par une capture d'écran réelle sur `renderCompareCourt()` pour confirmation visuelle finale.

## Critères d'acceptation

- [x] **`renderPlayerDetail()`** — jeu de test à 5 tirs répartis de x=5% à x=95% (et y=10% à y=90%) : avant correctif, `cx`/`cy` = `5,10` / `25,30` / `50,50` / `75,70` / `95,90` (regroupés dans les 28,6%/48,1% haut-gauche du terrain) ; après correctif, `cx`/`cy` = `17.5,20.8` / `87.5,62.4` / `175,104` / `262.5,145.6` / `332.5,187.2` — progression linéaire correcte sur toute la largeur/hauteur du `viewBox 350×208`
- [x] **`renderGkSheet()`** — même formule appliquée (`s.x/100*350`, `s.y/100*208`), lecture de code confirmée identique au site ci-dessus, pas de re-test numérique séparé nécessaire (code strictement identique)
- [x] **`renderShotOverlay()`** (aperçu pendant la saisie en direct) — même formule appliquée, lecture de code confirmée
- [x] **`renderCompareCourt()`** (nouveau, STORY-44) — vérifié directement en même temps que STORY-44, capture d'écran à l'appui : marqueurs but/arrêt/hors-cadre/PB répartis sur toute la largeur du mini-terrain après correctif
- [x] Mode "zones" non affecté — `shotZoneCourt()`/`buildCourtZones()`/`renderCourtZones()` non modifiés, capture d'écran zones re-confirmée identique avant/après (même jeu de données, même rendu)
- [x] Le crosshair de sélection pendant la saisie (positionnement CSS `%`, pas SVG) non affecté — confirmé par lecture de code, aucune modification à cet endroit, à raison (il n'avait pas le bug)
- [x] `S.events[].x/.y` (donnée stockée) non modifié — confirmé par lecture de code, le correctif est strictement dans le rendu

## Cas limites testés
- **0 tir** : `renderPlayerDetail()`/`renderCompareCourt()` avec liste de tirs vide — `shots.map()` sur tableau vide, aucune exception, aucun marqueur affiché.
- **Valeurs aux bornes** (x=0%, x=100%) : `0/100*350=0`, `100/100*350=350` — tombent exactement sur les bords du `viewBox`, cohérent avec un tir tapé au ras du bord du terrain (touche ou ligne de but).

## Impact sur des matchs déjà sauvegardés
Vérifié que le correctif est purement côté rendu : un match archivé (`S.events` chargé depuis Supabase/IndexedDB) affichera immédiatement ses tirs à la bonne position dès le prochain rendu, sans ré-enregistrement ni migration. Les positions affichées vont visuellement "bouger" par rapport à ce que Romain a pu voir jusqu'ici sur des matchs existants — attendu et sans perte de données, signalé explicitement dans le rapport final.

## Bugs trouvés
Le bug qui fait l'objet de cette story lui-même — aucun bug supplémentaire trouvé pendant sa correction.

## Régressions détectées
Aucune — mode "zones", export PDF et capture en direct (crosshair) tous confirmés non affectés par construction (code non touché) et par re-vérification visuelle pour le mode zones.

## Verdict
**PASSED**
