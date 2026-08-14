# Architecture — Détail joueur au format compact

## Fichiers touchés
`app.js` (uniquement `renderPlayerDetail()`, ~ligne 2627-2732 — aucune autre fonction), `style.css` (ajout de `.pd-modal` + variante d'animation, aucune classe existante modifiée).

## `app.js` — restructuration de `renderPlayerDetail()`
Aucun changement de state, aucun changement des calculs (`shots`, `goals`, `totalShots`, `assists`, `pct`, `zoneData`, `penData`, `zoneShots`, `selInfo`) — uniquement le `return` final (le markup) change de structure.

**Avant** (structure actuelle) :
```
<div style="position:fixed;...100vw;100vh...">      <!-- conteneur plein écran -->
  <div>en-tête (nom + toggle + fermer)</div>
  <div style="overflow-y:auto">                      <!-- zone scrollable -->
    <div>4 stats en ligne (BUTS/PD/TIRS/EFF%)</div>
    ${selInfo}
    <div class="pd-layout">grille Impact</div>
    <div>terrain SVG + légende</div>
  </div>
</div>
```

**Après** :
```
<div class="overlay" id="pd-overlay">                <!-- reprend .overlay, deja utilise par renderShotOverlay() -->
  <div class="pd-modal card gk-sheet" style="--gk-accent-rgb:${accentRgb};">
    <div>en-tête (nom + toggle + fermer)</div>        <!-- INCHANGE tel quel -->
    ${selInfo}                                        <!-- INCHANGE, deplace juste sous l'en-tete -->
    <div class="gk-sheet-body">
      <div class="gk-sheet-nums">
        <!-- BUTS en .gk-lvl1, EFF% en .gk-lvl2, PD+TIRS en 2 .gk-pill -->
      </div>
      <div class="gk-sheet-court">
        <div class="pd-layout">grille Impact</div>     <!-- INCHANGE -->
        <div>terrain SVG + légende</div>               <!-- INCHANGE -->
      </div>
    </div>
  </div>
</div>
```
`accentRgb` calculé exactement comme dans `renderGkSheet()` : `const accentRgb = side==="home" ? "95,168,211" : "232,70,90";` (même valeurs, pas de nouvelle palette).

**Points de vigilance sur le déplacement de code** :
- Le bloc "4 stats en ligne" (lignes ~2682-2687 actuelles) est **remplacé** par le nouveau bloc `.gk-sheet-nums` (BUTS/EFF%/pills), pas conservé en plus — Design D3.
- La grille Impact (`.pd-goalzone`) et le terrain SVG (`#pd-court-svg`, `.pd-court`) sont **déplacés tels quels** (aucune ligne de leur contenu interne modifiée) à l'intérieur de `.gk-sheet-court` — leurs `id`/classes restent identiques, donc les bindings existants (`data-pd-shot`, `data-pd-clear-sel`, tout code qui cible `#pd-court-svg`) continuent de fonctionner sans modification.
- Le bloc `<div style="height:60px;flex-shrink:0;"></div>` (espaceur de fin, pensé pour le scroll plein écran avec zone de sécurité iOS) devient inutile avec une modale de taille fixe — supprimé.
- `overflow-y:auto` se déplace du conteneur plein-écran vers `.pd-modal` (`max-height:90vh;overflow-y:auto`, cf. Design D1) — un seul point de scroll, pas deux imbriqués.

## `style.css` — ajouts
```css
.pd-modal{ background:#1A2840; padding:16px; width:min(520px,94vw);
  max-height:90vh; overflow-y:auto;
  animation: pd-modal-in .18s ease-out; }
@keyframes pd-modal-in{ from{ opacity:0; transform:scale(.96); } to{ opacity:1; transform:scale(1); } }
@media (prefers-reduced-motion: reduce){ .pd-modal{ animation:none; } }
```
**Pas de `border`/`border-radius` dans `.pd-modal`** — l'élément final porte `class="card gk-sheet pd-modal"`, donc `.gk-sheet` (bordure teintée par équipe via `--gk-accent-rgb`) et `.card` (border-radius de base) s'appliquent déjà ; les redéclarer dans `.pd-modal` écraserait la bordure accentuée selon l'ordre des règles dans le fichier (les 3 classes ont la même spécificité, la dernière règle du fichier gagne) — a été identifié et corrigé au moment du Design, pas une découverte de dernière minute côté Developer.

Placé à côté du bloc `/* ── GK SHEET (STORY-30) ── */` déjà existant (~ligne 336 de `style.css`) puisque `.pd-modal` réutilise directement `.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court` définies là — garde les deux blocs visuellement liés proches dans le fichier, cohérent avec l'organisation actuelle par feature.

**Ne pas ajouter** de `--gk-pill-rgb` global — cette variable est déjà posée en `style` inline par instance de pill (`style="--gk-pill-rgb:80,200,120;"` dans `renderGkSheet()`) ; pour Joueur, fixer `240,199,94` (jaune) sur la pill PD et une valeur neutre grise (`var(--t2)` ne fonctionne pas comme RGB brut pour cette variable — utiliser `150,160,175` ou équivalent, à caler visuellement par le Developer) sur la pill TIRS, en style inline de la même façon — pas de nouvelle classe CSS pour ça.

## Aucun changement de state / d'appel
`S.playerDetail={side,playerId,selectedShot}` inchangé. Déclenchement (`data-player-detail` dans `renderStatPlayers()`), fermeture (`#close-player-detail`), sélection de tir (`data-pd-shot`), désélection (`data-pd-clear-sel`) — tous les bindings existants (~lignes 4647-4670 de `app.js`) ciblent des `id`/attributs qui ne bougent pas, donc **aucune modification de `bind()` nécessaire**.

## Risque technique principal
`renderPlayerDetail()` est actuellement injectée par `h+=renderPlayerDetail()` tout en bas du HTML global (après `renderStats()`, ~ligne 1595) — en dehors du DOM de l'onglet Stats. Avec `.overlay` (déjà `position:fixed;inset:0`), ça reste correct visuellement (la modale se centre sur tout le viewport, pas seulement sur le panneau Stats) — comportement identique à `renderShotOverlay()`, qui vit dans la même situation (déclenché depuis Match, rendu en fin de DOM, `position:fixed` le recentre). Pas de changement d'architecture nécessaire sur ce point, juste à vérifier visuellement que le centrage reste correct (Risk Analyst / QA).
