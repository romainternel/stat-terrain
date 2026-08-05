# Visual Spec — Encart Pénalty sur le terrain

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/prd-v6-encart-penalty.md` et la proposition informelle du Designer (structure de l'encart, badge jaune, 3 boutons, bouton de sortie non-destructeur — non encore formalisée en fichier `docs/design/`).*
*Ne modifie aucune décision UX/structure du Designer (l'encart étend `.ap-validate` in-place, le terrain reste cliquable pendant l'ouverture, la grille `.goal-zone-grid.gz-big` est réutilisée à l'identique) — uniquement la couche visuelle : couleurs exactes, ombres, transitions, typographie.*

## 0. Correction de cohérence chromatique — à appliquer avant tout le reste

L'objet `ACTIONS` (`app.js` ~ligne 20-32) définit déjà des couleurs pour les 3 issues pénalty, mais elles ne sont **ni cohérentes entre elles, ni cohérentes avec la palette dédiée "tirs" déjà introduite en STORY-30** (`--gk-goal`/`--gk-save`/`--gk-off`, réutilisée dans `renderGkSheet()` et `docs/visual/stats-gardiens.md`).

Constat sur le code actuel :
```
PEN_GOAL: color:"var(--green)"   // = #5FA8D3 (bleu ciel FENIX)
PEN_SAVE: color:"var(--blue)"    // = #5FA8D3 (identique à --green, aucune distinction possible)
PEN_OFF:  color:"var(--orange)"  // = #E88A4E
```
`--green` et `--blue` valent **le même hex** (`#5FA8D3` — cf. `CLAUDE.md` : *"il n'y a plus de vert distinct"*). Conséquence concrète et déjà présente en production : dans le fil d'événements, le label **"But Pen" et le label "Arrêt Pen" s'affichent aujourd'hui exactement dans la même couleur**. Un `PEN_GOAL` et un `PEN_SAVE` sont indiscernables au premier coup d'œil dans le feed — alors que leurs équivalents non-pénalty (`GOAL`=bleu / `SAVE`=rouge) sont eux bien distincts. C'est une régression de lisibilité silencieuse, indépendante de ce cycle mais que ce cycle rend visible puisqu'il ajoute un nouveau point d'entrée (l'encart) qui doit afficher ces 3 issues de façon non-ambiguë.

**Correction actée pour cette spec** — les 3 couleurs `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` sont réalignées sur la palette `--gk-*` déjà en production (STORY-30), pas sur la palette "action normale" (bleu/rouge/orange) :

| Type d'événement | Couleur actuelle (`ACTIONS`) | Couleur corrigée | Raison |
|---|---|---|---|
| `PEN_GOAL` | `var(--green)` → `#5FA8D3` | **`var(--gk-goal)` → `#50C878`** | Un but est vert partout où l'app raisonne déjà "issue d'un tir vers un but" (heatmap gardien) ; le bleu était en fait la couleur "action FENIX", pas la couleur "but" |
| `PEN_SAVE` | `var(--blue)` → `#5FA8D3` (= identique à `PEN_GOAL`) | **`var(--gk-save)` → `#4ECDE8`** | Corrige l'indistinction actuelle avec `PEN_GOAL` ; cyan est déjà la couleur "arrêt" partout ailleurs (terrain de tir, filtres `renderGkSheet()`) |
| `PEN_OFF` | `var(--orange)` → `#E88A4E` | **`var(--gk-off)` → `#E89A4E`** | Différence d'1 chiffre hex, déjà notée dans `docs/visual/stats-gardiens.md` §0 — alignement pixel-perfect avec le token déjà utilisé pour "hors cadre" partout ailleurs |

**Ce qui ne change pas** : `GOAL`/`SAVE`/`OFF` (les tirs normaux, non-pénalty) gardent leurs couleurs actuelles (`var(--green)`/`var(--red)`/`var(--orange)`) sans aucune modification — la barre d'actions normale (`.ml-actions`), le feed des tirs normaux, et tout le reste du workflow non-pénalty restent visuellement identiques. C'est une correction **strictement scopée aux 3 variantes `PEN_*`**, cohérente avec le Must Have #8 du PRD ("aucune régression sur le workflow non-pénalty").

Effet secondaire positif : la palette `--gk-*` devient désormais la palette pénalty **partout** dans l'app (encart de saisie ET feed d'événements), pas seulement dans l'encart — un `PEN_GOAL` sera vert à la fois au moment de la saisie (bouton de l'encart) et plus tard dans le feed, sans divergence.

*(Hors scope explicite : la palette bleu/rouge/orange des tirs normaux `GOAL`/`SAVE`/`OFF` n'est pas remise en cause par cette spec — un futur audit chromatique transverse pourrait un jour envisager d'unifier les deux palettes, mais ce n'est ni demandé par le PRD ni dans le périmètre de ce cycle.)*

## 1. Palette de tokens — aucun nouveau token

Tout ce dont l'encart a besoin existe déjà dans `:root` :
```
--yellow: #F0C75E;    /* badge tireur, anneau doré, label "MODE PENALTY" */
--gk-goal: #50C878;   /* bouton BUT */
--gk-save: #4ECDE8;   /* bouton ARRÊT */
--gk-off:  #E89A4E;   /* bouton HORS CADRE */
--bg:      #0F1923;   /* texte sur fond doré plein (anneau du tireur) */
--t2, --t3, --border  /* joueurs non désignés, neutres */
```
Triplets RGB nécessaires pour les glows (identiques à ceux déjà utilisés dans `renderGkSheet()`/`docs/visual/stats-gardiens.md` — ne pas en réinventer de nouveaux) :
```
--pen-goal-rgb: 80,200,120;   /* = --gk-goal */
--pen-save-rgb: 78,205,232;   /* = --gk-save */
--pen-off-rgb:  232,154,78;   /* = --gk-off */
```

## 2. Structure visuelle de l'encart — extension de `.ap-validate`, pas un nouveau calque

Conforme à la décision du Designer : l'encart occupe **exactement le même emplacement DOM** que `.ap-validate` aujourd'hui (le `statusHtml` produit par `renderMatchPanel()`, juste au-dessus de `.court-pick`, dans `.ml-court`). Ce n'est pas une modale, pas d'`overlay`/`backdrop-filter` plein écran — le terrain doit rester visible et lisible en dessous, exactement comme demandé.

Nouvelle classe `.ap-pen-panel`, utilisée **uniquement** quand l'état "en attente d'issue pénalty" est actif (remplace `.ap-validate` dans ce cas précis ; `.ap-validate` reste inchangée et utilisée telle quelle pour tout le reste du workflow — PB, PO avant conversion, Jet franc, tir normal en cours) :

```
.ap-pen-panel{
  position:relative;
  display:flex; flex-direction:column; gap:8px;
  padding:8px 64px 8px 10px;   /* 64px à droite = espace réservé au bouton ✕ Fermer, absolu */
  margin-bottom:4px;
  border-radius:var(--r2);
  border:1.5px solid rgba(240,199,94,.35);
  background:rgba(240,199,94,.05);
  animation:fadeIn .25s ease;   /* keyframe fadeIn déjà existante (style.css ~ligne 237) */
}
```
- Bordure et fond **très légèrement teintés** (`.35`/`.05` d'opacité) — pas une carte opaque saturée. Même logique de retenue que `docs/visual/stats-gardiens.md` §2 ("l'accent doit se sentir, pas s'imposer") : l'encart doit se lire comme une extension éclairée de la barre existante, pas comme une nouvelle boîte qui s'empile visuellement sur le terrain.
- `position:relative` sert d'ancrage au bouton ✕ Fermer positionné en absolu (§5) — garantit qu'il reste **toujours** en haut à droite, y compris si le contenu du header passe sur 2 lignes en largeur réduite (iPhone portrait).

### 2.1 Header (`.ap-pen-head`)
```
.ap-pen-head{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
```
Contenu, dans l'ordre :
1. Badge mode (existant, simplement déplacé — voir §2.2)
2. Badge tireur désigné (§3)

Le bouton ✕ Fermer n'est **pas** un enfant de `.ap-pen-head` — il est positionné en absolu directement dans `.ap-pen-panel` (§5), pour ne jamais dépendre du flux du header.

### 2.2 Badge "MODE PENALTY" — déplacé tel quel, pas recréé
Le PRD (décision actée #2) demande l'absorption du badge autonome `.ml-status` — pas un double signal. Concrètement : **le badge existant (même style, même texte) est simplement déplacé** du `.ml-status` vers l'intérieur de `.ap-pen-head`, il n'est pas redessiné :
```
/* Style déjà existant dans app.js ligne ~1838, à promouvoir en classe .ap-mode-badge-pen */
background:rgba(240,199,94,.12); border:1.5px solid var(--yellow);
border-radius:6px; padding:3px 10px; font-size:10px; font-weight:700;
color:var(--yellow); letter-spacing:.06em;
```
Texte inchangé : `🎯 MODE PENALTY`. Aucune nouvelle couleur, aucun nouveau texte — Romain reconnaît immédiatement un signal déjà familier, seulement déplacé d'emplacement.

## 3. Badge tireur désigné + anneau doré sur le terrain

### 3.1 Badge (dans le header de l'encart)
Nouvelle classe modificatrice sur la classe existante `.ap-badge` (réutilise sa géométrie déjà en place — `padding:2px 8px`, `border-radius:6px`, `font-size:10px`, `font-weight:700` — seule la couleur change) :
```
.ap-badge.ap-badge-pen{
  background:rgba(240,199,94,.15); border:1px solid var(--yellow); color:var(--yellow);
  display:inline-flex; align-items:center; gap:6px;
}
.ap-badge-pen .dot{ width:7px; height:7px; border-radius:50%; background:var(--yellow); flex-shrink:0; }
```
Contenu : `<span class="dot"></span> #{numéro} {Nom}`. **Pas d'emoji en préfixe** (contrairement au badge shooter bleu actuel qui utilise `🟢` en dur, ligne 1634) — le badge mode juste à côté porte déjà `🎯`, doubler l'icône sur la même ligne surchargerait le header pour un gain nul. Le point coloré (déjà le pattern établi par `.gk-pill .dot` dans `docs/visual/stats-gardiens.md` §5) suffit et reste cohérent avec ce vocabulaire visuel déjà posé ailleurs dans l'app.

### 3.2 Anneau sur le terrain — `.cp-player.pen-shooter`
C'est le point le plus important visuellement : **le contour bleu habituel (`.cp-player.shooter`, utilisé pour tout tir en cours) ne doit jamais apparaître pendant un penalty.** Nouvelle classe dédiée, exclusive de `.shooter` :

```
.cp-player.pen-shooter{
  border:3px solid var(--yellow) !important;      /* 3px, pas 2px — plus épais que .shooter (2px) et .pd-sel (2px) */
  background:rgba(240,199,94,.85) !important;      /* fond quasi plein, pas translucide comme .shooter (.3) */
  animation:penShooterPulse 1.8s ease-in-out infinite;
}
.cp-player.pen-shooter .cp-num,
.cp-player.pen-shooter .cp-name{
  color:var(--bg) !important;    /* texte foncé sur fond doré plein — pas var(--yellow), illisible sur lui-même */
  font-weight:800;
}

@keyframes penShooterPulse{
  0%,100%{ box-shadow:0 0 0 3px var(--yellow), 0 0 10px rgba(240,199,94,.45); }
  50%{     box-shadow:0 0 0 3px var(--yellow), 0 0 20px rgba(240,199,94,.85); }
}
```
`!important` nécessaire pour la même raison que `.cp-player.shooter`/`.cp-player.pd-sel` existants (ligne 215-218) : le template applique une `border-color` inline calculée (`clr`) sur chaque joueur — sans `!important`, la classe n'aurait aucune priorité. Bénéfice concret pour le Developer : comme pour `.shooter`/`.pd-sel`, il suffit d'ajouter la classe conditionnelle sur l'élément — pas besoin de retoucher le calcul de `clr` existant, l'`!important` s'en charge.

**Pourquoi un fond plein + pulsation, et pas un simple contour statique (réponse à la question posée) :**
- Un contour doré statique seul risquait de se lire comme "encore une variante de couleur parmi d'autres" — l'app utilise déjà le jaune pour `.cp-player.pd-sel` (sélection de passeur décisif), un contexte totalement différent. Le fond plein (`.85` d'opacité contre `.3` pour les variantes existantes) crée une différence de poids visuel immédiate, pas seulement une différence de teinte.
- La pulsation répond directement au risque identifié par le PRD lui-même : *"si le mécanisme de réassignation n'est pas suffisamment visible sous la pression du direct, un mauvais joueur pourrait être crédité comme tireur sans que Romain s'en aperçoive"*. Un enjeu de cette nature (donnée fausse enregistrée sans le remarquer) justifie un traitement qui **ne peut pas passer inaperçu**, contrairement à un badge de mode classique (§2.2) qui reste volontairement discret. Amplitude et vitesse restent calmes (1.8s, `ease-in-out`, variation d'opacité de glow uniquement — jamais de `scale()` qui ferait bouger/vibrer le numéro et gênerait sa lecture) : c'est une respiration, pas un clignotement.
- Contraste vérifié : `var(--bg)` (#0F1923) sur fond `#F0C75E` ≈ **11:1** — largement AAA, bien au-delà du 4.5:1 minimum, même en plein soleil bord de terrain.

### 3.3 Joueurs non désignés pendant que l'encart est ouvert — `.cp-player.pen-other`
Pour que l'anneau doré domine sans ambiguïté, les autres joueurs cliquables (toujours tappables pour réassignation, cf. Designer) passent en neutre plutôt que de garder leur couleur d'équipe habituelle :
```
.cp-player.pen-other{ border-color:rgba(255,255,255,.25) !important; opacity:.7; }
.cp-player.pen-other .cp-num, .cp-player.pen-other .cp-name{ color:var(--t2) !important; }
```
`opacity:.7` (pas moins) et `color:var(--t2)` (pas `--t3`) — restent clairement lisibles et identifiables au numéro/nom pour permettre une réassignation rapide ; ce n'est pas un état désactivé, seulement subordonné visuellement au joueur désigné. Les tailles de police (22px numéro / 16px nom, règle `CLAUDE.md`) ne changent pas — seule la couleur/opacité est affectée.

## 4. Transition de réassignation (tap sur un autre joueur)

Étant donné l'architecture de rendu de l'app (`R()` reconstruit tout le HTML à chaque interaction, cf. `CLAUDE.md` "Conventions de code" — pas de DOM persistant), une transition CSS classique entre deux états ne peut pas s'appliquer : l'élément `.pen-shooter` est détruit et recréé à chaque tap, pas modifié en place.

**Ce n'est pas un problème ici, c'est même la solution** : `penShooterPulse` (§3.2) est une animation qui démarre à 0% (glow bas) dès l'apparition de l'élément. Comme l'élément est recréé à *chaque* re-rendu (désignation initiale comme réassignation), l'animation **rejoue son cycle depuis le début à chaque tap** sans code supplémentaire — l'ancien anneau disparaît instantanément (l'ancien joueur redevient `.pen-other`), le nouveau apparaît déjà en train de respirer. Ce comportement natif remplit exactement l'exigence du PRD ("pas de changement silencieux") : le œil capte un mouvement (le glow qui s'anime) au moment précis où l'assignation change, pas seulement un état statique différent à découvrir a posteriori.

Décision explicite : **disparition instantanée de l'ancien anneau, pas de fondu de sortie.** Un fondu progressif entre ancien et nouveau tireur créerait une fenêtre ambiguë ("les deux sont un peu marqués") — exactement le risque que le PRD veut éviter. Le changement doit être net : à `T`, un seul joueur porte l'anneau doré, jamais deux, jamais une transition dégradée entre les deux. Cohérent aussi avec le reste de l'app, qui ne fait jamais de transition de sortie nulle part (uniquement des transitions d'entrée) — pas un nouveau pattern à inventer.

Le badge du header (§3.1) suit la même règle : le nom/numéro se met à jour instantanément au re-rendu, aucun morphing de texte.

## 5. Bouton "✕ Fermer" — jamais confondu avec une validation

```
.ap-pen-close{ position:absolute; top:6px; right:6px; }
```
Réutilise **exactement** le style déjà existant du bouton "✕ Fermer" du panneau de fil d'événements (`.feed-panel-header`, ligne ~1863 d'`app.js`) — même classe `btn btn-sm`, mêmes couleurs :
```
border-color:var(--border); color:var(--t2);   /* gris neutre, pas de teinte */
```
Texte : `✕ Fermer` (le mot complet, pas seulement le symbole — contrairement au `✕` nu actuel de `.ap-validate` ligne 1636). C'est un choix délibéré de réutilisation plutôt que d'invention : Romain connaît déjà ce bouton exact ailleurs dans l'app pour le même concept ("je quitte cette vue sans conséquence") — pas la peine d'apprendre un nouveau signe.

**Ce qui garantit l'absence de confusion au clic rapide, précisément :**
- **Position** : toujours ancré en haut à droite du panneau (`position:absolute`), jamais dans la même rangée que les 3 boutons d'issue (§6, qui occupent toute la largeur en dessous) — aucun risque de tap glissé de l'un vers l'autre, ils ne sont jamais côte à côte.
- **Couleur** : gris neutre pur, strictement aucune teinte verte/cyan/orange (les 3 couleurs de validation) ni rouge (déjà réservé à `↩ Annuler`, cf. contrainte explicite du PRD). Sur un bandeau où toutes les autres surfaces interactives sont colorées (jaune pour le badge, vert/cyan/orange pour les boutons d'issue), le gris se détache par contraste plutôt que par ressemblance.
- **Taille** : `btn-sm` (padding `5px 11px`, `font-size:13px`) — nettement plus petit que les 3 boutons d'issue (§6, traitement "xl"), renforçant qu'il s'agit d'une action secondaire, pas d'un choix principal parmi 4.
- **Pas d'icône de validation** (✓, ⚽, 🧤) à proximité immédiate — le symbole `✕` est déjà universellement associé à "annuler/fermer" ailleurs dans l'app (fil d'événements, sélecteur de zone via `.gz-cell`, etc.), jamais à une confirmation positive.

## 6. Les 3 boutons BUT / ARRÊT / HORS CADRE

```
.ap-pen-actions{ display:flex; gap:6px; }
.ap-pen-btn{
  flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center;
  gap:4px; padding:12px 8px; border-radius:var(--r2);
  border:2px solid rgba(var(--pen-rgb),.4);
  background:rgba(var(--pen-rgb),.08);
  color:rgb(var(--pen-rgb));
  font-family:inherit; transition:all .15s ease;
}
.ap-pen-btn .ah-icon{ font-size:26px; line-height:1; }
.ap-pen-btn .ah-label{ font-size:13px; font-weight:800; text-transform:uppercase; letter-spacing:.04em; margin-top:2px; }
.ap-pen-btn:active{
  transform:scale(.95);
  background:rgba(var(--pen-rgb),.22);
  box-shadow:0 0 0 1px rgba(var(--pen-rgb),.5), 0 0 16px rgba(var(--pen-rgb),.35);
}
```
Où `--pen-rgb` vaut, par bouton : `80,200,120` (BUT), `78,205,232` (ARRÊT), `232,154,78` (HORS CADRE) — cf. §0/§1, identiques aux tokens `--gk-goal`/`--gk-save`/`--gk-off` déjà en production.

**Pourquoi colorés au repos, pas seulement au tap** (contrairement à `.act-h` dans la barre d'actions normale, qui reste gris neutre tant qu'il n'est pas sélectionné) : le composant de référence le plus proche dans l'app n'est pas `.act-h`, c'est `.pd-prompt-yes`/`.pd-prompt-no` (le prompt "PD ?" qui apparaît après un but, `app.js` ligne ~380-391) — un autre cas de "décision binaire/ternaire à prendre en 2 secondes, sous pression du direct, sans retour en arrière possible". Ce composant est déjà coloré au repos (bordure + fond translucide + texte teintés), pas seulement au clic. L'encart pénalty reprend ce même registre visuel plutôt que celui de la barre d'actions générique : la décision est plus rare et plus chargée qu'un clic ordinaire, elle mérite d'être immédiatement lisible sans interaction préalable.

Taille des boutons : les 3 sont à poids visuel **égal** (`flex:1` uniforme) — contrairement à `.act-h-xl`/`.act-h-sm` dans la barre normale où BUT/ARRÊT sont plus larges que HORS CADRE. Ici, la possession et l'équipe sont déjà connues (fixées par le PO), il n'y a plus de hiérarchie d'usage entre les 3 issues à refléter visuellement.

## 7. Transitions d'apparition

| Moment | Traitement |
|---|---|
| Apparition de l'encart (juste après le clic sur le joueur qui obtient le PO) | `.ap-pen-panel` entier (header + 3 boutons) reçoit `animation:fadeIn .25s ease` (keyframe déjà existante, pas nouvelle) — l'ensemble apparaît comme un seul bloc cohérent, pas en 2 temps |
| Apparition de la grille de zone (après tap BUT/ARRÊT, si `S.trackGK`) | La grille elle-même (`.goal-zone-grid.gz-big`, `.gz-cell`) **ne reçoit aucune modification** — conforme à la consigne du Designer ("aucune nouvelle brique visuelle"). Seul le conteneur qui l'englobe (le `<div style="position:absolute;inset:0;z-index:4;...">` existant, ligne ~1649) reçoit la classe `.fade-in` déjà existante |
| Fermeture / validation (BUT, ARRÊT, HORS CADRE tapé, ou ✕ Fermer) | **Aucune transition de sortie** — l'encart disparaît au re-rendu suivant, comme tout le reste de l'app (aucune animation de sortie nulle part ailleurs, pas un nouveau pattern à inventer ici) |

Durée volontairement `.25s`, jamais plus — cohérent avec l'identité du rôle ("rapide, jamais gadget") et avec le standard déjà établi ailleurs dans l'app (`.fade-in`, `docs/visual/stats-gardiens.md` §9).

Le header (`.ap-pen-head`, badge mode + badge tireur) **reste visible et inchangé** pendant la transition vers l'étape zone — seule la ligne de boutons (§6) est remplacée par la grille. Cela maintient une confirmation continue de "qui est en train d'être crédité" même une fois l'issue choisie, ce qui réduit encore le risque d'incohérence de tireur signalé par le PRD comme risque central.

*Note pour l'Architect* : le bouton existant "↩ Modifier la position" à l'intérieur de l'étape zone (ligne ~1654) réinitialise `mapX`/`mapY`, ce qui n'a pas de sens pour un penalty dont la position est fixe (50/85) — à vérifier si ce bouton doit être masqué pour les types `PEN_*`. Remarque de cohérence visuelle, pas une décision fonctionnelle de ce document.

## 8. États

- **`S.readOnly` actif** : tout l'encart doit se désactiver comme les autres points d'écriture déjà listés dans `style.css` (~ligne 409-420, `.match-layout.is-readonly .act-h` etc.). Ajouter `.ap-pen-panel` et les `data-ap-player` du terrain à cette même liste de sélecteurs — traitement visuel identique (`opacity:.35;pointer-events:none;`, déjà défini, aucune nouvelle règle à écrire).
- **`S.trackGK` désactivé, ou HORS CADRE tapé** : validation immédiate, aucune grille — l'encart disparaît directement au re-rendu suivant (§7). Pas de traitement visuel intermédiaire à prévoir.
- **Aucun joueur sur le terrain** (roster vide) : ne devrait normalement pas se produire à ce stade du workflow (le PO vient d'être attribué à un joueur du roster) — pas de nouvel état vide à concevoir ici, `renderCourtEmptyState()` existant reste le filet de sécurité générique si jamais le cas se présentait.
- **Pas de toast de confirmation à la validation** : cohérent avec le comportement actuel des tirs normaux (`GOAL`/`SAVE`/`OFF` ne déclenchent aujourd'hui aucun `showToast()`) — pas de nouveau pattern d'interaction à introduire pour ce cycle.

## 9. Micro-animations — récapitulatif

| Élément | Animation | Durée | Déclencheur |
|---|---|---|---|
| `.ap-pen-panel` (apparition) | `fadeIn` (existante) | .25s ease | Ouverture de l'encart après PO |
| Overlay de la grille de zone | `fadeIn` (existante) | .25s ease | Tap BUT/ARRÊT avec `trackGK` actif |
| `.cp-player.pen-shooter` (anneau) | `penShooterPulse` (nouvelle) | 1.8s ease-in-out infinite | Continu tant qu'un tireur est désigné ; rejoue depuis 0% à chaque réassignation (effet de "flash" gratuit, cf. §4) |
| `.ap-pen-btn:active` | transform + glow | .15s ease | Tap sur BUT/ARRÊT/HORS CADRE |
| `.ap-pen-close:active` | héritée de `.btn:active` | .15s (déjà standard) | Tap sur ✕ Fermer |

Aucune animation sur le badge tireur (§3.1) ni sur le badge mode (§2.2) — un seul signal animé à la fois (l'anneau sur le terrain) pour ne pas diluer l'attention avec plusieurs éléments qui bougent simultanément dans un espace restreint.

## 10. Responsive <700px (iPhone)

| Élément | ≥700px | <700px |
|---|---|---|
| `.ap-pen-panel` padding | `8px 64px 8px 10px` | `6px 56px 6px 8px` |
| `.ap-pen-btn` icône | `26px` | `20px` |
| `.ap-pen-btn` label | `13px` | `11px` |
| `.ap-pen-head` | ligne unique si possible | `flex-wrap:wrap` autorisé — badges peuvent passer sur 2 lignes |
| `.ap-pen-close` | `position:absolute;top:6px;right:6px` | inchangé — reste ancré indépendamment du wrap du header |
| Anneau `.pen-shooter` | `border:3px` | inchangé (ne pas réduire l'épaisseur, c'est le signal le plus critique de l'écran) |

## Checklist contraste WCAG

- `var(--bg)` (#0F1923) sur fond `.pen-shooter` plein (#F0C75E à .85 d'opacité, composé sur le fond du terrain) : contraste ≈ **11:1** — AAA, calculé sur la valeur pleine du token, marge confortable même à opacité réduite.
- `#50C878` (BUT) / `#4ECDE8` (ARRÊT) / `#E89A4E` (HORS CADRE) en texte sur leur fond translucide respectif (`.08` composé sur fond sombre de l'app) : contrastes ≈ **8.3:1 / 9.5:1 / 7.8:1** respectivement — tous largement AA, la plupart déjà AAA. Mêmes valeurs de couleur déjà validées en production sur le terrain des tirs (`docs/visual/stats-gardiens.md`).
- `var(--yellow)` sur badge (`.15` d'opacité) : déjà validé ailleurs dans l'app (badge mode lecteur, badge PENALTY existant) — aucun nouveau risque introduit, réutilisation stricte.
- `var(--t2)` sur joueurs `.pen-other` (opacity .7) : `--t2` déjà validé partout comme texte secondaire ; l'opacité réduite du conteneur n'affecte pas le ratio texte/fond immédiat (le texte reste à pleine opacité relative à son propre fond de pastille).
- Aucune combinaison entièrement nouvelle : chaque couleur utilisée ici est soit déjà en production ailleurs (réutilisation stricte, `--gk-*`, `--yellow`, `--t2`), soit une correction vers une valeur qui l'est déjà (§0).

## Note du Visual Crafter

Cette spec ne cherche pas la sobriété par défaut : la demande explicite était de rendre un tireur désigné **impossible à confondre** avec un tir normal, sous la pression d'un match réel, avec un risque documenté (mauvais tireur crédité silencieusement) si le traitement reste timide. C'est pour cela que l'anneau doré n'est pas qu'un changement de couleur de bordure — fond quasi plein, épaisseur augmentée, pulsation continue : trois renforts cumulés sur le seul élément qui porte l'information la plus sensible de tout l'encart. À l'inverse, le reste du composant (badge mode, badge tireur, bouton ✕ Fermer) reste délibérément calme et reprend des styles déjà existants presque sans y toucher — pour que l'intensité visuelle du terrain (l'anneau) ne soit pas noyée par un bandeau tout aussi chargé au-dessus de lui. Un seul élément doit sauter aux yeux ; tout le reste doit s'effacer pour le laisser faire.
