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
