# STORY-02 — Layout Match adapté iPhone portrait

**En tant que** Romain,
**Je veux** que l'écran Match soit utilisable sur iPhone en portrait (score, actions, terrain tous accessibles sans zoom ni scroll horizontal involontaire),
**Afin de** pouvoir prendre des stats sur iPhone aussi vite que sur iPad.

## Contexte technique

- Zone concernée : `style.css` — `.match-layout`, `.ml-left`, `.ml-right`, `.ml-actions`, `.act-h`.
- Décision Architecte : nouvelle media query `max-width:700px` sur `.match-layout` (cohérente avec le seuil déjà utilisé ailleurs dans le fichier pour `.setup-grid`/`.stat-courts`), bascule en empilement vertical.
- Priorité d'espace : score condensé en haut, contrôles (TM/2min/carton), barre d'actions en scroll horizontal (`overflow-x:auto`), puis terrain en pleine largeur qui prend l'espace vertical restant.
- Aucune modification de `app.js` nécessaire — le rendu ne dépend pas de la taille d'écran, tout passe par CSS.
- Référence design : `docs/design/match-responsive-iphone.md` (maquette portrait).

## Preuve visuelle (capture réelle, app lancée et pilotée en local le 2026-07-23)

📷 `docs/design/screenshots/04-match-iphone-portrait.png` (viewport 390×844, iPhone portrait standard)

**Constat direct, pas une hypothèse** : à ce jour, sur ce format, la barre d'actions (BUT / TIR ARRÊTÉ / TIR NON CADRÉ / PB / PO / JET FRANC) **se chevauche visuellement** — les labels "TIR NON CADRÉ" et "PO"/"JET FRANC" se superposent, illisibles. Le terrain de jeu est repoussé hors de la zone visible. La media query portrait existante (`@media (orientation:portrait){.match-layout{grid-template-columns:1fr;...}}`) empile bien les colonnes mais ne traite pas le débordement de la barre d'actions elle-même (pas d'`overflow-x` ni de réduction de labels).

**Constat additionnel, hors du périmètre initial de cette story** : sur ce même viewport, la barre de navigation du header (Équipes/Match/Stats/Bilan/Matchs) déborde aussi — "Bilan" et "Matchs" sortent de l'écran, inatteignables. Comme ce header est partagé par tous les écrans (pas seulement Match), ce point est traité séparément dans **STORY-18** plutôt que rattaché ici.

## Critères d'acceptation

- [ ] **Corrige le chevauchement de labels constaté dans la capture ci-dessus** — c'est le bug le plus visible actuellement, à vérifier en premier avant toute autre chose sur cette story.
- [ ] Sur un viewport ≤430px de large en portrait, le score, le timer, les contrôles (TM/2min/carton) et la barre d'actions sont visibles sans scroll vertical au-dessus du terrain.
- [ ] La barre d'actions (`.act-h`) défile horizontalement (`overflow-x:auto`) au lieu de passer à la ligne, sans jamais réduire la hauteur disponible pour le terrain.
- [ ] Chaque zone tactile (boutons d'action, joueurs sur le terrain, zones de but) reste confortablement cliquable (~44px minimum) sur ce format.
- [ ] Le layout iPad existant (≥700px ou orientation paysage) n'est pas modifié — vérifier explicitement en testant les deux tailles avant de clôturer la story (cf. risque P1 `docs/risks/iphone-polish.md` #2).
- [ ] Une action de jeu (but, tir, etc.) se saisit en autant de taps sur ce format que sur iPad.

## Hors scope

- Le mode paysage iPhone (traité dans STORY-03).
- Toute logique JS différente selon l'appareil (uniquement du CSS).

## Dépend de

Aucune (recommandé après un passage rapide de `STORY-09` si des frictions de workflow sont trouvées, mais non bloquant).

## Taille

M

## Notes du Developer (implémentation livrée le 2026-07-27)

**Fix 1 — chevauchement de la barre d'actions** : la cause réelle était `.act-h`/`.act-h-xl`/`.act-h-sm` en flex à ratio (`flex:1.4`/`2.4`/`1.1`, `min-width:0`), qui se comprimaient sous leur largeur de contenu sur petit écran — le texte du label débordait alors visuellement de sa boîte plutôt que de wrapper (à cause de `white-space:nowrap` sur `.ah-label`). Correctif : sous `max-width:700px`, chaque bouton passe en `flex:0 0 auto;min-width:56px` (taille pilotée par son propre contenu, jamais compressée), et `.ml-actions` devient scrollable horizontalement (`overflow-x:auto` + indice visuel de scroll, même pattern que STORY-18).

**Fix 2 — bloc équipes/timer trop haut, terrain repoussé hors écran** : sous `max-width:700px and orientation:portrait` (nouveau, pour ne pas toucher l'iPad portrait), condensation du padding/font-size de `.ml-team`, `.ml-timer` et `.mlt-poss-btn` (score 52px→32px, chrono 38px→28px, etc.), en gardant `.mlt-poss-btn` ≥44px de hauteur (le `min-height:44px` existant n'a pas été touché). Hauteur mesurée de `.ml-left` : 541px sur un viewport de 844px de haut — le terrain redevient atteignable après un scroll raisonnable, au lieu d'être totalement hors-champ comme avant.

**Fichiers modifiés** : `style.css` (un bloc ajouté après la règle portrait existante), `sw.js` (v48→v49). **`app.js` non touché**, conforme à la décision Architecte.

**Vérification faite** (Chrome headless piloté via CDP, données réalistes injectées) :
- `docs/design/screenshots/15-story02-final-portrait.png` — plus de chevauchement visible.
- Mesure DOM automatisée : aucune paire de `.act-h` ne se chevauche (`overlap:false`), largeurs entre 56px et 112px selon le label, hauteur uniforme 71px — tout au-dessus du seuil de 44px.
- `docs/design/screenshots/16-story02-final-scrolled.png` — après scroll, les 6 boutons (BUT/TIR ARRÊTÉ/TIR NON CADRÉ/PB/PO/JET FRANC) sont tous atteignables et lisibles.
- `docs/design/screenshots/14-story02-ipad-landscape-noregress.png` — capture identique à la référence d'avant fix, media queries scoping bien étanche au-dessus de 700px.

**Point d'attention pour le Code Reviewer/QA — trouvaille hors scope, non corrigée ici** : en testant à 390px de large avec un effectif complet (22 joueurs sélectionnés), les étiquettes des joueurs sur le terrain (`.cp-player`) se chevauchent visuellement entre elles (ex. "Timéo"/"Gabriel"/"Simon" bunched together) — confirmé comme un vrai problème de largeur (absent sur la même donnée à 1024px, `docs/design/screenshots/14-story02-ipad-landscape-noregress.png`), pas un artefact du jeu de données de test. **Hors du périmètre de cette story** (`Zone concernée` ne couvrait que `.match-layout`/`.ml-left`/`.ml-right`/`.ml-actions`/`.act-h`, pas `.court-pick`/`.cp-player`). À remonter au Scrum Master comme candidate à une nouvelle story.
