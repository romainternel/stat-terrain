# Risques — Détail joueur au format compact

## R1 — Cascade CSS `.pd-modal`/`.gk-sheet`/`.card` (P2, déjà mitigé au Design)
Les 3 classes cohabitent sur le même élément avec la même spécificité — un `border`/`border-radius` déclaré deux fois écraserait silencieusement la bordure accentuée par équipe selon l'ordre des règles dans le fichier. **Déjà corrigé dans le Design/Architecture** (`.pd-modal` ne déclare ni l'un ni l'autre) — ce risque devient une **vérification** pour le Code Reviewer : confirmer au moment du montage que `.pd-modal` n'a pas récupéré de déclaration `border`/`border-radius` en cours de route.

## R2 — Largeur `.gk-sheet-body` à 520px, breakpoint à 700px (P2)
`.gk-sheet-body` bascule en colonne sous 700px de **largeur de viewport** (`@media(max-width:700px)`), pas de largeur de conteneur — dans une modale de `520px`, cette media query ne se déclenche que si le **viewport entier** fait moins de 700px (iPhone), pas simplement parce que la modale est étroite. Sur iPad (viewport ≥768px même en portrait), la disposition 2 colonnes (65%/35%) s'applique **à l'intérieur des 520px** de la modale — c'est le comportement voulu (c'est exactement la largeur où cette disposition fonctionne déjà aujourd'hui pour une carte `.gk-sheet` dans `.stat-courts`), mais à vérifier visuellement plutôt que supposé : le Developer doit confirmer par capture d'écran réelle sur iPad (portrait ET paysage) que rien ne se chevauche à cette largeur précise, pas juste faire confiance au calcul.

## R3 — Copie de `--gk-pill-rgb` sans adaptation (P3, mineur mais visible si manqué)
`renderGkSheet()` fixe `--gk-pill-rgb` en style inline par pill (ex. `80,200,120` pour vert). En adaptant le composant pour PD (jaune) et TIRS (neutre), un copier-coller trop rapide du bloc `renderGkSheet()` existant laisserait les valeurs RGB vertes/oranges d'origine — la pill afficherait la mauvaise couleur sans erreur JS, un bug purement visuel facile à ne pas remarquer en survolant le code. Signalé explicitement par le Visual Crafter — le Code Reviewer doit vérifier les valeurs RGB réellement utilisées, pas seulement que la structure `.gk-pill` est présente.

## R4 — Point d'entrée unique, mais overlay partagé par nom de pattern (pas par id) (P3)
`.overlay`/`.pd-modal` (nouveau) coexiste dans le CSS avec `.overlay`/`.shot-modal` (existant, `renderShotOverlay()`). Les deux sont déclenchés depuis des écrans différents (`S.view==="match"` pour l'un, Stats → Joueurs pour l'autre) et utilisent des `id` différents (`shot-overlay` vs un nouvel `id` pour la modale Joueur) — aucun scénario réaliste où les deux seraient montés simultanément (un seul `S.view` actif à la fois). Risque théorique, pas pratique — mentionné pour mémoire, pas bloquant, pas de garde supplémentaire nécessaire.

## R5 — `prefers-reduced-motion` (P3)
La nouvelle animation d'ouverture (`pd-modal-in`) doit respecter `prefers-reduced-motion: reduce` (déjà prévu dans le CSS proposé) — à vérifier que ça fonctionne réellement plutôt que de faire confiance à la présence de la media query dans le code (test simple : activer la réduction de mouvement dans les réglages système avant capture).

## Hors scope de risque — ce qui NE change PAS et n'a donc pas besoin d'être re-risqué
Calculs de stats (`goals`/`totalShots`/`assists`/`pct`/`zoneData`), sélection de tir individuel (`data-pd-shot`), bascule points/zones (`S.shotViewMode`), mode lecteur — aucune de ces logiques n'est touchée par ce changement de conteneur, donc aucun risque nouveau introduit sur ces axes. Le Risk Analyst de STORY-43 a déjà couvert la géométrie du terrain et la bascule elle-même — non ré-audité ici, à raison.

## Recommandation de découpage
Une seule story — le changement est contenu (une fonction, quelques lignes de CSS ajoutées), aucune des décisions ne dépend d'une autre feature en cours.
