# Design — Stats Gardiens (fusion des cartes, hiérarchie des chiffres)

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/brief-v5-stats-gardiens.md` et `docs/prd-v5-stats-gardiens.md`*
*Concerne `renderStatGk()` (`app.js` ~2992-3094) et son entourage (`renderGkDetailTables()`, ~2946-2990) — écran uniquement, aucune donnée ne change*

## Confirmation de mon avis informel initial

Mon avis d'avant-PRD tenait sur trois points : format condensé côte-à-côte plutôt qu'empilé, fusion des deux cartes actuelles en une "feuille" par équipe (terrain à gauche, chiffres à droite, ~65/35), empilement forcé sous 700px. **Je le confirme intégralement** — le PRD ne le contredit sur aucun point, il le complète. Deux ajustements liés aux décisions actées que je ne connaissais pas encore :

1. **Le filtre GB devient un `<select>` compact, pas une rangée de boutons.** Le code confirme qu'il pilote aussi les tirs affichés sur le terrain (`gkIds` dérivés du filtre, ~ligne 3047) — il ne peut donc pas disparaître ni devenir un simple lien texte, mais rien n'oblige à lui donner le même poids visuel que "Tous les GB". Un menu déroulant compact fait exactly ça : présent, fonctionnel, discret.
2. **La heatmap 3×3 doit être redimensionnée** — elle est aujourd'hui à `40%` de la largeur d'une carte pleine largeur (`goalZoneHeatmap(shots,"40%")`, ligne 3064). Dans la feuille fusionnée, la colonne terrain ne fait plus toute la largeur de la carte mais ~65% d'une carte elle-même à ~50% de la page — `40%` de cette nouvelle base donnerait une heatmap illisible (~85-95px de large sur iPad portrait). Elle doit être recalculée en proportion de la **colonne terrain**, pas de la carte entière (voir section Responsive).

Une seule disposition, comme tranché par le PRD (point 2) : ce qui est lisible "en 2 secondes debout" (bord de terrain) l'est a fortiori en debrief posé — pas de variante distincte à concevoir.

## Vue d'ensemble de la page (ordre vertical, inchangé dans sa logique)

```
1. Onglets Stats (inchangé)
2. Filtre type de tir — Encaissés / Arrêtés / Hors cadre (Should Have #8, repositionné : remonte
   au-dessus des deux feuilles puisqu'il pilote maintenant l'intérieur des DEUX cartes fusionnées)
3. Les deux "feuilles gardien" (FENIX + adversaire) — le cœur de cette refonte
4. Table de détail par GB (renderGkDetailTables(), INCHANGÉE, toujours visible sans clic — Must Have #6)
```

Le filtre type de tir remonte d'un cran par rapport à aujourd'hui (il était entre les 2 cartes résumé et les 2 cartes terrain) : maintenant qu'il n'y a plus qu'un seul niveau de cartes, il doit précéder les deux feuilles qu'il affecte, pas se glisser entre deux blocs qui n'existent plus séparément.

## Maquette — Feuille gardien fusionnée, ≥700px (bord de terrain ET debrief)

Une carte par équipe, dans la grille `.stat-courts` existante (`grid-template-columns:1fr 1fr`, inchangée) :

```
┌─────────────────────────────────────────────────────────────────────┐
│  🧤 FENIX Toulouse                                [Tous les GB ▾] ⛶  │
│  ┌──────────────────────────────────┐  ┌───────────────────────────┐ │
│  │         ●●●  ○○○  ○●○            │  │                           │ │
│  │        [heatmap 3×3, zones]      │  │      8/11                 │ │
│  │                                   │  │      ARRÊTS               │ │
│  │      ╭──────────────────╮        │  │                           │ │
│  │      │   ⌐──────────┐   │        │  │      73%                  │ │
│  │      │   │  ·  ✕  · │   │        │  │                           │ │
│  │      │   │    ●     │   │        │  │   ● 2 encaissés            │ │
│  │      │   └──────────┘   │        │  │   ● 1 hors cadre           │ │
│  │      ╰──────────────────╯        │  │                           │ │
│  │         [terrain SVG + tirs]     │  │                           │ │
│  └──────────────────────────────────┘  └───────────────────────────┘ │
│              ~65% de la carte                 ~35% de la carte       │
└─────────────────────────────────────────────────────────────────────┘
```

Et juste en dessous, la même structure pour l'équipe adverse (bordure/accent rouge au lieu de bleu, comme aujourd'hui).

### Hiérarchie exacte des 3 (+1) chiffres, colonne de droite

Le PRD impose 3 niveaux ; je les traduis en taille/poids/position, tous alignés à gauche dans la colonne, empilés verticalement (voir justification largeur ci-dessous) :

| Niveau | Contenu | Taille / style | Couleur | Rôle |
|---|---|---|---|---|
| **1 — primaire** | `8/11` (arrêts/total, remplace ARRÊTS + TIRS CADRÉS d'aujourd'hui) | `36-40px`, `font-weight:800`, `.mono` | `var(--blue)` | LA donnée de synthèse — doit être lisible en un regard, avant tout le reste |
| Label niveau 1 | `ARRÊTS` | `10-11px`, uppercase, `letter-spacing:.08em` | `var(--t2)` | Rattaché immédiatement sous le ratio, pas d'espace qui le détache |
| **2 — dérivé** | `73%` | `22-24px`, `font-weight:800`, `.mono` | `var(--yellow)` | Traduction directe du ratio — visuellement plus petit que le niveau 1 mais nettement plus gros que le niveau 3, jamais au même rang que les chiffres contextuels |
| **3 — contextuel** | `● 2 encaissés` / `● 1 hors cadre` | `12-13px`, `font-weight:500`, pas de `.mono` | pastille `var(--red)` / `var(--t2)` texte ; pastille `var(--orange)` / `var(--t2)` texte | Deux lignes fines, meme registre visuel — ENCAISSÉS (buts, donnée de score) et HORS CADRE (contextuel) regroupés au même niveau subordonné : aucun des deux n'a plus le poids qu'aujourd'hui, mais ENCAISSÉS reste identifiable par sa pastille rouge (cohérente avec le rouge "but" utilisé partout ailleurs dans l'app) |

Pourquoi empilé verticalement plutôt qu'une seule ligne "8/11 · 73% · 3 HC" à l'identique de la formulation de Romain : la colonne de droite ne fait que ~35% d'une carte elle-même à moitié de la largeur de page — sur iPad portrait (~370px de carte), ça laisse ~130px de large pour la colonne chiffres. Une ligne unique à 3 tailles décroissantes ne tient pas dans cette largeur sans se compresser ou passer à la ligne de façon imprévisible. L'empilement vertical **conserve l'esprit exact de la demande de Romain** (les 3 informations lues d'affilée, sans les 5 cartes équivalentes d'aujourd'hui) tout en restant fiable à toutes les largeurs de la colonne — et la hiérarchie de taille/couleur fait le travail que Romain demandait avec son format "·", juste organisée verticalement au lieu d'horizontalement.

### Dropdown GB — comportement

Remplace la rangée de boutons `Tout / #3 Nom / #7 Nom` actuelle (ligne 3008-3015). Réutilise le style déjà existant `.sb-gk-sel select` (utilisé pour le sélecteur de GB du scoreboard — même famille visuelle, déjà "discrète" dans l'app) :

```html
<select class="gk-filter-select">
  <option value="all" selected>Tous les GB</option>
  <option value="{id1}">#7 Nom GB1</option>
  <option value="{id2}">#12 Nom GB2</option>
</select>
```

- Position : coin supérieur droit du header de carte, à côté du nom d'équipe, avant le bouton ⛶.
- **Un seul `change` event** doit déclencher exactement ce que déclenchent aujourd'hui les clics sur les boutons `data-gk-filter` : mise à jour simultanée de la colonne chiffres (niveaux 1/2/3) ET des tirs affichés sur le terrain/heatmap à gauche, dans la **même carte** — l'avantage concret de la fusion : avant, changer le filtre dans la carte résumé demandait de redescendre l'œil vers une 2e carte plus bas pour voir l'effet sur le terrain ; maintenant l'effet est visible sans déplacer le regard.
- **Si l'équipe n'a qu'un seul GB sélectionné** (`gbs.length===1`) : masquer le `<select>` entièrement, afficher à la place le nom du GB en texte statique (même taille/position) — il n'y a rien à filtrer, un menu déroulant à une seule option réelle ("Tous les GB" = ce GB) n'apporterait que du bruit visuel.
- **Si aucun GB sélectionné** (`gbs.length===0`) : masquer le `<select>`, la carte entière bascule dans l'état vide (voir section États).
- Le `<select>` natif est délibérément préféré à un dropdown custom (pas de nouveau composant à construire/maintenir, comportement tactile natif déjà correct sur iPad Safari).

### Filtre type de tir — position

Reste fonctionnellement identique (mêmes 3 boutons "● Encaissés / ✕ Arrêtés / ✕ Hors cadre", même état visuel actif/inactif). Remonte au-dessus des deux feuilles (voir Vue d'ensemble) puisqu'il n'existe plus de second niveau de cartes en dessous où le placer — un seul rendu de ce bloc, partagé, comme aujourd'hui (`S.gkShotFilter` reste un état global, pas dupliqué par équipe).

## Maquette — Repli mobile, <700px (breakpoint existant `.stat-courts`, STORY-02/03/18/19)

`.stat-courts` repasse déjà à `grid-template-columns:1fr` sous 700px (règle existante, inchangée). La feuille elle-même doit en plus empiler **son intérieur** (terrain/stats passent de côte-à-côte à l'un-sous-l'autre) — ce nouveau comportement interne doit utiliser le **même seuil de 700px**, pas un nouveau breakpoint, pour ne pas introduire une deuxième variation de mise en page (le PRD est explicite : le repli mobile est le seul point de variation).

Ordre choisi sous 700px : **les chiffres d'abord, le terrain ensuite.** Le critère "sans scroller" du PRD ne s'applique explicitement qu'à l'iPad (les deux orientations) — pour l'iPhone, le critère est seulement "pas de régression, repli propre". Autant profiter de cette liberté pour mettre en premier ce qui se lit le plus vite (le ratio), et laisser le terrain — plus riche visuellement mais moins urgent à lire dans les 2 premières secondes — juste après, quitte à nécessiter un petit scroll sur les téléphones les plus petits.

```
┌───────────────────────────────────┐
│  🧤 FENIX Toulouse   [Tous ▾]  ⛶   │
│                                     │
│            8/11                    │
│           ARRÊTS                   │
│                                     │
│            73%                     │
│                                     │
│    ● 2 encaissés   ● 1 hors cadre  │
│                                     │
│      [heatmap 3×3, pleine largeur] │
│                                     │
│      [terrain SVG + tirs,          │
│       pleine largeur de carte]     │
└───────────────────────────────────┘

┌───────────────────────────────────┐
│  🧤 US Nantes Hb    [Tous ▾]  ⛶    │   ← 2e feuille, empilée sous la 1ère
│  ...                                │      (grille .stat-courts déjà 1 colonne)
└───────────────────────────────────┘

┌───────────────────────────────────┐
│ 📋 FENIX — Détail GB               │
│ [table existante, scroll horiz.    │   ← inchangée, position inchangée
│  si besoin — déjà géré aujourd'hui]│
└───────────────────────────────────┘
┌───────────────────────────────────┐
│ 📋 US Nantes Hb — Détail GB        │
│ [table]                            │
└───────────────────────────────────┘
```

Sur mobile, plus de contrainte de largeur ~130px pour la colonne chiffres : la carte fait toute la largeur de l'écran (moins padding), donc la ligne "● 2 encaissés   ● 1 hors cadre" peut rester sur une seule ligne côte-à-côte (contrairement au repli forcé en 2 lignes distinctes sur desktop faute de place) — léger avantage naturel du mobile ici, pas une règle à forcer, juste une conséquence de `flex-wrap` sur un conteneur plus large.

## Responsive — récapitulatif du seuil 700px

| | ≥700px (iPad portrait/paysage, desktop) | <700px (iPhone) |
|---|---|---|
| `.stat-courts` (grille des 2 équipes) | 2 colonnes (inchangé) | 1 colonne (inchangé) |
| Intérieur d'une feuille | terrain+heatmap (gauche, ~65%) / chiffres (droite, ~35%), côte à côte | chiffres (haut) / terrain+heatmap (bas), empilés pleine largeur |
| Chiffres niveau 3 (encaissés/hors cadre) | 2 lignes empilées (contrainte de largeur ~35%) | 1 ligne côte à côte (largeur pleine carte disponible) |
| Heatmap 3×3 | ~85-90% de la **colonne terrain** (pas de la carte entière — recalibrage nécessaire vs les `40%` actuels) | ~70-80% de la carte, centrée (comme le comportement actuel) |
| Dropdown GB | coin haut-droit du header de carte | identique, header reste sur 1 ligne |

Aucun nouveau breakpoint : uniquement une nouvelle classe de layout interne (ex. `.gk-sheet`) avec sa propre media query `@media(max-width:700px){.gk-sheet{flex-direction:column}}`, au même seuil que celui déjà en dur dans `style.css` (ligne 256 notamment) — à réutiliser tel quel, ne pas redéfinir un nombre en dur une 3e fois si évitable (note pour l'Architect).

## États

- **Aucun GB sélectionné pour l'équipe** (`gbs.length===0`) : la feuille entière affiche un état vide cohérent avec le pattern déjà établi ailleurs (`docs/design/terrain-joueurs.md`, état vide du terrain) — terrain SVG visible mais sans impacts, message centré ton neutre : "🧤 Aucun gardien sélectionné". Pas de `0/0` affiché en gros dans la colonne chiffres (afficherait une fausse donnée de synthèse) — la colonne chiffres est remplacée par ce même message, pas par des zéros.
- **Un seul GB sélectionné** : dropdown masqué, nom du GB affiché en statique à sa place (voir section Dropdown). Chiffres et terrain fonctionnent normalement (équivalent à "Tous les GB" avec un seul élément).
- **Aucun tir encore enregistré** (0-0 début de match) : `0/11`... plutôt `0/0`, `pct:"-"` → afficher `0/0` et `-` tels quels (comportement déjà celui de `gkStats()` aujourd'hui, ne pas le masquer : un score à 0 est une donnée réelle, pas une absence de donnée).
- **Filtre type de tir avec toutes les catégories désactivées** : comportement inchangé (déjà géré aujourd'hui, boutons barrés/atténués), le terrain affiche alors 0 impact — pas un nouveau cas à concevoir.

## Plein écran (⛶)

Un seul bouton ⛶ par feuille fusionnée (au lieu de deux aujourd'hui — un sur la carte résumé, un sur la carte terrain). `openFullscreen()` (`app.js` ~2708) détecte déjà la présence du SVG terrain par sélecteur (`svg[viewBox="0 0 350 208"]`) pour appliquer la classe `.fs-court` et ses règles d'agrandissement — ce mécanisme fonctionne tel quel sur la carte fusionnée sans modification, puisqu'il cherche le SVG à l'intérieur de la carte clonée, pas une carte dédiée.

**Point d'attention pour l'Architect/Developer** : la règle CSS existante `.fs-overlay-body>.card.fs-court div[style*="grid-template-columns"]` (style.css ligne 187) cible spécifiquement la heatmap par sa signature de style inline. La nouvelle colonne chiffres (à droite dans la feuille) ne doit **pas** utiliser `display:grid` avec `grid-template-columns` dans son style inline, sous peine d'être capturée par erreur par cette règle en plein écran — utiliser `flex`/`flex-direction:column` pour la colonne chiffres, pas `grid`.

## Composants réutilisés vs nouveaux

**Réutilisés tels quels** :
- `.stat-courts` (grille 2 colonnes, breakpoint 700px existant)
- `.card`, `.card-t`, `.fs-btn` + `openFullscreen()` (détection automatique du SVG terrain, aucune modification requise)
- `.sb-gk-sel select` (style de dropdown compact — nouvelle utilisation du même pattern visuel)
- `goalZoneHeatmap()`, `courtSvgMarkup()` — logique et rendu inchangés, seul le paramètre de largeur passé change
- `renderGkDetailTables()` — totalement inchangée, position inchangée (toujours sous les feuilles, sans clic supplémentaire)
- Filtre type de tir (3 boutons `.btn-xs`) — markup et logique inchangés, seule la position verticale bouge
- `.mono` pour les chiffres

**Nouveaux** :
- Layout interne "feuille gardien" (ex. `.gk-sheet` : flex côte-à-côte ≥700px, colonne <700px) qui fusionne les deux cartes actuelles
- Markup du `<select>` de filtre GB (remplace la rangée de boutons `data-gk-filter`)
- Hiérarchie typographique à 3 niveaux pour les chiffres (tailles/poids spécifiés ci-dessus — probablement en styles inline, cohérent avec la convention déjà en place dans `renderStatGk()`/`renderGkDetailTables()` qui n'utilisent pas de classes CSS dédiées pour ces éléments)
- État vide spécifique "🧤 Aucun gardien sélectionné" au niveau de la feuille entière (variante du pattern déjà établi pour le terrain vide côté Match)
