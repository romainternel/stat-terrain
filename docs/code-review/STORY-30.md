# Code Review — STORY-30 : Fusionner la carte gardien (terrain + chiffres) en une "feuille" par équipe

## Historique de cette revue
- **Passage 1** (voir Annexe ci-dessous pour le détail complet) : verdict **REJETÉ — à reprendre**, deux points bloquants sur la section C/I (tailles responsive niveau 1/2 absentes, dot de chip non coloré).
- **Passage 2** (ce document) : vérification des deux corrections + d'un point non-bloquant traité en bonus. Nouveau verdict ci-dessous.

## Périmètre revu au passage 2
Diff `git diff` (working tree, non commité) sur `app.js`, `style.css`, `sw.js` — confirmé strictement limité aux fichiers et zones attendus, aucun fichier hors story touché. Trois hunks pertinents dans `app.js` (zone `renderGkSheet`/`renderGkDetailTables` l.2990-3099, binding `[data-gk-filter-select]` l.3666-3675, reset `newMatch()` l.1401) plus un changement de valeur par défaut (`statsTab:"compare"` au lieu de `"gk"`, l.47) sans rapport avec les deux points bloquants — vraisemblablement un résidu de test corrigé au passage, comportement par défaut correct, aucune inquiétude.

## Vérification point bloquant #1 — Tailles responsive niveau 1/2

**Corrigé, conforme.**

`style.css` l.286-291 :
```css
.gk-lvl1{ font-size:38px; font-weight:800; }
.gk-lvl2{ font-size:23px; font-weight:800; }
@media(max-width:700px){
  .gk-lvl1{ font-size:34px; }
  .gk-lvl2{ font-size:20px; }
}
```
`app.js` l.3023 et l.3025 : `<div class="mono gk-lvl1" style="color:var(--gk-save);">` et `<div class="mono gk-lvl2" style="color:var(--yellow);margin-top:12px;">` — le `font-size`/`font-weight` ne sont plus posés en inline (seule la couleur et les marges le restent), la classe porte la valeur de base et la media query la variante réduite. Seuil 700px réutilisé (aucun nouveau breakpoint). Vérifié qu'aucune règle plus spécifique (`.gk-sheet-nums div{...}` ou équivalent) n'entre en conflit de spécificité avec `.gk-lvl1`/`.gk-lvl2` — recherche dans `style.css` : aucune. Vérifié aussi que `.mono` (l.31, `font-family` seul) ne définit pas de `font-size` qui pourrait entrer en cascade concurrente. Valeurs exactes conformes à la story (38/34 et 23/20).

## Vérification point bloquant #2 — Dot coloré des chips

**Corrigé, conforme.**

`app.js` l.3027-3028 :
```html
<span class="gk-pill" style="--gk-pill-rgb:80,200,120;"><span class="gk-pill-dot"></span>${gk.goals} encaissés</span>
<span class="gk-pill" style="--gk-pill-rgb:232,154,78;"><span class="gk-pill-dot"></span>${gk.offs} hors cadre</span>
```
`style.css` l.284 : `.gk-pill-dot{ width:7px; height:7px; border-radius:50%; background:rgb(var(--gk-pill-rgb)); flex-shrink:0; }` — exactement la règle documentée dans `docs/visual/stats-gardiens.md` §5. Le caractère "●" textuel a disparu, remplacé par un `<span>` dédié dont le fond porte la couleur pleine (vert/orange selon le custom property `--gk-pill-rgb` posé par équipe/chip). Le texte du chip (`${gk.goals} encaissés`) reste en `color:var(--t2)` via `.gk-pill` (l.281-283) — cohérent avec la spécification ("dot en couleur pleine, texte neutre"). `.gk-pill` est `display:inline-flex` avec `gap:5px` (l.281) : le dot (premier enfant) et le texte (item flex anonyme suivant) sont donc correctement espacés sans qu'il soit nécessaire de conserver un caractère espace littéral — solution plus propre que l'ancien "● " textuel. Aucune régression sur la bordure/fond en alpha réduit (`rgba(var(--gk-pill-rgb),.10)`/`.28`, inchangés).

Lien visuel avec le terrain (but de la section I) désormais effectif : le point vert/orange du chip est visuellement de la même teinte pleine que les points "but"/"hors cadre" du SVG juste en dessous (`#50C878`/`#E89A4E`, l.3051) — cohérence chromatique obtenue.

## Point bonus (non demandé comme bloquant, traité quand même)

**Label statique du gardien unique — couleur d'équipe.**
`app.js` l.3014 : `color:${side==="home"?"var(--fenix-sky)":"var(--red)"}` — identique à l'expression déjà utilisée pour la couleur du `<select>` actif (l.3005). Conforme à `docs/visual/stats-gardiens.md` §3 ("même couleur `var(--gk-accent-color)`"). Corrige la remarque non-bloquante n°2 du passage 1. Aucun effet de bord : ne touche que la branche `gbs.length===1`, les branches `>=2` et `===0` sont inchangées.

## Non-régression vérifiée au passage 2
- `new Function()` sur `app.js` complet : aucune erreur de syntaxe.
- Diff `style.css` : ajout strictement additif du bloc `GK SHEET (STORY-30)` (l.259-291) + un token (`--gk-save`/`--gk-goal`/`--gk-off`, l.17) déjà revus au passage 1 ; rien retiré ni modifié ailleurs.
- Diff `app.js` : les quatre hunks correspondent exactement au périmètre attendu (feuille GK, binding du select, reset d'état) ; aucune ligne touchée dans `gkStats()`, `gkStatsCombined()`, `selectedGbs()`, `goalZoneHeatmap()`, `courtSvgMarkup()`, `renderGkDetailTables()`, `openFullscreen()` — toutes confirmées identiques au passage 1.
- `sw.js` : `CACHE_NAME` à `fenix-stats-v76`. Ce numéro couvre l'ensemble du travail STORY-30 non encore commité (implémentation initiale + les deux corrections + le bonus), puisque le dernier commit sur ces fichiers (`778ec91`, STORY-29) précède tout ce lot — pas de risque de version obsolète tant que ce commit unique est poussé tel quel. Pas d'action requise ici, mais rappel pour l'étape 2 du process de déploiement (`CLAUDE.md` l.169) : si d'autres retouches sont faites après un premier commit/push de ce lot, il faudra réincrémenter à v77.
- Aucune trace résiduelle de l'ancien "●" textuel ou de `font-size:38px/23px` inline ailleurs dans `app.js` (recherché explicitement).

## Recommandé (non-bloquant, reporté du passage 1, toujours valable)
Les points 1, 3, 4, 5 du passage 1 n'ont pas été traités dans cette correction (ce n'était pas demandé) et restent valables tels quels — voir Annexe. Rien de nouveau à ajouter.

## Sécurité basique
RAS, inchangé depuis le passage 1 — aucune nouvelle surface touchée par les deux corrections (uniquement CSS + un `<span>` statique, pas de nouvelle donnée injectée).

## Verdict
**APPROUVÉ**

Les deux points bloquants du passage 1 sont corrigés exactement comme spécifié par la story et le doc Visual Crafter, sans effet de bord : tailles responsive niveau 1/2 (38/34 et 23/20 via classes + media query 700px réutilisée) et dot de chip coloré (`<span class="gk-pill-dot">` séparé du texte, teinte pleine cohérente avec les points du terrain). Le bonus (couleur du label statique 1-GB) est également conforme et sans risque. Aucune régression détectée sur le reste du périmètre déjà validé (D à L au passage 1). Prêt pour le QA.

---

## Annexe — Détail complet du passage 1 (REJETÉ)

### Périmètre revu
`app.js` :
- Nouvelle fonction `renderGkSheet(side)` (l.2993-3079), appelée deux fois par `renderStatGk()` restructurée (l.3081-3103).
- Binding `[data-gk-filter-select]` (l.3669-3675) remplaçant l'ancien binding boutons `[data-gk-filter]`.
- Reset `S.gkFilter`/`S.gkShotFilter` dans `newMatch()` (l.1401) et `[data-load-match]` (l.3912).
- Fonctions confirmées **non modifiées** : `gkStats()` (l.1014), `gkStatsCombined()` (l.1032), `selectedGbs()` (l.1051), `goalZoneHeatmap()` (l.1057-1079), `courtSvgMarkup()` (l.2094), `renderGkDetailTables()` (l.2947-2991), `openFullscreen()` (l.2709-2769).

`style.css` :
- Tokens `--gk-save`/`--gk-goal`/`--gk-off` (l.17).
- Bloc `/* GK SHEET (STORY-30) */` (l.259-284) : `.gk-sheet`, `.gk-sheet-body`, `.gk-filter-select`, `.gk-pill-group`, `.gk-pill`, `.gk-col-empty`.
- `.stat-courts` (l.256-257) et règle plein écran l.187-193 confirmées **non modifiées**.

`sw.js` : `CACHE_NAME` → `fenix-stats-v76`.

`new Function()` sur `app.js` complet : aucune erreur de syntaxe.

### Point vérifié en premier — le conteneur `.gk-sheet-body` (déviation du bloc CSS littéral section B)

**Vérifié, déviation justifiée, ne pose pas de problème.**

Le bloc CSS donné littéralement en section B de la story applique `display:flex;flex-direction:row-reverse` directement sur `.stat-courts > .card.gk-sheet`. Le markup de `renderGkSheet()` a trois enfants directs sous `.gk-sheet` : le header (nom d'équipe + sélecteur GB), puis (dans l'implémentation) un conteneur `.gk-sheet-body`. Si le flex avait été posé sur `.gk-sheet` lui-même comme écrit littéralement dans la story, le header serait devenu un item flex au même rang que les deux colonnes — exactement le bug décrit (header repoussé hors écran par le `row-reverse`, `getBoundingClientRect` donnant des x négatifs massifs).

La correction introduit `.gk-sheet-body` (style.css l.268-275) comme unique conteneur flex, ne contenant que `.gk-sheet-nums`/`.gk-sheet-court` ; `.gk-sheet` redevient un simple bloc empilé (confirmé : la règle `.stat-courts > .card.gk-sheet` — l.260-262 — ne pose ni `display` ni `flex-direction`, seulement `border`/`box-shadow`). Le commentaire l.266-267 documente explicitement la raison.

Conséquence sur le contrat DOM de la section A ("les deux [.gk-sheet-court/.gk-sheet-nums] sont enfants directs du même conteneur `.gk-sheet`") : **littéralement non respecté** — ils sont enfants directs de `.gk-sheet-body`, elle-même enfant de `.gk-sheet`, pas enfants directs de `.gk-sheet` lui-même. Mais l'intention fonctionnelle de la story (terrain à gauche/chiffres à droite ≥700px via `row-reverse`, empilé chiffres-au-dessus/terrain-en-dessous <700px via `column`, sans dupliquer de markup ni `order:`) est intégralement respectée : l'ordre DOM `.gk-sheet-nums` puis `.gk-sheet-court` (l.3075-3076) combiné à `row-reverse` produit bien terrain-gauche/chiffres-droite en desktop, et `column` (non `column-reverse`) produit bien chiffres-en-haut/terrain-en-bas en mobile. Pas de nouveau breakpoint introduit (700px réutilisé, l.271).

**Verdict sur ce point : la déviation est la bonne décision technique** — suivre le bloc CSS littéral aurait reproduit le bug. Elle mérite d'être actée explicitement dans la story/CLAUDE.md (le texte de la section A/B devrait être mis à jour pour refléter `.gk-sheet-body` comme conteneur flex réel), mais ne bloque pas cette review.

### Vérification section par section

**A. Fusion structurelle** — Conforme, sous réserve de la nuance ci-dessus. Une seule `<div class="card gk-sheet">` par équipe (l.3068), `renderStatGk()` délègue bien à `renderGkSheet("home"/"away")` dans un unique `.stat-courts` (l.3090-3092). Filtre type de tir repositionné avant `.stat-courts`, markup/logique inchangés (comparé à `S.gkShotFilter`/`data-shot-filter`, binding l.3677-3683 identique à l'esprit de l'existant). `renderGkDetailTables()` appelée après, sans modification, visible sans clic (l.3094). Classes `.gk-sheet-court`/`.gk-sheet-nums` présentes (l.3075-3076). Ordre DOM nums-puis-court conforme.

**B. CSS layout interne** — Conforme fonctionnellement (cf. point ci-dessus pour la déviation structurelle). `.stat-courts` non modifiée (l.256-257). Seuil 700px réutilisé, aucun nouveau nombre de breakpoint.

**C. Hiérarchie des chiffres à 3 niveaux** — **Non conforme sur un point testable** : voir Bloquant #1 (tailles responsive 38px/34px et 23px/20px absentes). Le reste est conforme : label "ARRÊTS" (10px/700/uppercase/`var(--t2)`/margin-top:2px, l.3024), niveau 2 `%` en `var(--yellow)` avec `margin-top:12px` (l.3025), chips niveau 3 avec `margin-top:16px` (l.3026), colonne verticale ≥700px / ligne <700px (`.gk-pill-group`, style.css l.279-280), anciens libellés à plat disparus, cas `0/0`/`pct:"-"` affiché avec le même style (pas de branche conditionnelle réduisant la taille — `numsHtml` ne distingue pas ce cas, correct). Voir aussi Bloquant #2 pour le `dot` des chips.
`.gk-sheet-nums` : aucune occurrence de `display:grid`/`grid-template-columns` dans son contenu (vérifié, `numsHtml` ne contient que des blocs `<div>` simples) — conforme au contrat plein écran.

**D. Dropdown GB** — Conforme. `gbs.length>=2` → `<select data-gk-filter-select>` sans plafond (pas de `.slice(0,3)`, l.3007 `gbs.map`). `gbs.length===1` → label statique `font-weight:700` (l.3014). `gbs.length===0` → ni select ni label (délégué à l'état vide F). Binding l.3669-3675 identique caractère pour caractère à celui donné par la story, ancien binding boutons `[data-gk-filter]` totalement absent du fichier (vérifié par grep, aucune coexistence). Un seul `onchange` → un seul `R()` → nums et court lisent la même valeur `S.gkFilter[side]` au même passage de rendu (aucune désynchronisation possible). Style `.gk-filter-select` (style.css l.276-278) conforme sur tous les points listés (`background`, `border-radius`, `font-size`, `font-weight`, `padding`, `min-height`, `max-width` 148px/130px) ; `border`/`color` posés en inline par équipe (l.3005) plutôt que dans la classe — fonctionnellement correct, voir Recommandé.

**E. Terrain + heatmap** — Conforme. `goalZoneHeatmap(allShots,"88%")` (l.3047), dans la fourchette 85-90% demandée, fonction non modifiée. Un seul `<svg viewBox="0 0 350 208">` par feuille (vérifié par grep, cf. section G). Écart heatmap→SVG réduit à `margin:6px auto 0` (l.3048). Bordure du SVG terrain conservée (`border:1px solid var(--border)`, l.3048).

**F. États** — Conforme. `gbs.length===0` → `.gk-col-empty` avec icône 🧤 + texte, remplace intégralement la colonne chiffres, aucun `0/0` affiché (l.3020). `gbs.length===1` → cf. D. `0/0`/`pct:"-"` traité comme une donnée normale (pas de branche spéciale). Filtre type de tir tout désactivé → `shots=[]`, comportement délégué à la logique de filtre déjà en place, rien de nouveau à écrire.

**G. Contrat plein écran** — Conforme, vérifié mécaniquement :
- `fs-btn` : exactement 1 occurrence dans le bloc `renderGkSheet` (l.3069).
- `viewBox="0 0 350 208"` : exactement 1 occurrence (l.3048).
- `grid-template-columns` : 0 occurrence **littérale** dans le texte source de `renderGkSheet` — c'est attendu et correct, puisque cette sous-chaîne n'est produite qu'au runtime par l'appel (non modifié) à `goalZoneHeatmap()`, appelé une seule fois par feuille (l.3047). Le HTML généré au final contient donc bien exactement 1 occurrence par feuille, et elle appartient uniquement au `<div>` de `goalZoneHeatmap()` — aucune autre trace dans `.gk-sheet-nums` (vérifié, cf. section C).
`openFullscreen()` non modifiée (l.2709-2769) ; `.closest(".card")` résout bien `.gk-sheet` (qui porte les deux classes, l.3068). Règle CSS l.187-193 non modifiée. Le test manuel iPad paysage/portrait mentionné par la story reste à faire par Romain/QA avant clôture — pas réalisable depuis cette revue statique, à signaler au QA.

**H. Reset `S.gkFilter`/`S.gkShotFilter`** — Conforme. Présent dans `newMatch()` (l.1401) et `[data-load-match]` (l.3912), aux mêmes emplacements que les autres resets d'état, valeurs par défaut identiques (`{home:"all",away:"all"}` / `{goals:true,saves:true,offs:true}`).

**I. Accent visuel + tokens** — Conforme sur l'essentiel, voir Bloquant #2 pour la nuance sur le "dot". Tokens présents (style.css l.17). Niveau 1 référence `var(--gk-save)` (l.3023) — usage du token, mieux que la tolérance hex. Couleurs SVG des points restent en hex littéral (`#4ECDE8`/`#50C878`/`#E89A4E`, l.3051) — strictement identiques aux valeurs des tokens, couvert par la tolérance explicite de la story. `.gk-sheet` : `border`/`box-shadow` avec `--gk-accent-rgb` conformes (style.css l.260-264), pas de fond coloré ni de gradient. Niveau 1 bien en `#4ECDE8` via le token, pas `var(--blue)`.

**J. Micro-animations** — Conforme. `.fade-in` appliquée à `.gk-sheet-nums` et `.gk-sheet-court` (l.3075-3076), pas à la carte entière (le header n'a pas la classe). Comme `R()` reconstruit tout le `innerHTML` à chaque rendu (convention du projet), l'animation rejoue naturellement à chaque changement de filtre. Aucun stagger par point SVG.

**K. Non-régression données/fonctionnel** — Conforme sur les points demandés : `gkStats()`/`gkStatsCombined()`/`selectedGbs()` non modifiées (aucune ligne différente de ce qui est documenté dans `CLAUDE.md`). `S.gkShotFilter` reste global partagé, pas dupliqué par équipe (une seule instance lue par les deux appels de `renderGkSheet`). `renderStatGk()` garde sa signature sans argument (l.3081). Voir toutefois la remarque non-bloquante sur les tirs pénalty en Recommandé.

**L. Déploiement** — Conforme. `sw.js` → `fenix-stats-v76` (≥ v76 minimum demandé). `new Function()` passe sans erreur sur `app.js` complet.

### Bloquant (passage 1 — corrigé au passage 2, voir plus haut)

1. **Tailles responsive niveau 1/niveau 2 absentes (`section C`, valeurs explicites de la story).** La story fixe littéralement `font-size:38px (≥700px) / 34px (<700px)` pour le ratio `8/11` et `23px (≥700px) / 20px (<700px)` pour le `%`. L'implémentation (app.js l.3023 et l.3025) pose ces tailles en style inline fixe (`font-size:38px`, `font-size:23px`) sans aucune variante ; aucune règle média dans `style.css` ne cible `.gk-sheet-nums` pour réduire ces tailles sous 700px (vérifié par recherche de `34px`/`20px` dans tout `style.css` et `app.js` : absentes). Concrètement, sur un écran <700px (iPhone en portrait, cas réel d'usage bord de terrain cité par le PRD), le ratio et le `%` s'affichent 4px/3px plus grands que spécifié — écart mineur en soi, mais c'est un critère chiffré et cochable de la section C, non satisfait tel quel.

2. **Le "dot" coloré des chips niveau 3 n'existe pas — le point ● reste dans la couleur neutre du texte (`section C`/`I`).** La story précise, mot pour mot : *"Chip encaissés : dot + bordure rgb(80,200,120)/rgba(80,200,120,.28), fond rgba(80,200,120,.10)"* — trois propriétés distinctes (dot en couleur pleine, bordure et fond en alpha réduit). `docs/visual/stats-gardiens.md` §5 détaille la même chose avec le markup exact : `.gk-pill .dot{width:7px;height:7px;border-radius:50%;background:rgb(var(--pill-rgb));flex-shrink:0;}`, un `<span>` séparé. L'implémentation (app.js l.3027-3028) n'a pas de `<span class="dot">` : elle imprime le caractère "●" comme simple texte dans `<span class="gk-pill" style="--gk-pill-rgb:...">● ${n} encaissés</span>`, et ce texte hérite de `color:var(--t2)` posé par `.gk-pill` (style.css l.281-283, aucune règle `.gk-pill .dot` n'existe). Résultat : le "●" s'affiche en gris/blanc neutre, **pas** en vert/orange saturé — seuls la bordure et le fond (10-28% d'opacité) portent la teinte. C'est exactly le problème que la section 0 du doc Visual Crafter cherchait à éliminer (cohérence chromatique forte entre la pastille et les points du terrain juste en dessous) : avec un dot non coloré, le lien visuel fort voulu par cette story (le but même de la section I) n'est que partiellement obtenu — un chip à peine teinté au lieu d'un point plein de la même couleur que les points "but"/"hors cadre" affichés sur le terrain juste en dessous, dans la même carte.

### Recommandé (non-bloquant, toujours ouvert après le passage 2)

1. **Duplication évitable de `accentRgb` dans le `<select>`.** `.gk-sheet` porte déjà `--gk-accent-rgb` en style inline (l.3068), mais `renderGkSheet` reconstruit `border:1px solid rgba(${accentRgb},.30)` en JS pour le `<select>` (l.3005) au lieu de laisser la classe CSS faire `border:1px solid rgba(var(--gk-accent-rgb),.30)` (héritage de custom property déjà en place). Fonctionnellement identique, mais une divergence future entre les deux valeurs (si l'une est modifiée sans l'autre) deviendrait possible. Piste simple : déplacer `border`/`color` dans `.gk-filter-select` via `var(--gk-accent-rgb)` et une classe `.home`/`.away` pour la couleur du texte.
2. ~~Label statique (1 seul GB) sans couleur d'équipe.~~ **Traité au passage 2** (voir plus haut).
3. **État `:active`/tap du `<select>` non implémenté.** Le doc Visual Crafter §3 demande `background: rgba(var(--gk-accent-rgb),.10)` au tap, absent de `.gk-filter-select`. Absent aussi des critères d'acceptation stricts de la story — pur polish, à la discrétion d'un futur passage.
4. **Cohérence des compteurs "encaissés"/"hors cadre" en présence de tirs pénalty.** Les chips niveau 3 (`gk.goals`/`gk.offs`, via `gkStats()`) excluent explicitement les tirs `isPen` (cf. définition de `gkStats()`, `!ACTIONS[e.type].isPen`), alors que les compteurs "ENCAISSÉS"/"H. CADRE" affichés sous le SVG terrain (l.3064-3065, calculés depuis `allShots`) n'excluent pas les tirs pénalty (`PEN_GOAL`/`PEN_OFF` ont `needsMap:true` et une position fixe non nulle d'après `CLAUDE.md`). Sur un match sans pénalty pour le GB filtré, aucune différence visible ; si des pénaltys existent, les deux nombres pourraient diverger dans la même carte. Cette logique de calcul semble reprise telle quelle de l'ancien code (non un nouveau calcul introduit par cette story — `gkStats()` et la logique `allShots` ne sont pas dans la liste des fonctions modifiées), donc pas un problème introduit ici selon le critère K ("valeurs identiques avant/après"). Mais la fusion des deux cartes rapproche visuellement ces deux nombres bien plus qu'avant, rendant une éventuelle divergence plus visible qu'auparavant. Suggestion : que le QA teste spécifiquement un scénario avec pénaltys sur le GB filtré pour confirmer qu'aucune confusion réelle n'apparaît à l'écran.
5. **Story/CLAUDE.md à mettre à jour** pour documenter `.gk-sheet-body` comme le vrai conteneur flex (au lieu du bloc CSS littéral de la section B), pour que la prochaine lecture de la story ne soit pas prise en défaut face au code réel.
