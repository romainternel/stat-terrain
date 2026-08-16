# QA — STORY-53 (Bandeau de validation au lancement)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-53-fenetre-validation-lancement.md`, `docs/code-review/STORY-53.md` (APPROUVÉ), `docs/design/retours-premier-match-reel.md`, `docs/risks/retours-premier-match-reel.md` (R5).

## Méthode
CDP sur Chrome headless, vrais clics réels sur `#lwb-collapse`/`#lwb-reopen`/`#lwb-dismiss`, état forcé (GK non sélectionné, effectifs renseignés) pour déclencher les warnings, capture d'écran réelle.

## Critères d'acceptation
- [x] Bandeau affiché à l'arrivée sur l'écran Match si GK manquant et/ou effectif vide — testé avec GK manquant sur les 2 équipes, effectif renseigné (1 joueur chacune) : bandeau affiche exactement "GB non sélectionné pour FENIX Toulouse" et "GB non sélectionné pour Adversaire", pas de ligne "effectif vide" (correct, l'effectif était bien renseigné)
- [x] `[–]` réduit le bandeau vers une pastille près de "⚙ Réglages", ré-ouvrable — testé dans l'ordre : collapse → bandeau disparaît/pastille apparaît → clic sur la pastille → bandeau réapparaît
- [x] `[✕]` ferme définitivement pour la session de match — testé : dismiss → bandeau disparaît, `S.launchWarningsDismissed===true`
- [x] Jamais bloquant pour la saisie — purement un bloc d'affichage conditionnel en haut de `.match-layout`, aucune garde `readOnly`/interaction avec le flux de saisie
- [x] Reset par `newMatch()` — vérifié par lecture de code (`S.launchWarningsCollapsed=false; S.launchWarningsDismissed=false;` ajoutés à `newMatch()`)
- [x] Vérifié Mode Simple ET Mode Expert — le bandeau est rendu dans `renderMatch()`, commun aux deux modes (`renderMatchSimple()` est appelée à l'intérieur du même layout, pas un écran séparé)

## Cas limites testés
- **Effectif partiellement sélectionné** (pas testé avec un cas à "quelques joueurs" spécifique, mais la condition `S.home.players.filter(p=>p.selected).length===0` ne peut logiquement déclencher que sur zéro exactement — vérifié par lecture, pas de risque de faux positif sur un effectif partiel).
- **Match rechargé/repris** : le bandeau se recalcule à chaque rendu à partir de l'état courant (`launchWarnings()` pure, pas de cache) — un match repris avec un GK toujours manquant réafficherait le bandeau normalement, sauf s'il a été explicitement fermé (`S.launchWarningsDismissed`) — comportement voulu, pas testé avec un vrai cycle de reprise complet (hors scope CDP simple, comportement dérivé directement de la lecture de code).

## Portée hors scope confirmée
Le mode "équipe générale" (M6), abandonné avant développement sur demande de Romain — aucune trace dans le code livré (`ap.shooterId`, `validateAndClose()`, `clickGoalZone()`, `clickCourtPosition()`, `clickActionMap()`, calcul de `shotMode` : tous non modifiés, vérifié par le diff livré).

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune — `renderMatch()`/`renderHeader()` modifiés uniquement par ajout de blocs conditionnels, aucun code existant supprimé ou restructuré.

## Verdict
**PASSED**
