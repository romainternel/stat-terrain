# QA — STORY-70 : le temps mort arrête le chrono

*Produit par le QA — squad de contrôle BMAD*
*S'appuie sur `docs/code-review/STORY-70.md` (APPROUVÉ)*

## Méthode
Validation par trace de code exhaustive (tous les chemins d'exécution de `recordTM()` rejoués à la main contre chaque critère). Le test au clic réel dans un navigateur (parcours "cliquer TM, observer le chrono s'arrêter") est délégué à l'E2E Tester (Playwright), conformément à la répartition du squad.

## Critères validés
- ✅ Clic TM pour FENIX (`recordTM('home')`, TM disponible) : chemin tracé jusqu'à `stopTimer()` → `S.running=false`, `clearInterval`, re-render. Chrono arrêté.
- ✅ Clic TM pour l'adversaire (`recordTM('away')`) : le bloc de garde `if(team==="home")` est sauté entièrement, le chemin rejoint directement `stopTimer()` — pas de dépendance à l'équipe.
- ✅ TM refusé (FENIX, plus de TM disponible) : `return` explicite avant `stopTimer()` — chrono non touché, confirmé par lecture directe du flux de contrôle.
- ✅ Pas de redémarrage automatique après le TM : `stopTimer()` ne programme aucun redémarrage ; seul le bouton ▶/⏸ existant (`t-toggle`) peut relancer, comportement inchangé.
- ✅ `new Function()` passe sur `app.js` (vérifié directement, `node -e "new Function(...)"`).
- ✅ Mode Simple **et** Expert : point important vérifié en remontant la structure du fichier, pas supposé — le bloc scoreboard/timer contenant le bouton `.mlt-btn-tm` (`app.js:2230-2350`, dans `renderMatch()`) est rendu **une seule fois**, **au-dessus** du branchement conditionnel `S.mode==="simple" ? renderMatchSimple() : ...` (`app.js:2368`). Il n'y a donc pas deux implémentations à synchroniser — un seul rendu, partagé, structurellement identique dans les deux modes.

## Régression
- Le compteur de temps morts par mi-temps (`S.tmUsed`) : chemin de code inchangé par ce correctif, incrément toujours au même endroit, avant l'ajout de `stopTimer()`. Pas de régression.
- `upsertMatchSnapshot()` (appelé désormais indirectement via `stopTimer()`) : fonction déjà en production depuis STORY-10/13, aucune modification de son propre code — le seul changement est la fréquence à laquelle `recordTM()` la déclenche. Pas de nouveau risque de sécurité ou de donnée exposée (déjà couvert par les audits précédents de ce mécanisme).

## Découverte annexe (informationnelle, hors scope de cette story — à ne PAS corriger ici)
En vérifiant les points de rendu du bouton TM, `renderScoreboard()` (`app.js:2436`) contient une **deuxième** occurrence de `onclick="recordTM(...)"` et de `per-btn` — mais cette fonction n'est **appelée nulle part ailleurs dans le fichier** (vérifié par recherche exhaustive de `renderScoreboard(`). C'est du code mort, dans la même famille que `renderMiniCompare()`/`renderGkBar()` déjà signalés dans `CLAUDE.md` ("Point d'attention (non résolu)"). Sans impact sur cette story (le vrai bouton TM du match live vit uniquement dans `renderMatch()`), mais à garder en tête : la documentation de `docs/architecture/chrono-mi-temps.md` (STORY-71) mentionne "deux emplacements de rendu" pour `per-btn` — à corriger mentalement en "un seul emplacement réellement actif" au moment de la QA de STORY-71, pas une nouvelle story de nettoyage à ouvrir maintenant.

## Bugs trouvés
Aucun.

## Verdict
**PASSED**

Recommandation : l'E2E Tester confirme en conditions réelles (clic TM en Mode Simple ET Mode Expert) que le bouton ▶/⏸ passe visiblement à l'état pause — parcours critique unique pour cette story, étant donné qu'il n'y a qu'un seul point d'entrée réel malgré l'apparence de duplication dans le code.
