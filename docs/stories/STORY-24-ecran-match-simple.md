# STORY-24 — Écran Match en mode Simple

**En tant qu'**utilisateur non-expert (aidant occasionnel, ou Romain sur iPhone),
**Je veux** saisir le score et les événements clés d'un match sans terrain ni zone ni attribution joueur,
**Afin de** suivre un match sans formation, sans ralentir ni me tromper.

## Contexte technique
- Nouvelle fonction `renderMatchSimple()`, appelée à la place du bloc `.ml-actions` + `.ml-court` quand `S.mode==='simple'`. `.ml-left` (équipes, timer, GB toggle, badges 2min/Carton R déjà auto-validés via `.mlt-btn-sanc`) reste **strictement inchangé et réutilisé** — ces éléments ne font pas partie du périmètre à simplifier (ils sont déjà des badges simples, sans terrain ni zone).
- Nouvelle fonction `recordSimpleEvent(team, type)` (cf. `docs/architecture/mode-simple-expert.md` pour le code exact) : construit un événement complet avec `x/y/goalZone/playerId/playerName/playerNumber/assistId/assistName/assistNumber` à `null`, et `gkId = S[opp].gkId` renseigné automatiquement (pas de saisie requise).
- 3 boutons par équipe : BUT, TIR ARRÊTÉ, TIR NON CADRÉ — auto-validation au clic, pas d'étape intermédiaire.
- Indicateur de mode actif : badge visible en permanence pendant la saisie en mode Simple (cf. `docs/visual/mode-simple-expert.md` — même traitement visuel que le badge "MODE PENALTY" existant).
- Vérifié par l'Architecture : `teamScore()`, `teamStat()`, `teamPoss()`, `gkStats()` fonctionnent déjà correctement avec des événements à `playerId` null (filtrage par `team`/`type`/`gkId` uniquement) — aucune modification requise sur ces fonctions.

## Critères d'acceptation
- [x] En mode Simple, l'écran Match n'affiche ni terrain, ni zone de but, ni bouton PD, ni PO/PEN détaillé.
- [x] Un tap sur BUT/TIR ARRÊTÉ/TIR NON CADRÉ pour une équipe crée immédiatement un événement complet (auto-validé), sans étape intermédiaire.
- [x] Le score de chaque équipe (`teamScore()`) est correct après une série d'événements Simple.
- [x] Les stats Gardiens (`gkStats()`) restent correctes pour des événements Simple (le `gkId` de l'équipe adverse est renseigné automatiquement, sans saisie).
- [x] Le feed d'événements (overlay glissant) affiche et permet d'annuler/éditer les événements Simple, comme pour Expert.
- [x] Les 2min/Carton Rouge/TM restent accessibles et fonctionnels en mode Simple, sans aucune modification (ils vivent déjà dans `.ml-left`, hors du périmètre simplifié).
- [x] Un badge visible indique en permanence que le mode Simple est actif pendant la saisie (pas seulement au changement de mode).
- [x] **Comportement accepté et documenté (pas une régression)** : sur un match à mode mixte (Simple puis Expert ou l'inverse), la table Stats "Joueurs" peut afficher une somme de buts par joueur inférieure au score total de l'équipe — les événements Simple ne s'attribuent à aucun joueur, par conception (pas de rattrapage a posteriori, hors scope de ce cycle).
- [x] Aucune régression du mode Expert : le parcours complet (BUT/SAVE/OFF/PB/PO/PEN/PD/2min/carton, terrain, zones) fonctionne à l'identique quand `S.mode==='expert'`.

## Notes Developer

- **Amélioration par rapport à l'Architecture prévue** : plutôt que d'écrire une nouvelle fonction `recordSimpleEvent(team,type)`, j'ai découvert que `recordEvent(type,team,x,y,playerId)` (déjà existante, utilisée par 2 autres flux : sélection joueur pour badges de sanction, et édition de tir sur le shot overlay) fait déjà exactement ce qu'il fallait — `x`/`y`/`playerId` sont optionnels (`??null`/`||null`), `gkId` est déjà posé uniquement pour les actions isGoal/isSave/isOff. Résultat : `recordEvent(type, team)` suffit, aucune nouvelle fonction de saisie n'a été nécessaire. Plus de réutilisation que prévu par l'Architecture — noté ici plutôt que dans le doc d'architecture, qui reste correct dans son intention.
- `renderMatchSimple()` remplace conditionnellement le bloc `.ml-actions` + `.ml-status` + `.ml-court` dans `renderMatch()` (`S.mode==='simple' ? renderMatchSimple() : ...`) ; `.ml-left` (équipes/timer/GB/badges sanction) et `.ml-bottom` (feed/annuler) restent strictement communs aux deux modes, conformément à l'Architecture.
- `pdBtnHtml` conditionné à `S.mode==="expert"` en plus de ses conditions existantes — c'est le seul autre point de `renderMatch()` touché en dehors du bloc `.ml-right` principal.
- Alertes automatiques (`checkGkConsecutiveAlert`/`checkTimeoutAdvisor`) **non déclenchées** par les événements Simple, par cohérence avec le comportement déjà existant de `recordEvent()` pour ses 2 autres appelants (ces alertes ne sont déclenchées que par le flux `validateActionPanel`/`validateAndClose`, pas par `recordEvent`) — pas une omission, un alignement avec l'existant.
- Testé fonctionnellement via CDP (clics réels) : rendu du nouvel écran, absence de `.ml-actions`/`.court-pick`/`#pd-btn` en Simple, clic sur chacun des 6 boutons vérifié individuellement (score, `gkStats`, `teamStat`), feed/annuler fonctionnels, bascule Simple→Expert en cours de match conservant les événements déjà saisis (score correctement reporté). Vérifié sur iPad (1024×768) et iPhone portrait réel (390×844) — sur iPhone, l'écran Simple ne nécessite quasiment plus de scroll (31px, contre plusieurs centaines en mode Expert), conforme à l'objectif initial de la feature.

## Hors scope
- Le rattrapage a posteriori des détails manquants sur un événement Simple.
- L'adaptation visuelle des écrans Stats/Bilan/PDF à la richesse réelle des données (ils affichent simplement les zones vides/à zéro, comme aujourd'hui pour tout match sans `trackGK`).
- Toute nouvelle action absente du mode Expert.

## Dépend de
STORY-23 (fondation de l'état `S.mode` et du toggle)

## Taille
M
