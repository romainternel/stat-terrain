# Code Review — STORY-47 (Détail joueur au format compact)

## Portée revue
`app.js` : uniquement le `return` final de `renderPlayerDetail()` (~ligne 2627-2732) — calculs (`shots`, `goals`, `totalShots`, `assists`, `pct`, `zoneData`, `penData`, `zoneShots`, `selInfo`) strictement inchangés, `id="pd-overlay"` renommé en `id="pd-detail-overlay"`. `style.css` : nouvelle classe `.pd-modal` + animation, suppression de 2 lignes obsolètes dans `@media (orientation:landscape)`. Comparé à `docs/design/detail-joueur-format-compact.md` et `docs/arch/detail-joueur-format-compact.md`.

## Conformité architecture
- Conteneur `.overlay`/`.pd-modal` conforme à la structure "avant/après" documentée par l'Architecture — aucun écart.
- `.pd-modal` ne déclare ni `border` ni `border-radius` (repose sur `.card`/`.gk-sheet` pour ces propriétés) — **vérifié dans le CSS livré, conforme au point de vigilance R1 explicitement signalé par le Risk Analyst**.
- `accentRgb` calculé à l'identique de `renderGkSheet()` (`"95,168,211"`/`"232,70,90"`) — pas de nouvelle palette.
- Grille Impact et terrain SVG déplacés tels quels dans `.gk-sheet-court`, aucune ligne de leur contenu interne modifiée — `id`/classes internes (`pd-goalzone`, `pd-court-svg`, `data-pd-shot`) tous préservés.

## Bug trouvé et corrigé pendant le développement (avant cette revue)
**Collision d'`id`** : le nouveau conteneur reprenait `id="pd-overlay"`, déjà utilisé par une fonction totalement différente (`renderPdSelect()` ~ligne 2214, l'overlay de sélection de passe décisive après un but, piloté par `S.pdSelect`). Aucun crash possible en usage normal (les deux vues ne sont jamais montées simultanément — `S.pdSelect` vit sur l'écran Match, `S.playerDetail` sur Stats), mais un `id` HTML dupliqué reste incorrect et un piège pour un futur développement. Corrigé en renommant le nouveau conteneur `id="pd-detail-overlay"` — trouvé par une recherche de code systématique (`grep "pd-overlay"`) avant toute vérification visuelle, pas découvert a posteriori.

## Nettoyage CSS
`@media (orientation:landscape){ .pd-goalzone{...} .pd-court{...} }` (2 lignes) supprimées — ces overrides `!important` étaient spécifiques à l'ancien overlay plein écran (forçaient une largeur réduite en paysage, où le plein écran aurait sinon rendu la grille/le terrain disproportionnés). Avec le nouveau conteneur déjà étroit (`.gk-sheet-court`, ~65% de 520px), ces overrides seraient devenus contre-productifs (rétrécissement en double) — confirmé par grep que `.pd-goalzone`/`.pd-court` ne sont utilisées nulle part ailleurs dans `app.js`, donc suppression sans risque de régression sur un autre écran.

## Conventions de code
- Réutilisation directe des classes `.gk-lvl1`/`.gk-lvl2`/`.gk-pill`/`.gk-pill-group`/`.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court` — aucune classe dupliquée, conforme à la convention "reprendre le format visuel" du PRD.
- `--gk-pill-rgb` fixé en style inline par pill (`240,199,94` jaune pour PD, `150,160,175` neutre pour TIRS) — pas de valeur recopiée par erreur de Gardien (vert/orange) : vérifié par lecture directe des valeurs dans le code, conforme au point de vigilance R3 du Risk Analyst.

## Scope
Aucun fichier hors `app.js`/`style.css` touché. Aucune fonction partagée modifiée (`shotViewToggleHtml()`, `courtSvgMarkup()`, `renderCourtZones()` consommées en lecture seule, comme avant).

## Vérification visuelle et fonctionnelle (menée par le Developer avant cette revue)
Captures d'écran réelles sur iPad paysage (1024×768), iPad portrait (768×1024) et iPhone portrait (390×844), modes points et zones — modale centrée horizontalement et verticalement dans les trois cas (vérifié explicitement, demande prioritaire de Romain). Disposition 2 colonnes confirmée sur iPad (côte à côte), bascule en colonne unique confirmée sur iPhone (breakpoint `@media(max-width:700px)` déjà existant dans `.gk-sheet-body`, hérité sans modification). Interactions vérifiées par **vrais clics CDP** (pas seulement injection d'état) : ouverture via clic réel sur 🎯, sélection d'un tir individuel via clic réel (grille Impact filtrée, halo blanc sur le tir, info bar affichée), fermeture via clic réel sur "✕ Fermer".

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- En-tête (nom joueur + nom équipe) peut passer sur 2 lignes sur iPhone très étroit selon la longueur du nom d'équipe — comportement de retour à la ligne du texte, pas une régression (largeur de contenu comparable à l'ancien overlay plein écran sur ce même viewport), non bloquant.

## Verdict
**APPROUVÉ**
