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
