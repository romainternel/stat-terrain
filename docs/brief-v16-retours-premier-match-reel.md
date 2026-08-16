# Brief — Retours du premier match réel joué en conditions réelles

## Origine
Romain a joué un premier match complet (Mode Simple) et remonte 5 points en un seul message. Certains sont des bugs déjà root-causés par lecture de code, un a été définitivement élucidé par un test direct pendant ce cadrage, et deux sont de vraies nouvelles fonctionnalités.

## 1. Chrono qui ne démarre pas automatiquement — BUG CONFIRMÉ
"Lancer le match" (`launch-match-btn`) fixe l'identifiant Supabase, s'abonne au canal temps réel, pousse le snapshot initial, bascule sur l'écran Match — mais n'appelle jamais `startTimer()`. L'utilisateur doit cliquer une seconde fois sur "▶ Start". `S.period` vaut déjà `1` par défaut (`freshState()`/`newMatch()`) — à sécuriser explicitement au même endroit plutôt que de faire confiance à l'état résiduel.

## 2. Pas de confirmation visuelle au clic sur une action (BUT/Tir arrêté/etc.) — BUG CONFIRMÉ, CSS cassé
Le mécanisme existe déjà et fonctionne côté état (`S.selectedAction` est bien mis à jour, la classe `.selected` est bien appliquée sur le bouton) — mais `.act-h.selected` (`style.css`) référence deux variables CSS (`--accent`, `--accent-rgb`) qui **ne sont définies nulle part dans `app.js`**. `var(--accent)` retombe sur rien (bordure inchangée), `rgba(var(--accent-rgb),.22)` est une valeur CSS invalide (le `box-shadow` entier est silencieusement ignoré par le navigateur). Le retour visuel est donc systématiquement invisible, pas seulement "pas assez marqué" — un vrai bug, pas un réglage à ajuster.

## 3. Pas de changement de possession automatique — BUG CONFIRMÉ, présent seulement en Mode Expert
La fonctionnalité existe et fonctionne déjà dans `validateAndClose()` (Mode Expert) : un commentaire explicite `// Auto-switch possession after shots and turnovers` bascule `S.possession` après tout tir (but/arrêt/hors cadre) ou perte de balle. **`recordEvent()` (utilisée exclusivement par Mode Simple) n'a aucune ligne équivalente.** Romain a testé en Mode Simple — explique exactement l'absence observée. Le Mode Expert n'est probablement pas concerné (à revérifier quand même, cf. contrainte de Romain de tout vérifier dans les deux modes).

## 4. Évolution du score : rien de nouveau affiché pour la mi-temps 2 — ÉLUCIDÉ PENDANT CE CADRAGE, PAS UN BUG DE GRAPHIQUE
Test direct mené avant d'écrire ce brief : `renderStatCompare()` appelée avec un jeu d'événements construit dans l'ordre réel de l'app (`S.events.unshift()` = le plus récent en index 0), 2 buts en période 1 et 3 buts en période 2. Résultat : les points calculés progressent correctement `0 → 5 → 10 → 32 → 38 → 45` (le décalage +30 pour la période 2 fonctionne exactement comme prévu). **Le calcul et le rendu du graphique sont corrects.**

Conclusion : le vrai problème n'est pas dans le graphique, mais très probablement en amont — les buts de la "2e mi-temps" du match de Romain portent en réalité `period:1` parce que **la transition de mi-temps n'a jamais été déclenchée pendant le match** (le bouton qui bascule `S.period` et remet le chrono à zéro n'a probablement pas été cliqué, ou n'a pas été assez visible/évident pour que Romain pense à le faire). Ce n'est donc pas une story de correction de graphique, mais une conséquence directe du même besoin de guidage que les points 5 et 6 ci-dessous (rendre le déroulé du match plus explicite).

## 5. Fenêtre de validation au lancement du match — VRAIE NOUVELLE FONCTIONNALITÉ
Romain décrit précisément : au clic sur "Lancer le match", en plus du chrono auto-démarré (point 1), une petite fenêtre non bloquante liste ce qui manque (ex: "pas de GB sélectionné") — réductible via une icône (pour la revoir plus tard) ou fermable via une croix, sans jamais empêcher de démarrer le match. Rien de tel n'existe aujourd'hui — la mise en place actuelle du match ne valide/signale rien.

## 6. Mode "équipe générale" quand aucun joueur ni GB n'est sélectionné — VRAIE NOUVELLE FONCTIONNALITÉ
Aujourd'hui (STORY-20), si `roster.length===0`, le terrain affiche un état vide (`renderCourtEmptyState()`) et bloque toute attribution de tir à un joueur — comportement volontaire à l'époque ("le terrain n'affiche que les joueurs sélectionnés"), mais qui devient un vrai blocage si Romain veut suivre un match SANS effectif détaillé saisi. Il demande une dégradation automatique vers un mode où les événements s'attribuent à l'équipe en général, pas à un joueur précis — une bascule implicite plutôt qu'un blocage. Proche en esprit de Mode Simple (déjà sans attribution de joueur) mais concerne ici le Mode Expert sans effectif, une situation différente à cadrer séparément.

## Ce qui ne change pas
Le reste du fonctionnement de la saisie (Mode Simple/Expert eux-mêmes, la logique de tir/zone/GB une fois un joueur attribué, tout ce qui a été livré dans les cycles précédents).
