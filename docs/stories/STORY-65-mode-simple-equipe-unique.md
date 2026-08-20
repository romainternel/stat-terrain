# STORY-65 — Mode Simple : un seul jeu de boutons, l'équipe change selon la possession

**En tant que** Romain (ou tout aidant occasionnel, en priorité sur téléphone),
**Je veux** ne voir qu'un seul jeu de boutons de résultat en Mode Simple, celui de l'équipe qui a la balle,
**Afin de** gagner de l'espace vertical et saisir plus facilement d'une main sur téléphone, sans le bloc grisé de l'équipe adverse qui prend de la place pour rien.

Demande directe de Romain, remontée en marge de l'Audit Final du 2026-08-20.

## Contexte technique
- Zone concernée : `renderMatchSimple()` (`app.js:1218-1248`), binding `[data-simple]` (`app.js:4612-4627`)
- Impact sur l'existant : `data-simple` n'encode plus que le `type` (plus `team|type`) — le `team` est désormais toujours lu depuis `S.possession` au moment du clic ; le garde `team!==S.possession` (STORY-59) devient structurellement inatteignable et est supprimé, avec lui le toast d'erreur associé ; la classe CSS `.simple-inactive` (`style.css:702`) devient inutilisée
- Maquette avant/après : `docs/design/audit-corrections-et-mode-simple.md` section F4 ; specs couleur/transition exactes : `docs/visual/audit-corrections-et-mode-simple.md` section F4
- Code de référence détaillé (structure attendue de la fonction) : `docs/arch/audit-corrections-et-mode-simple.md` section F4

## Point à clarifier avant de coder
Romain a dit "une seule ligne de bouton" — interprété par le Designer comme **un seul jeu de boutons affiché à la fois** (la disposition interne 3+2 boutons reste inchangée, c'est la duplication par équipe qui disparaît), pas une compression littérale des 5 boutons sur une seule rangée CSS. Si ce n'est pas ce que Romain avait en tête, revenir vers lui avant d'implémenter plutôt que de deviner.

## Critères d'acceptation
- [ ] En Mode Simple, un seul bloc de boutons de résultat est visible à l'écran, jamais deux empilés
- [ ] Le libellé d'équipe affiché (avec le point `●` de couleur) correspond toujours à `S.possession`
- [ ] La couleur d'accent des boutons/libellé correspond à l'équipe active (bleu FENIX `var(--fenix-sky)` / rouge Adversaire `var(--red)`)
- [ ] Après une action qui fait basculer la possession (BUT/ARRÊT/NON CADRÉ/PB, règle existante inchangée), le bloc se redessine instantanément avec le nom/couleur de l'autre équipe, sans étape ni confirmation supplémentaire
- [ ] Cliquer un bouton enregistre toujours l'événement pour la bonne équipe — vérifié spécifiquement juste après un changement de possession (cliquer immédiatement après le re-render doit enregistrer pour la **nouvelle** équipe affichée, pas l'ancienne)
- [ ] Le bouton "◉ POSSESSION" du scoreboard reste fonctionnel et inchangé — bascule manuelle toujours possible, le bloc Mode Simple suit
- [ ] Le flash de confirmation (`.simple-flash`, `S.simpleFlash`) fonctionne toujours après le clic, sur le bon bouton
- [ ] Double-clic rapide sur le même bouton juste après qu'il ait fait basculer la possession : au pire un seul événement mal attribué, corrigible par "↩ Annuler" — pas de crash ni d'incohérence de score irrécupérable (cf. `docs/risks/audit-corrections-et-mode-simple.md` R5)
- [ ] Aucune régression sur le score, les stats GB, les alertes TM/GB (STORY-60, déjà branchées sur `recordEvent()`, non touchées par ce changement)
- [ ] Le scoreboard (score, sélecteur GB, TM, 2min, carton, chrono) reste affiché pour les deux équipes, strictement inchangé — seule la zone des boutons de résultat est concernée
- [ ] Testé sur iPhone portrait (390×844, viewport historique STORY-24) : gain d'espace vertical visible, moins de scroll nécessaire qu'avant
- [ ] Mode lecteur : le bloc reste affiché en lecture seule comme aujourd'hui (garde `readOnly` déjà présente dans `recordEvent()`, non dupliquée ici)
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Refonte du Mode Expert
- Nouveau composant de bascule de possession (le bouton "◉ POSSESSION" existant suffit)
- Afficher le score inline dans le bloc de boutons (déjà visible dans le scoreboard au-dessus, pas dupliqué ici)

## Dépend de
Aucune

## Taille
M
