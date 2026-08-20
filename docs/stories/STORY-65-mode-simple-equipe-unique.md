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

## Clarifié par Romain (résout l'ambiguïté initiale)
Retour de Romain : pas forcément tout sur une seule rangée dans l'absolu selon l'appareil ("sur tél c'est mieux mais sur tablette/iPad je sais pas"), et il tient à garder **le nom de l'équipe affiché au-dessus des boutons** — pas seulement la surbrillance de couleur comme seul repère de qui a la possession.
**Décision retenue** (voir `docs/arch/audit-corrections-et-mode-simple.md` F4) : réutiliser telle quelle la barre `.ml-actions`/`.act-h` déjà utilisée par le Mode Expert — une seule rangée de 5 boutons, déjà responsive (rétrécit proportionnellement sur téléphone via les points de rupture existants `style.css:787-804`, déjà validés pour 6 boutons Mode Expert), sans nouveau seuil à inventer ni à tester séparément pour tablette/iPad. Le nom d'équipe reste sur sa propre ligne, au-dessus de cette rangée, dans tous les cas.

## Critères d'acceptation
- [ ] En Mode Simple, un seul bloc de boutons de résultat est visible à l'écran, jamais deux empilés
- [ ] Les 5 boutons (`BUT`/`ARRÊT`/`NON CADRÉ`/`PB`/`JET FRANC`) sont sur **une seule rangée** (conteneur `.ml-actions`, comme la barre Mode Expert), pas répartis sur deux rangées de 3+2
- [ ] Le **nom de l'équipe est affiché en toutes lettres au-dessus de la rangée de boutons**, dans tous les cas (téléphone, tablette, iPad) — jamais retiré au profit de la seule couleur d'accent
- [ ] Le libellé d'équipe affiché (avec le point `●` de couleur) correspond toujours à `S.possession`
- [ ] La couleur d'accent des boutons/libellé correspond à l'équipe active (bleu FENIX `var(--fenix-sky)` / rouge Adversaire `var(--red)`)
- [ ] Après une action qui fait basculer la possession (BUT/ARRÊT/NON CADRÉ/PB, règle existante inchangée), le bloc se redessine instantanément avec le nom/couleur de l'autre équipe, sans étape ni confirmation supplémentaire
- [ ] Cliquer un bouton enregistre toujours l'événement pour la bonne équipe — vérifié spécifiquement juste après un changement de possession (cliquer immédiatement après le re-render doit enregistrer pour la **nouvelle** équipe affichée, pas l'ancienne)
- [ ] Le bouton "◉ POSSESSION" du scoreboard reste fonctionnel et inchangé — bascule manuelle toujours possible, le bloc Mode Simple suit
- [ ] Le flash de confirmation (`.simple-flash`, `S.simpleFlash`) fonctionne toujours après le clic, sur le bon bouton
- [ ] Double-clic rapide sur le même bouton juste après qu'il ait fait basculer la possession : au pire un seul événement mal attribué, corrigible par "↩ Annuler" — pas de crash ni d'incohérence de score irrécupérable (cf. `docs/risks/audit-corrections-et-mode-simple.md` R5)
- [ ] Aucune régression sur le score, les stats GB, les alertes TM/GB (STORY-60, déjà branchées sur `recordEvent()`, non touchées par ce changement)
- [ ] Le scoreboard (score, sélecteur GB, TM, 2min, carton, chrono) reste affiché pour les deux équipes, strictement inchangé — seule la zone des boutons de résultat est concernée
- [ ] Testé sur iPhone portrait ET paysage (390×844 et paysage, viewports historiques STORY-24/03) : les 5 boutons tiennent sur une seule rangée, lisibles et cliquables sans être écrasés, gain d'espace vertical visible par rapport à l'ancien double bloc
- [ ] Testé sur iPad (paysage et portrait) : la même rangée de 5 boutons reste confortable, pas de gaspillage d'espace horizontal disproportionné ni de boutons démesurés
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
