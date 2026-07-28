# Architecture — Terrain et affichage des joueurs

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v3-terrain-joueurs.md` et `docs/visual/terrain-joueurs.md`*

## F10 — Terrain SVG natif

**Décision** : remplacer `background-image:url(${COURT_IMG})` sur `.court-pick` par un **SVG inline rendu comme enfant du conteneur**, positionné en `position:absolute;inset:0;z-index:0`, sous les étiquettes `.cp-player` (déjà en `z-index:1`, pas de changement nécessaire côté joueurs).

**Nouvelle fonction** `renderCourtSvg()` (dans `app.js`) — génère le markup SVG (viewBox `0 0 350 208` conservé, cf. contrainte de compatibilité avec les coordonnées `x`/`y` déjà enregistrées dans les événements existants) à partir des specs du Visual Crafter. Appelée partout où `.court-pick` est actuellement généré (`renderMatchPanel`, `renderPdSelect`, `renderPlayerSelect`) et dans les cartes de tir Stats (remplace `<image href="${COURT_IMG}">`).

**`COURT_IMG` (la constante base64)** : supprimée une fois toutes les références remplacées — pas de raison de la garder si plus aucun usage (~700 lignes de `app.js` en moins, bonus de lisibilité du fichier).

**Pourquoi ne pas juste recolorer l'image existante** : une image raster ne peut pas référencer les variables CSS du thème (`--fenix-sky`, etc.) — elle resterait figée si le thème évolue, et son fond clair "assourdi" restera toujours un compromis visuel. Le SVG natif coûte un peu plus cher à écrire une fois, mais aligne le terrain sur exactement les mêmes tokens que le reste de l'app, durablement.

**Risque de précision géométrique** : les proportions réglementaires (zone 6m, ligne 9m, penalty 7m, 4m) doivent rester correctes dans le référentiel `350×208`. Le Developer devra calculer les rayons/positions en conservant les proportions d'un terrain de hand réel (largeur de but ~3m sur une largeur de terrain ~20m, zone 6m = arc de rayon 6m à l'échelle) plutôt que copier des valeurs approximatives — cf. critère d'acceptation PRD "pas de perte d'information réglementaire".

## F11 — Terrain vide si aucune sélection

**Décision** : supprimer la ligne `if(roster.length===0) roster = S[team].players;` dans les **3 emplacements** identifiés (`renderMatchPanel`, `renderPdSelect`, `renderPlayerSelect`) — traitement uniforme, pas de comportement différencié entre "terrain de saisie" et "sélecteurs PD/2min-carton". Une règle simple ("`selected` gouverne tout affichage de joueurs sur un terrain, sans exception") est plus robuste et prévisible qu'une règle à exceptions.

**Nouvelle fonction** `renderCourtEmptyState()` — retourne le HTML du message d'état vide (spec Visual Crafter), affiché quand `roster.length===0` à la place des étiquettes joueurs (le SVG du terrain, lui, reste toujours affiché — seul le contenu joueurs change).

**Impact sur l'existant** : si Romain teste l'app sans avoir sélectionné de roster (ce qui vient d'être justement son cas dans la capture d'écran fournie), les 3 écrans concernés seront vides tant qu'il n'aura pas coché des joueurs dans Équipes — **changement de comportement visible immédiatement après déploiement**, à mentionner clairement dans le message de livraison pour ne pas que ça paraisse être une régression.

## F13 — Numéro manquant

**Décision** : la fonction `dn()` est dupliquée 3 fois dans `app.js` (lignes ~1131, ~1554, ~1620) — plutôt que de corriger 3 copies séparément, **extraire une fonction unique `displayNumber(p)`** au niveau module, réutilisée partout. Petit refactor de cohérence, risque nul (fonction pure, même signature).
```js
function displayNumber(p){ return p.number ? p.number : "–"; }
```
Ajout de la classe `cp-num-missing` conditionnellement quand `!p.number`, pour le style réduit défini par le Visual Crafter.

**Ne touche pas** au `?`/✏️ de `renderTeamSetup` (nom de joueur non renseigné) — logique et contexte différents, code séparé.

## Impact global sur l'existant

- `app.js` : suppression de `COURT_IMG` (grosse chaîne), ajout de `renderCourtSvg()`/`renderCourtEmptyState()`/`displayNumber()`, 3 sites d'appel modifiés pour le fallback de roster.
- `style.css` : nouveaux tokens couleur terrain, `.court-empty-msg`, `.cp-num-missing`.
- Aucun changement de structure de données (`S`, événements déjà enregistrés) — les coordonnées `x`/`y` historiques restent valides dans le nouveau référentiel SVG identique.

## Risques (vue technique)

Voir `docs/risks/terrain-joueurs.md` pour le détail — le point le plus sensible est la précision géométrique du SVG (reproduire un terrain réglementaire fidèle, pas approximatif) et le changement de comportement immédiatement visible de F11.

## Critère de bascule

Si un jour il faut un terrain interactif plus riche (zoom, replay animé des tirs), le SVG natif rend ça possible nativement (contrairement à l'image raster) — pas une raison de complexifier maintenant, juste une note que ce choix ouvre des portes futures sans coût supplémentaire.
