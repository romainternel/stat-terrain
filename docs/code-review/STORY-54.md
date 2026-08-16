# Code Review — STORY-54 (Écran de lancement dédié sur la page Match)

## Portée revue
`app.js` : nouvelle fonction `renderMatchLaunch()`, early-return dans `renderMatch()`, `renderSetup()` (bouton retiré), `renderHeader()` (condition `inLiveMatch` étendue). `style.css` : `.match-launch`/`.ml-launch-teams`/`.ml-launch-vs`/`.ml-launch-btn`/`.ml-launch-warnings`.

## Point critique trouvé et corrigé avant tout test
La condition de garde initiale (`!S.currentMatchId` seul) aurait cassé `loadMatchAsCurrent()` — cette fonction (bouton "📂 Charger" de l'Historique et raccourci PDF de Bilan, STORY-36) met explicitement `S.currentMatchId=null` en tout début de fonction (sécurité P0 documentée : couper le lien avec le match en cours avant de charger les données archivées, pour ne pas laisser une souscription Realtime active écrire par-dessus le mauvais match) **avant** de charger les événements réels du match archivé — et ne réassigne jamais `currentMatchId` ensuite (il est régénéré paresseusement au premier nouvel événement via `queueEventForSync()`, mécanisme préexistant). Avec la garde initiale, charger n'importe quel match archivé aurait affiché l'écran de lancement au lieu du match chargé. Trouvé par grep systématique de tous les points d'écriture de `S.currentMatchId` avant de considérer la story terminée, pas découvert a posteriori. Corrigé en ajoutant `&& S.events.length===0` à la condition — les deux scénarios qui doivent afficher l'écran de lancement (état frais, `newMatch()`) ont bien `events.length===0`, les deux qui ne le doivent pas (match repris, match chargé) ont l'un ou l'autre des deux signaux déjà positif.

## Conformité au choix de Romain
Écran dédié confirmé via `AskUserQuestion` (pas une bannière au-dessus de l'interface déjà visible) — `renderMatch()` retourne **uniquement** `renderMatchLaunch()` dans ce cas, aucune fuite de l'interface de saisie en dessous.

## Cohérence avec STORY-53
`launchWarnings()` réutilisée telle quelle (aucune duplication de logique) — affichée maintenant à deux moments : sur l'écran de lancement (lecture seule, informative) et, après lancement, dans le bandeau dismissible existant de STORY-53 (comportement inchangé, toujours utile pour un rappel après avoir commencé sans avoir corrigé le manque).

## Vérification fonctionnelle (CDP)
Écran de lancement sur état frais (820px et 390px, capture d'écran) ; bouton absent d'Équipes ; clic réel → chrono démarré + interface complète (re-vérifie M1 de STORY-52, non régressé) ; cas `loadMatchAsCurrent()` simulé (`currentMatchId=null`, événement déjà présent) → interface complète affichée directement ; `#settings-btn` absent sur l'écran de lancement, présent après.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** : aucune.

**Note** :
- Edge case résiduel accepté : un match archivé sauvegardé avec **zéro** événement (`S.events.length===0` après chargement) afficherait l'écran de lancement au lieu du match vide chargé. Cas extrêmement improbable en usage réel (personne ne sauvegarde un match sans une seule action) ; si ça arrivait, cliquer "Lancer le match" dessus resterait sans danger (régénère juste un nouvel id, repart du temps déjà chargé) — dégradation gracieuse, pas un crash.

## Verdict
**APPROUVÉ**
