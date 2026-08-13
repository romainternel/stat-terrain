# Code Review — STORY-43 (Zones sur le terrain : fondation + Joueurs/Gardiens)

## Portée revue
`app.js` : nouvelles fonctions `shotZoneCourt()`, `buildCourtZones()`, `aggregateCourtZones()`, `renderCourtZones()`, `shotViewToggleHtml()` (ajoutées après `courtSvgMarkup()`) ; nouvel état `S.shotViewMode` + `setShotViewMode()` ; modifications de `renderPlayerDetail()` et `renderGkSheet()` ; binding `[data-shotview]` dans `bind()`. `style.css` : classes `.shotview-toggle`/`.shotview-btn`. Comparé à `docs/stories/STORY-43-zones-terrain-fondation-joueurs-gardiens.md` et `docs/arch/zones-terrain-et-tableau-joueurs.md`.

## Conformité architecture
- Constantes de calibrage (`AY=56, AX=88`, colonne centrale doublée/centrée) reprises exactement du prototype validé, pas re-devinées.
- `shotZoneCourt()` implémentée telle que spécifiée (aucune classification via `R6`, seul `R9` sert de frontière — évite le piège identifié pendant le prototypage).
- Repères visuels 6m/9m/4m/7m : **déjà présents** dans `courtSvgMarkup()` (vérifié en lisant le code existant avant de développer) — correctement non redessinés, `renderCourtZones()` se contente de superposer les zones par-dessus ce fond déjà tracé, conforme à la note de l'Architecture ("ne pas redessiner").
- Marqueur `7m` : alimenté par `ACTIONS[e.type]?.isPen` (jamais x/y), conforme.
- Marqueur `Sans GB` : **volontairement absent** du rendu live — décision documentée dans le code (commentaire explicite) plutôt qu'un badge à vide en permanence. C'est une interprétation raisonnable de l'archi ("badge vide tant que pas de capture") ; à confirmer que ça correspond à l'intention du Designer plutôt qu'un badge visible mais neutre — point à trancher en QA/avec Romain, pas bloquant pour ce Code Review.

## Conventions de code
- Commentaires alignés sur la convention du fichier (le "pourquoi" : ex. le commentaire sur `shotZoneCourt()` explique pourquoi `R6` n'est jamais utilisé, pas ce que fait chaque ligne).
- `S.shotViewMode` suit exactement le pattern déjà établi par `S.mode`/`S.readOnly` (init `try{}` + `localStorage`, setter dédié qui persiste et appelle `R()`).
- Nommage cohérent avec l'existant (`renderCourtZones` à côté de `renderCourtEmptyState`, `shotViewToggleHtml` dans l'esprit de `goalZoneHeatmap`).

## Réutilisation vs duplication
Aucune duplication de géométrie : `courtSvgMarkup()` non touchée, réutilisée telle quelle par les deux écrans comme avant. `renderCourtZones()` est bien une fonction unique partagée par `renderPlayerDetail()` et `renderGkSheet()`, pas deux implémentations parallèles — conforme à la story ("Un seul composant... pas de prop par écran").

## Scope
- Aucun fichier hors `app.js`/`style.css` touché.
- Aucune fonction partagée hors du périmètre modifiée (`ACTIONS`, `gkStats()`, `selectedGbs()` consommées en lecture seule).
- Point vérifié explicitement (Risk R2) : `S.shotViewMode` n'est référencé nulle part dans `newMatch()`/`loadMatchAsCurrent()` (recherche globale faite) — reste protégé par construction, comme `S.mode`, sans code de garde supplémentaire nécessaire.
- Point vérifié explicitement (Risk R3) : `setShotViewMode()` ne contient aucune garde `S.readOnly` — confirmé par lecture du code, cohérent avec le fait que ce n'est pas une écriture de donnée de match.

## Vérification visuelle (menée par le Developer avant cette revue)
Jeu de données dédié (8 tirs couvrant explicitement les 8 zones + 2 événements `PEN_*`), vérifié par clics réels CDP (pas d'injection d'état pour l'interaction elle-même) : clic sur la cible d'un joueur → overlay détail → clic sur le bouton de bascule → rendu zones correct et identique au prototype déjà validé par Romain ; navigation vers Gardiens → réglage toujours "zones" (état global confirmé) → les deux cartes GB (vide côté FENIX, peuplée côté adversaire) rendent correctement, y compris le cas 0 tir sans crash ; re-bascule vers points sur Gardiens → rendu points intact, aucune régression visible. Mode lecteur testé explicitement : bouton toujours actif et fonctionnel.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Une première valeur de test (`9mC` à `y=75%`) tombait juste en dessous du vrai seuil des 9m (75.7%), classée par erreur en `6mC` — confirmé qu'il s'agissait d'une imprécision du jeu de test, pas d'un bug de `shotZoneCourt()`, après recalcul et re-test avec `y=85%`. À garder en tête pour la QA : les seuils de zone sont sensibles au dernier degré près du 9m, prévoir des coordonnées de test clairement au-delà plutôt qu'à la limite.
- Le badge `Sans GB` étant absent du rendu live (décision du Developer, cf. ci-dessus), s'assurer que le QA/Design valide explicitement ce choix plutôt que de le découvrir en production.

## Verdict
**APPROUVÉ**
