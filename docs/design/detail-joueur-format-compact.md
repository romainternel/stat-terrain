# Design — Détail joueur au format compact

## Décision D1 — Conteneur : modale centrée, pas overlay plein écran
Réutilise le pattern déjà établi par `renderShotOverlay()` (`.overlay` : `position:fixed;inset:0`, fond noir 70% + flou, `display:flex;align-items:center;justify-content:center`) — **pas** un nouveau pattern de modale inventé.

À l'intérieur, une nouvelle classe `.pd-modal` (au lieu de réutiliser `.shot-modal`, dont le `width:min(900px,98vw)` est justement le genre de gabarit "trop grand" que Romain critique) :
```
.pd-modal{ background:#1A2840; padding:16px; width:min(520px,94vw);
  max-height:90vh; overflow-y:auto; }
```
Volontairement **sans `border`/`border-radius` propres** — l'élément porte aussi les classes `.card.gk-sheet` (cf. Architecture), qui fournissent déjà la bordure teintée par équipe et l'arrondi ; les déclarer une 2e fois dans `.pd-modal` risquerait d'écraser silencieusement la bordure accentuée par équipe selon l'ordre des règles dans la feuille de style — un piège de cascade repéré en écrivant cette section, pas à reproduire.

`520px` choisi pour correspondre à la largeur naturelle d'**une seule carte `.gk-sheet`** dans la grille `.stat-courts` (`1fr 1fr`, gap 12px) sur un panneau Stats de largeur iPad courante — sensiblement plus proche d'"une carte parmi d'autres" que d'un plein écran. `max-height:90vh`+`overflow-y:auto` en filet de sécurité si un effectif a beaucoup de tirs (liste de tirs + terrain + grille sur petit écran) — jamais nécessaire sur iPad en usage normal, utile surtout en test iPhone portrait.

## Décision D2 — Disposition interne : réutilise `.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court` telles quelles
Aucune nouvelle classe de mise en page. À l'intérieur de `.pd-modal` :
```
<div class="gk-sheet-body">
  <div class="gk-sheet-nums">...</div>   <!-- chiffres joueur -->
  <div class="gk-sheet-court">...</div>  <!-- grille Impact + terrain + legende -->
</div>
```
`flex-direction:row-reverse` (déjà dans `.gk-sheet-body`) place le terrain visuellement à gauche (zone dominante, 65%) et les chiffres à droite (35%) — identique à Gardiens. Sous 700px de large, bascule automatiquement en colonne (terrain au-dessus, chiffres en dessous) — comportement déjà présent dans le CSS existant, hérité gratuitement.

## Décision D3 — Colonne chiffres : mapping direct BUTS/PD/TIRS/EFF% → gabarit ARRÊTS/%/pills
| Gabarit Gardien (`.gk-lvl1`/`.gk-lvl2`/`.gk-pill`×2) | Joueur |
|---|---|
| `.gk-lvl1` (gros nombre, 38px) — ARRÊTS | **BUTS** |
| `.gk-lvl2` (23px, jaune) — % | **EFF%** |
| pill 1 (`--gk-pill-rgb` vert) — ENCAISSÉS | **PD** (jaune, cohérent avec la couleur PD déjà utilisée ailleurs dans l'app — `--yellow`) |
| pill 2 (`--gk-pill-rgb` orange) — HORS CADRE | **TIRS** (neutre, `--t2`) |

Libellés en majuscules sous chaque valeur, identique au style Gardien (`text-transform:uppercase;letter-spacing:.08em`). Cas 0 tir : même traitement que Gardien 0 GB (`.gk-col-empty`, icône + texte plutôt que des zéros nus) — ici icône `🎯` + "Aucun tir enregistré".

## Décision D4 — Colonne terrain : contenu inchangé, juste redimensionné à la nouvelle largeur de carte
Grille Impact (`pd-goalzone`) au-dessus, terrain SVG (points ou zones selon `S.shotViewMode`) en dessous, légende sous le terrain — **exactement l'agencement vertical actuel**, seule la largeur disponible change (celle de `.gk-sheet-court`, ~65% de 520px ≈ 340px, au lieu de la pleine largeur d'écran). `svg.pd-court` garde `width:100%` (déjà relatif), s'adapte automatiquement.

## Décision D5 — En-tête et fermeture (le point explicitement laissé en suspens par le PRD)
L'en-tête actuel (nom joueur + bouton bascule + "✕ Fermer") **reste tel quel**, en haut de `.pd-modal`, au-dessus de `.gk-sheet-body` — Gardiens n'a pas ce bouton parce que sa carte est permanente ; le détail Joueur reste une vue à la demande pour un seul joueur choisi dans une liste qui peut en compter 15+, donc la fermeture explicite est nécessaire et conservée. Pas de fermeture par clic sur le fond assombri (cohérent avec `renderShotOverlay()`, qui n'a pas non plus cette fermeture implicite — évite un clic accidentel qui fermerait la vue en visant le terrain).

## Décision D6 — Info tir sélectionné (`selInfo`)
Reste une bande pleine largeur, sous l'en-tête et au-dessus de `.gk-sheet-body` — inchangée dans son contenu, juste réduite en largeur avec le reste de la modale.

## Ce qui ne bouge pas visuellement
Couleurs, icônes, texte de tous les éléments internes (grille Impact, légende terrain, pills) — seul le conteneur et la disposition changent, aucune retouche de palette nécessaire au-delà de la réutilisation directe des classes `.gk-*` déjà en place.
