# STORY-54 — Écran de lancement dédié sur la page Match

**En tant que** Romain,
**Je veux** trouver un gros bouton "Lancer le match" directement sur l'onglet Match plutôt que caché en bas de l'onglet Équipes,
**Afin de** démarrer un match sans devoir savoir qu'il faut d'abord aller sur Équipes.

Demande directe : "Est-ce qu'on peut mettre lancer le match en gros plutôt sur la page match ?" — confirmé via question de clarification : écran dédié (le bouton remplace l'interface de saisie tant que le match n'est pas lancé), pas une bannière au-dessus de l'interface déjà visible.

## Contexte technique
Corrige au passage un trou trouvé pendant l'implémentation : avant cette story, accéder à l'onglet Match sans être passé par le bouton "Lancer le match" (ex. clic direct sur "⚡ Match" depuis Équipes) affichait immédiatement l'interface de saisie complète, sans chrono auto-démarré ni bandeau de validation (STORY-52/53) — l'utilisateur pouvait saisir des actions sur un match jamais vraiment "lancé".

Nouvelle fonction `renderMatchLaunch()` (gros bouton centré + noms d'équipe + `launchWarnings()` en lecture informative), appelée en early-return par `renderMatch()` quand `!S.currentMatchId && S.events.length===0`. La double condition (pas seulement `currentMatchId`) est nécessaire car `loadMatchAsCurrent()` (bouton "📂 Charger" et raccourci PDF, STORY-36) met délibérément `currentMatchId` à `null` par sécurité P0 tout en chargeant un vrai match archivé (événements déjà présents) — sans le `S.events.length===0`, charger un match afficherait à tort l'écran de lancement au lieu du match réellement chargé.

Le petit bouton précédemment en bas d'Équipes est retiré (remplacé par une phrase d'aide pointant vers l'onglet Match). Le bouton "⚙ Réglages" et sa pastille d'alerte réduite (STORY-53) sont masqués tant qu'aucun match n'est réellement actif, pour la même raison (rien à régler avant d'avoir un match en cours).

## Critères d'acceptation
- [x] Onglet Match sans match actif (`!S.currentMatchId && S.events.length===0`) → écran dédié : noms des deux équipes, gros bouton "▶ Lancer le match", liste des manques (`launchWarnings()`) si applicable — l'interface de saisie complète n'apparaît pas
- [x] Clic sur le bouton → comportement inchangé (chrono auto-démarré, `S.period=1`, bascule vers l'interface complète, cf. STORY-52/M1)
- [x] Bouton retiré de l'onglet Équipes, remplacé par une indication textuelle
- [x] Résister au cas `loadMatchAsCurrent()` (`currentMatchId===null` mais `S.events` déjà rempli) — l'interface complète s'affiche directement, pas l'écran de lancement
- [x] Match repris (`resumeMatch()`) ou déjà en cours → écran de lancement jamais affiché (`currentMatchId` déjà fixé avant `S.view="match"`)
- [x] `#settings-btn` et la pastille d'alerte réduite masqués sur l'écran de lancement, visibles dès qu'un match est actif

## Vérifié par CDP (vrais clics)
Écran de lancement affiché sur état frais (capture d'écran, 820px et 390px) ; bouton retiré d'Équipes (`#launch-match-btn` absent sur cet onglet) ; clic réel sur le bouton → `S.running===true`, `S.period===1`, `S.currentMatchId` défini, interface complète affichée (capture d'écran) ; cas `loadMatchAsCurrent()` simulé (`currentMatchId=null`, `S.events` non vide) → interface complète affichée directement, pas l'écran de lancement.

## Hors scope
Aucun changement sur le contenu du bandeau de validation (STORY-53) lui-même, seulement sur son point d'apparition (déjà présent dans l'écran de lancement en plus de son apparition post-lancement existante).

## Taille
S — un écran de garde + une condition de bascule, pas de nouvelle donnée persistée.
