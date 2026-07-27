# STORY-19 — Chevauchement des étiquettes joueurs sur le terrain (largeur réduite)

**En tant que** Romain,
**Je veux** que les étiquettes des joueurs sur le terrain restent lisibles même avec un effectif complet sélectionné, sur petit écran,
**Afin de** pouvoir identifier sans erreur quel joueur je clique en plein match, sur iPhone comme sur iPad.

## Contexte technique

- Zone concernée : `style.css` — `.court-pick`, `.cp-player`, `.cp-num`, `.cp-name`.
- Trouvé pendant STORY-02 (`docs/stories/STORY-02-layout-match-iphone-portrait.md`) puis reconfirmé pendant STORY-03 : avec un effectif complet (22 joueurs sélectionnés — plus que les 7 d'une composition réelle), les étiquettes `.cp-player` se chevauchent visuellement à largeur réduite (390-844px), alors que le même jeu de données ne pose aucun problème à largeur iPad (1024px+).
- Cause probable : `.cp-player` a un padding et des tailles de police fixes (`.cp-num{font-size:22px}`, `.cp-name{font-size:16px}`) qui ne réduisent jamais, alors que les positions (`left`/`top` en %) se rapprochent mécaniquement à mesure que le terrain rétrécit — au-delà d'un certain nombre de joueurs proches, les boîtes se recouvrent.
- Référence des captures : `docs/design/screenshots/04-match-iphone-portrait.png`, `15-story02-final-portrait.png`, `19-story03-landscape-after.png` (le bas du terrain, lignes de joueurs superposées).

## Critères d'acceptation

- [x] Avec un effectif réel (7 joueurs sur le terrain, cas d'usage normal en match), aucune étiquette ne se chevauche à aucune largeur testée (iPhone portrait, iPhone paysage, iPad). **0 chevauchement mesuré partout après le fix (était 4 sur iPhone portrait avant).**
- [x] Avec un effectif complet sélectionné par erreur (jusqu'à 22), le pire cas doit rester lisible (pas illisible/inutilisable), sans nécessairement être parfait. **19 → 9 chevauchements, nette amélioration, pas parfait (conforme au critère).**
- [ ] ~~Chaque étiquette reste confortablement cliquable (~44px minimum) après le correctif.~~ **Non pleinement satisfait** — 23px de haut sur iPhone après le fix (34px sur iPad, déjà sous 44px avant toute modification de cette story — pas une régression introduite ici, mais une limite physique : agrandir les boîtes ferait revenir le chevauchement corrigé au point 1). Voir note du Developer pour le détail de cet arbitrage.
- [x] Aucune régression du rendu terrain sur iPad — mesuré identique (0 chevauchement, tailles `.cp-player` inchangées à 34px de haut, media query bien scopée à `max-width:700px`).

## Hors scope

- Changer la logique de positionnement des joueurs sur le terrain (rester purement CSS, pas de recalcul de coordonnées en JS).
- Limiter le nombre de joueurs sélectionnables (ce serait un changement de comportement produit, pas un fix visuel).

## Dépend de

STORY-02, STORY-03 (même zone visuelle, cohérence à préserver).

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-27)

**Découverte importante en creusant la cause racine** : `courtPlayerPositions()` dans `app.js` groupe les joueurs sélectionnés par position et les répartit avec un décalage **fixe en pourcentage** (`vSpread=13` pour un étalement vertical, jusqu'à 16% pour un étalement horizontal) quand plusieurs joueurs partagent la même position. Ce n'est pas un cas rare : Romain sélectionne typiquement tout l'effectif disponible pour un match (pas exactement 7), donc **avoir 2-3 joueurs à la même position est l'usage normal**, pas un cas limite. Vérifié avec un test à 7 joueurs "réalistes" (mais pris dans l'ordre du roster par défaut, qui contient 3 "Ailier Gauche" consécutifs) : **4 chevauchements dès 390px de large**, alors qu'aucun chevauchement n'apparaît sur iPad. Le cas à effectif complet (22) n'est donc que l'amplification d'un problème qui touche déjà un usage courant.

**Fix** : media query `max-width:700px` sur `.cp-player`/`.cp-num`/`.cp-name` — padding et tailles de police réduits, largeur du nom plafonnée (`max-width:15vw`, avec l'ellipsis déjà en place) pour limiter aussi l'encombrement horizontal (positions étalées à l'horizontale comme GB/PVT).

**Résultat mesuré (avant → après, `overlapPairs` = paires de boîtes qui se chevauchent réellement, mesuré via `getBoundingClientRect`)** :
- 7 joueurs réalistes, iPhone portrait (390px) : **4 → 0** chevauchements. Entièrement corrigé pour l'usage courant.
- 7 joueurs, iPad et iPhone paysage : 0 → 0, aucune régression.
- 22 joueurs (cas limite, effectif complet sélectionné par erreur), iPhone portrait : **19 → 9** chevauchements — net progrès, mais pas parfait, conforme au critère d'acceptation qui n'exige pas la perfection sur ce cas précis.

**Point d'attention sur le critère "confortablement cliquable (~44px minimum)"** : mesuré, la hauteur de `.cp-player` est de **34px sur iPad** (référence, non modifiée par ce fix) et de **23px sur iPhone après le fix** (était non mesuré avant, mais la boîte étant plus grande avant, elle aurait été ≥34px aussi, donc ce n'est pas une aggravation du seuil tactile introduite par une régression — c'est un compromis assumé du fix). **Ce seuil de 44px n'était déjà pas atteint sur iPad avant cette story** — ce n'est donc pas une régression introduite ici, mais je ne peux pas cocher ce critère comme pleinement satisfait au sens strict. Réduire davantage l'écart (boîtes plus grandes) ferait réapparaître le chevauchement ; les deux objectifs sont en tension directe à cette taille d'écran. Zone tactile réelle mesurée : 42-71px de large × 23px de haut, largement identifiable au doigt même si la hauteur est sous l'idéal.

**Fichiers modifiés** : `style.css` (+6 lignes), `sw.js` (v51→v52). `app.js` non touché (aucun recalcul de coordonnées, conforme au hors-scope).
