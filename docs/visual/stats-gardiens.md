# Visual Spec — Stats Gardiens (feuille fusionnée)

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/design/stats-gardiens.md` (Designer) et `docs/prd-v5-stats-gardiens.md`*
*Ne modifie aucune décision UX/wireframe du Designer (fusion 65/35, dropdown compact, hiérarchie 3 niveaux empilée, seuil 700px) — uniquement la couche visuelle : couleurs exactes, tailles, ombres, transitions.*

## 0. Correction de cohérence chromatique — à appliquer avant tout le reste

La maquette du Designer propose `var(--red)` pour la pastille "encaissés" ("cohérent avec le rouge 'but' utilisé partout ailleurs dans l'app"). **Ce n'est pas la bonne couleur ici, et il faut s'en écarter.**

`CLAUDE.md` et le code existant (`renderStatGk()`, terrain des tirs subis, ~ligne 3068-3085) utilisent déjà une palette **dédiée aux tirs sur GB**, distincte de la palette "équipe" :
- but encaissé → `#50C878` (vert)
- tir arrêté → `#4ECDE8` (cyan)
- hors cadre → `#E89A4E` (orange)

Aujourd'hui ces deux palettes cohabitent sans se toucher visuellement, car la carte résumé (chiffres, en haut) et la carte terrain (points de tir, en bas) sont séparées par tout un bloc de mise en page. Le résumé utilise `var(--blue)`/`var(--red)`/`var(--orange)` (palette équipe), le terrain utilise `#4ECDE8`/`#50C878`/`#E89A4E` (palette tirs). Personne ne le remarque parce que l'œil ne les compare jamais côte à côte.

**La fusion change tout ça.** Une fois les chiffres et le terrain dans la même carte à 30px l'un de l'autre, l'incohérence devient visible dans le pire sens possible : la pastille "● 2 encaissés" serait rouge juste au-dessus d'un terrain où les points "but encaissé" sont verts. Un utilisateur qui ne connaît pas le code lirait ça comme deux informations différentes, pas la même.

**Correction actée pour cette spec** — les 3 niveaux de chiffres et les pastilles reprennent strictement les couleurs dédiées tirs, pas la palette équipe :

| Donnée | Couleur maquette Designer | Couleur corrigée (Visual Crafter) | Raison |
|---|---|---|---|
| Niveau 1 `8/11` (arrêts/total) | `var(--blue)` | **`#4ECDE8`** | C'est un ratio d'*arrêts* — doit matcher visuellement les croix cyan sur le terrain juste en dessous |
| Pastille "encaissés" | `var(--red)` | **`#50C878`** | Un but encaissé est vert partout ailleurs dans cette même carte (terrain) — le garder rouge ici créerait une contradiction visuelle immédiate |
| Pastille "hors cadre" | `var(--orange)` (`#E88A4E`) | **`#E89A4E`** | Différence d'1 chiffre hexadécimal avec le token existant, invisible à l'œil mais autant utiliser le hex exact déjà câblé dans `renderStatGk()` pour un alignement pixel-perfect avec les croix du terrain |
| Niveau 2 `%` | `var(--yellow)` | **inchangé, `var(--yellow)`** | Le pourcentage n'est pas un type de tir — c'est une métrique dérivée, cohérente avec l'usage déjà établi de `var(--yellow)` pour `%ARRÊTS`/`%Pen` dans `renderGkDetailTables()` |

Le reste de cette spec applique cette correction partout. Rien d'autre ne change dans le contenu du Design.

## 1. Palette de tokens

```
--gk-save:  #4ECDE8;   /* arrêt — déjà utilisé sur le terrain, ne pas réinventer */
--gk-goal:  #50C878;   /* but encaissé — déjà utilisé sur le terrain */
--gk-off:   #E89A4E;   /* hors cadre — déjà utilisé sur le terrain */
```
Ces 3 valeurs existent déjà en dur dans `app.js` (~ligne 3068). Pas de nouvelle teinte introduite — on les remonte simplement en tokens pour qu'elles servent aussi dans la colonne chiffres, au lieu d'être dupliquées en inline à deux endroits avec des valeurs qui pourraient diverger un jour.

**Accent d'équipe pour la carte "feuille"** — réutilise exactement les paires RGB déjà en place ailleurs dans l'app (`.match-layout`/`.match-layout.poss-away`, `.player-card` via `--pc-accent`), pas de nouvelle teinte :
```
FENIX (home)     --gk-accent-rgb: 95,168,211;   /* = --fenix-sky, identique à --accent-rgb du poss-home */
Adversaire (away)--gk-accent-rgb: 232,70,90;    /* = --red, identique à --accent-rgb du poss-away */
```

## 2. Carte "feuille gardien" — bordure, ombre, accent d'équipe

Aujourd'hui, `.card` est visuellement identique pour FENIX et l'adversaire — seul le texte `card-t` change de couleur (`var(--green)`/`var(--red)`). Une fois les deux cartes fusionnées empilées verticalement (une par équipe), cette différence doit se voir sans lire le texte : c'est le repère visuel le plus rapide pour distinguer "ma carte" de "la carte adverse" en un coup d'œil bord de terrain.

- Bordure : `border: 1px solid rgba(var(--gk-accent-rgb),.22)` au lieu du `var(--card-border)` neutre actuel — teinte discrète, pas un contour saturé.
- Ombre : ajoute une lueur d'accent très légère à l'ombre existante, sans la remplacer :
  ```
  box-shadow: var(--shadow-card), 0 0 0 1px rgba(var(--gk-accent-rgb),.08);
  ```
  Au survol/tap (desktop hover only, cf. `@media(hover:hover)` déjà en place) : `0 0 0 1px rgba(var(--gk-accent-rgb),.16), var(--shadow-card-hover)` — cohérent avec le pattern `.card:hover` déjà défini, juste teinté.
- Pas de fond coloré, pas de gradient d'équipe sur toute la carte : à ce niveau de saturation on retombe dans la surcharge que le Designer et le PRD veulent justement éviter ("faux sentiment de gain" — risque déjà identifié). L'accent doit se sentir, pas s'imposer.
- `border-radius` : `var(--r3)` inchangé (cohérence avec `.card`).

## 3. Dropdown GB — style & micro-interactions

Nouvelle classe (`.gk-filter-select` selon le Designer) — dérivée de `.sb-gk-sel select` mais **pas identique**, car le contexte diffère : `.sb-gk-sel select` vit dans le scoreboard, un espace exigu où la miniaturisation est une contrainte ; ici, le header de carte a assez de place pour un contrôle tactile correct sur iPad.

```
.gk-filter-select{
  background: var(--bg3);
  border: 1px solid rgba(var(--gk-accent-rgb),.30);
  border-radius: var(--r1);
  color: var(--gk-accent-color);      /* var(--fenix-sky) côté home, var(--red) côté away — même couleur que card-t */
  font-size: 12px;
  font-weight: 600;
  padding: 5px 8px;
  min-height: 30px;                    /* cible tactile correcte sans casser la ligne d'en-tête */
  max-width: 148px;
  transition: border-color .15s ease, background .15s ease;
}
```
- État `:active`/tap : `background: rgba(var(--gk-accent-rgb),.10)` — retour tactile immédiat cohérent avec `.btn:active{transform:scale(.96)}` déjà en place ailleurs, mais **sans** le `scale()` ici (un `<select>` natif qui rétrécit au tap a un rendu bizarre sur iOS Safari, la plateforme cible) — se limiter au changement de fond.
- `:focus-visible` : règle globale déjà posée (`outline:2px solid var(--accent)`), rien à ajouter.
- **Un seul GB sélectionné** (dropdown masqué, nom statique à la place, cf. Design) : même taille de police (12px), même couleur (`var(--gk-accent-color)`), `font-weight:700` (légèrement plus appuyé qu'un select actif, pour signaler "c'est un fait, pas un choix à faire") — pas de bordure ni de fond, texte seul, aligné à la même position exacte que le select qu'il remplace (évite un saut de layout selon le nombre de GB).
- **Aucun GB** : dropdown absent, remplacé par l'état vide de la carte (section 8) — rien à styler ici.

## 4. Hiérarchie des 3 niveaux de chiffres — typographie exacte

| Niveau | Taille | Poids | Police | Couleur | Marge |
|---|---|---|---|---|---|
| **1 — `8/11`** | `38px` | `800` | `.mono` | `#4ECDE8` (corrigé, voir §0) | `line-height:1` |
| Label `ARRÊTS` | `10px` | `700` | normale | `var(--t2)` | `margin-top:2px`, `letter-spacing:.08em`, uppercase |
| **2 — `73%`** | `23px` | `800` | `.mono` | `var(--yellow)` | `margin-top:12px` (respire nettement du niveau 1, jamais collé) |
| **3 — pastilles** | voir §5 | | | | `margin-top:16px` (le plus grand écart des trois — c'est le niveau le plus subordonné) |

Pourquoi `38px` et pas `36-40px` comme fourchette du Designer : figer une valeur précise évite un arbitrage du Developer au pixel près — `38px` reste net à la lecture debout sur iPad (contrainte "2 secondes, sans scroller" du PRD) tout en laissant de la marge verticale pour le niveau 2 et le niveau 3 dans une carte qui doit tenir sans scroll.

Cas `0/0` / `pct:"-"` (début de match, cf. États du Design) : même taille/poids/couleur que le cas normal — ne jamais réduire la taille ou l'opacité d'un `0/0` ou d'un `-`, ce sont des données réelles (le PRD est explicite là-dessus), pas des placeholders visuels.

## 5. Pastilles niveau 3 — traitement visuel

Le Design décrit une pastille comme "● texte" (puce colorée + texte). Passage en véritable **chip** plutôt qu'un texte avec puce devant — traitement plus premium, cohérent avec la demande mémoire du projet de ne pas faire de retouche timide sur les éléments répétitifs :

```
.gk-pill{
  display:inline-flex; align-items:center; gap:6px;
  padding:3px 10px 3px 8px;
  border-radius:999px;
  font-size:12px; font-weight:600;
  color:var(--t2);
  background: rgba(var(--pill-rgb),.10);
  border: 1px solid rgba(var(--pill-rgb),.28);
}
.gk-pill .dot{width:7px;height:7px;border-radius:50%;background:rgb(var(--pill-rgb));flex-shrink:0;}
```
- Pastille "encaissés" : `--pill-rgb: 80,200,120` (= `#50C878`).
- Pastille "hors cadre" : `--pill-rgb: 232,154,78` (= `#E89A4E`).
- Sur desktop (≥700px, colonne ~35%) : les deux chips restent empilées verticalement, `gap:6px` entre les deux — comme spécifié par le Designer.
- Sur mobile (<700px, pleine largeur) : `flex-direction:row`, `gap:10px` — les deux chips côte à côte, comme déjà noté par le Designer comme avantage naturel du mobile.
- Ne pas mettre ces chips en `.mono` : ce sont des données contextuelles, pas des métriques de synthèse — la police normale renforce qu'elles sont d'un rang inférieur aux niveaux 1 et 2 (cohérent avec la consigne du Designer "Composants réutilisés" qui réserve `.mono` aux chiffres de synthèse).

## 6. Heatmap 3×3 + terrain — cohésion visuelle de la colonne "tirs"

Le Design demande de recalibrer la largeur de la heatmap (~85-90% de la colonne terrain, pas 40% de la carte entière) sans en préciser le traitement visuel. Deux ajustements pour que heatmap + terrain se lisent comme **un seul bloc "tirs"**, pas deux éléments empilés par hasard :

- Réduire l'écart vertical entre la heatmap et le SVG du terrain à `6px` (au lieu de l'espacement par défaut d'un bloc suivi d'un autre, généralement ~12-16px ailleurs dans l'app) — la bordure inférieure épaisse déjà existante de la heatmap (`border-bottom:3px solid var(--fenix-sky)`, ligne 1069 d'`app.js`) agit déjà comme une "ligne de but" visuelle : en resserrant l'écart, elle se lit comme la transition entre "vue du but" (heatmap) et "vue du terrain" (SVG) plutôt que comme deux widgets séparés.
- Le SVG du terrain garde son `border:1px solid var(--border)` actuel — ne pas le retirer même si visuellement proche de la heatmap : la bordure du terrain reste nécessaire pour délimiter le SVG sur le fond de carte (`--card-bg` et `--court-fill` sont deux teintes très proches, cf. `docs/visual/terrain-joueurs.md` §1 — sans bordure le terrain "fuit" dans le fond de carte).
- Aucune modification des couleurs de cellule heatmap (`rgba(80,200,120,α)` / `rgba(78,205,232,α)` déjà correctement alignées sur la palette dédiée tirs, contrairement au résumé chiffré — la heatmap n'a donc pas besoin de la correction du §0).

## 7. Filtre type de tir (Encaissés / Arrêtés / Hors cadre) — polish des 3 boutons existants

Le markup et la logique restent inchangés (Design : "seule la position verticale bouge"). Ces 3 boutons utilisent déjà les bonnes couleurs dédiées (`#50C878`/`#4ECDE8`/`#E89A4E`) — contrairement au résumé chiffré, ils n'ont pas besoin de correction de teinte, seulement de polish :

- État actif : ajouter une lueur d'accent cohérente avec `--shadow-accent` déjà défini dans `:root`, mais teintée par bouton plutôt que par `--accent-rgb` global :
  ```
  box-shadow: 0 0 0 1px rgba(var(--btn-rgb),.3), 0 0 14px rgba(var(--btn-rgb),.18);
  ```
  où `--btn-rgb` vaut `80,200,120` / `78,205,232` / `232,154,78` selon le bouton. Actuellement ces boutons n'ont qu'un changement de fond/bordure/couleur de texte, sans lueur — cette glow, courte et discrète, donne le même niveau de "feedback satisfaisant" que `.act-h.selected` déjà présent ailleurs dans l'app (`box-shadow:0 0 14px rgba(var(--accent-rgb),.22)`), sans introduire un nouveau langage visuel.
- Transition : `transition: all .15s ease` (déjà hérité de `.btn`, confirmer qu'il s'applique bien puisque le style inline actuel écrase `background`/`border-color`/`color` à chaque render — si les valeurs inline changent d'un render à l'autre sans que l'élément DOM soit recréé, la transition CSS s'applique nativement ; si `R()` recrée le DOM à chaque clic, ajouter la classe utilitaire déjà existante `.fade-in` sur le bouton concerné pour simuler une transition d'état, cf. §9).
- État barré/inactif (`opacity:.4;text-decoration:line-through`) : inchangé, déjà cohérent.

## 8. États

- **Aucun GB sélectionné** : la colonne chiffres est remplacée par un message centré, même traitement que `.court-empty-msg` (`docs/visual/terrain-joueurs.md` §2), adapté à la largeur de colonne (~35% desktop / pleine largeur mobile) :
  ```
  .gk-col-empty{
    display:flex; flex-direction:column; align-items:center; justify-content:center;
    gap:6px; color:var(--t3); font-size:12px; text-align:center; min-height:120px;
  }
  .gk-col-empty .icon{font-size:22px; opacity:.5;}
  ```
  Icône `🧤`, texte "Aucun gardien sélectionné" — reprend `var(--t3)` déjà validé partout comme ton neutre pour les états vides, aucune nouvelle couleur.
- **Un seul GB** : voir §3, dropdown remplacé par label statique, chiffres/terrain fonctionnent normalement, aucun traitement d'état vide.
- **`0/0` et `-`** : voir §4, même style que le cas rempli, jamais atténué.
- **Filtre type de tir toutes catégories désactivées** : comportement déjà géré, pas de nouveau style — le terrain affichera naturellement 0 point.

## 9. Micro-animations

Le vrai gain de cette fusion (souligné par le Design) est que changer le dropdown GB met à jour **simultanément** les chiffres et le terrain, dans la même carte, sans déplacer le regard. Pour que ce lien se *sente* et pas seulement se voit :

- Sur `change` du dropdown GB (et sur clic des boutons de filtre type de tir) : appliquer la classe utilitaire déjà existante `.fade-in` (`@keyframes fadeIn{from{opacity:0;transform:translateY(-5px);}to{opacity:1;transform:translateY(0);}}`, `.25s ease`) au bloc "colonne chiffres" ET au bloc "terrain+heatmap" de la carte concernée, au moment du re-render. Les deux blocs jouent l'animation **en même temps** — c'est ce qui rend visible, dans le mouvement, que les deux proviennent du même changement de filtre. Ne pas l'appliquer à la carte entière (le header avec le nom d'équipe et le dropdown lui-même ne doivent pas re-clignoter à chaque changement, seulement le contenu qui vient de changer).
- Durée volontairement courte (`.25s`, déjà le standard de l'app, cf. identité Visual Crafter — jamais >250ms) : assez pour être perçu, pas assez pour ralentir une lecture répétée pendant un match.
- Pas d'animation sur les points de tir individuels du SVG (pas de stagger, pas d'apparition point par point) : avec potentiellement une dizaine de tirs affichés, une animation par point serait un gadget qui ralentit la lecture plutôt qu'il ne l'accélère — le fade-in de groupe suffit.
- Bouton `⛶` plein écran : aucun changement, transition déjà standard (`.15s`) sur `.fs-btn:active`.

## 10. Plein écran (⛶)

Rappel du point d'attention déjà signalé par le Designer (§ Plein écran de son doc) : la colonne chiffres ne doit **pas** utiliser `display:grid` avec `grid-template-columns` en style inline (règle CSS existante `.fs-overlay-body>.card.fs-court div[style*="grid-template-columns"]` la capturerait par erreur, ligne 187 `style.css`). Ceci concerne aussi le §5 : les chips `.gk-pill`, si empilées via un conteneur, doivent utiliser `display:flex;flex-direction:column`, jamais `grid`.

En plein écran, la lueur d'accent d'équipe (§2) et le fade-in (§9) restent identiques — pas de traitement spécifique nécessaire, `.fs-overlay-body>.card` hérite déjà de `.card`.

## 11. Responsive <700px — ajustements spécifiques

| Élément | ≥700px | <700px |
|---|---|---|
| Niveau 1 `8/11` | `38px` | `34px` (légère réduction, la carte fait toute la largeur mais reste contrainte en hauteur) |
| Niveau 2 `%` | `23px` | `20px` |
| Chips niveau 3 | empilées, `gap:6px` | côte à côte, `gap:10px` |
| Heatmap | ~85-90% colonne terrain | ~70-80% carte, centrée (déjà spécifié par le Designer) |
| Dropdown GB | `max-width:148px` | `max-width:130px` (header doit tenir sur 1 ligne avec un nom d'équipe potentiellement long) |
| Accent bordure carte (§2) | inchangé | inchangé — pas de raison de le retirer, coûte rien en largeur |

## Checklist contraste WCAG

- `#4ECDE8` (niveau 1) sur `--card-bg` (fond ≈ `#131c26` à cette opacité) : contraste ≈ 8.5:1 — largement conforme AA, déjà utilisé tel quel sur le terrain sans problème signalé.
- `#50C878` (pastille encaissés) sur fond chip `rgba(80,200,120,.10)` composé sur `--card-bg` : contraste du texte `var(--t2)` (pas du vert lui-même, qui n'est que le dot+bordure) ≈ conforme, `var(--t2)` déjà validé partout ailleurs dans l'app pour du texte secondaire.
- `#E89A4E` (pastille hors cadre) : même raisonnement, déjà en production sur le terrain à cette luminosité.
- `var(--yellow)` (niveau 2) : déjà validé (utilisé pour `%ARRÊTS`/`%Pen` en production sans changement ici).
- Texte du dropdown (`var(--fenix-sky)`/`var(--red)` selon équipe) sur `var(--bg3)` : même contraste que `.sb-gk-sel select` déjà en production, aucun nouveau risque.
- Aucune combinaison entièrement nouvelle n'est introduite par cette spec — tout est soit déjà validé ailleurs dans l'app (réutilisation stricte), soit une correction vers une couleur *déjà* en production sur le même écran (§0), donc déjà éprouvée en conditions réelles.
