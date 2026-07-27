# STORY-03 — Layout Match adapté iPhone paysage

**En tant que** Romain,
**Je veux** que l'écran Match reste utilisable sur iPhone en paysage (colonne équipes réduite à l'essentiel + terrain toujours visible),
**Afin de** pouvoir prendre des stats aussi quand je tiens mon iPhone à l'horizontale.

## Contexte technique

- Zone concernée : `style.css` — mêmes classes que STORY-02, media query combinée `max-width:932px and orientation:landscape` (largeur d'un iPhone Pro Max en paysage) distincte des règles `orientation:landscape and min-width:700px` déjà présentes (pensées pour iPad).
- La colonne gauche garde le principe 2 colonnes de l'iPad mais réduite au strict nécessaire (score, timer, contrôles courts) — pas de place pour le détail GB étendu visible en continu comme sur iPad large.
- Référence design : `docs/design/match-responsive-iphone.md` (maquette paysage).

## Preuve visuelle (capture réelle, app lancée et pilotée en local le 2026-07-23)

📷 `docs/design/screenshots/05-match-iphone-landscape.png` (viewport 844×390, iPhone en paysage)

**Constat direct** : la barre de contrôles du bas (score restant "15", "Annuler", "PD") se **superpose visuellement au terrain** au lieu de rester en dessous — la hauteur réduite (~390px) ne laisse pas assez de place pour empiler proprement `.ml-actions` + `.ml-court` + `.ml-bottom`. Le chrono ("15:12") en bas de la colonne gauche est également **coupé**, partiellement hors champ. Les règles `@media (orientation:landscape) and (min-width:700px)` existantes ne s'appliquent pas ici (l'iPhone fait moins de 700px de large même en paysage), donc aucune des optimisations de hauteur déjà prévues pour iPad paysage (`height:calc(100dvh - 78px)`, zones `flex-shrink:0`) ne profite à ce format.

## Critères d'acceptation

- [ ] **Corrige le chevauchement barre du bas / terrain constaté dans la capture ci-dessus**, et l'affichage tronqué du chrono en colonne gauche — c'est le problème concret le plus visible sur ce format actuellement.
- [ ] Sur un viewport iPhone en paysage (≤932px de large, hauteur réduite), le terrain reste visible et utilisable sans scroll excessif.
- [ ] La colonne gauche affiche au minimum : score, timer, contrôles TM/2min/carton — le détail GB étendu peut être masqué ou simplifié sur ce format.
- [ ] Le layout iPad en paysage (règles `@media (orientation:landscape) and (min-width:700px)` existantes) n'est pas affecté.
- [ ] Bascule portrait ↔ paysage sur iPhone ne fait perdre aucune donnée de l'action en cours de saisie.

## Hors scope

- Le mode portrait iPhone (traité dans STORY-02).

## Dépend de

STORY-02 (même zone de code, cohérence de l'approche à valider avant d'ajouter la variante paysage).

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-27)

**Correction du diagnostic initial** : en re-testant précisément (mesures DOM, pas seulement visuel), le "chevauchement barre du bas / terrain" décrit dans la preuve visuelle d'origine n'est en réalité pas un chevauchement de boîtes — `.ml-bottom` et `.ml-court` ne se recouvraient jamais (confirmé par `getBoundingClientRect`). Le vrai problème mesuré : (1) le terrain n'avait que 168px de hauteur disponible (`.ml-court`), ne montrant que 2 rangées de joueurs sur 7, et (2) le bloc équipe FENIX + le chrono dépassaient à eux seuls la hauteur de la colonne gauche (312px), poussant le chrono et l'équipe adverse hors du cadre visible (chrono coupé de ~1px seulement en réalité, mais l'équipe adverse entièrement hors-écran).

**Fix** : nouveau bloc `@media (max-width:932px) and (orientation:landscape)`, placé après la règle paysage iPad existante (`min-width:700px`) pour que la cascade CSS laisse la version condensée l'emporter sur la plage iPhone (700–932px), sans toucher l'iPad (>932px, donc hors de ce nouveau seuil). Condensation du padding/font-size de `.ml-team`, `.ml-timer`, `.mlt-poss-btn`, `.ml-actions`/`.act-h` — a libéré ~27px de hauteur supplémentaire pour le terrain (168px→195px) et rendu le chrono + les contrôles de l'équipe FENIX pleinement visibles sans scroll.

**Arbitrage assumé** : l'équipe adverse (2e bloc `.ml-team`) reste hors du cadre initial et nécessite un scroll dans `.ml-left` pour être atteinte — accepté car (a) `.ml-left` était déjà scrollable avant cette story (`overflow-y:auto`), (b) l'info la plus utile en direct (son propre score/chrono/contrôles) est désormais visible sans rien faire, et (c) la story autorise explicitement à "masquer/simplifier le détail GB" sur ce format. Aucune donnée n'est perdue, juste accessible par un scroll plutôt qu'affichée en continu.

**Fichiers modifiés** : `style.css` (nouveau bloc de ~20 lignes), `sw.js` (v49→v50). `app.js` non touché.

**Vérification faite** (mesures DOM automatisées, pas seulement des captures) :
- `docs/design/screenshots/19-story03-landscape-after.png` — chrono et contrôles FENIX pleinement visibles, terrain nettement agrandi.
- `docs/design/screenshots/20-story03-mlleft-scrolled.png` — après scroll de `.ml-left`, l'équipe adverse (US Nantes) apparaît intacte avec son sélecteur GB et ses contrôles.
- Zones tactiles mesurées : boutons d'action 48px de haut, bouton possession 44-49px — tous ≥44px.
- `docs/design/screenshots/21-story03-ipad-landscape-noregress.png` + mesures DOM identiques à avant fix (`.act-h` 71px, `.ml-actions` 85px, boutons `.ml-bottom`/`.mlt-btn-tm` à 37px/34px) — confirme zéro impact sur iPad (seuil `max-width:932px` bien étanche).

**Point d'attention pour le Code Reviewer/QA — préexistant, pas introduit ici** : `.ml-bottom .ml-ctrl-btn` (37px) et `.mlt-btn-tm`/`.mlt-btn-sanc` (34px) sont sous le seuil de 44px — **mesuré identique sur iPad**, donc pas une régression de cette story ni de STORY-02, juste une caractéristique déjà présente dans toute l'app. Hors scope ici (ces classes ne sont pas dans la "Zone concernée" de la story), mais à garder en tête pour un futur audit d'accessibilité tactile transverse.
