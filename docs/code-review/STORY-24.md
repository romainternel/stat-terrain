# Code Review — STORY-24 : Écran Match en mode Simple

## Périmètre revu
- `app.js` : nouvelle fonction `renderMatchSimple()`, branchement conditionnel dans `renderMatch()` (`.ml-right`), condition ajoutée à `pdBtnHtml`, binding `[data-simple]` dans `bind()`.
- `sw.js` : `CACHE_NAME` v58 → v59.

## Conformité architecture
- Respecte le principe de "couche additive légère" de l'Architect : un seul point de branchement conditionnel (`S.mode==="simple" ? renderMatchSimple() : ...`) dans `.ml-right`, `.ml-left` et `.ml-bottom` restent des blocs communs non touchés.
- **Amélioration notable par rapport au plan d'architecture** : le Developer a évité de créer une nouvelle fonction `recordSimpleEvent()` en découvrant que `recordEvent(type,team,x,y,playerId)` (déjà existante, avec paramètres optionnels) fait exactement le travail. C'est exactement le type de réutilisation que le mindset Developer doit rechercher — moins de code neuf, moins de surface à maintenir. Vérifié : `recordEvent` sans x/y/playerId construit bien un événement avec ces champs à `null`/`undefined`, cohérent avec les deux autres appelants existants.
- Le `gkId` est posé automatiquement par `recordEvent` (déjà conditionné à `isGoal||isSave||isOff`, qui couvre exactement les 3 types utilisés en Simple) — aucune modification nécessaire à cette logique, confirmé dans le diff (aucune touche sur `recordEvent`).

## Conventions de code
- Style cohérent (template literals, pas de framework, indentation identique au reste du fichier).
- `renderMatchSimple()` suit le même pattern de fonctions locales imbriquées (`simpleBtn`, `teamRow`) que le reste du fichier utilise déjà pour des rendus similaires (ex: `actBtn` dans `renderMatch()`).

## Réutilisation vs duplication
- RAS — `recordEvent` réutilisée telle quelle, `.ml-left`/`.ml-bottom` réutilisés sans changement, badge de mode inspiré du style déjà existant du badge "MODE PENALTY" (cohérent avec la prescription du Visual Crafter).

## Scope
- Diff strictement contenu au périmètre de la story. Aucune touche sur `renderMatchPanel()`, `recordEvent()`, ou tout autre code du chemin Expert — seul un point de branchement (`S.mode`) a été ajouté à deux endroits (`.ml-right`, `pdBtnHtml`).
- Point vérifié explicitement : les alertes automatiques (`checkGkConsecutiveAlert`/`checkTimeoutAdvisor`) ne sont pas déclenchées par les boutons Simple — le Developer a documenté que c'est un alignement volontaire avec le comportement déjà existant de `recordEvent` pour ses 2 autres appelants (pas une omission). Comportement cohérent, accepté.

## Gestion d'erreurs
- Non applicable — pas de nouvel appel externe/asynchrone, réutilisation d'une fonction déjà éprouvée.

## Sécurité basique
- Aucune donnée utilisateur interpolée sans échappement dans `renderMatchSimple()` (`S.home.name`/`S.away.name` sont déjà affichés ailleurs dans l'app de la même façon, pas un nouveau vecteur). Pas de saisine du Security Auditor nécessaire.

## Verdict
**APPROUVÉ**

Aucune remarque bloquante. La déviation positive (réutilisation de `recordEvent` au lieu d'une nouvelle fonction) est un exemple à citer pour de futures stories similaires.
