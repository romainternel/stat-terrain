# PRD — Retours du premier match réel

## Objectif
Fermer les 3 bugs confirmés, résoudre la vraie cause du problème d'évolution du score (guidage, pas le graphique), et livrer les 2 nouvelles fonctionnalités demandées par Romain pour rendre le démarrage d'un match plus sûr et plus explicite.

## Must (cette version)

### M1 — Chrono auto-démarré au lancement du match
`launch-match-btn` appelle `startTimer()` juste après avoir basculé `S.view="match"` (une fois l'écran affiché). `S.period` fixé explicitement à `1` au même endroit (sécurité, même s'il devrait déjà l'être).

### M2 — Correction du highlight de sélection d'action
`--accent`/`--accent-rgb` définies dans `style.css` (valeurs fixes, pas d'injection dynamique depuis `app.js` — l'action sélectionnée n'appartient à aucune équipe en particulier, une seule couleur suffit). Le mécanisme d'état (`S.selectedAction`, classe `.selected`) reste inchangé, seule la CSS cassée est corrigée.

### M3 — Changement de possession automatique en Mode Simple
`recordEvent()` bascule `S.possession` après tout but/arrêt/hors cadre/PB, exactement comme `validateAndClose()` le fait déjà en Mode Expert — même condition (`isGoal||isSave||isOff||type==="TURNOVER"`), pas de nouvelle règle inventée.

### M4 — Rendre la transition de mi-temps impossible à manquer
Pas un correctif du graphique d'évolution (déjà vérifié correct) — le vrai sujet est que rien ne rappelle à l'utilisateur de basculer `S.period` à la mi-temps. Réutilise le système d'alertes déjà existant (STORY historique : "TM conseillé", "Changez de GB !", `S.tmLastAlert`, anti-spam 30s) plutôt que d'inventer un nouveau mécanisme : une alerte "Pensez à passer en mi-temps 2" se déclenche quand `S.period===1` et `S.time` dépasse la durée réglementaire d'une mi-temps, avec le même style/emplacement que les alertes existantes. Le bouton `per-btn` (bascule de mi-temps) lui-même reste au même endroit mais gagne un traitement visuel plus visible (à trancher par le Designer) tant qu'il n'a pas été cliqué alors que le temps l'exige.

### M5 — Fenêtre de validation non bloquante au lancement du match
Au clic sur "Lancer le match" : bascule vers l'écran Match (déjà le cas) + chrono démarré (M1) + une fenêtre listant les manques détectés (ex: "GB non sélectionné pour [équipe]") — jamais bloquante, réductible (icône, pour la revoir plus tard sans perdre l'information) ou fermable (croix, avec confirmation implicite "on démarre quand même").

### M6 — Mode "équipe générale" quand aucun effectif n'est sélectionné
Si `roster.length===0` pour une équipe au moment de démarrer un tir en Mode Expert, ne plus se contenter d'un terrain vide bloquant (STORY-20) — détecter cette situation (déjà couverte comme un des cas listés par M5 dans la fenêtre de validation) et permettre de valider un tir sans attribution de joueur, l'événement étant alors rattaché à l'équipe seule (`playerId:null`, cohérent avec ce que Mode Simple fait déjà). Ne concerne que le Mode Expert sans effectif — Mode Simple n'attribue déjà jamais de joueur, non affecté.

## Won't (hors scope explicite)
- Pas de blocage empêchant de démarrer un match incomplet (effectif manquant, GB manquant) — toujours un avertissement, jamais une contrainte dure (cohérent avec l'usage terrain réel, où l'app doit rester utilisable même en configuration imparfaite).
- Pas de nouveau système d'alerte générique — M4 réutilise explicitement le mécanisme déjà en place.
- Pas de correction rétroactive des matchs déjà mal enregistrés (period:1 partout) — hors scope, un correctif de saisie future, pas un outil de réparation de données.

## Vérification transverse (rappel explicite de Romain)
Chaque correctif (M1 à M4) doit être vérifié dans les **deux modes** (Simple et Expert), pas seulement celui où le problème a été observé.

## Priorité et découpage
Suggestion (à confirmer par le Scrum Master) : les corrections ciblées (M1/M2/M3/M4) forment un lot cohérent à faible risque, développable et vérifiable rapidement ; M5/M6 (fenêtre de validation + mode équipe générale) partagent un vrai risque croisé (M6 est un des types de manques que M5 doit détecter et afficher) et devraient être bundlées ensemble.
