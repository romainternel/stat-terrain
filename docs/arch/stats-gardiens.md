# Architecture — Stats Gardiens (fusion des cartes)

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v5-stats-gardiens.md`, `docs/design/stats-gardiens.md`, `docs/visual/stats-gardiens.md`*
*Concerne `renderStatGk()` (`app.js` ~2992-3094), `renderGkDetailTables()` (~2946-2990), `openFullscreen()` (~2708-2768), `goalZoneHeatmap()` (~1057-1079), et les règles CSS `.stat-courts`/`.fs-court` (`style.css`)*

## Décision technique globale

Refonte de présentation pure, en CSS + JS existant, zéro nouvelle dépendance, zéro changement de structure de données. Toute la logique de calcul (`gkStats()`, `gkStatsCombined()`, `selectedGbs()`) reste intouchée. Le seul JS qui bouge : `renderStatGk()` est **restructuré** (pas juste retouché en place) pour rester lisible, et le binding du filtre GB passe de boutons à un `<select>`.

## 1. Découpage de `renderStatGk()` : extraction de `renderGkSheet(side)`

**Décision : extraire une nouvelle fonction `renderGkSheet(side)`, appelée par `renderStatGk()`.** Pas de modification en place.

Pourquoi : `renderStatGk()` fait aujourd'hui ~102 lignes et construit dans une seule fonction deux `.stat-courts` distincts (résumé chiffré, puis terrain+heatmap) via deux `.map(["home","away"])` séparés. La fusion demandée par le PRD/Design supprime cette séparation : les deux blocs par équipe deviennent un seul bloc par équipe. Garder tout ça inline ferait grimper `renderStatGk()` à une fonction encore plus longue et plus dense (dropdown GB + 3 niveaux de chiffres + heatmap + terrain SVG + légende, le tout dans un seul `.map`), ce qui casse la convention déjà en place dans ce fichier (beaucoup de petites fonctions `renderXxx()` à responsabilité unique — `renderGkDetailTables()`, `renderPdfTab()`, etc.).

Nouvelle structure :

```javascript
function renderStatGk(){
  const sf = S.gkShotFilter;
  let html = renderShotTypeFilterBar(sf); // remonté au-dessus des feuilles (Design: "Vue d'ensemble")
  html += `<div class="stat-courts">
    ${["home","away"].map(side=>renderGkSheet(side)).join("")}
  </div>`;
  html += renderGkDetailTables(); // inchangée, position inchangée
  return html;
}

function renderGkSheet(side){
  // gbs, filter, gk = gkStats/gkStatsCombined, name/dropdown, shots, heatmap, court SVG
  // -> une seule <div class="card gk-sheet"> par équipe, un seul <button class="fs-btn">
}
```

`renderShotTypeFilterBar(sf)` est une extraction mineure supplémentaire (le bloc de 3 boutons Encaissés/Arrêtés/Hors cadre, ~6 lignes, inchangé fonctionnellement) — surtout utile parce qu'il change de position dans le flux (remonte au-dessus des feuilles) ; l'isoler en fonction évite de la dupliquer visuellement dans le code de `renderStatGk()`. Optionnel si le Developer préfère la garder inline vu sa taille réduite — pas structurant.

**Ce qui ne change pas** : `renderGkDetailTables()` reste telle quelle, appelée à la même place logique (après les feuilles).

## 2. Bouton plein écran (`.fs-btn` / `openFullscreen()`) — compatible sans modification de `openFullscreen()`

Vérifié dans le code (`app.js` ~2708-2768) : `openFullscreen(cardEl)` clone le `.card` cliqué, détecte la présence d'un `<svg viewBox="0 0 350 208">` pour ajouter `.fs-court` et appliquer l'agrandissement dédié (terrain 100%, redimensionnement du div heatmap détecté par `clone.querySelector('div[style*="grid-template-columns"]')`).

**Ça fonctionne sans changement sur `openFullscreen()`**, à trois conditions que le Developer doit respecter dans le nouveau markup :

1. **Un seul `.fs-btn` par feuille fusionnée**, pas un par colonne interne. Aujourd'hui il y en a deux (un sur la carte résumé, un sur la carte terrain) parce que ce sont deux `.card` séparées ; demain une seule feuille = un seul bouton, positionné sur le wrapper `.gk-sheet`.
2. **Le wrapper de la feuille garde la classe `.card`** en plus de `.gk-sheet` (`class="card gk-sheet"`, pas `class="gk-sheet"` seul). Le binding générique existant (`document.querySelectorAll(".fs-btn").forEach(btn=>{...btn.closest(".card")...})`, `app.js` ~3622) résout la carte via `.closest(".card")` — s'il n'y a pas de `.card` sur le wrapper, `openFullscreen()` ne sera jamais appelé.
3. **La colonne chiffres ne doit contenir aucun autre `<svg viewBox="0 0 350 208">` ni aucun autre `div[style*="grid-template-columns"]`** que ceux déjà attendus (le terrain et la heatmap). Ces deux sélecteurs (un `querySelector` JS singulier + une règle CSS) supposent qu'il n'existe qu'une seule occurrence de chacun dans la carte — voir point 4 ci-dessous, qui est la même contrainte vue côté CSS.

Le reste du mécanisme de plein écran (branche `if(courtSvg)`, resize du SVG à 100%, resize de la heatmap à 85%/600px/20px) s'applique tel quel à la feuille fusionnée puisqu'il clone et redimensionne des éléments internes par sélecteur, pas par structure de carte fixe. La disposition interne de `.gk-sheet` (flex côte-à-côte / colonne) reste active dans l'overlay plein écran (qui s'affiche toujours ≥700px de large sur iPad, donc dans le mode "côte à côte") sans code supplémentaire — le clone garde ses classes CSS.

**Aucune modification de `openFullscreen()` n'est nécessaire.**

## 3. Binding du filtre GB — remplacement, pas coexistence

**Décision : le `<select>` remplace entièrement le binding des boutons `[data-gk-filter]`, il ne coexiste pas avec.**

Le PRD est explicite : le filtre reste "fonctionnellement identique, juste un autre widget" (pas un widget en plus). Le Design confirme : le `<select>` "Remplace la rangée de boutons actuelle". Il n'y a donc jamais les deux widgets affichés en même temps pour un même côté — un seul contrôle par équipe, sous une forme qui dépend de `gbs.length` (select si ≥2, texte statique si 1, rien si 0, cf. Design §États).

Changement concret dans `bind()` (`app.js` ~3661-3667) : supprimer le bloc `document.querySelectorAll("[data-gk-filter]")` (boutons) et le remplacer par :

```javascript
document.querySelectorAll("[data-gk-filter-select]").forEach(el=>{
  el.onchange=()=>{
    S.gkFilter[el.dataset.gkFilterSelect]=el.value;
    R();
  };
});
```

avec un markup `<select class="gk-filter-select" data-gk-filter-select="${side}"><option value="all">Tous les GB</option>...</select>`. **`S.gkFilter` (état global `{home,away}`) ne change pas de forme** — seule la façon de l'écrire change (un `change` d'un `<select>` au lieu d'un `click` sur un bouton). Aucun nouvel état à créer. Quand `gbs.length===1` ou `0`, aucun `<select>` n'est rendu pour ce côté : `querySelectorAll` ne trouve rien à binder, pas de cas d'erreur à gérer.

## 4. CSS — grid vs flex pour la colonne chiffres (point flaggé par le Designer, vérifié)

Vérification faite dans `style.css` : la règle exacte est ligne 187 —

```css
@media (orientation:landscape){
  .fs-overlay-body>.card.fs-court div[style*="grid-template-columns"]{width:50%!important;max-width:400px!important;font-size:18px!important;}
  ...
}
```

Elle cible **tout** `div` dont le `style` inline contient la sous-chaîne `"grid-template-columns"`, à l'intérieur d'un `.card.fs-court`, en orientation paysage. Aujourd'hui il n'y en a qu'un par carte : le div produit par `goalZoneHeatmap()` (`app.js` ~1069, `style="display:grid;grid-template-columns:1fr 1fr 1fr;..."`). C'est volontaire — cette règle a été écrite pour cibler précisément la heatmap.

**En plus de cette règle CSS**, `openFullscreen()` fait la même hypothèse côté JS avec un `querySelector` **singulier** (~ligne 2729) : `clone.querySelector('div[style*="grid-template-columns"]')` — il ne prend que la **première** occurrence trouvée dans le DOM. Si la colonne chiffres utilisait aussi `display:grid` avec un style inline contenant `grid-template-columns`, deux problèmes surviendraient simultanément : (a) la règle CSS lui appliquerait `width:50%!important` en plein écran paysage, ce qui n'a aucun sens pour une colonne de chiffres empilés verticalement ; (b) selon l'ordre du DOM, le `querySelector` JS pourrait cibler la colonne chiffres au lieu de la heatmap, et ne jamais redimensionner la vraie heatmap en plein écran.

**Consigne exacte pour le Developer** : la colonne chiffres (niveaux 1/2/3 + pastilles) doit être construite exclusivement avec `display:flex;flex-direction:column` (ou des blocs simples empilés sans `display:grid` du tout) dans son style inline. Aucune règle `grid-template-columns` ne doit apparaître dans le style inline de quoi que ce soit à l'intérieur de `.gk-sheet` en dehors de la heatmap elle-même (produite par `goalZoneHeatmap()`, inchangée). C'est non négociable, pas une préférence stylistique — c'est ce qui garde la détection JS et la règle CSS fonctionnelles sans les modifier.

## 5. `.stat-courts` vs nouvelle classe `.gk-sheet` — aucun risque de régression, classes orthogonales

Vérifié dans `style.css` (ligne 255-256) :

```css
.stat-courts{display:grid;grid-template-columns:1fr 1fr;gap:12px;}
@media(max-width:700px){.stat-courts{grid-template-columns:1fr;}}
```

`.stat-courts` gère un seul axe : la grille à 2 colonnes qui met FENIX et l'adversaire côte à côte (repliée à 1 colonne sous 700px). C'est un rôle qu'elle joue déjà aujourd'hui pour les deux blocs séparés (résumé, terrain) et qu'elle continuera de jouer demain pour les deux `.gk-sheet` (une par équipe) — **rien ne change dans `.stat-courts`, ni règle, ni modificateur**.

L'empilement demandé par le Designer (terrain/heatmap ↔ chiffres, côte à côte ≥700px puis empilés <700px) est un **second axe, interne à chaque carte**, complètement indépendant du premier. Il ne doit **pas** vivre comme un modificateur de `.stat-courts` (pas de `.stat-courts.stacked`) : `.gk-sheet` est une classe nouvelle, imbriquée un niveau plus bas, qui régit la disposition *à l'intérieur* d'une carte déjà positionnée par `.stat-courts`. Les deux grilles ne se voient jamais l'une l'autre — zéro conflit de spécificité, zéro risque de régression sur `.stat-courts` existant (utilisé aussi par `renderStatCompare()`/`renderGkDetailTables()`/`posSvg`, qu'on ne touche pas).

```css
.stat-courts > .card.gk-sheet{
  display:flex;
  flex-direction:row-reverse;   /* voir note ordre DOM ci-dessous */
  gap:16px;
}
.stat-courts > .card.gk-sheet .gk-sheet-court{ flex:0 0 65%; min-width:0; }
.stat-courts > .card.gk-sheet .gk-sheet-nums{ flex:0 0 35%; min-width:0; }
@media(max-width:700px){
  .stat-courts > .card.gk-sheet{ flex-direction:column; }
}
```

**Note technique sur l'ordre DOM/visuel** (détail non couvert par le Design, nécessaire pour que le repli mobile respecte "chiffres d'abord, terrain ensuite" sans dupliquer de markup) : mettre la **colonne chiffres en premier dans le DOM**, puis la colonne terrain. En `row-reverse` (≥700px), l'ordre visuel s'inverse — le terrain apparaît à gauche (~65%), les chiffres à droite (~35%), conforme à la maquette. En `column` (<700px), `flex-direction` ne touche pas l'ordre du DOM — les chiffres restent affichés en premier (en haut), le terrain en second (en bas), exactement l'ordre demandé par le Designer pour mobile ("les chiffres d'abord, le terrain ensuite"). Un seul flip de `flex-direction` suffit donc à couvrir les deux dispositions sans `order:` CSS ni JS conditionnel selon la largeur d'écran.

## Impact sur l'existant

- `renderStatGk()` : restructurée (voir §1), signature et usage externe inchangés (toujours appelée depuis le routeur de vues Stats sans argument).
- `renderGkDetailTables()` : aucun changement.
- `openFullscreen()` : aucun changement de code (voir §2), seulement des contraintes de markup à respecter côté appelant.
- `bind()` : un bloc remplacé (`[data-gk-filter]` boutons → `[data-gk-filter-select]` select), le reste de `bind()` non affecté.
- `goalZoneHeatmap(shots, width)` : signature inchangée, seule la valeur de `width` passée par `renderGkSheet()` change (`"40%"` de la carte entière aujourd'hui → recalculée en `%` de la colonne terrain, ~85-90%, cf. Design/Visual). Aucun changement de la fonction elle-même.
- `style.css` : ajout de `.gk-sheet` + variantes responsive (§5), plus les tokens/couleurs du Visual Crafter (`--gk-save`/`--gk-goal`/`--gk-off`, `.gk-pill`, `.gk-filter-select`, `.gk-col-empty`). Aucune règle existante modifiée — uniquement additive.
- `S.gkFilter` / `S.gkShotFilter` : structure inchangée (§3), aucune nouvelle clé d'état.
- Pas d'impact sur `gkStats()`/`gkStatsCombined()`/`selectedGbs()`/structure d'événement — conforme au PRD (100% présentation).

## Nouvelles structures de données

Aucune. Confirmé par le PRD et vérifié dans le code : cette refonte ne touche à aucun état persistant, aucun schéma IndexedDB/Supabase, aucune structure d'événement.

## Nouvelles fonctions / modules

- `renderGkSheet(side)` — nouvelle fonction, responsabilité : construire la feuille gardien fusionnée pour un côté (`"home"`/`"away"`) : header (nom équipe + dropdown/label GB + `.fs-btn` unique), colonne terrain (heatmap + SVG + légende), colonne chiffres (3 niveaux + pastilles), état vide si `gbs.length===0`.
- `renderShotTypeFilterBar(sf)` — extraction optionnelle et mineure (§1), pas structurante.
- Pas de nouveau module JS séparé, pas de découpage d'`app.js` en plusieurs fichiers — hors de proportion avec l'ampleur du changement (cf. critère de bascule ci-dessous).

## Risques (vue technique)

- **Régression plein écran si la consigne §4 n'est pas respectée** : le risque le plus concret de cette refonte. Si le Developer construit la colonne chiffres avec un `display:grid` en style inline "pour faire vite", la règle CSS ligne 187 et le `querySelector` singulier d'`openFullscreen()` produiront un plein écran cassé (mauvaise heatmap redimensionnée, ou colonne chiffres écrasée à 50% en paysage) — silencieux à l'écran normal, visible seulement en testant le bouton ⛶ en paysage iPad. **Test explicite à prévoir côté QA** : ouvrir le plein écran des deux feuilles (FENIX et adverse) en paysage iPad, vérifier que seule la heatmap est redimensionnée et que la colonne chiffres garde sa mise en page verticale.
- **Un seul `.fs-btn` oublié en double** si le Developer copie-colle les deux boutons existants au lieu d'en garder un seul sur le wrapper fusionné — provoquerait deux clones de carte empilés dans l'overlay (`openFullscreen` est appelé deux fois sur le même `.card` via `closest`). À vérifier visuellement en revue de code, pas seulement en test fonctionnel (les deux boutons produiraient le même résultat correct pris isolément, la redondance ne casse rien mais indique un oubli de nettoyage).
- **Ordre DOM chiffres/terrain (§5)** : si le Developer inverse l'ordre du markup (terrain avant chiffres) en pensant que `flex-direction:column` seul suffit pour le mobile, le repli mobile affichera le terrain en premier au lieu des chiffres — contraire à la spec Design. Pas une régression fonctionnelle (les critères d'acceptation du PRD ne portent pas sur l'ordre mobile précis) mais un écart visible par rapport à la maquette validée.
- Aucun risque identifié côté données/sync (Supabase, IndexedDB) — cette feature ne touche à aucun de ces chemins.

## Critère de bascule

`app.js` reste un fichier unique (~4341 lignes avant cette story). Cette refonte ajoute une fonction et en modifie une, sans changer l'organisation générale du fichier — elle reste largement en dessous du seuil qui justifierait un découpage en modules. Le jour où l'onglet Stats accumulerait une logique de rendu significativement plus complexe que de l'agencement (ex : plusieurs modes d'affichage persistés par utilisateur, pas seulement responsive), ce serait le signal pour extraire les fonctions `renderStatXxx()` dans un fichier dédié (`stats.js`) — pas justifié par cette story.
