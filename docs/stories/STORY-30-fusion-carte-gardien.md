# STORY-30 — Fusionner la carte gardien (terrain + chiffres) en une "feuille" par équipe

**En tant que** Romain,
**Je veux** lire la performance d'un gardien (le mien et l'adverse) en un seul regard — chiffres ET localisation des tirs dans la même carte —,
**Afin de** ne plus avoir à scroller ni relier mentalement deux cartes séparées pour comprendre "combien" et "où", que ce soit bord de terrain pendant le match ou en debrief juste après (onglet Stats → Gardiens, match rechargé via Historique).

## Contexte technique

- Zone concernée : `app.js` — fonction `renderStatGk()` (lignes 2992-3094 avant story), `bind()` (bloc `[data-gk-filter]` lignes 3661-3667), `newMatch()` (lignes 1391-1407), handler `[data-load-match]` (lignes 3890-3911).
- Zone concernée : `style.css` — `:root` (tokens, ligne 1-15), règle plein écran `.fs-overlay-body>.card.fs-court div[style*="grid-template-columns"]` (ligne 187, **ne pas modifier**), `.stat-courts` (lignes 255-256, **ne pas modifier**).
- Fonctions **inchangées, ne pas toucher** : `gkStats()`, `gkStatsCombined()`, `selectedGbs()`, `goalZoneHeatmap()` (~1057-1079, seul le paramètre `width` passé par l'appelant change), `courtSvgMarkup()`, `renderGkDetailTables()` (2946-2990), `openFullscreen()` (2708-2768).
- Nouvelle fonction à créer : `renderGkSheet(side)`, appelée deux fois (`"home"`/`"away"`) par `renderStatGk()` restructurée. Extraction optionnelle `renderShotTypeFilterBar(sf)` (pas structurante, à la discrétion du Developer).
- Nouvelle classe CSS : `.gk-sheet` (+ `.gk-sheet-court`, `.gk-sheet-nums`), nouvelle classe `.gk-filter-select`, `.gk-pill`, `.gk-col-empty`.
- Nouveaux tokens CSS : `--gk-save:#4ECDE8`, `--gk-goal:#50C878`, `--gk-off:#E89A4E`.
- Aucune nouvelle structure de données, aucun changement de schéma IndexedDB/Supabase. `S.gkFilter`/`S.gkShotFilter` gardent exactement leur forme actuelle (`{home,away}` / `{goals,saves,offs}`).
- Cette refonte ne touche **ni** `renderBilanMatch()` **ni** `matchStats()` (confirmé hors scope par Romain : le debrief passe par Historique → Charger → Stats → Gardiens, pas par l'écran Bilan).

## Critères d'acceptation

### A. Fusion structurelle (une carte par équipe)
- [ ] Il n'existe plus qu'**une seule `<div class="card">` par équipe** dans l'onglet Stats → Gardiens (au lieu des deux cartes empilées actuelles : résumé chiffré + terrain/heatmap). Cette carte porte les classes `class="card gk-sheet"` (la classe `.card` est conservée en plus de `.gk-sheet`, condition nécessaire pour que `openFullscreen()` la résolve via `.closest(".card")`).
- [ ] `renderStatGk()` délègue la construction de chaque carte à une fonction `renderGkSheet(side)` appelée pour `"home"` et `"away"`, à l'intérieur d'un unique `<div class="stat-courts">` (grille 2 colonnes existante, non modifiée).
- [ ] Le filtre de type de tir (● Encaissés / ✕ Arrêtés / ✕ Hors cadre) est repositionné **au-dessus** des deux feuilles fusionnées (avant le `<div class="stat-courts">`), pas entre deux blocs comme aujourd'hui. Markup et logique (`S.gkShotFilter`, `data-shot-filter`) strictement inchangés, seule la position dans le flux HTML bouge.
- [ ] `renderGkDetailTables()` reste appelée après les deux feuilles, sans aucune modification de son code, et reste visible sans clic supplémentaire (pas d'accordéon/toggle).
- [ ] Dans chaque feuille : la colonne terrain (heatmap + SVG + légende) porte une classe `.gk-sheet-court`, la colonne chiffres porte une classe `.gk-sheet-nums`. Les deux sont enfants directs du même conteneur `.gk-sheet`.
- [ ] **Ordre DOM** : le bloc `.gk-sheet-nums` (chiffres) précède le bloc `.gk-sheet-court` (terrain) dans le HTML — c'est ce qui permet au seul flip de `flex-direction` (row-reverse ≥700px / column <700px) de produire "terrain à gauche/chiffres à droite" en desktop ET "chiffres en haut/terrain en bas" en mobile sans dupliquer de markup ni utiliser `order:`.

### B. CSS `.gk-sheet` — layout interne
- [ ] Ajout dans `style.css` (bloc additif, aucune règle existante modifiée) :
  ```css
  .stat-courts > .card.gk-sheet{ display:flex; flex-direction:row-reverse; gap:16px; }
  .stat-courts > .card.gk-sheet .gk-sheet-court{ flex:0 0 65%; min-width:0; }
  .stat-courts > .card.gk-sheet .gk-sheet-nums{ flex:0 0 35%; min-width:0; }
  @media(max-width:700px){
    .stat-courts > .card.gk-sheet{ flex-direction:column; }
    .stat-courts > .card.gk-sheet .gk-sheet-court,
    .stat-courts > .card.gk-sheet .gk-sheet-nums{ flex:0 0 auto; }
  }
  ```
- [ ] `.stat-courts` elle-même (lignes 255-256 de `style.css`) n'est **pas modifiée** — aucun nouveau modificateur du type `.stat-courts.stacked`.
- [ ] Sous 700px, l'intérieur de la feuille bascule en colonne au **même seuil** que celui déjà utilisé par `.stat-courts` (700px) — aucun nouveau nombre de breakpoint introduit dans le CSS.

### C. Hiérarchie des chiffres à 3 niveaux (colonne `.gk-sheet-nums`)
- [ ] Niveau 1 — ratio `arrêts/total` (ex. `8/11`, valeur = `gk.saves + "/" + gk.total`) : `font-size:38px` (≥700px) / `34px` (<700px), `font-weight:800`, classe `.mono`, couleur `#4ECDE8`. Remplace les deux blocs séparés ARRÊTS et TIRS CADRÉS affichés côte à côte aujourd'hui (lignes 3018/3022 avant story).
- [ ] Label sous le niveau 1 : texte `ARRÊTS`, `font-size:10px`, `font-weight:700`, uppercase, `letter-spacing:.08em`, couleur `var(--t2)`, `margin-top:2px`.
- [ ] Niveau 2 — `%` (`gk.pct`) : `font-size:23px` (≥700px) / `20px` (<700px), `font-weight:800`, `.mono`, couleur `var(--yellow)`, `margin-top:12px` par rapport au bloc niveau 1.
- [ ] Niveau 3 — deux chips (`.gk-pill`) : "● {gk.goals} encaissés" et "● {gk.offs} hors cadre", `margin-top:16px` par rapport au niveau 2. Chip encaissés : dot + bordure `rgb(80,200,120)`/`rgba(80,200,120,.28)`, fond `rgba(80,200,120,.10)`. Chip hors cadre : `rgb(232,154,78)`/`rgba(232,154,78,.28)`/`rgba(232,154,78,.10)`. Texte des chips en `var(--t2)`, `font-size:12px`, `font-weight:600`, **pas** en `.mono`.
- [ ] ≥700px : les 2 chips empilées verticalement (`flex-direction:column`, `gap:6px`). <700px : côte à côte (`flex-direction:row`, `gap:10px`).
- [ ] Les anciens libellés ARRÊTS/ENCAISSÉS/H. CADRE/% ARRÊTS/TIRS CADRÉS affichés à plat sur une seule ligne (lignes 3017-3023 avant story) n'existent plus sous cette forme dans la carte fusionnée.
- [ ] Cas `0/0` / `pct:"-"` (aucun tir encore enregistré) : affiché avec exactement le même style que le cas rempli (même taille, même graisse, même couleur) — jamais réduit ni grisé.
- [ ] `.gk-sheet-nums` (et tout élément qu'elle contient, y compris le conteneur des chips) utilise exclusivement `display:flex;flex-direction:column` ou des blocs simples empilés en style inline. **Aucune occurrence de `display:grid` ni de `grid-template-columns` n'apparaît dans le style inline de quoi que ce soit à l'intérieur de `.gk-sheet-nums`** (voir section G, contrat plein écran).

### D. Dropdown GB (remplace les boutons `[data-gk-filter]`)
- [ ] Quand `gbs.length>=2` : un `<select class="gk-filter-select" data-gk-filter-select="${side}">` remplace la rangée de boutons `Tout/#N Nom` actuelle, avec une `<option value="all">Tous les GB</option>` puis une option par GB (`value="{gb.id}"`, texte `"#{numéro} {nom}"` ou `"{nom}"` si pas de numéro). Aucun plafond à 3 options (contrairement à l'actuel `gbs.slice(0,3)`) — toutes les GB sélectionnées de l'équipe apparaissent dans le menu.
- [ ] Quand `gbs.length===1` : le `<select>` n'est **pas rendu**. À la place, le nom du GB unique s'affiche en texte statique (`font-weight:700`, même taille/position que le select), sans bordure ni fond.
- [ ] Quand `gbs.length===0` : ni `<select>` ni texte statique — la feuille bascule dans l'état vide (section F).
- [ ] Position : coin supérieur droit du header de la feuille, à côté du nom d'équipe, avant le bouton `⛶`.
- [ ] `bind()` : le bloc `document.querySelectorAll("[data-gk-filter]")` (boutons, lignes 3661-3667 avant story) est **supprimé et remplacé**, pas dupliqué en coexistence, par :
  ```javascript
  document.querySelectorAll("[data-gk-filter-select]").forEach(el=>{
    el.onchange=()=>{
      S.gkFilter[el.dataset.gkFilterSelect]=el.value;
      R();
    };
  });
  ```
- [ ] Le changement du `<select>` met à jour **dans la même carte** à la fois la colonne chiffres (niveaux 1/2/3) ET les tirs affichés sur le terrain/heatmap — un seul événement `change`, un seul re-render, aucune désynchronisation possible entre les deux colonnes (elles lisent la même valeur `S.gkFilter[side]` au même passage de rendu).
- [ ] Style `.gk-filter-select` : `background:var(--bg3)`, `border:1px solid rgba(var(--gk-accent-rgb),.30)`, `border-radius:var(--r1)`, couleur = `var(--fenix-sky)` côté home / `var(--red)` côté away, `font-size:12px`, `font-weight:600`, `padding:5px 8px`, `min-height:30px`, `max-width:148px` (≥700px) / `130px` (<700px).

### E. Terrain + heatmap (colonne `.gk-sheet-court`)
- [ ] `goalZoneHeatmap(shots, width)` reste appelée sans modification de la fonction ; seule la valeur `width` passée change : recalculée en proportion de la colonne terrain (~85-90%), plus `"40%"` de la carte entière comme aujourd'hui.
- [ ] Un seul `<svg viewBox="0 0 350 208">` par feuille (pas un par ancienne carte).
- [ ] Écart vertical entre la heatmap et le SVG du terrain réduit à `6px` (au lieu de l'espacement par défaut actuel).
- [ ] Le SVG du terrain garde sa bordure actuelle (`border:1px solid var(--border)`), non retirée.

### F. États
- [ ] `gbs.length===0` (aucun GB sélectionné pour l'équipe) : la colonne chiffres (`.gk-sheet-nums`) est intégralement remplacée par un bloc `.gk-col-empty` centré : icône `🧤` (`font-size:22px;opacity:.5`) + texte `"Aucun gardien sélectionné"` (`color:var(--t3);font-size:12px`). **Aucun `0/0` n'est affiché dans ce cas** — la colonne chiffres est remplacée par ce message, pas par des zéros.
- [ ] `gbs.length===1` : voir section D — dropdown remplacé par label statique, chiffres et terrain fonctionnent normalement (pas de traitement d'état vide).
- [ ] `0/0` / `pct:"-"` avec un match qui vient de démarrer (0 tir enregistré) : affiché tel quel, même style que le cas rempli (voir section C) — ce n'est pas un état vide, c'est une donnée réelle.
- [ ] Filtre type de tir avec toutes les catégories désactivées : comportement inchangé (déjà géré aujourd'hui), le terrain affiche 0 impact — aucun nouveau code d'état à écrire pour ce cas.

### G. Contrat plein écran — non négociable, vérifiable mécaniquement
- [ ] **Exactement un** `class="fs-btn"` par feuille fusionnée (pas un par ancienne sous-carte). Positionné sur le wrapper `.gk-sheet` (celui qui porte aussi `.card`).
- [ ] **Exactement une** occurrence de la sous-chaîne littérale `grid-template-columns` dans le style inline généré par `renderGkSheet(side)`, et elle appartient uniquement au `<div>` produit par `goalZoneHeatmap()` (inchangée). Aucune autre occurrence ailleurs dans la feuille, en particulier pas dans `.gk-sheet-nums`.
- [ ] **Exactement un** `<svg viewBox="0 0 350 208">` par feuille.
- [ ] Ces 3 comptages sont vérifiables par le Code Reviewer par simple recherche texte sur le diff (`grep -c 'fs-btn'`, `grep -c 'grid-template-columns'`, `grep -c 'viewBox="0 0 350 208"'` dans le bloc `renderGkSheet`) — pas besoin de lancer l'app pour les valider.
- [ ] `openFullscreen()` (`app.js` 2708-2768) n'est **pas modifiée**. Le mécanisme existant (détection du SVG 350×208, redimensionnement de la heatmap à 85%/600px/20px via `querySelector` singulier) doit fonctionner sans changement de code sur la feuille fusionnée.
- [ ] Règle CSS `.fs-overlay-body>.card.fs-court div[style*="grid-template-columns"]` (`style.css` ligne 187) **n'est pas modifiée**.
- [ ] Test manuel obligatoire avant de considérer la story terminée : ouvrir le ⛶ des deux feuilles (FENIX et adverse), en orientation **paysage et portrait** sur iPad (ou simulateur équivalent) — seule la heatmap est redimensionnée en plein écran, la colonne chiffres garde sa mise en page verticale (pas d'écrasement à `width:50%`).

### H. Reset de `S.gkFilter` / `S.gkShotFilter` entre deux matchs (bug latent corrigé, risque #1)
- [ ] `newMatch()` (`app.js` 1391-1407) réinitialise explicitement `S.gkFilter={home:"all",away:"all"}` et `S.gkShotFilter={goals:true,saves:true,offs:true}`, au même endroit que les autres resets d'état de match (`S.events=[]`, etc., ligne 1397-1400).
- [ ] Le handler `[data-load-match]` (`app.js` 3890-3911, chargement d'un match depuis l'Historique) réinitialise également `S.gkFilter` et `S.gkShotFilter` aux mêmes valeurs par défaut, au même endroit que les autres champs remplacés (`S.home`, `S.away`, `S.events`, lignes 3896-3903).
- [ ] Vérification manuelle : filtrer sur un GB spécifique pendant un match, terminer/charger un autre match, ouvrir Stats → Gardiens — le filtre affiche "Tous les GB" par défaut, jamais un `0/0` provenant d'un `gkId` qui n'existe plus dans le nouveau match.

### I. Accent visuel carte + tokens
- [ ] Nouveaux tokens dans `:root` : `--gk-save:#4ECDE8; --gk-goal:#50C878; --gk-off:#E89A4E;` — les 3 usages en dur déjà présents dans `renderGkSheet` (couleurs des points SVG, du niveau 1, des chips) référencent ces tokens plutôt que de dupliquer les valeurs hex à plusieurs endroits (tolérance : rester en hex littéral est acceptable seulement si strictement identique aux valeurs ci-dessus).
- [ ] `.gk-sheet` : `border:1px solid rgba(var(--gk-accent-rgb),.22)` (au lieu de `var(--card-border)` neutre), avec `--gk-accent-rgb:95,168,211` côté home et `232,70,90` côté away (valeurs fixées en style inline ou via classe `.gk-sheet.away`/`.gk-sheet.home`, au choix du Developer).
- [ ] `box-shadow: var(--shadow-card), 0 0 0 1px rgba(var(--gk-accent-rgb),.08)`, et au hover (`@media(hover:hover)`, pattern `.card:hover` déjà en place) : `0 0 0 1px rgba(var(--gk-accent-rgb),.16), var(--shadow-card-hover)`.
- [ ] Pas de fond coloré ni de gradient sur toute la carte — uniquement bordure + ombre teintées.
- [ ] Niveau 1 (`8/11`) en couleur `#4ECDE8` — **pas** `var(--blue)`/`var(--green)` — cohérent avec la palette dédiée tirs déjà utilisée sur le terrain, pas la palette équipe (correction actée par le Visual Crafter, section 0 de `docs/visual/stats-gardiens.md`).
- [ ] Chip "encaissés" en teinte verte (`#50C878`) — **pas** `var(--red)` — même raison de cohérence avec les points verts "but" déjà affichés sur le terrain juste en dessous, dans la même carte.

### J. Micro-animations
- [ ] Sur `change` du dropdown GB et sur clic des boutons de filtre type de tir : la classe utilitaire déjà existante `.fade-in` (`style.css` ligne 237) est appliquée à `.gk-sheet-nums` ET `.gk-sheet-court` au moment du re-render — pas à la carte entière (le header avec le nom d'équipe et le dropdown ne doivent pas re-clignoter).
- [ ] Aucune animation par point individuel sur le SVG (pas de stagger).

### K. Non-régression données et fonctionnel
- [ ] `gkStats()`, `gkStatsCombined()`, `selectedGbs()` : aucune ligne modifiée.
- [ ] Pour un même match et un même filtre GB, les valeurs affichées (ratio, %, encaissés, hors cadre, tirs sur le terrain) sont strictement identiques avant/après cette story — seule la présentation change.
- [ ] Le filtre type de tir (Encaissés/Arrêtés/Hors cadre) reste un état global partagé `S.gkShotFilter`, pas dupliqué par équipe.
- [ ] `renderStatGk()` garde la même signature externe (aucun argument), toujours appelée sans changement depuis le routeur de vues Stats.

### L. Déploiement
- [ ] Version incrémentée dans `sw.js` (`fenix-stats-v75` → `v76` au minimum, ou version suivante disponible au moment du commit).
- [ ] `new Function()` passe sur `app.js` avant livraison (vérification JS obligatoire du projet).

## Hors scope

- Toute modification de `renderBilanMatch()` ou `matchStats()` — confirmé par Romain : le debrief passe par Historique → Charger → Stats → Gardiens, pas par l'écran Bilan. L'écran Bilan reste inchangé dans cette story.
- La page Gardiens du rapport PDF (jsPDF) — écran seulement, PDF non touché (décision actée par le PRD).
- Tout changement de `gkStats()`, `gkStatsCombined()`, `selectedGbs()`, structure d'événement, ou tout nouveau calcul.
- Le plafond de GB affichés au-delà de la suppression du `.slice(0,3)` dans le `<select>` — aucun autre changement de logique de sélection des GB.
- Tout ajustement de lisibilité pour écran partagé/projeté (audience multiple en debrief) — reporté, non tranché par le PRD.
- Repenser plus profondément le filtre GB (fusion avec la table de détail, autre présentation) ou la table `renderGkDetailTables()` elle-même.
- Tester une variante "chiffres empilés verticalement" indépendante de l'appareil au-delà du repli mobile — Nice to Have, hors de cette version.
- La validation réelle par Romain en conditions bord de terrain ET debrief (PRD Should Have #9, Risque #4 : lisibilité en plein soleil) — cette story livre le code et le polish visuel ; la confirmation terrain se fait après livraison, par Romain, pas par le Developer/QA en intérieur. Ne bloque pas la clôture technique de la story mais bloque la clôture du cycle PRD.

## Dépend de

- Aucune. Cette story dépend uniquement du code existant déjà en place (`renderStatGk()`, `renderGkDetailTables()`, `gkStats()`, `gkStatsCombined()`, `selectedGbs()`, `goalZoneHeatmap()`, `courtSvgMarkup()`, `openFullscreen()`) — aucune évolution structurelle préalable requise.

## Taille

L — refonte complète d'une fonction de rendu (~150 lignes avant/après), ajout d'un bloc CSS additif (~40-50 lignes), changement du binding d'un filtre, correction d'un bug d'état latent (reset), et un contrat plein écran à respecter précisément. Un seul écran, une seule fonction principale, livrable en une session par un développeur suivant les specs Design/Visual/Architecture déjà détaillées.
