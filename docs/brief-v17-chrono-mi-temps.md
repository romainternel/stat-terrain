# Brief — Chrono : temps mort et changement de mi-temps

## Origine
Demande directe de Romain, en conditions d'usage réel (bord de terrain, iPad). Deux comportements du chrono ne correspondent pas à ce qui se passe réellement pendant un match.

## 1. Le bouton "Temps mort" ne coupe pas le chrono — BUG CONFIRMÉ
Vérifié dans le code : deux chemins mènent à un temps mort.
- `clickTeam(team)` (workflow action-bar historique) appelle bien `stopTimer()`.
- `recordTM(team)` — celui réellement branché sur le bouton "⏸ TM" du timer aujourd'hui (`.mlt-btn-tm`, décrit dans `CLAUDE.md`) — **n'appelle jamais `stopTimer()`**. Le chrono continue de tourner pendant tout le temps mort, ce qui fausse le temps de jeu affiché et tout ce qui en dépend (rappel de mi-temps à 30min, timing des tags).

## 2. Changement de mi-temps sans confirmation ni garde-fou — VRAIE NOUVELLE FONCTIONNALITÉ (corrige un flux à risque)
Aujourd'hui, le bouton "MT" (`per-btn`) bascule la période instantanément au clic, sans aucune confirmation :
- MT1 → MT2 : le chrono est stoppé et remis à 0, mais **reste à l'arrêt** — rien ne le relance, l'utilisateur doit penser à recliquer sur ▶.
- MT2 → MT1 : aucune remise à zéro, aucun arrêt — le chrono continue de tourner sur le temps de la mi-temps 2, ce qui casse silencieusement l'attribution `period` de tous les tags suivants.
- **Aucune confirmation dans les deux sens** : un clic accidentel sur "MT" (bouton présent en permanence dans le timer, cf. `CLAUDE.md` "bouton MT pulsant" au rappel de mi-temps) bascule immédiatement la période et perd le temps de jeu de la mi-temps en cours, sans aucun rattrapage possible aujourd'hui.

Romain décrit précisément le comportement attendu :
- **Clic MT1 → MT2** : un message demande de confirmer que la mi-temps 1 est bien terminée. Si oui, le chrono repasse à 0 et redémarre automatiquement en mi-temps 2. Si non, rien ne change.
- **Clic accidentel MT2 → MT1** : un message demande de confirmer le retour à la mi-temps 1. Si oui, le chrono revient au **timing du dernier tag enregistré de la mi-temps 1** (pas à 0, pas au temps réglementaire — au dernier événement réellement tagué pendant MT1). Si non, rien ne change.
- **Uniquement quand le passage à la mi-temps 2 est validé** (pas au retour) : un message d'alerte supplémentaire rappelle de vérifier si les gardiens sont toujours les mêmes — un changement de gardien à la pause est fréquent et n'est aujourd'hui suivi par aucun garde-fou (le `gkId` sélectionné reste celui de MT1 tant que personne ne le change manuellement).

## Ce qui ne change pas
- Le compteur de temps morts par mi-temps (`S.tmUsed`, max 2/mi-temps, 3 au total) — aucune modification de cette logique.
- Le rappel automatique de fin de MT1 réglementaire (30min, toast + bouton pulsant) — reste le déclencheur qui pousse à cliquer sur MT, mais n'est pas modifié par ce brief.
- Le reste du fonctionnement du chrono (▶/⏸ manuel, `startTimer()`/`stopTimer()`) — inchangé, réutilisé tel quel.

## Utilisateurs
Romain (ou tout aidant occasionnel) sur iPad, en bord de terrain, pendant un match officiel — le même contexte que tout le reste de l'app. Les deux comportements corrigés touchent un geste fait au minimum deux fois par match (le passage MT1→MT2) et un risque de clic accidentel toujours possible sur un bouton présent en permanence pendant tout le match.

## Vision
Le chrono ne doit jamais mentir sur le temps réellement joué, et changer de mi-temps ne doit jamais être un geste qu'on peut faire par erreur sans rattrapage.

## Scope
**Dans le scope :**
- `recordTM()` arrête le chrono.
- Confirmation bloquante dans les deux sens du changement de mi-temps (MT1→MT2 et MT2→MT1).
- Remise à 0 + redémarrage automatique du chrono en MT2 validée.
- Restauration du chrono au dernier tag de MT1 en cas de retour validé depuis MT2.
- Alerte "vérifier les gardiens" uniquement au passage validé vers MT2.

**Hors scope (explicitement) :**
- Toute détection automatique d'un changement réel de gardien (comparaison de `gkId`) — l'alerte est un simple rappel, pas une vérification technique.
- Toute nouvelle granularité de zone de tir (6m/6-9m/9m — idée mentionnée par Romain en passant, à cadrer séparément si elle est confirmée plus tard, pas dans ce brief).
- Modification du compteur de temps morts ou du rappel de fin de MT1 réglementaire.

## Critères de succès
- Un temps mort déclenché depuis le bouton du timer arrête visiblement le chrono, sans exception.
- Impossible de changer de mi-temps sans un geste de confirmation explicite, dans les deux sens.
- Après un passage validé en MT2, le chrono affiche 00:00 et tourne déjà.
- Après un retour validé en MT1, le chrono affiche le temps du dernier tag de MT1, pas 00:00 ni le temps de MT2.
- Le rappel gardien apparaît systématiquement au passage validé vers MT2, jamais au retour vers MT1.

## Questions en suspens
Aucune bloquante — Romain a donné un comportement précis et complet pour les deux sens du changement de mi-temps. Un point à trancher en Architecture : le chrono redémarre-t-il automatiquement (running) après un retour confirmé vers MT1, ou reste-t-il à l'arrêt en attendant un ▶ manuel ? Romain ne l'a précisé que pour le sens MT1→MT2 ("se met en route"), pas pour le retour.
